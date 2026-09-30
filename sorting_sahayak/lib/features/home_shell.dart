import 'package:flutter/material.dart';

import '../core/l10n/app_localizations.dart';
import 'air/air_finder_screen.dart';
import 'find_pin/find_pin_screen.dart';
import 'learn/learn_screen.dart';
import 'lookup/sort_screen.dart';
import 'settings/more_screen.dart';

/// Bottom navigation: Sort · Find PIN · Air · Learn · More.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  /// Global key so pushed routes (Favourites, Find PIN sheets) can switch tabs.
  static final GlobalKey<HomeShellState> shellKey = GlobalKey<HomeShellState>();

  static HomeShellState? of(BuildContext context) =>
      shellKey.currentState ?? context.findAncestorStateOfType<HomeShellState>();

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
          const AirFinderScreen(),
          const LearnScreen(),
          const MoreScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: selectTab,
        destinations: [
          NavigationDestination(icon: const Icon(Icons.dialpad_outlined), selectedIcon: const Icon(Icons.dialpad), label: l.navSort),
          NavigationDestination(icon: const Icon(Icons.travel_explore_outlined), selectedIcon: const Icon(Icons.travel_explore), label: l.navFindPin),
          NavigationDestination(icon: const Icon(Icons.flight_outlined), selectedIcon: const Icon(Icons.flight), label: l.navAir),
          NavigationDestination(icon: const Icon(Icons.school_outlined), selectedIcon: const Icon(Icons.school), label: l.navLearn),
          NavigationDestination(icon: const Icon(Icons.more_horiz), label: l.navMore),
        ],
      ),
    );
  }
}
