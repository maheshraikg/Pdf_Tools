import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:kspstadk_app/app.dart';
import 'package:kspstadk_app/content/post_content.dart';
import 'package:kspstadk_app/data/repository.dart';
import 'package:kspstadk_app/data/site_config.dart';
import 'package:kspstadk_app/data/store.dart';
import 'package:kspstadk_app/data/wp_api.dart';
import 'package:kspstadk_app/downloads/download_manager.dart';
import 'package:kspstadk_app/state/app_state.dart';
import 'package:kspstadk_app/ui/screens/post_screen.dart';
import 'package:kspstadk_app/ui/widgets/common.dart';

import 'fixtures.dart';

const json = {'content-type': ['application/json']};

/// Services backed by in-memory stores and a mocked REST API that answers
/// with the real fixtures.
AppServices testServices({DioAdapter Function(Dio)? configure, Stores? stores, String locale = 'kn', DownloadManager? downloads}) {
  NetImage.enabled = false;
  postParser = (html) async => parsePostContent(html);
  final dio = Dio(BaseOptions(baseUrl: 'https://kspstadk.com/wp-json/wp/v2'))
    // The default transformer decodes big bodies in an isolate, which never
    // completes under the widget-test fake clock.
    ..transformer = SyncTransformer();
  final adapter = DioAdapter(dio: dio, matcher: const UrlRequestMatcher());
  final posts = fixture('posts_embed_20.json') as List;
  adapter
    ..onGet('/posts', (s) => s.reply(200, posts, headers: {...json, 'x-wp-totalpages': ['93'], 'x-wp-total': ['1853']}))
    ..onGet('/categories', (s) => s.reply(200, fixture('categories.json'), headers: {...json, 'x-wp-totalpages': ['1']}));
  for (final p in posts) {
    adapter.onGet('/posts/${p['id']}', (s) => s.reply(200, p, headers: json));
  }
  configure?.call(dio);
  final s = stores ?? Stores.memory();
  s.prefs.put('locale', locale);
  final repo = Repository(WpApi(dio), s);
  return AppServices(
    stores: s,
    repo: repo,
    config: SiteConfig.parse(File('assets/config/home_sections.json').readAsStringSync()),
    settings: Settings(s.prefs),
    bookmarks: Bookmarks(s.bookmarks),
    history: History(s.history),
    inbox: Inbox(s.inbox),
    downloads: downloads ?? DownloadManager(s.downloads, dio: dio, baseDir: () async => Directory.systemTemp.createTemp('ksp')),
    network: NetworkStatus(),
  );
}

Future<void> pumpApp(WidgetTester tester, AppServices services, {Widget? home}) async {
  tester.view.physicalSize = const Size(1080, 2340);
  tester.view.devicePixelRatio = 2.75;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(KspstadkApp(services: services, home: home));
  // Let streams, futures and a few animation frames run (shimmer never settles).
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}
