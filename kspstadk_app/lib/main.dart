import 'dart:async';

import 'package:flutter/material.dart';

import 'app.dart';
import 'data/repository.dart';
import 'data/site_config.dart';
import 'data/store.dart';
import 'data/wp_api.dart';
import 'downloads/download_manager.dart';
import 'state/app_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final services = await createServices();
  runApp(KspstadkApp(services: services));
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
  );
}
