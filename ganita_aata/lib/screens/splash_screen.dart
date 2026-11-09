import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/app_state.dart';
import '../widgets/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/l10n_ext.dart';
import 'home_screen.dart';
import 'language_screen.dart';
import 'profile_setup_screen.dart';

/// Short animated logo, then language choice (first launch), profile setup
/// (no children yet) or Home.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, this.delay = const Duration(milliseconds: 1300)});

  final Duration delay;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _t;

  @override
  void initState() {
    super.initState();
    _t = Timer(widget.delay, _go);
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  void _go() {
    if (!mounted) return;
    final app = context.read<AppState>();
    final Widget next = !app.languageChosen
        ? const LanguageScreen()
        : app.active == null
        ? const ProfileSetupScreen(firstRun: true)
        : const HomeScreen();
    Navigator.of(context).pushReplacement(MaterialPageRoute<void>(builder: (_) => next));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GameBackground(
        colors: const [Color(0xFFFFA62B), Color(0xFFFF7A00)],
        child: Center(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.3, end: 1),
            duration: const Duration(milliseconds: 900),
            curve: Curves.elasticOut,
            builder: (c, v, child) => Transform.scale(scale: v, child: child),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const AppLogo(size: 150),
                    const Positioned(right: -34, bottom: -18, child: AppImage('owl', size: 86)),
                  ],
                ),
                const SizedBox(height: 28),
                Text(context.l10n.appTitle, style: display(52, color: Colors.white)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The app's logo: maths symbols on a bright tile.
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 120});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(size * 0.28),
        boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 16, offset: Offset(0, 6))],
      ),
      child: GridView.count(
        crossAxisCount: 2,
        padding: EdgeInsets.all(size * 0.1),
        physics: const NeverScrollableScrollPhysics(),
        children: [
          for (final (s, c) in const [
            ('+', Color(0xFFFF6B6B)),
            ('−', Color(0xFF4D96FF)),
            ('×', Color(0xFF6BCB77)),
            ('÷', Color(0xFF9B5DE5)),
          ])
            Center(
              child: Text(s, style: display(size * 0.34, color: c, height: 1)),
            ),
        ],
      ),
    );
  }
}
