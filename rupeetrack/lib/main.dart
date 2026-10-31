import 'dart:async';

import 'package:flutter/material.dart';

import 'app/notifications.dart';
import 'app/scope.dart';
import 'app/store.dart';
import 'screens/accounts_screen.dart';
import 'screens/cards_screen.dart';
import 'screens/home_screen.dart';
import 'screens/investments_screen.dart';
import 'screens/quick_add_sheet.dart';
import 'screens/transactions_screen.dart';
import 'widgets/design.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = await FinanceStore.load();
  await store.postDueRecurring(today());
  runApp(RupeeTrackApp(store: store));
}

class RupeeTrackApp extends StatefulWidget {
  const RupeeTrackApp({super.key, required this.store, this.background = true});
  final FinanceStore store;

  /// Whether to schedule notifications (off in tests).
  final bool background;

  @override
  State<RupeeTrackApp> createState() => _RupeeTrackAppState();
}

class _RupeeTrackAppState extends State<RupeeTrackApp>
    with WidgetsBindingObserver {
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.store.addListener(_onChange);
    _refreshReminders();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.store.removeListener(_onChange);
    _debounce?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // A new day may have made recurring entries due.
      widget.store.postDueRecurring(today());
      _refreshReminders();
    }
  }

  void _onChange() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(seconds: 2), _refreshReminders);
  }

  void _refreshReminders() {
    if (widget.background) Reminders.refresh(widget.store);
  }

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    return AppScope(
      store: store,
      child: ListenableBuilder(
        listenable: store,
        builder: (context, _) => MaterialApp(
          title: 'RupeeTrack',
          debugShowCheckedModeBanner: false,
          theme: buildAppTheme(Brightness.light),
          darkTheme: buildAppTheme(Brightness.dark),
          themeMode: store.themeMode,
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

  void _openTab(int i) => setState(() => _tab = i);

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeScreen(onOpenTab: _openTab),
      const TransactionsScreen(),
      const CardsScreen(),
      const InvestmentsScreen(),
      const AccountsScreen(),
    ];
    return Scaffold(
      body: IndexedStack(index: _tab, children: pages),
      floatingActionButton: context.store.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: () => showQuickAdd(context),
              icon: const Icon(Icons.add),
              label: const Text('Add'),
            ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: _openTab,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.space_dashboard_outlined),
            selectedIcon: Icon(Icons.space_dashboard),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Activity',
          ),
          NavigationDestination(
            icon: Icon(Icons.credit_card_outlined),
            selectedIcon: Icon(Icons.credit_card),
            label: 'Cards',
          ),
          NavigationDestination(
            icon: Icon(Icons.show_chart),
            selectedIcon: Icon(Icons.insights),
            label: 'Invest',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_outlined),
            selectedIcon: Icon(Icons.account_balance),
            label: 'Accounts',
          ),
        ],
      ),
    );
  }
}
