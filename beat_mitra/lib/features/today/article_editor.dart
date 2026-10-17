import 'package:flutter/material.dart';

import '../../core/address_parser.dart';
import '../../core/article_matcher.dart';
import '../../core/article_number.dart';
import '../../data/models.dart';
import '../common/widgets.dart';
import '../places/place_edit_screen.dart';
import '../search/search_screen.dart';
import 'scan_screens.dart';

/// Add / edit one article: number (validated), type, address text (typed or
/// OCR), and linking to a place with the top-3 suggestions.
class ArticleEditorScreen extends StatefulWidget {
  const ArticleEditorScreen({super.key, required this.date, this.article, this.ocrText, this.scanOnOpen = false});
  final String date;
  final Article? article;
  final String? ocrText;
  final bool scanOnOpen;

  @override
  State<ArticleEditorScreen> createState() => _ArticleEditorScreenState();
}

class _ArticleEditorScreenState extends State<ArticleEditorScreen> {
  late final _no = TextEditingController(text: widget.article?.articleNo ?? '');
  late final _addr = TextEditingController(text: widget.article?.rawAddress ?? widget.ocrText ?? '');
  late final _note = TextEditingController(text: widget.article?.note ?? '');
  late ArticleType _type = widget.article?.type ?? ArticleType.letter;
  int? _placeId;
  PlaceDetails? _place;
  List<(MatchSuggestion, PlaceDetails)> _suggestions = [];
  bool _matchedOnce = false;

