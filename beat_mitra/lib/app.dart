import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'app_state.dart';
import 'core/app_lock.dart';
import 'core/l10n/app_localizations.dart';
import 'core/services/platform.dart';
import 'core/settings.dart';
import 'core/theme.dart';
import 'features/home/home_screen.dart';
import 'features/settings/lock_screen.dart';
import 'features/settings/onboarding_screen.dart';

class BeatMitraApp extends StatelessWidget {
  const BeatMitraApp({super.key, required this.services, required this.state, this.home});
  final AppServices services;
  final AppState state;

  /// Widget tests can open a screen directly.
  final Widget? home;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AppServices>.value(value: services),
        ChangeNotifierProvider<AppSettings>.value(value: services.settings),
        ChangeNotifierProvider<AppLock>.value(value: services.lock),
        ChangeNotifierProvider<AppState>.value(value: state),
      ],
      child: Consumer<AppSettings>(
        builder: (context, settings, _) => MaterialApp(
          title: 'Beat Mitra',
          debugShowCheckedModeBanner: false,
          theme: buildTheme(Brightness.light, sunlight: settings.sunlight),
          darkTheme: buildTheme(Brightness.dark, sunlight: settings.sunlight),
          themeMode: settings.themeMode,
          locale: settings.locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          localeResolutionCallback: (device, supported) {
            for (final s in supported) {
              if (s.languageCode == device?.languageCode) return s;
            }
            return const Locale('en');
          },
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(
                (MediaQuery.of(context).textScaler.scale(1) * settings.textScale).clamp(1.0, 2.0),
              ),
            ),
            child: home != null ? child! : _LockGate(child: child!),
          ),
          home: home ?? const _Root(),
        ),
      ),
    );
  }
}

/// Onboarding until a PIN exists, then home.
class _Root extends StatelessWidget {
  const _Root();

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettings>();
    final lock = context.watch<AppLock>();
    if (!settings.onboarded || !lock.hasPin) return const OnboardingScreen();
    return const HomeScreen();
  }
}

/// Sits above the Navigator: shows the lock screen over every page, re-locks
/// after the background timeout and applies the screenshot-blocking flag.
class _LockGate extends StatefulWidget {
  const _LockGate({required this.child});
  final Widget child;

  @override
  State<_LockGate> createState() => _LockGateState();
}

class _LockGateState extends State<_LockGate> with WidgetsBindingObserver {
  late final AppSettings _settings;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _settings = context.read<AppSettings>();
    _settings.addListener(_applySecure);
    _applySecure();
  }

  void _applySecure() => PlatformBridge.setSecure(_settings.blockScreenshots);

  @override
  void dispose() {
    _settings.removeListener(_applySecure);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final lock = context.read<AppLock>();
    if (state == AppLifecycleState.paused || state == AppLifecycleState.hidden) {
      lock.onPaused();
    } else if (state == AppLifecycleState.resumed) {
      lock.onResumed(Duration(minutes: _settings.lockTimeoutMin));
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettings>();
    final lock = context.watch<AppLock>();
    final showLock = settings.onboarded && lock.locked;
    return Stack(
      children: [
        // Keep pages alive (and hidden from screen readers) under the lock.
        ExcludeSemantics(excluding: showLock, child: widget.child),
        if (showLock) const Positioned.fill(child: LockScreen()),
      ],
    );
  }
}
