import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app_state.dart';
import '../../core/article_number.dart';
import '../../data/models.dart';
import '../common/widgets.dart';
import '../run/route_screen.dart';
import 'article_editor.dart';
import 'scan_screens.dart';

/// Today's articles: add by barcode, OCR or typing; matched articles are
/// grouped by place, unmatched ones are listed first.
class TodayScreen extends StatefulWidget {
  const TodayScreen({super.key});

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  final String _date = dayKey(DateTime.now());
  List<Article> _articles = [];
  Map<int, PlaceDetails> _places = {};
  int _carryable = 0;
  int _version = -1;

  Future<void> _load() async {
    final s = context.services;
    final list = await s.articles.forDate(_date);
    final ids = list.map((a) => a.placeId).whereType<int>().toSet().toList();
    final details = await s.places.detailsForIds(ids);
    // Re-attempts from the last day with articles that are not yet carried.
    var carry = 0;
    final hist = await s.articles.history();
    final prev = hist.keys.where((d) => d.compareTo(_date) < 0).firstOrNull;
    if (prev != null) {
      final prevList = await s.articles.forDate(prev);
      carry = prevList
          .where(
            (a) =>
                a.status == ArticleStatus.notDelivered &&
                {'doorLocked', 'addresseeAbsent', 'other'}.contains(a.reason) &&
                !list.any((x) => x.carriedFrom == prev && x.articleNo == a.articleNo && x.rawAddress == a.rawAddress),
          )
          .length;
    }
    if (!mounted) return;
    setState(() {
      _articles = list;
      _places = {for (final d in details) d.place.id!: d};
      _carryable = carry;
    });
  }

  Future<void> _carry() async {
    final s = context.services;
    final hist = await s.articles.history();
    final prev = hist.keys.where((d) => d.compareTo(_date) < 0).firstOrNull;
    if (prev == null) return;
    final n = await s.articles.carryForward(prev, _date);
    if (!mounted) return;
    context.toast(context.l.carriedCount(n));
    context.app.touch();
  }

  Future<void> _open(Widget page) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  Future<void> _scanBarcodes() async {
    final codes = await Navigator.push<List<String>>(
      context,
      MaterialPageRoute(builder: (_) => const BarcodeScanScreen()),
    );
    if (codes == null || codes.isEmpty || !mounted) return;
    final s = context.services;
    var added = 0;
    for (final c in codes) {
      if (await s.articles.existsOn(_date, c)) continue;
      await s.articles.save(Article(date: _date, articleNo: c, type: guessArticleType(c) ?? ArticleType.registered));
      added++;
    }
    if (!mounted) return;
    context.toast(context.l.addedCount(added));
    context.app.touch();
  }

