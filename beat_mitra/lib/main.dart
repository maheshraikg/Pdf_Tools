import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';

import 'app.dart';
import 'app_state.dart';
import 'core/app_lock.dart';
import 'core/services/location_service.dart';
import 'core/services/photo_store.dart';
import 'core/services/secret_store.dart';
import 'core/services/voice_service.dart';
import 'core/settings.dart';
import 'data/db_open.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // cryptography_flutter registers itself and uses Android's native AES /
  // PBKDF2 where available (faster, same output).

  const secrets = DeviceSecretStore();
  // Open things in parallel to keep cold start short.
  final settingsF = AppSettings.load();
  final dbF = openEncryptedDatabase();
  final lock = AppLock(secrets, auth: LocalAuthentication());
  final lockF = lock.init();

  final services = AppServices(
    database: await dbF,
    settings: await settingsF,
    lock: lock,
    location: DeviceLocationService(),
    photos: DevicePhotoStore(secrets),
    voice: DeviceVoiceService(),
  );
  await lockF;
  final state = AppState(services);
  runApp(BeatMitraApp(services: services, state: state));
  // Build the search index after the first frame.
  await state.init();
}
