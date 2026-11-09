import 'package:flutter/material.dart';

import '../models/question.dart';
import 'l10n_ext.dart';

/// The current sum, in very large type.
class QuestionCard extends StatelessWidget {
  const QuestionCard({super.key, required this.question, this.fontSize = 46, this.trailing});

  final Question question;
  final double fontSize;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final text = context.l10n.questionText(question);
    final isLong = text.length > 18;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              text,
              key: const ValueKey('question_text'),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: isLong ? fontSize * 0.72 : fontSize, fontWeight: FontWeight.w700),
            ),
          ),
          ?trailing,
        ],
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
          ? const SizedBox(height: 40, key: ValueKey('empty'))
          : SizedBox(
              key: ValueKey(text),
              height: 40,
              child: FittedBox(
                child: Text(
                  text!,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: good ? const Color(0xFF1B8A45) : const Color(0xFFB35C00),
                  ),
                ),
              ),
            ),
    );
  }
}
