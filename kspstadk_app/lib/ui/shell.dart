import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../l10n/app_localizations.dart';
import 'link_router.dart';
import 'screens/browse_screen.dart';
import 'screens/downloads_screen.dart';
import 'screens/home_screen.dart';
import 'screens/more_screen.dart';
import 'screens/search_screen.dart';

/// Bottom navigation: Home · Browse · Downloads · Search · More.
class AppShell extends StatefulWidget {
  const AppShell({super.key, this.initialTab = 0, this.showSplash = true});

  final int initialTab;
  final bool showSplash;

  static AppShellState? of(BuildContext context) => context.findAncestorStateOfType<AppShellState>();

  @override
  State<AppShell> createState() => AppShellState();
}

class AppShellState extends State<AppShell> {
  late int _tab = widget.initialTab;
  final _searchKey = GlobalKey<SearchScreenState>();
  late bool _splash = widget.showSplash;

  void selectTab(int i) {
    setState(() => _tab = i);
    if (i == 3) WidgetsBinding.instance.addPostFrameCallback((_) => _searchKey.currentState?.focus());
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => flushPendingLink());
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final pages = [
      const HomeScreen(),
      const BrowseScreen(),
      const DownloadsScreen(),
      SearchScreen(key: _searchKey),
      const MoreScreen(),
    ];
    return PopScope(
      canPop: _tab == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) selectTab(0);
      },
      child: Stack(
        children: [
          Scaffold(
            body: IndexedStack(index: _tab, children: pages),
            bottomNavigationBar: NavigationBar(
              selectedIndex: _tab,
              onDestinationSelected: selectTab,
              destinations: [
                NavigationDestination(icon: const Icon(Icons.home_outlined), selectedIcon: const Icon(Icons.home_rounded), label: l.navHome),
                NavigationDestination(icon: const Icon(Icons.grid_view_outlined), selectedIcon: const Icon(Icons.grid_view_rounded), label: l.navBrowse),
                NavigationDestination(
                    icon: const Icon(Icons.download_for_offline_outlined), selectedIcon: const Icon(Icons.download_for_offline_rounded), label: l.navDownloads),
                NavigationDestination(icon: const Icon(Icons.search_rounded), label: l.navSearch),
                NavigationDestination(icon: const Icon(Icons.menu_rounded), label: l.navMore),
              ],
            ),
          ),
          // Short logo animation over the already-loading home screen.
          if (_splash) SplashOverlay(onDone: () => setState(() => _splash = false)),
        ],
      ),
    );
  }
}

/// < 1.5 s logo animation that fades out to reveal the home screen.
class SplashOverlay extends StatefulWidget {
  const SplashOverlay({super.key, required this.onDone});

  final VoidCallback onDone;

  @override
  State<SplashOverlay> createState() => _SplashOverlayState();
}

class _SplashOverlayState extends State<SplashOverlay> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))
    ..forward().whenComplete(widget.onDone);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final l = AppLocalizations.of(context);
    final logoIn = CurvedAnimation(parent: _c, curve: const Interval(0, .45, curve: Curves.easeOutBack));
    final textIn = CurvedAnimation(parent: _c, curve: const Interval(.25, .6, curve: Curves.easeOut));
    final fadeOut = CurvedAnimation(parent: _c, curve: const Interval(.78, 1, curve: Curves.easeIn));
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) => Opacity(
          opacity: 1 - fadeOut.value,
          child: DecoratedBox(
            decoration: const BoxDecoration(gradient: Brand.headerGradient),
            child: Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Transform.scale(
                  scale: .6 + .4 * logoIn.value,
                  child: Container(
                    width: 96,
                    height: 96,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 24, offset: Offset(0, 10))],
                    ),
                    child: ShaderMask(
                      shaderCallback: (r) => Brand.primaryGradient.createShader(r),
                      child: const Text('K', style: TextStyle(fontSize: 56, fontWeight: FontWeight.w800, color: Colors.white)),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Opacity(
                  opacity: textIn.value,
                  child: Transform.translate(
                    offset: Offset(0, 12 * (1 - textIn.value)),
                    child: Column(children: [
                      Text(l.appTitle,
                          style: t.textTheme.headlineSmall?.copyWith(color: Colors.white, letterSpacing: 2, fontWeight: FontWeight.w800)),
                      Text(l.appSubtitle, style: t.textTheme.bodyMedium?.copyWith(color: Colors.white70)),
                    ]),
                  ),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
