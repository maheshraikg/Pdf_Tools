import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/article_number.dart';
import '../../core/geo.dart';
import '../../data/models.dart';
import '../common/live_location.dart';
import '../common/widgets.dart';
import '../search/navigate_screen.dart';
import '../summary/summary_screen.dart';

/// The delivery run: one big "Next stop" card with Delivered / Not delivered
/// / Skip / Navigate. Every action stores the time and GPS (on device only).
class RunScreen extends StatefulWidget {
  const RunScreen({super.key, required this.order, this.date});
  final List<int> order;
  final String? date;

  @override
  State<RunScreen> createState() => _RunScreenState();
}

class _RunScreenState extends State<RunScreen> with LiveLocation {
  late final String _date = widget.date ?? dayKey(DateTime.now());
  late final List<int> _queue = List.of(widget.order);
  final Map<int, PlaceDetails> _places = {};
  Map<int, List<Article>> _byPlace = {};
  Set<int> _selected = {};
  int? _current;
  bool _loading = true;
  int _doneStops = 0;

  @override
  void initState() {
    super.initState();
    startLocation();
    _load();
  }

  Future<void> _load() async {
    final s = context.services;
    final articles = await s.articles.forDate(_date);
    final by = <int, List<Article>>{};
    for (final a in articles) {
      if (a.placeId != null) by.putIfAbsent(a.placeId!, () => []).add(a);
    }
    if (_places.isEmpty) {
      for (final d in await s.places.detailsForIds(_queue)) {
        _places[d.place.id!] = d;
      }
    }
    _byPlace = by;
    _doneStops = _queue.where((id) => !_hasPending(id)).length;
    final next = _queue.where((id) => _places.containsKey(id) && _hasPending(id)).firstOrNull;
    final changed = next != _current;
    if (!mounted) return;
    setState(() {
      _current = next;
      _loading = false;
      _selected = {for (final a in _pending(next)) a.id!};
    });
    if (changed && next != null) _announce(next);
  }

  bool _hasPending(int placeId) => (_byPlace[placeId] ?? const []).any((a) => a.status == ArticleStatus.pending);
  List<Article> _pending(int? placeId) => placeId == null
      ? const []
      : (_byPlace[placeId] ?? const []).where((a) => a.status == ArticleStatus.pending).toList();

  void _announce(int placeId) {
    final s = context.services;
    if (!s.settings.tts) return;
    final d = _places[placeId];
    if (d == null) return;
    final text = context.l.ttsNext([d.place.doorNo, d.streetName].where((x) => x.isNotEmpty).join(', '));
    s.voice.speak(text, context.lang);
  }

  Future<GeoPoint?> _gps() async {
    final f = fix;
    if (f != null && DateTime.now().difference(f.time).inSeconds < 60) return f.point;
    return (await context.services.location.current())?.point;
  }

  Future<void> _mark(ArticleStatus status, {String? reason, String note = ''}) async {
    final id = _current;
    if (id == null) return;
    final s = context.services;
    final app = context.app;
    final p = await _gps();
    final now = DateTime.now().millisecondsSinceEpoch;
    for (final a in _pending(id).where((a) => _selected.contains(a.id))) {
      await s.articles.save(
        a.copyWith(
          status: status,
          reason: reason,
          clearReason: reason == null,
          attempts: a.attempts + 1,
          deliveredAt: now,
          lat: p?.lat,
          lng: p?.lng,
          note: note.isEmpty ? a.note : (a.note.isEmpty ? note : '${a.note}; $note'),
        ),
      );
    }
    status == ArticleStatus.delivered ? HapticFeedback.mediumImpact() : HapticFeedback.heavyImpact();
    app.touch();
    await _load();
  }

