import 'dart:math';

import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'l10n_ext.dart';

/// Celebrates a newly earned badge with a bouncing, spinning medal.
Future<void> showBadgePopup(BuildContext context, String badgeId) {
  final l = context.l10n;
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: l.close,
    transitionDuration: const Duration(milliseconds: 450),
    pageBuilder: (c, a, b) => const SizedBox.shrink(),
    transitionBuilder: (c, anim, _, _) {
      final t = Curves.elasticOut.transform(anim.value.clamp(0.0, 1.0));
      return Opacity(
        opacity: anim.value.clamp(0.0, 1.0),
        child: Center(
          child: Transform.scale(
            scale: 0.4 + 0.6 * t,
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: 300,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(32)),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(l.newBadge, style: Theme.of(c).textTheme.headlineMedium),
                    const SizedBox(height: 12),
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: 1),
                      duration: const Duration(milliseconds: 1200),
                      builder: (c, v, child) => Transform.rotate(angle: sin(v * pi * 2) * 0.25, child: child),
                      child: Container(
                        width: 120,
                        height: 120,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(colors: [Color(0xFFFFF59D), AppColors.coin]),
                        ),
                        child: Text(badgeEmoji(badgeId), style: const TextStyle(fontSize: 64)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(l.badgeName(badgeId), textAlign: TextAlign.center, style: Theme.of(c).textTheme.titleLarge),
                    const SizedBox(height: 4),
                    Text(l.badgeDesc(badgeId), textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    FilledButton(
                      key: const ValueKey('badge_ok'),
                      onPressed: () => Navigator.pop(c),
                      child: Text(l.yay),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}
