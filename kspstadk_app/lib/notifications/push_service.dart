import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../firebase_options.dart';
import '../state/app_state.dart';
import 'deep_links.dart';

/// Push notifications for new posts via Firebase Cloud Messaging topics.
///
/// Messages are sent by the free GitHub Actions workflow
/// (.github/workflows/kspstadk-notify.yml → kspstadk_app/tool/notify.py).
class PushService {
  PushService({required this.settings, required this.inbox, required this.onOpen});

  final Settings settings;
  final Inbox inbox;

  /// Navigates to a notification's target (wired to the app navigator).
  final void Function(LinkTarget target) onOpen;

  final _local = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  bool get available => DefaultFirebaseOptions.isConfigured;

  static const _channel = AndroidNotificationChannel(
    'kspstadk_posts',
    'ಹೊಸ ಪೋಸ್ಟ್‌ಗಳು / New posts',
    description: 'KSPSTADK new post alerts',
    importance: Importance.high,
  );

  Future<void> init() async {
    if (!available || _ready) return;
    try {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
      await _local.initialize(
        settings: const InitializationSettings(android: AndroidInitializationSettings('@mipmap/ic_launcher')),
        onDidReceiveNotificationResponse: (r) {
          final id = int.tryParse(r.payload ?? '');
          if (id != null) onOpen(PostTarget(id));
        },
      );
      final android = _local.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      await android?.createNotificationChannel(_channel);

      final fm = FirebaseMessaging.instance;
      await fm.requestPermission();
      FirebaseMessaging.onMessage.listen(_onForeground);
      FirebaseMessaging.onMessageOpenedApp.listen(_onOpened);
      final initial = await fm.getInitialMessage();
      _ready = true;
      await syncTopics();
      if (initial != null) _onOpened(initial);
    } catch (e) {
      debugPrint('Push disabled: $e');
    }
  }

  /// Subscribes to the user's chosen topics and unsubscribes from the rest.
  Future<void> syncTopics() async {
    if (!_ready) return;
    final wanted = settings.topics;
    final fm = FirebaseMessaging.instance;
    final every = {...Topics.general, for (var n = 1; n <= 10; n++) Topics.forClass(n)};
    for (final t in every) {
      try {
        if (wanted.contains(t)) {
          await fm.subscribeToTopic(t);
        } else {
          await fm.unsubscribeFromTopic(t);
        }
      } catch (e) {
        debugPrint('topic $t: $e');
      }
    }
  }

  Future<void> _record(RemoteMessage m) => inbox.add(InboxItem(
        id: m.messageId ?? '${DateTime.now().millisecondsSinceEpoch}',
        title: m.notification?.title ?? '${m.data['title'] ?? ''}',
        body: m.notification?.body ?? '${m.data['category'] ?? ''}',
        postId: int.tryParse('${m.data['post_id'] ?? ''}'),
        at: m.sentTime ?? DateTime.now(),
      ));

  Future<void> _onForeground(RemoteMessage m) async {
    await _record(m);
    final n = m.notification;
    await _local.show(
      id: m.hashCode & 0x7fffffff,
      title: n?.title ?? '${m.data['title'] ?? ''}',
      body: n?.body ?? '${m.data['category'] ?? ''}',
      payload: '${m.data['post_id'] ?? ''}',
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
          styleInformation: const BigTextStyleInformation(''),
        ),
      ),
    );
  }

  void _onOpened(RemoteMessage m) {
    unawaited(_record(m).then((_) => inbox.markRead(m.messageId ?? '')));
    final target = notificationTarget(m.data);
    if (target != null) onOpen(target);
  }
}
