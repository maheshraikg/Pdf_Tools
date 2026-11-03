import 'dart:async';

import 'package:flutter/material.dart';

import 'app/native.dart';
import 'app/notifications.dart';
import 'app/scope.dart';
import 'app/store.dart';
import 'screens/accounts_screen.dart';
import 'screens/auto_detect_screen.dart';
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
  // New bank SMS since the last visit (when turned on).
  backgroundSmsSync(store);
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
  final _navigator = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.store.addListener(_onChange);
    _refreshReminders();
    if (widget.background) _listenForShares();
  }

  /// Statement PDFs shared to (or opened with) RupeeTrack.
  void _listenForShares() {
    void open(String? path) {
      final ctx = _navigator.currentContext;
      if (path == null || ctx == null) return;
      handleSharedPdf(ctx, path);
    }

    Native.listenForSharedPdfs(open);
    // Started by a share: wait for the first frame so a dialog can show.
    Native.takeSharedPdf().then(
      (path) => WidgetsBinding.instance.addPostFrameCallback((_) => open(path)),
    );
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
      if (widget.background) backgroundSmsSync(widget.store);
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
          navigatorKey: _navigator,
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
      floatingActionButton: context.store.isEmpty ? null : const _AddButton(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: _openTab,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long_rounded),
            label: 'Activity',
          ),
          NavigationDestination(
            icon: Icon(Icons.credit_card_outlined),
            selectedIcon: Icon(Icons.credit_card_rounded),
            label: 'Cards',
          ),
          NavigationDestination(
            icon: Icon(Icons.show_chart_rounded),
            selectedIcon: Icon(Icons.insights_rounded),
            label: 'Invest',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_outlined),
            selectedIcon: Icon(Icons.account_balance_rounded),
            label: 'Accounts',
          ),
        ],
      ),
    );
  }
}

/// Compact square "+" button with a soft tinted shadow, in place of a
/// loud extended pill.
class _AddButton extends StatelessWidget {
  const _AddButton();

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.28),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: FloatingActionButton(
        tooltip: 'Add entry',
        onPressed: () => showQuickAdd(context),
        child: const Icon(Icons.add_rounded, size: 30),
      ),
    );
  }
}
