import 'dart:convert';

import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html_parser;

import '../core/text_utils.dart';
import 'links.dart';

/// A post body split into native blocks and plain HTML chunks.
///
/// The site's custom HTML (download grids, class hubs, rainbow "ಇವುಗಳನ್ನೂ ಓದಿ"
/// lists, Ultimate Blocks buttons, accordions, tables …) is recognised and
/// turned into data so the app can draw it natively; everything else stays
/// HTML for `flutter_widget_from_html_core`.
sealed class ContentBlock {
  const ContentBlock();
}

class HtmlBlock extends ContentBlock {
  const HtmlBlock(this.html);
  final String html;
}

/// `.kh-hero`: badge, title, lede and stat pills.
class HeroBlock extends ContentBlock {
  const HeroBlock({this.badge, required this.title, this.lede, this.stats = const []});
  final String? badge;
  final String title;
  final String? lede;

  /// (value, label) pairs.
  final List<(String, String)> stats;
}

class FileLink {
  const FileLink({required this.label, required this.link, this.isAnswer = false});
  final String label;
  final LinkInfo link;
  final bool isAnswer;
}

class Lesson {
  const Lesson({this.number, required this.title, required this.files});
  final String? number;
  final String title;
  final List<FileLink> files;
}

/// `section.kspstadk-lba` → `.kl-grid` of `.kl-card`s (lesson + Q/A files).
class LessonGridBlock extends ContentBlock {
  const LessonGridBlock({this.title, this.subtitle, required this.lessons});
  final String? title;
  final String? subtitle;
  final List<Lesson> lessons;
}

/// Consecutive download buttons/links, grouped under the nearest heading.
class DownloadListBlock extends ContentBlock {
  const DownloadListBlock({this.heading, required this.files});
  final String? heading;
  final List<FileLink> files;
}

class HubCard {
  const HubCard({required this.name, this.sub, this.chip, required this.url});
  final String name;
  final String? sub;
  final String? chip;
  final String url;
}

class HubGroup {
  const HubGroup({required this.title, this.subtitle, required this.cards, this.colorKey});
  final String title;
  final String? subtitle;
  final List<HubCard> cards;

  /// `g-lang`, `g-bi`, `g-km`, `g-em` … picks the accent colour.
  final String? colorKey;
}

/// `section.ksp-hub` groups of `a.kh-card` subject tiles.
class HubBlock extends ContentBlock {
  const HubBlock(this.groups);
  final List<HubGroup> groups;
}

class RelatedItem {
  const RelatedItem({required this.title, required this.url, this.badge});
  final String title;
  final String url;
  final String? badge;
}

/// "ಇವುಗಳನ್ನೂ ಓದಿ" / "ಇದನ್ನೂ ಓದಿ" related-posts block (all three markups).
class RelatedBlock extends ContentBlock {
  const RelatedBlock({required this.title, required this.items});
  final String title;
  final List<RelatedItem> items;
}

class JoinBlock extends ContentBlock {
  const JoinBlock({required this.link, required this.label});
  final LinkInfo link;
  final String label;
}

/// A call-to-action button that is not a file (internal or external link).
class ButtonBlock extends ContentBlock {
  const ButtonBlock({required this.label, required this.link});
  final String label;
  final LinkInfo link;
}

class YoutubeBlock extends ContentBlock {
  const YoutubeBlock({required this.videoId, this.title});
  final String videoId;
  final String? title;
}

/// Non-YouTube iframes (Google Forms, Maps, …): shown as a link card.
class EmbedBlock extends ContentBlock {
  const EmbedBlock({required this.url, this.title});
  final String url;
  final String? title;
}

class TableBlock extends ContentBlock {
  const TableBlock({required this.rows, this.hasHeader = false});

  /// Cell texts; rows may have different lengths.
  final List<List<String>> rows;
  final bool hasHeader;
}

class AccordionBlock extends ContentBlock {
  const AccordionBlock({required this.title, required this.html});
  final String title;
  final String html;
}

