import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';

import '../../content/links.dart';
import '../../content/post_content.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../l10n/app_localizations.dart';
import '../downloads/file_actions.dart';
import '../routes.dart';
import '../widgets/common.dart';
import 'image_viewer.dart';

/// Renders one [ContentBlock] natively.
class BlockView extends StatelessWidget {
  const BlockView({super.key, required this.block, required this.post});

  final ContentBlock block;
  final Post post;

  @override
  Widget build(BuildContext context) {
    final b = block;
    const pad = EdgeInsets.symmetric(horizontal: 16, vertical: 8);
    return switch (b) {
      HtmlBlock() => Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: HtmlChunk(html: b.html, post: post)),
      HeroBlock() => Padding(padding: pad, child: _HeroView(b)),
      LessonGridBlock() => Padding(padding: pad, child: _LessonGridView(b, post)),
      DownloadListBlock() => Padding(padding: pad, child: _DownloadListView(b, post)),
      HubBlock() => Padding(padding: pad, child: _HubView(b)),
      RelatedBlock() => Padding(padding: pad, child: RelatedView(title: b.title, items: b.items)),
      JoinBlock() => Padding(padding: pad, child: JoinButton(link: b.link, label: b.label)),
      ButtonBlock() => Padding(
          padding: pad,
          child: GradientPill(
            label: b.label,
            icon: b.link.kind == LinkKind.internal ? Icons.article_rounded : Icons.open_in_new_rounded,
            onTap: () => openLink(context, b.link.url, from: post, label: b.label),
          ),
        ),
      YoutubeBlock() => Padding(padding: pad, child: YoutubeCard(videoId: b.videoId, title: b.title)),
      EmbedBlock() => Padding(padding: pad, child: _EmbedView(b)),
      TableBlock() => Padding(padding: pad, child: _TableView(b)),
      AccordionBlock() => Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4), child: _AccordionView(b, post)),
      InteractiveToolBlock() => Padding(padding: pad, child: _ToolNotice(post)),
    };
  }
}

/// Plain HTML via flutter_widget_from_html_core with app styling, cached
/// zoomable images and native link routing.
class HtmlChunk extends StatelessWidget {
  const HtmlChunk({super.key, required this.html, required this.post});

  final String html;
  final Post post;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final link = t.colorScheme.secondary;
    return HtmlWidget(
      html,
      textStyle: t.textTheme.bodyLarge,
      onTapUrl: (url) {
        openLink(context, url, from: post);
        return true;
      },
      customStylesBuilder: (e) {
        switch (e.localName) {
          case 'a':
            return {'color': '#${link.toARGB32().toRadixString(16).substring(2)}', 'text-decoration': 'none', 'font-weight': '600'};
          case 'h1' || 'h2':
            return {'font-size': '1.25em', 'margin': '1em 0 0.4em', 'line-height': '1.45'};
          case 'h3' || 'h4':
            return {'font-size': '1.1em', 'margin': '0.9em 0 0.3em', 'line-height': '1.45'};
          case 'p':
            return {'margin': '0 0 0.8em'};
          case 'figure':
            return {'margin': '0.6em 0'};
          case 'figcaption':
            return {'font-size': '0.85em', 'text-align': 'center', 'color': '#808898'};
          case 'blockquote':
            return {'margin': '0.6em 0', 'padding': '0.2em 0 0.2em 12px', 'border-left': '4px solid #16A34A'};
        }
        // Inline theme colours (black text, white boxes) break dark mode.
        if (e.attributes['style'] != null && t.brightness == Brightness.dark) {
          return {'color': 'inherit', 'background-color': 'transparent'};
        }
        return null;
      },
      customWidgetBuilder: (e) {
        if (e.localName == 'img') {
          final src = bestImageSrc(e.attributes['src'], e.attributes['srcset'], e.attributes['data-src']);
          if (src == null) return const SizedBox.shrink();
          final w = double.tryParse(e.attributes['width'] ?? '');
          final h = double.tryParse(e.attributes['height'] ?? '');
          return InlineCustomWidget(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: ZoomableNetImage(url: src, aspectRatio: w != null && h != null && h > 0 ? w / h : null, alt: e.attributes['alt']),
            ),
          );
        }
        return null;
      },
    );
  }
}