  @override
  void initState() {
    super.initState();
    _placeId = widget.article?.placeId;
    if (widget.ocrText != null) _applyParsed(parseAddress(widget.ocrText!));
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (_placeId != null) await _loadPlace();
      if (_addr.text.trim().isNotEmpty) await _suggest();
      if (widget.scanOnOpen) await _scan();
    });
  }

  @override
  void dispose() {
    _no.dispose();
    _addr.dispose();
    _note.dispose();
    super.dispose();
  }

  void _applyParsed(ParsedAddress p) {
    if (p.articleNo != null && _no.text.trim().isEmpty) {
      _no.text = p.articleNo!;
      _type = guessArticleType(p.articleNo!) ?? _type;
    }
  }

  Future<void> _loadPlace() async {
    final d = _placeId == null ? null : await context.services.places.details(_placeId!);
    if (mounted) setState(() => _place = d);
  }

  Future<void> _suggest() async {
    final raw = _addr.text.trim();
    if (raw.isEmpty) {
      setState(() => _suggestions = []);
      return;
    }
    final parsed = parseAddress(raw);
    final m = context.app.match(parsed, raw);
    final details = await context.services.places.detailsForIds(m.map((x) => x.placeId).toList());
    if (!mounted) return;
    final byId = {for (final d in details) d.place.id!: d};
    setState(() {
      _matchedOnce = true;
      _suggestions = [
        for (final s in m)
          if (byId[s.placeId] != null) (s, byId[s.placeId]!),
      ];
    });
  }

  Future<void> _scan() async {
    final text = await scanAddressText(context);
    if (text == null || !mounted) return;
    if (text.trim().isEmpty) {
      context.toast(context.l.ocrNothing);
      return;
    }
    setState(() {
      _addr.text = text;
      _applyParsed(parseAddress(text));
    });
    await _suggest();
  }

  Future<void> _searchPlace() async {
    final parsed = parseAddress(_addr.text);
    final id = await Navigator.push<int>(
      context,
      MaterialPageRoute(
        builder: (_) => SearchScreen(
          pickMode: true,
          initialQuery: parsed.isEmpty ? '' : parsed.toQuery(),
          title: context.l.pickPlace,
          pickLabel: context.l.select,
        ),
      ),
    );
    if (id == null) return;
    _placeId = id;
    await _loadPlace();
  }

  Future<void> _newPlace() async {
    final beat = context.app.activeBeat;
    if (beat == null) return;
    final p = parseAddress(_addr.text);
    final id = await Navigator.push<int>(
      context,
      MaterialPageRoute(
        builder: (_) => PlaceEditScreen(
          beatId: beat.id!,
          initialAddress: (
            door: p.doorNo ?? '',
            street: p.street ?? '',
            names: p.names,
            pin: p.pin ?? '',
            area: p.area ?? '',
          ),
        ),
      ),
    );
    if (id == null) return;
    _placeId = id;
    await _loadPlace();
  }

  Future<void> _save() async {
    final l = context.l;
    final no = cleanArticleNumber(_no.text);
    final s = context.services;
    if (no.isNotEmpty && widget.article == null && await s.articles.existsOn(widget.date, no)) {
      if (!mounted) return;
      if (!await confirm(context, l.duplicateArticle, l.duplicateArticleBody(no))) return;
    }
    final base = widget.article ?? Article(date: widget.date);
    final a = base.copyWith(
      articleNo: no,
      type: _type,
      rawAddress: _addr.text.trim(),
      note: _note.text.trim(),
      placeId: _placeId,
      clearPlace: _placeId == null,
    );
    await s.articles.save(a);
    if (!mounted) return;
    context.app.touch();
    Navigator.pop(context, true);
  }

  Future<void> _delete() async {
    final l = context.l;
    if (!await confirm(context, l.deleteArticle, l.deleteArticleConfirm, danger: true, ok: l.delete)) return;
    if (!mounted) return;
    await context.services.articles.delete(widget.article!.id!);
    if (!mounted) return;
    context.app.touch();
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final t = Theme.of(context).textTheme;
    final status = validateArticleNumber(_no.text);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.article == null ? l.addArticle : l.editArticle),
        actions: [
          if (widget.article != null)
            IconButton(tooltip: l.delete, icon: const Icon(Icons.delete_outline), onPressed: _delete),
          IconButton(tooltip: l.save, icon: const Icon(Icons.check, size: 30), onPressed: _save),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
        children: [
          TextField(
            controller: _no,
            textCapitalization: TextCapitalization.characters,
            style: const TextStyle(fontSize: 20, fontFamily: 'monospace', fontWeight: FontWeight.w700),
            onChanged: (v) => setState(() {
              final g = guessArticleType(v);
              if (g != null) _type = g;
            }),
            decoration: InputDecoration(
              labelText: l.articleNo,
              hintText: 'EK123456785IN',
              helperText: _no.text.trim().isEmpty
                  ? l.articleNoOptional
                  : switch (status) {
                      ArticleNumberStatus.valid => l.articleValid,
                      ArticleNumberStatus.badCheckDigit => l.articleBadCheck,
                      ArticleNumberStatus.otherFormat => l.articleOtherFormat,
                      ArticleNumberStatus.invalid => l.articleInvalid,
                    },
              helperStyle: TextStyle(
                fontSize: 14,
                color: status == ArticleNumberStatus.valid || _no.text.trim().isEmpty ? null : Colors.orange.shade800,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final ty in ArticleType.values)
                ChoiceChip(
                  avatar: Icon(articleTypeIcon(ty)),
                  label: Text(articleTypeLabel(l, ty)),
                  selected: _type == ty,
                  onSelected: (_) => setState(() => _type = ty),
                ),
            ],
          ),
          if (_type.needsSignature)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: TagChip(l.needsSignature, icon: Icons.draw),
              ),
            ),
          const SizedBox(height: 16),
          TextField(
            controller: _addr,
            maxLines: 6,
            minLines: 3,
            style: const TextStyle(fontSize: 17),
            decoration: InputDecoration(labelText: l.addressText, alignLabelWithHint: true),
            onEditingComplete: _suggest,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _scan,
                  icon: const Icon(Icons.document_scanner),
                  label: Text(l.scanAddress),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _suggest,
                  icon: const Icon(Icons.auto_fix_high),
                  label: Text(l.findMatch),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(l.place, style: t.titleLarge),
          if (_place != null)
            Card(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: ListTile(
                leading: PhotoThumb(_place!.photos.firstOrNull?.filePath, size: 56),
                title: Text(_place!.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                subtitle: Text(_place!.addressees.map((a) => a.name).join(', ')),
                trailing: IconButton(
                  tooltip: l.unlink,
                  icon: const Icon(Icons.link_off),
                  onPressed: () => setState(() {
                    _place = null;
                    _placeId = null;
                  }),
                ),
              ),
            )
          else ...[
            if (_suggestions.isNotEmpty) Text(l.suggestions, style: t.titleMedium),
            for (final (m, d) in _suggestions)
              Card(
                child: ListTile(
                  leading: PhotoThumb(d.photos.firstOrNull?.filePath, size: 56),
                  title: Text(d.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  subtitle: Text('${d.addressees.map((a) => a.name).join(', ')}  ·  ${(m.score * 100).round()}%'),
                  trailing: FilledButton(
                    onPressed: () => setState(() {
                      _place = d;
                      _placeId = d.place.id;
                    }),
                    child: Text(l.thisOne),
                  ),
                ),
              ),
            if (_matchedOnce && _suggestions.isEmpty)
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(l.noMatchFound, style: t.bodyLarge),
              ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _searchPlace,
                    icon: const Icon(Icons.search),
                    label: Text(l.searchPlace),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _newPlace,
                    icon: const Icon(Icons.add_home_outlined),
                    label: Text(l.addNewPlace),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          TextField(
            controller: _note,
            decoration: InputDecoration(labelText: l.note),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(onPressed: _save, icon: const Icon(Icons.save), label: Text(l.save)),
        ],
      ),
    );
  }
}
