import 'package:flutter/material.dart';

import '../data/shop_catalog.dart';
import 'app_theme.dart';

class AvatarCircle extends StatelessWidget {
  const AvatarCircle({super.key, required this.avatarId, this.size = 56, this.selected = false});

  final String avatarId;
  final double size;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: selected ? AppColors.primary.withValues(alpha: 0.18) : Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: selected ? AppColors.primary : const Color(0xFFE6E0F0), width: selected ? 4 : 2),
      ),
      child: Text(ShopCatalog.emojiFor(avatarId), style: TextStyle(fontSize: size * 0.55)),
    );
  }
}

/// A rounded pill with an icon and a value (coins, streak, timer…).
class StatChip extends StatelessWidget {
  const StatChip({
    super.key,
    required this.icon,
    required this.label,
    this.color = AppColors.coin,
    this.semantics,
    this.compact = false,
  });

  /// Smaller text and padding (game top bar).

  final Widget icon;
  final String label;
  final Color color;
  final String? semantics;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semantics,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 12, vertical: compact ? 4 : 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: color, width: 2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            icon,
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(fontSize: compact ? 17 : 20, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

class CoinChip extends StatelessWidget {
  const CoinChip({super.key, required this.coins, this.semantics});

  final int coins;
  final String? semantics;

  @override
  Widget build(BuildContext context) => StatChip(
    icon: const Text('🪙', style: TextStyle(fontSize: 20)),
    label: '$coins',
    semantics: semantics,
  );
}

/// A big, colourful, rounded tappable card.
class BigCard extends StatelessWidget {
  const BigCard({
    super.key,
    required this.color,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
  });

  final Color color;
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(28),
      elevation: 2,
      shadowColor: color.withValues(alpha: 0.5),
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

/// Sky gradient used behind game screens.
class GameBackground extends StatelessWidget {
  const GameBackground({super.key, required this.child, this.colors});

  final Widget child;
  final List<Color>? colors;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: colors ?? const [Color(0xFFBDE3FF), Color(0xFFFFF4E0)],
        ),
      ),
      child: child,
    );
  }
}