/// Picks a ~768px candidate from `srcset` (falls back to `src`).
String? bestImageSrc(String? src, String? srcset, [String? dataSrc]) {
  if (srcset != null && srcset.isNotEmpty) {
    final candidates = <(String, int)>[];
    for (final part in srcset.split(',')) {
      final bits = part.trim().split(RegExp(r'\s+'));
      if (bits.length == 2 && bits[1].endsWith('w')) {
        final w = int.tryParse(bits[1].substring(0, bits[1].length - 1));
        if (w != null) candidates.add((bits[0], w));
      }
    }
    if (candidates.isNotEmpty) {
      candidates.sort((a, b) => a.$2.compareTo(b.$2));
      return candidates.firstWhere((c) => c.$2 >= 700, orElse: () => candidates.last).$1;
    }
  }
  final s = (src != null && !src.startsWith('data:')) ? src : dataSrc;
  return s;
}

class _HeroView extends StatelessWidget {
  const _HeroView(this.b);

  final HeroBlock b;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final dark = t.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: dark ? Brand.darkHeaderGradient : const LinearGradient(colors: [Color(0xFF1E1B4B), Color(0xFF312E81), Color(0xFF1D4ED8)]),
        borderRadius: BorderRadius.circular(Brand.radius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (b.badge != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: .14), borderRadius: BorderRadius.circular(20)),
              child: Text(b.badge!, style: t.textTheme.labelSmall?.copyWith(color: Colors.white)),
            ),
          const SizedBox(height: 10),
          Text(b.title, style: t.textTheme.titleLarge?.copyWith(color: Colors.white)),
          if (b.lede != null) ...[
            const SizedBox(height: 8),
            Text(b.lede!, style: t.textTheme.bodyMedium?.copyWith(color: const Color(0xFFD7DEF5))),
          ],
          if (b.stats.isNotEmpty) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                for (final (value, label) in b.stats)
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: .10), borderRadius: BorderRadius.circular(14)),
                      child: Column(
                        children: [
                          Text(value, style: t.textTheme.titleLarge?.copyWith(color: Colors.white, height: 1.1)),
                          const SizedBox(height: 2),
                          Text(label, textAlign: TextAlign.center, maxLines: 2, style: t.textTheme.labelSmall?.copyWith(color: const Color(0xFFB9C3E4))),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// One file inside a lesson card / download list.
class FileRow extends StatelessWidget {
  const FileRow({super.key, required this.file, required this.post, this.lessonTitle, this.accent});

  final FileLink file;
  final Post post;
  final String? lessonTitle;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final l = AppLocalizations.of(context);
    final meta = metaFor(context, file, from: post, lessonTitle: lessonTitle);
    final color = accent ?? (file.isAnswer ? Brand.green : Brand.blue);
    final label = file.label.isEmpty ? l.download : file.label;
    return Semantics(
      label: '$label ${lessonTitle ?? ''}',
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(color: color.withValues(alpha: .12), borderRadius: BorderRadius.circular(10)),
              child: Icon(file.isAnswer ? Icons.task_alt_rounded : Icons.description_rounded, color: color, size: 19),
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(label, style: t.textTheme.labelLarge, maxLines: 2, overflow: TextOverflow.ellipsis)),
            IconButton(
              tooltip: l.download,
              visualDensity: VisualDensity.compact,
              onPressed: () => downloadFile(context, file, meta),
              icon: DownloadStatusIcon(fileKey: file.link.key),
            ),
            IconButton(
              tooltip: l.share,
              visualDensity: VisualDensity.compact,
              onPressed: () => shareFile(context, file, meta),
              icon: Icon(Icons.share_rounded, size: 20, color: t.colorScheme.onSurfaceVariant),
            ),
            FilledButton.tonal(
              style: FilledButton.styleFrom(visualDensity: VisualDensity.compact, padding: const EdgeInsets.symmetric(horizontal: 14)),
              onPressed: () => openFile(context, file, meta),
              child: Text(l.open),
            ),
          ],
        ),
      ),
    );
  }
}