  Future<void> _notDelivered() async {
    final l = context.l;
    final noteC = TextEditingController();
    final reason = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (c) => Padding(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + MediaQuery.of(c).viewInsets.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l.whyNotDelivered, style: Theme.of(c).textTheme.titleLarge),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final r in NotDeliveredReason.values)
                  ActionChip(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    label: Text(reasonLabel(l, r.name), style: const TextStyle(fontSize: 17)),
                    onPressed: () => Navigator.pop(c, r.name),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteC,
              decoration: InputDecoration(labelText: l.noteOptional),
            ),
          ],
        ),
      ),
    );
    if (reason == null) return;
    await _mark(ArticleStatus.notDelivered, reason: reason, note: noteC.text.trim());
  }

  void _skip() {
    final id = _current;
    if (id == null) return;
    HapticFeedback.selectionClick();
    setState(() {
      _queue.remove(id);
      _queue.add(id);
    });
    context.services.settings.setRunOrder(_date, _queue);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final total = _queue.where(_places.containsKey).length;
    return Scaffold(
      appBar: AppBar(
        title: Text(l.run),
        bottom: _loading || total == 0
            ? null
            : PreferredSize(
                preferredSize: const Size.fromHeight(28),
                child: Padding(
                  padding: const EdgeInsets.only(left: 16, bottom: 6, right: 16),
                  child: Row(
                    children: [
                      Text(
                        l.stopsDone(_doneStops, total),
                        style: TextStyle(color: Theme.of(context).colorScheme.onPrimary, fontSize: 16),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: LinearProgressIndicator(
                          value: total == 0 ? 0 : _doneStops / total,
                          minHeight: 8,
                          backgroundColor: Colors.white24,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _current == null
          ? _finished()
          : _stopCard(_places[_current]!),
    );
  }

  Widget _finished() {
    final l = context.l;
    return EmptyState(
      icon: Icons.celebration,
      text: l.runFinished,
      action: FilledButton.icon(
        icon: const Icon(Icons.summarize),
        label: Text(l.daySummary),
        onPressed: () =>
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => SummaryScreen(date: _date))),
      ),
    );
  }

  Widget _stopCard(PlaceDetails d) {
    final l = context.l;
    final t = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final p = d.place;
    final pending = _pending(p.id);
    final dist = (here != null && p.point != null) ? haversineMeters(here!, p.point!) : null;
    final sig = pending.any((a) => a.type.needsSignature);
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Text(
          l.nextStop,
          style: t.titleMedium?.copyWith(color: scheme.primary, fontWeight: FontWeight.w800),
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (d.photos.isNotEmpty)
                  Center(child: PhotoThumb(d.photos.first.filePath, size: 220, fit: BoxFit.cover)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        p.doorNo.isEmpty ? p.building : p.doorNo,
                        style: t.displaySmall?.copyWith(fontWeight: FontWeight.w900),
                      ),
                    ),
                    if (dist != null) Text(formatDistance(dist), style: t.headlineSmall),
                  ],
                ),
                if (d.streetName.isNotEmpty) Text(d.streetName, style: t.headlineSmall),
                if (p.landmark.isNotEmpty) Text('⚑ ${p.landmark}', style: t.titleLarge),
                if (d.addressees.isNotEmpty) Text(d.addressees.map((a) => a.name).join(', '), style: t.titleMedium),
                if (p.notes.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: scheme.errorContainer, borderRadius: BorderRadius.circular(8)),
                    child: Text('⚠ ${p.notes}', style: t.titleMedium?.copyWith(color: scheme.onErrorContainer)),
                  ),
                if (p.deliveryPref.isNotEmpty) Text('🤝 ${p.deliveryPref}', style: t.titleMedium),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(l.articlesCount(pending.length), style: t.titleLarge),
                    if (sig) TagChip(l.needsSignature, icon: Icons.draw),
                  ],
                ),
                if (pending.length > 1)
                  for (final a in pending)
                    CheckboxListTile(
                      dense: true,
                      value: _selected.contains(a.id),
                      onChanged: (v) => setState(() => v == true ? _selected.add(a.id!) : _selected.remove(a.id)),
                      secondary: Icon(articleTypeIcon(a.type)),
                      title: Text(a.articleNo.isEmpty ? articleTypeLabel(l, a.type) : a.articleNo),
                    ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 72,
          child: FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: Colors.green.shade700, foregroundColor: Colors.white),
            onPressed: _selected.isEmpty ? null : () => _mark(ArticleStatus.delivered),
            icon: const Icon(Icons.check_circle, size: 34),
            label: Text(l.delivered, style: const TextStyle(fontSize: 22)),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 64,
          child: FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: scheme.error, foregroundColor: scheme.onError),
            onPressed: _selected.isEmpty ? null : _notDelivered,
            icon: const Icon(Icons.cancel, size: 30),
            label: Text(l.notDelivered, style: const TextStyle(fontSize: 20)),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(onPressed: _skip, icon: const Icon(Icons.skip_next), label: Text(l.skip)),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: p.point == null
                    ? null
                    : () => Navigator.push(context, MaterialPageRoute(builder: (_) => NavigateScreen(placeId: p.id!))),
                icon: const Icon(Icons.explore),
                label: Text(l.navigate),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
