import 'package:flutter/material.dart';

import '../app_state.dart';
import '../screens/charts_screen.dart';
import '../screens/quiz_screen.dart';

/// A shortcut to one learning section.
class _Shortcut {
  const _Shortcut(this.kn, this.en, this.icon, this.builder);

  final String kn;
  final String Function() en;
  final IconData icon;
  final WidgetBuilder builder;
}

final List<_Shortcut> _shortcuts = [
  _Shortcut(
    'ಚಾರ್ಟ್',
    () => 'Charts',
    Icons.grid_view_rounded,
    (_) => const ChartsScreen(),
  ),
  _Shortcut(
    'ರಸಪ್ರಶ್ನೆ',
    () {
      final n = AppState.instance.currentStreak;
      return n > 0 ? 'Quiz · 🔥 $n' : 'Quiz';
    },
    Icons.quiz_outlined,
    (_) => const QuizScreen(),
  ),
];

/// Learning sections (wrapping row) shown at the top of the Lipi tab.
class LearnShortcuts extends StatelessWidget {
  const LearnShortcuts({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListenableBuilder(
      listenable: AppState.instance,
      builder: (context, _) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 2),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final s in _shortcuts)
              Material(
                color: cs.secondaryContainer,
                borderRadius: BorderRadius.circular(16),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () =>
                      Navigator.of(context)
                          .push(MaterialPageRoute<void>(builder: s.builder)),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 16, 10),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(s.icon, color: cs.onSecondaryContainer),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s.kn,
                              style: TextStyle(
                                color: cs.onSecondaryContainer,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              s.en(),
                              style: TextStyle(
                                color: cs.onSecondaryContainer,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