/// The post contains an interactive tool (calculator/form driven by
/// `<script>`), which can only work on the website.
class InteractiveToolBlock extends ContentBlock {
  const InteractiveToolBlock();
}

/// Parse result.
class PostContent {
  const PostContent(this.blocks);

  final List<ContentBlock> blocks;

  /// Every downloadable file in the post, in order.
  List<FileLink> get files => [
        for (final b in blocks)
          if (b is LessonGridBlock)
            for (final l in b.lessons) ...l.files
          else if (b is DownloadListBlock)
            ...b.files,
      ];

  RelatedBlock? get related => blocks.whereType<RelatedBlock>().firstOrNull;
}

const _relatedTitles = ['ಇವುಗಳನ್ನೂ ಓದಿ', 'ಇದನ್ನೂ ಓದಿ', 'ಇವನ್ನೂ ಓದಿ', 'also read', 'related'];

/// Parses a rendered WordPress post body.
PostContent parsePostContent(String html) {
  final frag = html_parser.parseFragment(html);
  final interactive = _isInteractive(frag);
  _strip(frag);

  final out = _Builder();
  if (interactive) out.add(const InteractiveToolBlock());
  for (final n in frag.nodes.toList()) {
    _walk(n, out);
  }
  out.flush();
  return PostContent(out.blocks);
}

bool _isInteractive(dom.DocumentFragment f) {
  final scripts = f.querySelectorAll('script').map((s) => s.text).join('\n');
  final hasInputs = f.querySelectorAll('input, select, textarea, canvas').length >= 2 ||
      f.querySelectorAll('button:not([class*=ub-])').length >= 2;
  return scripts.length > 400 && hasInputs;
}

void _strip(dom.DocumentFragment f) {
  for (final sel in [
    'style', 'script', 'noscript', 'svg', 'link', 'meta', 'form',
    // site decorations / share widgets
    '.share', '.kl-blob', '.kh-orb', '.kspstadk-share', '.sharedaddy', '.addtoany_share_save_container',
    'ins.adsbygoogle', '.code-block', '[class*=ai-viewport]', '.wp-block-spacer',
  ]) {
    for (final e in f.querySelectorAll(sel)) {
      e.remove();
    }
  }
  void dropComments(dom.Node n) {
    for (final c in n.nodes.toList()) {
      if (c is dom.Comment) {
        c.remove();
      } else {
        dropComments(c);
      }
    }
  }

  dropComments(f);
  // Shortcode leftovers like [ad id="3"] in text nodes.
  void scrubText(dom.Node n) {
    for (final c in n.nodes) {
      if (c is dom.Text) {
        final t = c.data.replaceAll(RegExp(r'\[/?[a-z_][\w-]*(\s[^\]]*)?\]'), '');
        if (t != c.data) c.data = t;
      } else {
        scrubText(c);
      }
    }
  }

  scrubText(f);
}

class _Builder {
  final blocks = <ContentBlock>[];
  final _html = StringBuffer();
  String? lastHeading;
  DownloadListBlock? _pending;

  void html(String s) {
    if (s.trim().isEmpty) return;
    _flushDownloads();
    _html.write(s);
  }

  void add(ContentBlock b) {
    flush();
    blocks.add(b);
  }

  void download(FileLink f) {
    if (_html.toString().trim().isNotEmpty) {
      blocks.add(HtmlBlock(_html.toString()));
      _html.clear();
    }
    _pending ??= DownloadListBlock(heading: lastHeading, files: []);
    _pending!.files.add(f);
  }

  void _flushDownloads() {
    if (_pending != null) {
      blocks.add(_pending!);
      _pending = null;
    }
  }

  void flush() {
    _flushDownloads();
    final s = _html.toString();
    if (s.trim().isNotEmpty && plainOrMedia(s)) blocks.add(HtmlBlock(s));
    _html.clear();
  }

  static bool plainOrMedia(String s) => plainText(s).isNotEmpty || s.contains('<img');
}

