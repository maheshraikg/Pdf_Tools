/// Android-only features implemented in MainActivity.kt / SilentScheduler.kt.
library;

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../core/alerts.dart';

enum LocationError { denied, disabled, unavailable }

class LocationResult {
  const LocationResult({
    this.latitude,
    this.longitude,
    this.altitude,
    this.error,
  });
  final double? latitude, longitude, altitude;
  final LocationError? error;
  bool get ok => error == null;
}

/// How the phone keeps its clock.
class ClockStatus {
  const ClockStatus({this.autoTime = true, this.autoZone = true, this.offset});

  /// "Automatic date & time" and "Automatic time zone" are on.
  final bool autoTime, autoZone;

  /// Phone clock minus satellite time, when a recent GPS fix gave it.
  final Duration? offset;

  /// Off by more than 90 seconds: prayer times would be shown late/early.
  bool get clockWrong => offset != null && offset!.inSeconds.abs() > 90;

  bool get ok => autoTime && autoZone && !clockWrong;
}

class Native {
  static const _ch = MethodChannel('com.maheshrai.waqt/native');

  static bool get supported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// Calls [method]; null when the platform side is missing (tests, other
  /// platforms) or fails.
  static Future<T?> _call<T>(String method, [Object? args]) async {
    if (!supported) return null;
    try {
      return await _ch.invokeMethod<T>(method, args);
    } on MissingPluginException {
      return null;
    } on PlatformException catch (e) {
      debugPrint('Native.$method failed: $e');
      return null;
    }
  }

  /// One location fix from the phone's GPS / network provider (asks for
  /// permission when needed). No Google Play services are used.
  static Future<LocationResult> getLocation({bool prompt = true}) async {
    if (!supported) {
      return const LocationResult(error: LocationError.unavailable);
    }
    try {
      final r = await _ch.invokeMapMethod<String, dynamic>('getLocation', {
        'prompt': prompt,
      });
      if (r == null) {
        return const LocationResult(error: LocationError.unavailable);
      }
      return LocationResult(
        latitude: (r['latitude'] as num).toDouble(),
        longitude: (r['longitude'] as num).toDouble(),
        altitude: (r['altitude'] as num?)?.toDouble(),
      );
    } on MissingPluginException {
      return const LocationResult(error: LocationError.unavailable);
    } on PlatformException catch (e) {
      return LocationResult(
        error: switch (e.code) {
          'denied' => LocationError.denied,
          'disabled' => LocationError.disabled,
          _ => LocationError.unavailable,
        },
      );
    }
  }

  static Future<bool> hasDndAccess() async =>
      await _call<bool>('hasDndAccess') ?? false;

  static Future<void> openDndSettings() => _call<void>('openDndSettings');

  static Future<bool> isIgnoringBatteryOptimizations() async =>
      await _call<bool>('isIgnoringBatteryOptimizations') ?? true;

  static Future<void> openBatterySettings() =>
      _call<void>('openBatterySettings');

  /// Sends new data to the home-screen widget.
  static Future<void> updateWidget(String json) =>
      _call<void>('updateWidget', {'data': json});

  /// Replaces the auto-silent schedule.
  static Future<void> setSilentWindows(
    List<SilentWindow> windows,
    SilentMode mode,
  ) async {
    await _call<void>('setSilentWindows', {
      'mode': mode.name,
      'windows': [
        for (final w in windows)
          [w.start.millisecondsSinceEpoch, w.end.millisecondsSinceEpoch],
      ],
    });
  }

  /// Replaces the Azan player schedule: events are maps with at (epoch ms),
  /// title, body, sound, volume (% of the alarm maximum, 0 = phone volume)
  /// and full (over the lock screen).
  static Future<void> setAzanAlarms(
    List<Map<String, Object>> events, {
    required bool vibrate,
    required bool playWhenSilent,
    required String stopLabel,
    required String channelName,
    required bool fullScreen,
  }) => _call<void>('setAzanAlarms', {
    'fullScreen': fullScreen,
    'events': jsonEncode(events),
    'vibrate': vibrate,
    'whenSilent': playWhenSilent,
    'stopLabel': stopLabel,
    'channelName': channelName,
  });

  /// Reminders answered from the notification ("I did" / "Remind me in
  /// 30 min"): maps with id, at, latest (epoch ms), title, text and done.
  static Future<void> setNotices(
    List<Map<String, Object>> notices, {
    required String laterLabel,
    required String channelName,
  }) => _call<void>('setNotices', {
    'notices': jsonEncode(notices),
    'laterLabel': laterLabel,
    'channelName': channelName,
  });

  /// Copies a picked audio file into app storage; returns its sound id.
  static Future<String?> saveSound(String slot, String ext, Uint8List bytes) =>
      _call<String>('saveSound', {'slot': slot, 'ext': ext, 'bytes': bytes});

  /// Plays [sound] now (preview / test) with a Stop notification.
  static Future<void> playSound(
    String sound,
    String title,
    String body, {
    int volume = 0,
  }) => _call<void>('playSound', {
    'sound': sound,
    'title': title,
    'body': body,
    'volume': volume,
  });

  static Future<void> stopSound() => _call<void>('stopSound');

  /// Android 14+ asks the user to allow full-screen alerts.
  static Future<bool> canFullScreen() async =>
      await _call<bool>('canFullScreen') ?? true;

  static Future<void> openFullScreenSettings() =>
      _call<void>('openFullScreenSettings');

  static Future<ClockStatus> clockStatus() async {
    final r = await _call<Map<Object?, Object?>>('clockStatus');
    if (r == null) return const ClockStatus();
    final off = r['offsetMs'] as num?;
    return ClockStatus(
      autoTime: r['autoTime'] as bool? ?? true,
      autoZone: r['autoZone'] as bool? ?? true,
      offset: off == null ? null : Duration(milliseconds: off.toInt()),
    );
  }

  static Future<void> openDateSettings() => _call<void>('openDateSettings');

  /// The permanent next-prayer notification: states with from / countdown
  /// (epoch ms), title and text; an empty list removes it.
  static Future<void> setStatusStates(
    List<Map<String, Object>> states,
    String channelName,
  ) => _call<void>('setStatusStates', {
    'states': jsonEncode(states),
    'channelName': channelName,
  });

  /// Lets the mosque display show over the lock screen.
  static Future<void> showOnLockScreen(bool on) =>
      _call<void>('showOnLockScreen', {'on': on});
}
