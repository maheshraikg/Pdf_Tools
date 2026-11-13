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
    final medal = switch (id) {
      Badges.speedStar => 'medal4',
      Badges.day100 => 'medal1',
      Badges.streak7 => 'medal9',
      Badges.streak30 => 'medal8',
      _ => 'medal6',
    };
    Widget img = Stack(
      alignment: Alignment.topCenter,
      children: [
        GameImage(medal, height: size, width: size),
        // Emblem on the medal's disc.
        Positioned(
          bottom: size * 0.1,
          child: SizedBox(
            width: size * 0.42,
            height: size * 0.42,
            child: Center(
              child: table != null
                  ? Container(
                      padding: EdgeInsets.symmetric(horizontal: size * 0.05),
                      decoration: BoxDecoration(color: AppColors.secondary, borderRadius: BorderRadius.circular(size)),
                      child: Text('$table', style: display(size * 0.2, color: Colors.white, height: 1.1)),
                    )
                  : AppImage(badgeImage(id), size: size * 0.3),
            ),
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
