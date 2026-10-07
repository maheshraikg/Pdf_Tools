import 'package:flutter/material.dart';

import '../app/scope.dart';
import '../app/strings.dart';
import '../monetization/flags.dart';
import '../packs/content.dart';
import '../widgets/vesha_guide.dart';

Future<void> openStory(
  BuildContext context,
  Story story, {
  PuzzleDef? puzzle,
}) => Navigator.of(context).push(
  MaterialPageRoute(
    builder: (_) => StoryScreen(story: story, puzzle: puzzle),
  ),
);

class StoryScreen extends StatefulWidget {
  const StoryScreen({super.key, required this.story, this.puzzle});
  final Story story;
  final PuzzleDef? puzzle;

  @override
  State<StoryScreen> createState() => _StoryScreenState();
}

class _StoryScreenState extends State<StoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final app = AppScope.read(context);
      final fresh = app.markStoryRead(widget.story.id);
      if (fresh.isNotEmpty) {
        final s = S.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${s.unlockedAchievement}: ${fresh.map(s.achievementTitle).join(', ')}',
            ),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final s = S.of(context);
    final lang = app.settings.lang;
    final story = widget.story;
    final t = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final paragraphs = story.body.of(lang).split(RegExp(r'\n\s*\n'));
    final fact = story.fact.of(lang);
    return Scaffold(
      appBar: AppBar(title: Text(s.stories)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        children: [
          if (widget.puzzle != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(
                widget.puzzle!.image,
                fit: BoxFit.cover,
                cacheWidth: 1080,
              ),
            ),
          const SizedBox(height: 16),
          Text(story.title.of(lang), style: t.headlineSmall),
          if (kShowReviewFlags && story.review.pending)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  Icon(
                    Icons.rate_review_outlined,
                    size: 18,
                    color: scheme.error,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      s.underReview,
                      style: t.labelMedium?.copyWith(color: scheme.error),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 12),
          for (final p in paragraphs)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(p.trim(), style: t.bodyLarge?.copyWith(height: 1.5)),
            ),
          if (fact.isNotEmpty)
            Card(
              color: scheme.secondaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.didYouKnow, style: t.titleSmall),
                    const SizedBox(height: 4),
                    Text(fact),
                  ],
                ),
              ),
            ),
          if (story.sources.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(s.sources, style: t.titleSmall),
            for (final src in story.sources) Text('• $src', style: t.bodySmall),
          ],
          const SizedBox(height: 16),
          if (app.settings.guideTips)
            VeshaGuide(
              line: VeshaGuide.pick(
                app.content,
                'story.',
                salt: story.id.hashCode,
              ),
            ),
        ],
      ),
    );
  }
}
