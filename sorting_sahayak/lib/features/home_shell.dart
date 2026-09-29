import 'package:flutter/material.dart';

import '../core/l10n/app_localizations.dart';
import 'bulk/bulk_screen.dart';
import 'find_pin/find_pin_screen.dart';
import 'learn/learn_screen.dart';
import 'lookup/sort_screen.dart';
import 'settings/more_screen.dart';

/// Bottom navigation: Sort · Find PIN · Bulk · Learn · More.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  static HomeShellState? of(BuildContext context) => context.findAncestorStateOfType<HomeShellState>();

  @override
  State<HomeShell> createState() => HomeShellState();
}

class HomeShellState extends State<HomeShell> {
  int _index = 0;
  final _sortKey = GlobalKey<SortScreenState>();

  /// Opens the Sort tab with [pin] entered (from Find PIN, favourites, …).
  void openSort(String pin) {
    setState(() => _index = 0);
    _sortKey.currentState?.setPin(pin);
  }

  void selectTab(int i) => setState(() => _index = i);

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          SortScreen(key: _sortKey),
          const FindPinScreen(),
          const BulkScreen(),
          const LearnScreen(),
          const MoreScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: selectTab,
        destinations: [
          NavigationDestination(icon: const Icon(Icons.dialpad), label: l.navSort),
          NavigationDestination(icon: const Icon(Icons.travel_explore), label: l.navFindPin),
          NavigationDestination(icon: const Icon(Icons.inventory_2_outlined), label: l.navBulk),
          NavigationDestination(icon: const Icon(Icons.school_outlined), label: l.navLearn),
          NavigationDestination(icon: const Icon(Icons.more_horiz), label: l.navMore),
        ],
      ),
    );
  }
}
