import 'package:flutter/material.dart';

import 'converter_screen.dart';
import 'dictionary_screen.dart';
import 'lipi_screen.dart';
import 'saved_screen.dart';

/// Bottom-navigation shell keeping each tab alive in an [IndexedStack].
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  static const _pages = <Widget>[
    DictionaryScreen(),
    LipiScreen(),
    ConverterScreen(),
    SavedScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book),
            label: 'ನಿಘಂಟು',
            tooltip: 'Dictionary',
          ),
          NavigationDestination(
            icon: Icon(Icons.draw_outlined),
            selectedIcon: Icon(Icons.draw),
            label: 'ಲಿಪಿ',
            tooltip: 'Script',
          ),
          NavigationDestination(
            icon: Icon(Icons.translate_outlined),
            selectedIcon: Icon(Icons.translate),
            label: 'ಬದಲಿಸಿ',
            tooltip: 'Convert',
          ),
          NavigationDestination(
            icon: Icon(Icons.bookmarks_outlined),
            selectedIcon: Icon(Icons.bookmarks),
            label: 'ಉಳಿಸಿದವು',
            tooltip: 'Saved',
          ),
        ],
      ),
    );
  }
}
