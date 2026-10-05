import 'package:firebase_core/firebase_core.dart';

/// Firebase client config for push notifications (FCM, free Spark plan).
///
/// These values are public by design (they identify the project, they are
/// not secrets). Fill them in from Firebase console → Project settings →
/// Your apps → Android app `com.kspstadk.app` (see README "Notifications"),
/// or run `flutterfire configure`, which regenerates this file.
///
/// While [apiKey] is empty the app runs normally with push turned off.
class DefaultFirebaseOptions {
  DefaultFirebaseOptions._();

  static const apiKey = '';
  static const appId = '';
  static const messagingSenderId = '';
  static const projectId = '';

  static bool get isConfigured => apiKey.isNotEmpty && appId.isNotEmpty && projectId.isNotEmpty;

  static FirebaseOptions get currentPlatform => const FirebaseOptions(
        apiKey: apiKey,
        appId: appId,
        messagingSenderId: messagingSenderId,
        projectId: projectId,
      );
}
