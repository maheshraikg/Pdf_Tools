import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import 'screens/browse_screen.dart';
import 'screens/downloads_screen.dart';
import 'screens/home_screen.dart';

/// Bottom navigation: Home · Browse · Downloads · Search · More.
class AppShell extends StatefulWidget {
  const AppShell({super.key, this.initialTab = 0});

  final int initialTab;

  static AppShellState? of(BuildContext context) => context.findAncestorStateOfType<AppShellState>();

  @override
  State<AppShell> createState() => AppShellState();
}

class AppShellState extends State<AppShell> {
  late int _tab = widget.initialTab;

  void selectTab(int i) => setState(() => _tab = i);

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final pages = [
      const HomeScreen(),
      const BrowseScreen(),
      const DownloadsScreen(),
      Center(child: Text(l.navSearch)),
      Center(child: Text(l.navMore)),
    ];
    return Scaffold(
      body: IndexedStack(index: _tab, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: selectTab,
        destinations: [
          NavigationDestination(icon: const Icon(Icons.home_outlined), selectedIcon: const Icon(Icons.home_rounded), label: l.navHome),
          NavigationDestination(icon: const Icon(Icons.grid_view_outlined), selectedIcon: const Icon(Icons.grid_view_rounded), label: l.navBrowse),
          NavigationDestination(icon: const Icon(Icons.download_for_offline_outlined), selectedIcon: const Icon(Icons.download_for_offline_rounded), label: l.navDownloads),
          NavigationDestination(icon: const Icon(Icons.search_rounded), label: l.navSearch),
          NavigationDestination(icon: const Icon(Icons.menu_rounded), label: l.navMore),
        ],
      ),
    );
  }
}