class _LessonGridView extends StatelessWidget {
  const _LessonGridView(this.b, this.post);

  final LessonGridBlock b;
  final Post post;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final l = AppLocalizations.of(context);
    final fileCount = b.lessons.fold<int>(0, (n, x) => n + x.files.length);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(gradient: Brand.headerGradient, borderRadius: BorderRadius.circular(Brand.radius)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('KSPSTADK · ${l.files}', style: t.textTheme.labelSmall?.copyWith(color: Colors.white70, letterSpacing: .6)),
              if (b.title != null) ...[
                const SizedBox(height: 6),
                Text(b.title!, style: t.textTheme.titleMedium?.copyWith(color: Colors.white)),
              ],
              const SizedBox(height: 8),
              Wrap(spacing: 8, children: [
                _GlassPill(Icons.menu_book_rounded, '${b.lessons.length}'),
                _GlassPill(Icons.picture_as_pdf_rounded, l.filesCount(fileCount)),
              ]),
            ],
          ),
        ),
        const SizedBox(height: 10),
        for (final (i, lesson) in b.lessons.indexed)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: AppCard(
              padding: const EdgeInsets.fromLTRB(14, 12, 6, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(gradient: Brand.rainbowAt(i), borderRadius: BorderRadius.circular(12)),
                        child: Text(lesson.number ?? '${i + 1}',
                            style: t.textTheme.labelLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 6, right: 8),
                          child: Text(lesson.title, style: t.textTheme.titleSmall),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  for (final f in lesson.files) FileRow(file: f, post: post, lessonTitle: lesson.title),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _GlassPill extends StatelessWidget {
  const _GlassPill(this.icon, this.text);

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: .16), borderRadius: BorderRadius.circular(20)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 4),
          Text(text, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
        ]),
      );
}

class _DownloadListView extends StatelessWidget {
  const _DownloadListView(this.b, this.post);

  final DownloadListBlock b;
  final Post post;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return AppCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 6, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (b.heading != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 4, right: 8),
              child: Row(children: [
                const Icon(Icons.folder_open_rounded, size: 18, color: Brand.blue),
                const SizedBox(width: 8),
                Expanded(child: Text(b.heading!, style: t.textTheme.titleSmall)),
              ]),
            ),
          for (final (i, f) in b.files.indexed)
            FileRow(file: f, post: post, lessonTitle: b.heading, accent: Brand.rainbow[i % Brand.rainbow.length][0]),
        ],
      ),
    );
  }
}

class _HubView extends StatelessWidget {
  const _HubView(this.b);

  final HubBlock b;

