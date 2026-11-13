import 'package:flutter/material.dart';

import '../models/question.dart';
import 'app_theme.dart';
import 'common.dart';
import 'motion.dart';
import 'l10n_ext.dart';
import 'shake.dart';

/// Four big, chunky answer buttons in a 2 × 2 grid.
///
/// After a choice, the correct answer turns green; a wrong choice shakes
/// gently and turns soft orange (never red).
class AnswerGrid extends StatelessWidget {
  const AnswerGrid({super.key, required this.options, required this.onTap, this.chosen, this.correct});

  final List<Answer> options;
  final ValueChanged<Answer> onTap;

  /// The child's choice, once made.
  final Answer? chosen;

  /// The correct answer, shown once [chosen] is set.
  final Answer? correct;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final done = chosen != null;
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 14,
      crossAxisSpacing: 14,
      childAspectRatio: 1.75,
      children: [
        for (var i = 0; i < options.length; i++)
          Builder(
            builder: (context) {
              final isRight = options[i] == correct;
              final isChosen = options[i] == chosen;
              final Color color = !done
                  ? AppColors.card(i).$1
                  : isRight
                  ? AppColors.good
                  : isChosen
                  ? AppColors.gentle
                  : const Color(0xFFCFCBE0);
              return Entrance(
                delay: 90 + 70 * i,
                child: Shake(
                  active: done && isChosen && !isRight,
                  child: AnimatedScale(
                    scale: done && isRight ? 1.06 : 1,
                    duration: const Duration(milliseconds: 200),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned.fill(
                          child: ChunkyButton(
                            key: ValueKey('answer_$i'),
                            color: color,
                            radius: 24,
                            depth: 7,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            onTap: done ? null : () => onTap(options[i]),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                l.answerText(options[i]),
                                textDirection: TextDirection.ltr,
                                style: display(42, color: Colors.white),
                              ),
                            ),
                          ),
                        ),
                        if (done && isRight) const Positioned(right: -6, top: -10, child: AppImage('check', size: 34)),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}