  Future<void> _scanAddress() async {
    final text = await scanAddressText(context);
    if (text == null || !mounted) return;
    await _open(ArticleEditorScreen(date: _date, ocrText: text));
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final v = context.watch<AppState>().version;
    if (v != _version) {
      _version = v;
      _load();
    }
    final unmatched = _articles.where((a) => a.placeId == null || !_places.containsKey(a.placeId)).toList();
    final byPlace = <int, List<Article>>{};
    for (final a in _articles) {
      if (a.placeId != null && _places.containsKey(a.placeId)) byPlace.putIfAbsent(a.placeId!, () => []).add(a);
    }
    final pending = _articles.where((a) => a.status == ArticleStatus.pending).length;

    return Scaffold(
      appBar: AppBar(title: Text(l.todaysArticles)),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 120),
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: _AddButton(icon: Icons.qr_code_scanner, label: l.scanBarcode, onTap: _scanBarcodes),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _AddButton(icon: Icons.document_scanner, label: l.scanAddress, onTap: _scanAddress),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _AddButton(
                    icon: Icons.keyboard,
                    label: l.typeIn,
                    onTap: () => _open(ArticleEditorScreen(date: _date)),
                  ),
                ),
              ],
            ),
          ),
          if (_carryable > 0)
            Card(
              color: Theme.of(context).colorScheme.tertiaryContainer,
              child: ListTile(
                leading: const Icon(Icons.replay, size: 32),
                title: Text(l.carryPrompt(_carryable)),
                trailing: FilledButton(onPressed: _carry, child: Text(l.add)),
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              l.todayCounts(_articles.length, pending, unmatched.length),
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          if (_articles.isEmpty) EmptyState(icon: Icons.inbox_outlined, text: l.noArticlesToday),
          if (unmatched.isNotEmpty) ...[
            _Header(l.unmatched, Icons.help_outline, Theme.of(context).colorScheme.error),
            for (final a in unmatched)
              _ArticleTile(
                article: a,
                onTap: () => _open(ArticleEditorScreen(date: _date, article: a)),
              ),
          ],
          if (byPlace.isNotEmpty) _Header(l.matched, Icons.check_circle_outline, Colors.green.shade700),
          for (final e in byPlace.entries)
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: PhotoThumb(_places[e.key]!.photos.firstOrNull?.filePath, size: 52),
                    title: Text(
                      _places[e.key]!.title,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(_places[e.key]!.addressees.map((x) => x.name).join(', ')),
                    trailing: CircleAvatar(child: Text('${e.value.length}')),
                  ),
                  for (final a in e.value)
                    _ArticleTile(
                      article: a,
                      dense: true,
                      onTap: () => _open(ArticleEditorScreen(date: _date, article: a)),
                    ),
                ],
              ),
            ),
        ],
      ),
      floatingActionButton: _articles.isEmpty
          ? null
          : FloatingActionButton.extended(
              heroTag: 'route',
              onPressed: () => _open(const RouteScreen()),
              icon: const Icon(Icons.alt_route),
              label: Text(l.planRoute),
            ),
    );
  }
}

class _AddButton extends StatelessWidget {
  const _AddButton({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 96,
    child: FilledButton.tonal(
      style: FilledButton.styleFrom(padding: const EdgeInsets.all(6)),
      onPressed: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 34),
          const SizedBox(height: 4),
          Text(label, textAlign: TextAlign.center, maxLines: 2, style: const TextStyle(fontSize: 15)),
        ],
      ),
    ),
  );
}

class _Header extends StatelessWidget {
  const _Header(this.text, this.icon, this.color);
  final String text;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
    child: Row(
      children: [
        Icon(icon, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text, style: Theme.of(context).textTheme.titleLarge?.copyWith(color: color)),
        ),
      ],
    ),
  );
}

class _ArticleTile extends StatelessWidget {
  const _ArticleTile({required this.article, required this.onTap, this.dense = false});
  final Article article;
  final VoidCallback onTap;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final a = article;
    final statusColor = switch (a.status) {
      ArticleStatus.delivered => Colors.green.shade700,
      ArticleStatus.notDelivered => Theme.of(context).colorScheme.error,
      ArticleStatus.pending => Theme.of(context).colorScheme.outline,
    };
    return ListTile(
      dense: dense,
      onTap: onTap,
      leading: Icon(articleTypeIcon(a.type), size: 30),
      title: Text(
        a.articleNo.isNotEmpty ? a.articleNo : articleTypeLabel(l, a.type),
        style: const TextStyle(fontSize: 17, fontFamily: 'monospace', fontWeight: FontWeight.w600),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (a.rawAddress.isNotEmpty && a.placeId == null)
            Text(a.rawAddress.replaceAll('\n', ', '), maxLines: 2, overflow: TextOverflow.ellipsis),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              TagChip(statusLabel(l, a.status), color: statusColor),
              if (a.type.needsSignature) TagChip(l.needsSignature, icon: Icons.draw),
              if (a.carriedFrom != null) TagChip(l.reattempt, color: Theme.of(context).colorScheme.tertiary),
              if (a.reason != null) Text(reasonLabel(l, a.reason)),
            ],
          ),
        ],
      ),
      trailing: const Icon(Icons.chevron_right),
    );
  }
}
