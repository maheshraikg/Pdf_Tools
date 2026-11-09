import 'package:flutter/material.dart';

import '../engine/rewards.dart';
import 'app_theme.dart';
import 'common.dart';
import 'l10n_ext.dart';

/// A badge picture; table badges show their number on the medal.
class BadgeIcon extends StatelessWidget {
  const BadgeIcon({super.key, required this.id, this.size = 72, this.earned = true});

  final String id;
  final double size;
  final bool earned;

  @override
  Widget build(BuildContext context) {
    final table = Badges.tableOf(id);
    Widget img = Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: earned
                  ? const [Color(0xFFFFF6C9), Color(0xFFFFD45C)]
                  : const [Color(0xFFF1F1F4), Color(0xFFDCDCE3)],
            ),
          ),
        ),
        AppImage(badgeImage(id), size: size * 0.72),
        if (table != null)
          Positioned(
            bottom: size * 0.14,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(color: AppColors.secondary, borderRadius: BorderRadius.circular(10)),
              child: Text('$table', style: display(size * 0.22, color: Colors.white)),
            ),
          ),
      ],
    );
    if (!earned) {
      img = Opacity(
        opacity: 0.45,
        child: ColorFiltered(
          colorFilter: const ColorFilter.matrix([
            0.33, 0.33, 0.33, 0, 0, //
            0.33, 0.33, 0.33, 0, 0, //
            0.33, 0.33, 0.33, 0, 0, //
            0, 0, 0, 1, 0,
          ]),
          child: img,
        ),
      );
    }
    return SizedBox(width: size, height: size, child: img);
  }
}
