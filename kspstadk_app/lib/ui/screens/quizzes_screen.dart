import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../data/wp_api.dart';
import '../../l10n/app_localizations.dart';
import '../../state/app_state.dart';
import '../routes.dart';
import 'post_list_screen.dart';

/// Quiz posts (QUIZ, MYGOV QUIZ, ರಸಪ್ರಶ್ನೆ) plus the KSPSTADK tools web app in
/// a Custom Tab. A native quiz engine is on the roadmap.
class QuizzesScreen extends StatelessWidget {
  const QuizzesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = Theme.of(context);
    final cfg = context.app.config;
    return Scaffold(
      appBar: AppBar(title: Text(l.quizzes)),
      body: PagedPostList(
        query: WpApi.postsQuery(categories: cfg.quizIds),
        heroPrefix: 'quiz',
        header: cfg.toolsUrl == null
            ? null
            : Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Material(
                  color: Colors.transparent,
                  child: Ink(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFFEA580C), Color(0xFFDB2777), Color(0xFF7C3AED)]),
                      borderRadius: BorderRadius.circular(Brand.radius),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(Brand.radius),
                      onTap: () => openInApp(cfg.toolsUrl!),
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Row(children: [
                          const Icon(Icons.emoji_events_rounded, color: Colors.white, size: 36),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(l.tools, style: t.textTheme.titleMedium?.copyWith(color: Colors.white)),
                              Text(l.toolsSubtitle, style: t.textTheme.bodySmall?.copyWith(color: Colors.white70)),
                            ]),
                          ),
                          const Icon(Icons.open_in_new_rounded, color: Colors.white),
                        ]),
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