String _text(dom.Element? e) => e == null ? '' : plainText(e.innerHtml);

bool _hasClass(dom.Element e, String c) => e.classes.contains(c);

void _walk(dom.Node n, _Builder out) {
  if (n is dom.Text) {
    out.html(const HtmlEscape(HtmlEscapeMode.element).convert(n.text));
    return;
  }
  if (n is! dom.Element) return;
  final e = n;
  final tag = e.localName;

  // ---- Recognised site components ----
  if (_hasClass(e, 'kspstadk-lba') || (_hasClass(e, 'kl-grid') && e.parent?.classes.contains('kspstadk-lba') != true)) {
    final grid = _lessonGrid(e);
    if (grid != null) out.add(grid);
    return;
  }
  if (_hasClass(e, 'ksp-hub')) {
    final hero = e.querySelector('.kh-hero');
    if (hero != null) out.add(_hero(hero));
    final hub = _hub(e);
    if (hub.groups.isNotEmpty) out.add(hub);
    return;
  }
  if (_hasClass(e, 'kh-hero')) {
    out.add(_hero(e));
    return;
  }
  final related = _related(e);
  if (related != null) {
    out.add(related);
    return;
  }
  if (_hasClass(e, 'wp-block-ub-button') || _hasClass(e, 'wp-block-buttons') || _hasClass(e, 'ub-buttons')) {
    for (final a in e.querySelectorAll('a[href]')) {
      _button(a, out);
    }
    return;
  }
  if (_hasClass(e, 'wp-block-ub-content-toggle') || _hasClass(e, 'wp-block-ub-content-toggle-accordion')) {
    final items = _hasClass(e, 'wp-block-ub-content-toggle-accordion')
        ? [e]
        : e.querySelectorAll('.wp-block-ub-content-toggle-accordion');
    for (final item in items) {
      final title = _text(item.querySelector('.wp-block-ub-content-toggle-accordion-title') ??
          item.querySelector('.wp-block-ub-content-toggle-accordion-title-wrap'));
      final body = item.querySelector('.wp-block-ub-content-toggle-accordion-content-wrap');
      if (title.isNotEmpty) out.add(AccordionBlock(title: title, html: body?.innerHtml ?? ''));
    }
    return;
  }
  if (tag == 'details') {
    final summary = e.querySelector('summary');
    final title = _text(summary);
    summary?.remove();
    out.add(AccordionBlock(title: title, html: e.innerHtml));
    return;
  }
  if (tag == 'table') {
    final t = _table(e);
    if (t != null) out.add(t);
    return;
  }
  if (tag == 'iframe') {
    final src = e.attributes['src'] ?? e.attributes['data-src'] ?? '';
    final vid = youtubeId(src);
    if (vid != null) {
      out.add(YoutubeBlock(videoId: vid, title: e.attributes['title']));
    } else if (src.startsWith('http')) {
      out.add(EmbedBlock(url: src, title: e.attributes['title']));
    }
    return;
  }
  if (tag == 'a' && e.attributes['href'] != null && _isStandaloneButton(e)) {
    _button(e, out);
    return;
  }
  if (const {'h1', 'h2', 'h3', 'h4'}.contains(tag)) {
    final t = _text(e);
    if (t.isNotEmpty) out.lastHeading = t;
  }

  // ---- Containers holding components: descend; otherwise keep as HTML ----
  if (_containsComponent(e)) {
    for (final c in e.nodes.toList()) {
      _walk(c, out);
    }
    return;
  }
  // A paragraph that is only a file link becomes a download row.
  if (tag == 'p' || tag == 'li') {
    final links = e.querySelectorAll('a[href]');
    if (links.length == 1 && _text(e) == _text(links.first)) {
      final info = classifyLink(links.first.attributes['href']!);
      if (info.isDownload) {
        out.download(FileLink(label: _label(links.first, out), link: info));
        return;
      }
      if (info.kind == LinkKind.whatsappGroup || info.kind == LinkKind.telegramGroup) {
        out.add(JoinBlock(link: info, label: _text(links.first)));
        return;
      }
    }
  }
  out.html(e.outerHtml);
}