  static const _groupColors = {
    'g-lang': [Color(0xFFF472B6), Color(0xFFDB2777)],
    'g-bi': [Color(0xFFC084FC), Color(0xFF7C3AED)],
    'g-km': [Color(0xFF60A5FA), Color(0xFF2563EB)],
    'g-em': [Color(0xFF34D399), Color(0xFF059669)],
  };

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (gi, g) in b.groups.indexed) ...[
          if (g.title.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 10),
              child: Row(children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: _groupColors[g.colorKey] ?? Brand.rainbow[gi % Brand.rainbow.length]),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.auto_stories_rounded, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(g.title, style: t.textTheme.titleSmall),
                    if (g.subtitle != null)
                      Text(g.subtitle!, style: t.textTheme.labelSmall?.copyWith(color: t.colorScheme.onSurfaceVariant)),
                  ]),
                ),
              ]),
            ),
          LayoutBuilder(builder: (context, c) {
            final cols = c.maxWidth > 560 ? 3 : 2;
            final w = (c.maxWidth - (cols - 1) * 10) / cols;
            return Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final (i, card) in g.cards.indexed)
                  SizedBox(
                    width: w,
                    child: AppCard(
                      semanticLabel: '${card.name} ${card.sub ?? ''}',
                      onTap: () => openLink(context, card.url),
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Container(
                              height: 4,
                              width: 28,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(colors: _groupColors[g.colorKey] ?? Brand.rainbow[(gi + i) % Brand.rainbow.length]),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Spacer(),
                            if (card.chip != null)
                              Flexible(child: TagChip(label: card.chip!, color: (_groupColors[g.colorKey] ?? Brand.rainbow[0])[1])),
                          ]),
                          const SizedBox(height: 10),
                          Text(card.name, style: t.textTheme.titleSmall, maxLines: 2),
                          if (card.sub != null)
                            Text(card.sub!,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: t.textTheme.labelSmall?.copyWith(color: t.colorScheme.onSurfaceVariant)),
                          const SizedBox(height: 8),
                          Row(children: [
                            Text(AppLocalizations.of(context).open, style: t.textTheme.labelMedium?.copyWith(color: t.colorScheme.primary)),
                            Icon(Icons.arrow_forward_rounded, size: 16, color: t.colorScheme.primary),
                          ]),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          }),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

/// The rainbow "ಇವುಗಳನ್ನೂ ಓದಿ" chips.
class RelatedView extends StatelessWidget {
  const RelatedView({super.key, required this.title, required this.items});

  final String title;
  final List<RelatedItem> items;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10, top: 6),
          child: Row(children: [
            ShaderMask(
              shaderCallback: (r) => Brand.rainbowAt(0).createShader(r),
              child: const Icon(Icons.auto_awesome_rounded, color: Colors.white),
            ),
            const SizedBox(width: 8),
            Semantics(header: true, child: Text(title, style: t.textTheme.titleMedium)),
          ]),
        ),
        for (final (i, it) in items.indexed)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Semantics(
              button: true,
              label: it.title,
              excludeSemantics: true,
              child: Material(
                color: Colors.transparent,
                child: Ink(
                  decoration: BoxDecoration(gradient: Brand.rainbowAt(i), borderRadius: BorderRadius.circular(14)),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => openLink(context, it.url),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      child: Row(children: [
                        Container(
                          constraints: const BoxConstraints(minWidth: 30),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                          decoration: BoxDecoration(color: Colors.white.withValues(alpha: .22), borderRadius: BorderRadius.circular(8)),
                          child: it.badge != null
                              ? Text(it.badge!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700))
                              : const Icon(Icons.article_rounded, color: Colors.white, size: 16),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(it.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: t.textTheme.labelLarge?.copyWith(color: Colors.white, height: 1.4)),
                        ),
                        const Icon(Icons.chevron_right_rounded, color: Colors.white),
                      ]),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class JoinButton extends StatelessWidget {
  const JoinButton({super.key, required this.link, required this.label});

  final LinkInfo link;
  final String label;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final wa = link.kind == LinkKind.whatsappGroup;
    final text = label.isEmpty ? (wa ? l.joinWhatsapp : l.joinTelegram) : label;
    return GradientPill(
      label: text,
      icon: wa ? Icons.forum_rounded : Icons.send_rounded,
      gradient: LinearGradient(colors: wa ? const [Color(0xFF25D366), Color(0xFF128C7E)] : const [Color(0xFF2AABEE), Color(0xFF229ED9)]),
      onTap: () => openExternal(link.url),
    );
  }
}

class YoutubeCard extends StatelessWidget {
  const YoutubeCard({super.key, required this.videoId, this.title});

  final String videoId;
  final String? title;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Semantics(
      button: true,
      label: '${l.playVideo} ${title ?? ''}',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: () => openExternal('https://www.youtube.com/watch?v=$videoId'),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(Brand.radius),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: Stack(fit: StackFit.expand, children: [
              NetImage('https://img.youtube.com/vi/$videoId/hqdefault.jpg', memWidth: 640),
              const DecoratedBox(decoration: BoxDecoration(color: Color(0x33000000))),
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  decoration: BoxDecoration(color: const Color(0xFFFF0000), borderRadius: BorderRadius.circular(14)),
                  child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 34),
                ),
              ),
              if (title != null)
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 10,
                  child: Text(title!, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, shadows: [Shadow(blurRadius: 6)])),
                ),
            ]),
          ),
        ),
      ),
    );
  }
}

