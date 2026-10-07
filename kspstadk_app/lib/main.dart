import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'data/repository.dart';
import 'data/site_config.dart';
import 'data/store.dart';
import 'data/wp_api.dart';
import 'downloads/download_manager.dart';
import 'notifications/deep_links.dart';
import 'notifications/push_service.dart';
import 'state/app_state.dart';
import 'ui/link_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final services = await createServices();
  services.push = PushService(settings: services.settings, inbox: services.inbox, onOpen: routeTarget);
  runApp(KspstadkApp(services: services));
  _watchConnectivity(services.network);
  _watchAppLinks();
  // After the first frame so startup stays fast.
  WidgetsBinding.instance.addPostFrameCallback((_) => services.push!.init());
}

Future<AppServices> createServices({Stores? stores, WpApi? api}) async {
  final s = stores ?? await Stores.openHive();
  final config = await SiteConfig.load(s.prefs);
  unawaited(SiteConfig.refreshRemote(s.prefs));
  final repo = Repository(api ?? WpApi(), s);
  // Keep the response cache bounded; bookmarks live in their own box.
  unawaited(repo.cache.prune(const Duration(days: 30)));
  return AppServices(
    stores: s,
    repo: repo,
    config: config,
    settings: Settings(s.prefs),
    bookmarks: Bookmarks(s.bookmarks),
    history: History(s.history),
    inbox: Inbox(s.inbox),
    downloads: DownloadManager(s.downloads),
    network: NetworkStatus(),
  );
}

void _watchConnectivity(NetworkStatus status) {
  bool online(List<ConnectivityResult> r) => r.any((c) => c != ConnectivityResult.none);
  final c = Connectivity();
  c.checkConnectivity().then((r) => status.online = online(r), onError: (_) => true);
  c.onConnectivityChanged.listen((r) => status.online = online(r), onError: (_) {});
}

/// Android App Links (https://kspstadk.com/...) and kspstadk:// links.
void _watchAppLinks() {
  final links = AppLinks();
  void handle(Uri uri) {
    final t = parseDeepLink(uri);
    if (t != null) routeTarget(t);
  }

  links.getInitialLink().then((u) {
    if (u != null) handle(u);
  }, onError: (_) {});
  links.uriLinkStream.listen(handle, onError: (_) {});
}