const _componentSelector =
    '.kspstadk-lba, .kl-grid, .ksp-hub, .kh-hero, .kspstadk-related, .sec.rel, .also-read-container, '
    '.wp-block-ub-button, .wp-block-buttons, .ub-buttons, .wp-block-ub-content-toggle, details, table, iframe';

bool _containsComponent(dom.Element e) {
  if (e.querySelector(_componentSelector) != null) return true;
  for (final a in e.querySelectorAll('a[href]')) {
    if (_isStandaloneButton(a)) return true;
  }
  return e.querySelectorAll('h2, h3').any((h) => _relatedTitles.any((t) => _text(h).toLowerCase().contains(t)));
}

/// Styled CTA anchors (gradient "float-btn", `.btn`, `.button`) that point to
/// files, groups or other posts.
bool _isStandaloneButton(dom.Element a) {
  final cls = a.className;
  if (!RegExp(r'btn|button|cta').hasMatch(cls)) return false;
  if (cls.contains('kl-btn') || cls.contains('kh-card') || cls.contains('read-more')) return false;
  return true;
}

void _button(dom.Element a, _Builder out) {
  final href = a.attributes['href'];
  if (href == null || href.startsWith('#') || href.startsWith('javascript')) return;
  final info = classifyLink(href);
  final label = _label(a, out);
  switch (info.kind) {
    case LinkKind.drive:
    case LinkKind.file:
      out.download(FileLink(label: label, link: info));
    case LinkKind.whatsappGroup:
    case LinkKind.telegramGroup:
      out.add(JoinBlock(link: info, label: label));
    case LinkKind.youtube:
      out.add(YoutubeBlock(videoId: info.videoId!, title: label));
    case _:
      // wa.me / t.me/share buttons are the site's share widgets.
      if (href.contains('wa.me/') || href.contains('/share/url') || href.contains('facebook.com/sharer')) return;
      out.add(ButtonBlock(label: label.isEmpty ? href : label, link: info));
  }
}

String _label(dom.Element a, _Builder out) {
  final inner = a.querySelector('.ub-button-block-btn') ?? a;
  var label = cleanLinkLabel(_text(inner));
  if (label.isEmpty) label = out.lastHeading ?? '';
  return label;
}

LessonGridBlock? _lessonGrid(dom.Element section) {
  final cards = section.querySelectorAll('.kl-card');
  if (cards.isEmpty) return null;
  final lessons = <Lesson>[];
  for (final c in cards) {
    final files = <FileLink>[];
    for (final a in c.querySelectorAll('a[href]')) {
      final href = a.attributes['href']!;
      if (href == '#' || href.isEmpty) continue;
      final info = classifyLink(href);
      if (!info.isDownload) continue;
      files.add(FileLink(label: cleanLinkLabel(_text(a)), link: info, isAnswer: a.classes.contains('a')));
    }
    final num = _text(c.querySelector('.kl-num'));
    lessons.add(Lesson(
      number: num.isEmpty ? null : num,
      title: _text(c.querySelector('.kl-title')).isEmpty ? _text(c.querySelector('h3, h4')) : _text(c.querySelector('.kl-title')),
      files: files,
    ));
  }
  return LessonGridBlock(
    title: _text(section.querySelector('.kl-head h2') ?? section.querySelector('h2')).ifEmptyNull,
    subtitle: _text(section.querySelector('.kl-sub')).ifEmptyNull,
    lessons: lessons,
  );
}

HeroBlock _hero(dom.Element hero) => HeroBlock(
      badge: _text(hero.querySelector('.kh-badge')).ifEmptyNull,
      title: _text(hero.querySelector('h1, h2')),
      lede: _text(hero.querySelector('.kh-lede')).ifEmptyNull,
      stats: [
        for (final s in hero.querySelectorAll('.kh-stat'))
          (_text(s.querySelector('b')), _text(s.querySelector('span'))),
      ],
    );

