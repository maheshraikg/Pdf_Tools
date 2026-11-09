import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'data/app_store.dart';
import 'l10n/app_localizations.dart';
import 'screens/splash_screen.dart';
import 'services/app_state.dart';
import 'services/audio_service.dart';
import 'services/notification_service.dart';
import 'widgets/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  LicenseRegistry.addLicense(() async* {
    final ofl = await rootBundle.loadString('assets/fonts/OFL.txt');
    yield LicenseEntryWithLineBreaks(['Noto Sans Kannada'], ofl);
    yield LicenseEntryWithLineBreaks([
      'Baloo Tamma 2',
    ], await rootBundle.loadString('assets/fonts/OFL-BalooTamma2.txt'));
    yield LicenseEntryWithLineBreaks([
      'Fluent Emoji (illustrations)',
    ], await rootBundle.loadString('assets/images/LICENSE-fluentui-emoji.txt'));
    yield LicenseEntryWithLineBreaks([
      'Kenney game art',
    ], await rootBundle.loadString('assets/game/LICENSE-kenney.txt'));
    yield LicenseEntryWithLineBreaks([
      'Kenney Music Jingles (sound effects)',
    ], await rootBundle.loadString('assets/audio/sfx/LICENSE-kenney-jingles.txt'));
  });
  NotificationService.initTimeZones();
  final store = await HiveAppStore.open();
  final app = AppState(store: store, audio: AudioService(), notifications: NotificationService());
  runApp(GanitaAataApp(state: app));
  // Restore the daily reminder (also restored after reboot by the plugin).
  app.syncReminder();
  app.audio.playMusic(MusicTrack.menu);
}

class GanitaAataApp extends StatefulWidget {
  const GanitaAataApp({super.key, required this.state, this.home});

  final AppState state;

  /// Override the first screen (tests).
  final Widget? home;

  @override
  State<GanitaAataApp> createState() => _GanitaAataAppState();
}

class _GanitaAataAppState extends State<GanitaAataApp> with WidgetsBindingObserver {
  AppState get state => widget.state;
  Widget? get home => widget.home;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Music stops while the app is in the background.
  @override
  void didChangeAppLifecycleState(AppLifecycleState s) {
    if (s == AppLifecycleState.resumed) {
      state.audio.resumeMusic();
    } else if (s == AppLifecycleState.paused || s == AppLifecycleState.hidden) {
      state.audio.pauseMusic();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: state,
      child: Consumer<AppState>(
        builder: (context, app, _) => MaterialApp(
          onGenerateTitle: (c) => AppLocalizations.of(c).appTitle,
          debugShowCheckedModeBanner: false,
          theme: buildTheme(),
          locale: app.locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: home ?? const SplashScreen(),
        ),
      ),
    );
  }
}
