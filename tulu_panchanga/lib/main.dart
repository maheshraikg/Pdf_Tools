import 'dart:async';

import 'package:flutter/material.dart';

import 'app/background.dart';
import 'app/scope.dart';
import 'app/settings.dart';
export 'app/theme.dart' show debugFontFallback;
import 'app/theme.dart';
import 'screens/calendar_screen.dart';
import 'screens/festivals_screen.dart';
import 'screens/muhurta_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/splash.dart';
import 'screens/today_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final settings = await AppSettings.load();
  runApp(TuluPanchangaApp(settings: settings));
}

class TuluPanchangaApp extends StatefulWidget {
  const TuluPanchangaApp({
    super.key,
    required this.settings,
    this.background = true,
    this.splash = true,
  });
  final AppSettings settings;

  /// Whether to schedule notifications / update the widget (off in tests).
  final bool background;

  /// Whether to show the animated Kannada opening screen.
  final bool splash;

  @override
  State<TuluPanchangaApp> createState() => _TuluPanchangaAppState();
}

class _TuluPanchangaAppState extends State<TuluPanchangaApp>
    with WidgetsBindingObserver {
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.settings.addListener(_onSettings);
    _refreshBackground();
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
    if (state == AppLifecycleState.resumed) _refreshBackground();
  }

  void _onSettings() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(seconds: 2), _refreshBackground);
  }

  void _refreshBackground() {
    if (!widget.background) return;
    final s = widget.settings;
    final repo = AppScope.repoFor(s);
    Background.refresh(s, repo);
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      settings: widget.settings,
      child: ListenableBuilder(
        listenable: widget.settings,
        builder: (context, _) => MaterialApp(
          title: 'Tulu Panchanga',
          debugShowCheckedModeBanner: false,
          theme: buildTheme(Brightness.light),
          darkTheme: buildTheme(Brightness.dark),
          themeMode: widget.settings.themeMode,
          builder: scaleText,
          home: widget.splash ? const _SplashThenHome() : const HomeShell(),
        ),
      ),
    );
  }
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
    const pages = [
      TodayScreen(),
      CalendarScreen(),
      FestivalsScreen(),
      MuhurtaScreen(),
      SettingsScreen(),
    ];
    return Scaffold(
      body: IndexedStack(index: _tab, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.wb_sunny_outlined),
            selectedIcon: const Icon(Icons.wb_sunny),
            label: s.today,
          ),
          NavigationDestination(
            icon: const Icon(Icons.calendar_month_outlined),
            selectedIcon: const Icon(Icons.calendar_month),
            label: s.calendar,
          ),
          NavigationDestination(
            icon: const Icon(Icons.celebration_outlined),
            selectedIcon: const Icon(Icons.celebration),
            label: s.festivals,
          ),
          NavigationDestination(
            icon: const Icon(Icons.access_time),
            selectedIcon: const Icon(Icons.access_time_filled),
            label: s.muhurta,
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

/// Shows the opening animation, then cross-fades to the app.
class _SplashThenHome extends StatefulWidget {
  const _SplashThenHome();

  @override
  State<_SplashThenHome> createState() => _SplashThenHomeState();
}

class _SplashThenHomeState extends State<_SplashThenHome> {
  bool _home = false;

  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
    duration: const Duration(milliseconds: 700),
    switchInCurve: Curves.easeOut,
    transitionBuilder: (c, a) => FadeTransition(
      opacity: a,
      child: ScaleTransition(
        scale: Tween(begin: 1.04, end: 1.0).animate(a),
        child: c,
      ),
    ),
    child: _home
        ? const HomeShell()
        : SplashScreen(onDone: () => setState(() => _home = true)),
  );
}
