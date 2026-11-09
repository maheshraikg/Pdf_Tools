import 'package:flutter/material.dart';

import '../models/question.dart';
import 'app_theme.dart';
import 'l10n_ext.dart';
import 'shake.dart';

/// Four big answer buttons in a 2 × 2 grid.
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
      childAspectRatio: 1.9,
      children: [
        for (var i = 0; i < options.length; i++)
          _AnswerButton(
            key: ValueKey('answer_$i'),
            label: l.answerText(options[i]),
            color: !done
                ? AppColors.cardColors[i % AppColors.cardColors.length]
                : options[i] == correct
                ? AppColors.good
                : options[i] == chosen
                ? AppColors.gentle
                : Colors.grey.shade400,
            shake: done && options[i] == chosen && chosen != correct,
            onTap: done ? null : () => onTap(options[i]),
          ),
      ],
    );
  }
}

class _AnswerButton extends StatelessWidget {
  const _AnswerButton({super.key, required this.label, required this.color, required this.onTap, required this.shake});

  final String label;
  final Color color;
  final VoidCallback? onTap;
  final bool shake;

  @override
  Widget build(BuildContext context) {
    return Shake(
      active: shake,
      child: Material(
        color: color,
        borderRadius: BorderRadius.circular(24),
        elevation: 3,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  label,
                  style: const TextStyle(fontSize: 38, fontWeight: FontWeight.w700, color: Colors.white),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
