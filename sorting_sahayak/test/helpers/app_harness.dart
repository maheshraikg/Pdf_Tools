import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sorting_sahayak/core/app_scope.dart';
import 'package:sorting_sahayak/core/l10n/app_localizations.dart';
import 'package:sorting_sahayak/core/settings.dart';
import 'package:sorting_sahayak/core/theme.dart';
import 'package:sorting_sahayak/data/app_services.dart';
import 'package:sorting_sahayak/data/import/scheme_io.dart';
import 'package:sorting_sahayak/data/scheme_repo.dart';

import 'fixture.dart';

class Harness {
  Harness(this.settings, this.services);

  final Settings settings;
  final AppServices services;

  static Future<Harness> create(WidgetTester tester, {bool sample = true, bool parcelExtras = false, Map<String, Object> prefs = const {}}) async {
    SharedPreferences.setMockInitialValues(prefs);
    late Harness h;
    await tester.runAsync(() async {
      final settings = await Settings.load();
      final userDb = await memoryUserDb();
      if (sample) await installSampleScheme(SchemeRepo(userDb), (p) async => File(p).readAsBytesSync(), withParcelExtras: parcelExtras);
      final services = AppServices(directoryDb: await fixtureDirectoryDb(), userDb: userDb);
      await services.reloadActive();
      h = Harness(settings, services);
    });
    return h;
  }

  Widget wrap(Widget child, {Locale locale = const Locale('en')}) => AppScope(
    settings: settings,
    services: services,
    child: MaterialApp(
      theme: buildTheme(Brightness.light),
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: child,
    ),
  );
}

/// Lets real (ffi) database futures complete, then rebuilds.
Future<void> settle(WidgetTester tester, {int rounds = 3}) async {
  for (var i = 0; i < rounds; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 40)));
    await tester.pump();
  }
}
