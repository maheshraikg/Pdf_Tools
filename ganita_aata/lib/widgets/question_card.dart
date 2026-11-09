import 'package:flutter/material.dart';

import '../models/question.dart';
import 'app_theme.dart';
import 'common.dart';
import 'l10n_ext.dart';

/// The current sum, in very large type, on a white card with a colourful rim.
class QuestionCard extends StatelessWidget {
  const QuestionCard({super.key, required this.question, this.fontSize = 50, this.trailing});

  final Question question;
  final double fontSize;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final text = context.l10n.questionText(question);
    final isLong = text.length > 18;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(colors: [AppColors.secondary, Color(0xFFFF6FB5), AppColors.primary]),
        boxShadow: [
          BoxShadow(color: AppColors.secondary.withValues(alpha: 0.3), blurRadius: 14, offset: const Offset(0, 6)),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(26)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                text,
                key: const ValueKey('question_text'),
                textAlign: TextAlign.center,
                style: display(isLong ? fontSize * 0.66 : fontSize, height: 1.2),
              ),
            ),
            ?trailing,
          ],
        ),
      ),
    );
  }
}

/// A short, encouraging line under the question.
class FeedbackLine extends StatelessWidget {
  const FeedbackLine({super.key, required this.text, required this.good});

  final String? text;
  final bool good;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
      child: text == null
          ? const SizedBox(height: 48, key: ValueKey('empty'))
          : SizedBox(
              key: ValueKey(text),
              height: 48,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AppImage(good ? 'glow_star' : 'muscle', size: 32),
                  const SizedBox(width: 6),
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        text!,
                        style: display(22, color: good ? AppColors.goodDark : const Color(0xFFC46A00)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