HubBlock _hub(dom.Element hub) {
  final groups = <HubGroup>[];
  for (final g in hub.querySelectorAll('.kh-group')) {
    final cards = [
      for (final a in g.querySelectorAll('a.kh-card[href]'))
        HubCard(
          name: _text(a.querySelector('.kh-name')),
          sub: _text(a.querySelector('.kh-sub2')).ifEmptyNull,
          chip: _text(a.querySelector('.kh-chip')).ifEmptyNull,
          url: a.attributes['href']!,
        ),
    ];
    if (cards.isEmpty) continue;
    groups.add(HubGroup(
      title: _text(g.querySelector('.kh-gtext h3') ?? g.querySelector('h3')),
      subtitle: _text(g.querySelector('.kh-gtext span')).ifEmptyNull,
      cards: cards,
      colorKey: g.classes.firstWhere((c) => c.startsWith('g-'), orElse: () => '').ifEmptyNull,
    ));
  }
  // Hubs without groups: loose cards.
  if (groups.isEmpty) {
    final cards = [
      for (final a in hub.querySelectorAll('a.kh-card[href]'))
        HubCard(name: _text(a.querySelector('.kh-name')), sub: _text(a.querySelector('.kh-sub2')).ifEmptyNull, url: a.attributes['href']!),
    ];
    if (cards.isNotEmpty) groups.add(HubGroup(title: '', cards: cards));
  }
  return HubBlock(groups);
}

RelatedBlock? _related(dom.Element e) {
  List<RelatedItem> items(Iterable<dom.Element> anchors, String? titleSel, {String? badgeSel}) => [
        for (final a in anchors)
          if (a.attributes['href'] != null)
            RelatedItem(
              title: titleSel == null ? _text(a) : (_text(a.querySelector(titleSel)).ifEmptyNull ?? _text(a)),
              url: a.attributes['href']!,
              badge: badgeSel == null ? null : _text(a.querySelector(badgeSel)).ifEmptyNull,
            ),
      ];

  if (_hasClass(e, 'kspstadk-related')) {
    return RelatedBlock(
      title: _text(e.querySelector('.kr-head h2') ?? e.querySelector('h2, h3')).ifEmptyNull ?? 'ಇವುಗಳನ್ನೂ ಓದಿ',
      items: items(e.querySelectorAll('a.kr-row'), '.kr-title', badgeSel: '.kr-num'),
    );
  }
  if (_hasClass(e, 'sec') && _hasClass(e, 'rel')) {
    return RelatedBlock(
      title: _text(e.querySelector('h2, h3')).ifEmptyNull ?? 'ಇವುಗಳನ್ನೂ ಓದಿ',
      items: items(e.querySelectorAll('a[href]'), '.tt'),
    );
  }
  final alsoRead = _hasClass(e, 'also-read-container') ? e : null;
  if (alsoRead != null) {
    return RelatedBlock(
      title: _text(e.querySelector('.also-read-title')).ifEmptyNull ?? 'ಇದನ್ನೂ ಓದಿ',
      items: [
        for (final it in items(e.querySelectorAll('a.also-read-link'), 'span'))
          RelatedItem(title: it.title.replaceAll(RegExp(r'^📌\s*'), ''), url: it.url),
      ],
    );
  }
  return null;
}

TableBlock? _table(dom.Element t) {
  final rows = <List<String>>[];
  var header = false;
  for (final tr in t.querySelectorAll('tr')) {
    final cells = tr.children.where((c) => c.localName == 'td' || c.localName == 'th').toList();
    if (cells.isEmpty) continue;
    if (rows.isEmpty && (cells.every((c) => c.localName == 'th') || tr.parent?.localName == 'thead')) header = true;
    rows.add([for (final c in cells) _text(c)]);
  }
  if (rows.isEmpty) return null;
  return TableBlock(rows: rows, hasHeader: header);
}

extension on String {
  String? get ifEmptyNull => trim().isEmpty ? null : trim();
}
