import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'app/background.dart';
import 'app/location.dart';
import 'app/scope.dart';
import 'app/settings.dart';
import 'app/strings.dart';
import 'screens/month_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/qibla_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/tasbih_screen.dart';
import 'screens/today_screen.dart';
import 'ui/theme.dart';

export 'ui/theme.dart' show buildTheme, debugFontFallback;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final settings = await AppSettings.load();
  runApp(WaqtApp(settings: settings));
}

class WaqtApp extends StatefulWidget {
  const WaqtApp({super.key, required this.settings, this.background = true});
  final AppSettings settings;

  /// Whether to schedule alarms (off in tests).
  final bool background;

  @override
  State<WaqtApp> createState() => _WaqtAppState();
}

class _WaqtAppState extends State<WaqtApp> with WidgetsBindingObserver {
  Timer? _debounce;
  final _messenger = GlobalKey<ScaffoldMessengerState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.settings.addListener(_onSettings);
    _refreshBackground();
    _followLocation();
  }

  /// Automatic location: move the place when the phone has moved.
  Future<void> _followLocation() async {
    if (!widget.background) return;
    await refreshBuiltInChart(widget.settings);
    final p = await refreshAutoLocation(widget.settings);
    if (p == null) return;
    final s = S(widget.settings.lang);
    _messenger.currentState?.showSnackBar(
      SnackBar(content: Text(s.locationUpdated(p.label(s.ml)))),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.settings.removeListener(_onSettings);
    _debounce?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshBackground();
      _followLocation();
    }
  }

  void _onSettings() {
    if (widget.settings.takeQuietChange()) return;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), _refreshBackground);
  }

  void _refreshBackground() {
    if (widget.background) Background.refresh(widget.settings);
  }

  @override
  Widget build(BuildContext context) => AppScope(
    settings: widget.settings,
    child: ListenableBuilder(
      listenable: widget.settings,
      builder: (context, _) => MaterialApp(
        title: 'Azan Time',
        scaffoldMessengerKey: _messenger,
        debugShowCheckedModeBanner: false,
        theme: buildTheme(Brightness.light),
        darkTheme: buildTheme(Brightness.dark),
        themeMode: widget.settings.themeMode,
        // The app's language drives Material texts and the layout direction
        // (Arabic and Urdu are right-to-left).
        locale: Locale(widget.settings.lang.code),
        supportedLocales: [for (final l in Lang.values) Locale(l.code)],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: widget.settings.onboarded
            ? const HomeShell()
            : const OnboardingScreen(),
      ),
    ),
  );
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Scaffold(
      body: IndexedStack(
        index: _tab,
        children: [
          for (final (i, tab) in [
            const TodayScreen(),
            const MonthScreen(),
            QiblaScreen(active: _tab == 2),
            const TasbihScreen(),
            const SettingsScreen(),
          ].indexed)
            // The chosen tab fades and rises in (state is kept).
            AnimatedOpacity(
              opacity: _tab == i ? 1 : 0,
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOut,
              child: AnimatedSlide(
                offset: _tab == i ? Offset.zero : const Offset(0, 0.03),
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                child: tab,
              ),
            ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.access_time),
            selectedIcon: const Icon(Icons.access_time_filled),
            label: s.today,
          ),
          NavigationDestination(
            icon: const Icon(Icons.calendar_month_outlined),
            selectedIcon: const Icon(Icons.calendar_month),
            label: s.month,
          ),
          NavigationDestination(
            icon: const Icon(Icons.explore_outlined),
            selectedIcon: const Icon(Icons.explore),
            label: s.qibla,
          ),
          NavigationDestination(
            icon: const Icon(Icons.radio_button_checked_outlined),
            selectedIcon: const Icon(Icons.radio_button_checked),
            label: s.tasbih,
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings),
            label: s.settings,
          ),
        ],
      ),
    );
  }
}