class _EmbedView extends StatelessWidget {
  const _EmbedView(this.b);

  final EmbedBlock b;

  @override
  Widget build(BuildContext context) {
    final host = Uri.tryParse(b.url)?.host ?? b.url;
    return AppCard(
      onTap: () => openInApp(b.url),
      padding: const EdgeInsets.all(14),
      child: Row(children: [
        const Icon(Icons.open_in_browser_rounded, color: Brand.blue),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(b.title ?? host, style: Theme.of(context).textTheme.titleSmall, maxLines: 2),
            Text(host, style: Theme.of(context).textTheme.labelSmall),
          ]),
        ),
        const Icon(Icons.chevron_right_rounded),
      ]),
    );
  }
}

class _TableView extends StatelessWidget {
  const _TableView(this.b);

  final TableBlock b;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final scheme = t.colorScheme;
    final cols = b.rows.map((r) => r.length).fold(0, (a, n) => a > n ? a : n);
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: scheme.outlineVariant),
        borderRadius: BorderRadius.circular(14),
        color: scheme.surfaceContainerLowest,
      ),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: MediaQuery.sizeOf(context).width - 32),
          child: Table(
            defaultColumnWidth: const IntrinsicColumnWidth(),
            border: TableBorder(horizontalInside: BorderSide(color: scheme.outlineVariant.withValues(alpha: .6))),
            children: [
              for (final (i, row) in b.rows.indexed)
                TableRow(
                  decoration: BoxDecoration(
                    gradient: i == 0 && b.hasHeader ? Brand.primaryGradient : null,
                    color: i == 0 && b.hasHeader ? null : (i.isOdd ? scheme.surfaceContainer.withValues(alpha: .5) : null),
                  ),
                  children: [
                    for (var c = 0; c < cols; c++)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 260),
                          child: Text(
                            c < row.length ? row[c] : '',
                            style: i == 0 && b.hasHeader
                                ? t.textTheme.labelLarge?.copyWith(color: Colors.white)
                                : t.textTheme.bodySmall?.copyWith(fontSize: 13.5),
                          ),
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AccordionView extends StatelessWidget {
  const _AccordionView(this.b, this.post);

  final AccordionBlock b;
  final Post post;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          shape: const RoundedRectangleBorder(),
          leading: const Icon(Icons.help_outline_rounded, color: Brand.blue),
          title: Text(b.title, style: Theme.of(context).textTheme.titleSmall),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          children: [HtmlChunk(html: b.html, post: post)],
        ),
      ),
    );
  }
}

class _ToolNotice extends StatelessWidget {
  const _ToolNotice(this.post);

  final Post post;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          const Icon(Icons.calculate_rounded, color: Brand.indigo),
          const SizedBox(width: 10),
          Expanded(child: Text(l.interactiveNotice, style: Theme.of(context).textTheme.bodyMedium)),
        ]),
        const SizedBox(height: 12),
        GradientPill(label: l.openTool, icon: Icons.open_in_new_rounded, onTap: () => openInApp(post.link)),
      ]),
    );
  }
}
