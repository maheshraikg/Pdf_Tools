import 'dart:async';

import 'package:beat_mitra/app.dart';
import 'package:beat_mitra/app_state.dart';
import 'package:beat_mitra/core/app_lock.dart';
import 'package:beat_mitra/core/geo.dart';
import 'package:beat_mitra/core/services/location_service.dart';
import 'package:beat_mitra/core/services/photo_store.dart';
import 'package:beat_mitra/core/services/secret_store.dart';
import 'package:beat_mitra/core/services/voice_service.dart';
import 'package:beat_mitra/core/settings.dart';
import 'package:beat_mitra/data/db.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class FakeLocation implements LocationService {
  FakeLocation(this.point);
  GeoPoint point;
  final _ctrl = StreamController<GpsFix>.broadcast();
  GpsFix get _fix => GpsFix(point, 5, DateTime.now());

  @override
  Future<LocationProblem> ensurePermission() async => LocationProblem.none;
  @override
  Future<GpsFix?> current() async => _fix;
  @override
  Stream<GpsFix> fixes() async* {
    yield _fix;
    yield* _ctrl.stream;
  }

  @override
  Stream<double?> heading() => Stream.value(0);
  @override
  Future<void> openSettings() async {}
}

/// Services backed by an in-memory database and fakes.
Future<AppServices> testServices({GeoPoint here = const GeoPoint(12.9716, 77.6412)}) async {
  SharedPreferences.setMockInitialValues({'onboarded': true});
  final db = await databaseFactoryFfiNoIsolate.openDatabase(
    inMemoryDatabasePath,
    options: OpenDatabaseOptions(
      version: AppDatabase.version,
      onConfigure: AppDatabase.onConfigure,
      onCreate: AppDatabase.onCreate,
      singleInstance: false,
    ),
  );
  return AppServices(
    database: AppDatabase(db),
    settings: await AppSettings.load(),
    lock: AppLock(MemorySecretStore()),
    location: FakeLocation(here),
    photos: MemoryPhotoStore(),
    voice: SilentVoiceService(),
  );
}

Future<void> pumpApp(WidgetTester tester, AppServices s, AppState state, Widget home) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(BeatMitraApp(services: s, state: state, home: home));
  await tester.pumpAndSettle();
}
