import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'app/scope.dart';
import 'app/settings.dart';
import 'app/strings.dart';
import 'data/saved_account_repository.dart';
import 'domain/rates/rate_repository.dart';
import 'features/accounts/accounts_screen.dart';
import 'features/compare/compare_screen.dart';
import 'features/home/home_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/staff/staff_screen.dart';
import 'reminders/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final rates = RateRepository.fromJson(
    await rootBundle.loadString('assets/rates.json'),
  );
  final settings = await AppSettings.load();
  final accounts = await SavedAccountRepository.load();
  runApp(PoSahayakApp(settings: settings, rates: rates, accounts: accounts));
}

/// India Post-neutral blue (no India Post colours or emblem).
const Color kSeed = Color(0xFF1F5FA8);

ThemeData buildTheme(Brightness b) {
  final scheme = ColorScheme.fromSeed(seedColor: kSeed, brightness: b);
  // Larger text and touch targets for senior citizens. Sizes live in the
  // script geometries (Kannada uses "tall"), so scale all three.
  TextTheme big(TextTheme t) => t.apply(fontSizeFactor: 1.12);
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    typography: Typography.material2021(
      platform: TargetPlatform.android,
      colorScheme: scheme,
      englishLike: big(Typography.englishLike2021),
      dense: big(Typography.dense2021),
      tall: big(Typography.tall2021),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(minimumSize: const Size(64, 52)),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(minimumSize: const Size(64, 52)),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      border: OutlineInputBorder(),
    ),
    cardTheme: const CardThemeData(elevation: 0.5),
  );
}

class PoSahayakApp extends StatefulWidget {
  const PoSahayakApp({
    super.key,
    required this.settings,
    required this.rates,
    required this.accounts,
    this.background = true,
  });

  final AppSettings settings;
  final RateRepository rates;
  final SavedAccountRepository accounts;

  /// Schedule reminders (off in tests).
  final bool background;

  @override
  State<PoSahayakApp> createState() => _PoSahayakAppState();
}

class _PoSahayakAppState extends State<PoSahayakApp> {
  @override
  void initState() {
    super.initState();
    widget.accounts.addListener(_reschedule);
    widget.settings.addListener(_reschedule);
    _reschedule();
  }

  @override
  void dispose() {
    widget.accounts.removeListener(_reschedule);
    widget.settings.removeListener(_reschedule);
    super.dispose();
  }

  void _reschedule() {
    if (!widget.background) return;
    NotificationService.reschedule(
      widget.accounts.accounts,
      S(widget.settings.lang),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      settings: widget.settings,
      rates: widget.rates,
      accounts: widget.accounts,
      child: ListenableBuilder(
        listenable: widget.settings,
        builder: (context, _) => MaterialApp(
          title: 'PO Sahayak',
          debugShowCheckedModeBanner: false,
          theme: buildTheme(Brightness.light),
          darkTheme: buildTheme(Brightness.dark),
          themeMode: widget.settings.themeMode,
          locale: Locale(widget.settings.lang.name),
          supportedLocales: const [Locale('en'), Locale('kn')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: const HomeShell(),
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
      HomeScreen(),
      CompareScreen(),
      AccountsScreen(),
      StaffScreen(),
      SettingsScreen(),
    ];
    return Scaffold(
      body: IndexedStack(index: _tab, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home),
            label: s.home,
          ),
          NavigationDestination(
            icon: const Icon(Icons.compare_arrows),
            label: s.compare,
          ),
          NavigationDestination(
            icon: const Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: const Icon(Icons.account_balance_wallet),
            label: s.myAccounts,
          ),
          NavigationDestination(
            icon: const Icon(Icons.badge_outlined),
            selectedIcon: const Icon(Icons.badge),
            label: s.staff,
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
