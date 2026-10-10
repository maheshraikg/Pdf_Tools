import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'app/scope.dart';
import 'app/settings.dart';
import 'app/strings.dart';
import 'app/theme.dart';
import 'data/local_rates.dart';
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
  final localRates = await LocalRates.load(rates);
  runApp(
    PoSahayakApp(
      settings: settings,
      rates: rates,
      accounts: accounts,
      localRates: localRates,
    ),
  );
}

class PoSahayakApp extends StatefulWidget {
  const PoSahayakApp({
    super.key,
    required this.settings,
    required this.rates,
    required this.accounts,
    this.localRates,
    this.background = true,
  });

  final AppSettings settings;
  final RateRepository rates;
  final SavedAccountRepository accounts;

  /// Rates typed in on the phone (null in tests: built-in table only).
  final LocalRates? localRates;

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
    final local = widget.localRates;
    return ListenableBuilder(
      listenable: Listenable.merge([widget.settings, ?local]),
      builder: (context, _) => AppScope(
        settings: widget.settings,
        rates: local?.repo ?? widget.rates,
        accounts: widget.accounts,
        localRates: local,
        child: ListenableBuilder(
          listenable: widget.settings,
          builder: (context, _) => MaterialApp(
            title: 'PO Calculator',
            debugShowCheckedModeBanner: false,
            theme: buildTheme(Brightness.light),
            darkTheme: buildTheme(Brightness.dark),
            themeMode: widget.settings.themeMode,
            locale: Locale(widget.settings.lang.name),
            supportedLocales: [for (final l in Lang.values) Locale(l.name)],
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            // Phones set to very large fonts would break layouts; above 1.3x
            // the app stops growing text (it is already 10% larger).
            builder: (context, child) => MediaQuery.withClampedTextScaling(
              maxScaleFactor: 1.3,
              child: child!,
            ),
            home: const HomeShell(),
          ),
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
      // Tab labels stay at normal size (as in Android's own bars) so they
      // fit on one line even with a large system font.
      bottomNavigationBar: MediaQuery.withClampedTextScaling(
        maxScaleFactor: 1.0,
        child: NavigationBar(
          selectedIndex: _tab,
          onDestinationSelected: (i) => setState(() => _tab = i),
          destinations: [
            for (final (icon, selected, label) in [
              (Icons.home_outlined, Icons.home_rounded, s.home),
              (
                Icons.leaderboard_outlined,
                Icons.leaderboard_rounded,
                s.compare,
              ),
              (
                Icons.account_balance_wallet_outlined,
                Icons.account_balance_wallet_rounded,
                s.navAccounts,
              ),
              (
                Icons.support_agent_outlined,
                Icons.support_agent_rounded,
                s.staff,
              ),
              (Icons.settings_outlined, Icons.settings_rounded, s.settings),
            ])
              NavigationDestination(
                icon: Icon(icon),
                selectedIcon: Icon(selected, color: Brand.red),
                label: label,
                tooltip: label,
              ),
          ],
        ),
      ),
    );
  }
}
