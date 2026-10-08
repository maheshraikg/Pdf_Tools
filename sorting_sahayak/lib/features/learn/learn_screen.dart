/// Learn / practice hub: flashcards, timed quiz, weak areas, PIN basics.
library;

import 'package:flutter/material.dart';

import '../../core/app_scope.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/widgets.dart';
import '../../data/import/scheme_io.dart';
import '../../core/files.dart';
import 'flashcards_screen.dart';
import 'pin_basics_screen.dart';
import 'quiz_screen.dart';
import 'weak_areas_screen.dart';

class LearnScreen extends StatelessWidget {
  const LearnScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final services = context.services;
    final scheme = services.active;
    void open(Widget w) => Navigator.push(context, MaterialPageRoute(builder: (_) => w));
    Widget tile(IconData icon, String title, String sub, VoidCallback? onTap) => Card(
      child: ListTile(
        leading: Icon(icon, size: 36, color: Theme.of(context).colorScheme.primary),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(sub),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
        enabled: onTap != null,
      ),
    );
    final hasAir = scheme != null && !scheme.airResolver.isEmpty;
    return Scaffold(
      appBar: AppBar(title: Text(l.navLearn)),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          if (scheme == null)
            WarningBanner(
              text: l.learnNeedsScheme,
              icon: Icons.school_outlined,
              action: TextButton(
                onPressed: () async {
                  await installSampleScheme(services.schemes, loadAssetBytes);
                  await services.reloadActive();
                },
                child: Text(l.useSample),
              ),
            )
          else
            ListTile(
              title: Text(scheme.scheme.name),
              subtitle: Text(l.learnFromScheme),
              trailing: scheme.scheme.isSample ? const SampleChip() : null,
            ),
          tile(Icons.style_outlined, l.flashcards, l.flashcardsSub, scheme == null ? null : () => open(const FlashcardsScreen(mode: FlashMode.bag))),
          tile(Icons.timer_outlined, l.timedQuiz, l.timedQuizSub, scheme == null ? null : () => open(const QuizScreen(mode: FlashMode.bag))),
          tile(Icons.flight_takeoff, l.airFlashcards, l.airFlashcardsSub, hasAir ? () => open(const FlashcardsScreen(mode: FlashMode.air)) : null),
          tile(Icons.quiz_outlined, l.airQuiz, l.airQuizSub, hasAir ? () => open(const QuizScreen(mode: FlashMode.air)) : null),
          tile(Icons.hub_outlined, l.hubFlashcards, l.hubFlashcardsSub, scheme != null && !scheme.hubResolver.isEmpty ? () => open(const FlashcardsScreen(mode: FlashMode.hub)) : null),
          tile(Icons.trending_down, l.weakAreas, l.weakAreasSub, () => open(const WeakAreasScreen())),
          tile(Icons.menu_book_outlined, l.pinBasics, l.pinBasicsSub, () => open(const PinBasicsScreen())),
        ],
      ),
    );
  }
}
