import 'dart:math';

import 'package:flutter/material.dart';

/// Gently shakes its child sideways while [active] turns true.
class Shake extends StatelessWidget {
  const Shake({super.key, required this.active, required this.child});

  final bool active;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!active) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 500),
      builder: (context, t, c) => Transform.translate(offset: Offset(sin(t * pi * 6) * 10 * (1 - t), 0), child: c),
      child: child,
    );
  }
}
