/// Bulk sorting: sessions list, live counting, summary.
library;

import 'package:flutter/material.dart';

import '../../core/app_scope.dart';
import '../../core/feedback.dart';
import '../../core/files.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/labels.dart';
import '../../core/pin_utils.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/models/scheme.dart';
import '../../data/user_repo.dart';
import '../lookup/keypad.dart';
import '../scan/scan_screen.dart';
import 'bulk_counter.dart';

class BulkScreen extends StatefulWidget {
  const BulkScreen({super.key});

  @override
  State<BulkScreen> createState() => _BulkScreenState();
}

class _BulkScreenState extends State<BulkScreen> {
  List<BulkSession>? _sessions;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _load();
  }

  Future<void> _load() async {
    final s = await context.services.user.sessions();
    if (mounted) setState(() => _sessions = s);
  }

  Future<void> _start() async {
    final l = AppLocalizations.of(context);
    final services = context.services;
    final settings = context.settings;
    final now = DateTime.now();
    final date = now.toIso8601String().substring(0, 10);
    final name = TextEditingController(text: l.sessionDefaultName('${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}'));
    var category = settings.category;
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => StatefulBuilder(
        builder: (d, set) => AlertDialog(
          title: Text(l.startSession),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(controller: name, decoration: InputDecoration(labelText: l.sessionName)),
              const SizedBox(height: 8),
              Text('${l.date}: $date'),
              Text('${l.scheme}: ${services.active?.scheme.name ?? l.none}'),
              DropdownButtonFormField<String>(
                initialValue: category,
                decoration: InputDecoration(labelText: l.fCategory),
                items: [for (final c in services.categories) DropdownMenuItem(value: c, child: Text(categoryLabel(l, c)))],
                onChanged: (v) => set(() => category = v ?? category),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(d, false), child: Text(l.cancel)),
            FilledButton(onPressed: () => Navigator.pop(d, true), child: Text(l.start)),
          ],
        ),
      ),
    );
    if (ok != true || !mounted) return;
    final id = await services.user.startSession(
      name: name.text.trim().isEmpty ? date : name.text.trim(),
      date: date,
      schemeId: services.active?.scheme.id,
      schemeName: services.active?.scheme.name ?? '',
      category: category,
    );
    if (!mounted) return;
    await Navigator.push(context, MaterialPageRoute(builder: (_) => BulkSessionScreen(sessionId: id)));
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final list = _sessions;
    return Scaffold(
      appBar: AppBar(title: Text(l.bulkTitle)),
      floatingActionButton: FloatingActionButton.extended(onPressed: _start, icon: const Icon(Icons.play_arrow), label: Text(l.startSession)),
      body: list == null
          ? const Center(child: CircularProgressIndicator())
          : list.isEmpty
          ? EmptyState(icon: Icons.inventory_2_outlined, text: l.bulkEmpty)
          : ListView.builder(
              padding: const EdgeInsets.only(bottom: 96),
              itemCount: list.length,
              itemBuilder: (_, i) {
                final s = list[i];
                return Dismissible(
                  key: ValueKey(s.id),
                  direction: DismissDirection.endToStart,
                  background: Container(color: Theme.of(context).colorScheme.error, alignment: Alignment.centerRight, padding: const EdgeInsets.all(16), child: const Icon(Icons.delete, color: Colors.white)),
                  confirmDismiss: (_) => confirm(context, l.confirmDelete(s.name)),
                  onDismissed: (_) async {
                    await context.services.user.deleteSession(s.id);
                    await _load();
                  },
                  child: ListTile(
                    leading: CircleAvatar(child: Text('${s.count}')),
                    title: Text(s.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text('${s.date} · ${categoryLabel(l, s.category)} · ${s.schemeName}${s.ended ? '' : ' · ${l.inProgress}'}'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => s.ended ? BulkSummaryScreen(sessionId: s.id) : BulkSessionScreen(sessionId: s.id)),
                      );
                      await _load();
                    },
                  ),
                );
              },
            ),
    );
  }
}

class BulkSessionScreen extends StatefulWidget {
  const BulkSessionScreen({super.key, required this.sessionId});

  final int sessionId;

  @override
  State<BulkSessionScreen> createState() => _BulkSessionScreenState();
}

class _BulkSessionScreenState extends State<BulkSessionScreen> {
  BulkSession? _session;
  List<BulkEntry> _entries = [];
  String _digits = '';
  BulkEntry? _last;
  int _flash = 0;
  bool _adding = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_session == null) _load();
  }

  Future<void> _load() async {
    final u = context.services.user;
    final s = await u.session(widget.sessionId);
    final e = await u.entries(widget.sessionId);
    if (mounted) {
      setState(() {
        _session = s;
        _entries = e;
      });
    }
  }

  Future<void> _submit(String raw) async {
    if (_adding) return;
    _adding = true;
    final services = context.services;
    final settings = context.settings;
    final l = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    try {
      final entry = await makeBulkEntry(services.engine, raw, _session?.category ?? settings.category);
      await services.user.addEntry(widget.sessionId, entry);
      if (entry.resolved) {
        AppFeedback.success(settings);
        AppFeedback.speak(settings, AppFeedback.spellDigits(entry.airCode != null ? AppFeedback.spell(entry.airCode!) : entry.bagCode!), lang: lang);
      } else {
        AppFeedback.warning(settings);
        AppFeedback.speak(settings, l.unresolved);
      }
      setState(() {
        _digits = '';
        _last = entry;
        _flash++;
      });
      await _load();
    } finally {
      _adding = false;
    }
  }

  void _digit(String d) {
    AppFeedback.tap(context.settings);
    final next = _digits + d;
    if (next.length >= 6) {
      _submit(next);
      setState(() => _digits = next);
    } else {
      setState(() => _digits = next);
    }
  }

  Future<void> _undo() async {
    if (_entries.isEmpty) return;
    await context.services.user.deleteEntry(_entries.last.id!);
    setState(() => _last = null);
    await _load();
  }

  Future<void> _fix(BulkEntry e) async {
    final l = AppLocalizations.of(context);
    final c = TextEditingController(text: e.pin?.toString() ?? PinUtils.digitsOnly(e.raw));
    final v = await showDialog<String>(
      context: context,
      builder: (d) => AlertDialog(
        title: Text(l.fixEntry(e.raw)),
        content: TextField(controller: c, keyboardType: TextInputType.number, maxLength: 6, autofocus: true, decoration: InputDecoration(labelText: l.fPin)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d, '\u0000delete'), child: Text(l.delete)),
          TextButton(onPressed: () => Navigator.pop(d), child: Text(l.cancel)),
          FilledButton(onPressed: () => Navigator.pop(d, c.text), child: Text(l.save)),
        ],
      ),
    );
    if (v == null || !mounted) return;
    final services = context.services;
    if (v == '\u0000delete') {
      await services.user.deleteEntry(e.id!);
    } else {
      final ne = await makeBulkEntry(services.engine, v, _session?.category ?? context.settings.category);
      await services.user.updateEntry(widget.sessionId, e.id!, ne);
    }
    await _load();
  }

  Future<void> _end() async {
    await context.services.user.endSession(widget.sessionId);
    if (!mounted) return;
    await Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => BulkSummaryScreen(sessionId: widget.sessionId)));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final s = _session;
    final scheme = context.services.active;
    final sum = summarize(_entries, bagOrder: scheme?.bagOrder ?? const []);
    final last = _last;
    final lastBag = last?.bagCode == null ? null : scheme?.bags[last!.bagCode!] ?? Bag(code: last!.bagCode!);
    final flashColour = last == null
        ? Theme.of(context).colorScheme.surfaceContainerHighest
        : last.resolved
        ? bagColour(context, lastBag)
        : Theme.of(context).colorScheme.error;
    return Scaffold(
      appBar: AppBar(
        title: Text(s?.name ?? ''),
        actions: [
          IconButton(tooltip: l.undoLast, icon: const Icon(Icons.undo), onPressed: _entries.isEmpty ? null : _undo),
          TextButton(onPressed: _end, child: Text(l.endSession, style: TextStyle(color: Theme.of(context).colorScheme.onPrimary))),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Big flash of the bag colour for each entry.
            TweenAnimationBuilder<double>(
              key: ValueKey(_flash),
              tween: Tween(begin: 1, end: 0),
              duration: const Duration(milliseconds: 700),
              builder: (_, t, child) => Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                color: Color.lerp(flashColour.withValues(alpha: 0.55), flashColour, t),
                child: child,
              ),
              child: Semantics(
                liveRegion: true,
                child: Column(
                  children: [
                    Text(
                      last == null ? (_digits.isEmpty ? l.enterPin : _digits) : (last.resolved ? (last.airCode != null ? '${last.airCode}  ·  ${last.bagCode}' : last.bagCode!) : l.unresolved),
                      style: TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: onColour(flashColour)),
                      textAlign: TextAlign.center,
                    ),
                    if (last != null)
                      Text('${last.raw}${lastBag?.name.isNotEmpty == true ? ' · ${lastBag!.name}' : ''}${last.connectivity != null ? ' · ${last.connectivity}' : ''}',
                          style: TextStyle(color: onColour(flashColour), fontSize: 16)),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  Text(l.totalN(sum.total), style: Theme.of(context).textTheme.titleMedium),
                  const Spacer(),
                  if (s != null) Text(categoryLabel(l, s.category)),
                  IconButton(
                    tooltip: l.scanAddress,
                    icon: const Icon(Icons.document_scanner_outlined),
                    onPressed: () async {
                      await Navigator.push(context, MaterialPageRoute(builder: (_) => ScanScreen(bulkSessionId: widget.sessionId)));
                      await _load();
                    },
                  ),
                ],
              ),
            ),
            FittedBox(fit: BoxFit.scaleDown, child: PinDisplay(digits: _digits)),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final e in sum.byBag.entries)
                        Chip(
                          backgroundColor: bagColour(context, scheme?.bags[e.key]),
                          label: Text('${e.key}: ${e.value}', style: TextStyle(color: onColour(bagColour(context, scheme?.bags[e.key])), fontWeight: FontWeight.w800, fontSize: 16)),
                        ),
                    ],
                  ),
                  if (sum.byAir.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(l.airCodes, style: Theme.of(context).textTheme.labelLarge),
                    Wrap(spacing: 6, children: [for (final e in sum.byAir.entries) Chip(label: Text('${e.key}: ${e.value}', style: const TextStyle(fontWeight: FontWeight.w800)))]),
                  ],
                  if (sum.byConnectivity.isNotEmpty)
                    Wrap(spacing: 6, children: [
                      for (final e in sum.byConnectivity.entries)
                        Chip(
                          backgroundColor: e.key == Connectivity.air.label ? kAirYellow : kSurfaceBlue,
                          label: Text('${e.key == Connectivity.air.label ? l.badgeAir : l.badgeSurface}: ${e.value}',
                              style: TextStyle(color: e.key == Connectivity.air.label ? Colors.black : Colors.white, fontWeight: FontWeight.w800)),
                        ),
                    ]),
                  if (sum.unresolved.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(l.unresolvedEntries(sum.unresolved.length), style: TextStyle(color: Theme.of(context).colorScheme.error, fontWeight: FontWeight.w700)),
                    for (final e in sum.unresolved)
                      ListTile(dense: true, leading: const Icon(Icons.error_outline), title: Text(e.raw), subtitle: Text(e.pin == null ? l.invalidPin : l.noBagRule), onTap: () => _fix(e)),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(6, 0, 6, 6),
              child: NumericKeypad(
                scale: context.settings.keypadScale,
                onDigit: _digit,
                onBackspace: () {
                  if (_digits.isNotEmpty) setState(() => _digits = _digits.substring(0, _digits.length - 1));
                },
                onClear: () => setState(() => _digits = ''),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BulkSummaryScreen extends StatefulWidget {
  const BulkSummaryScreen({super.key, required this.sessionId});

  final int sessionId;

  @override
  State<BulkSummaryScreen> createState() => _BulkSummaryScreenState();
}

class _BulkSummaryScreenState extends State<BulkSummaryScreen> {
  BulkSession? _session;
  List<BulkEntry> _entries = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_session == null) _load();
  }

  Future<void> _load() async {
    final u = context.services.user;
    final s = await u.session(widget.sessionId);
    final e = await u.entries(widget.sessionId);
    if (mounted) {
      setState(() {
        _session = s;
        _entries = e;
      });
    }
  }

  Map<String, String> _labels(AppLocalizations l) => {
    'title': l.bulkTitle,
    'date': l.date,
    'scheme': l.scheme,
    'category': l.fCategory,
    'total': l.total,
    'unresolved': l.unresolved,
    'bags': l.bags,
    'air': l.airCodes,
    'connectivity': l.fConnectivity,
    'hubs': l.hubRoute,
  };

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final s = _session;
    if (s == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final scheme = context.services.active;
    final bags = scheme?.bags ?? const <String, Bag>{};
    final sum = summarize(_entries, bagOrder: scheme?.bagOrder ?? const []);
    final text = summaryText(s, sum, bags: bags, labels: _labels(l));
    Widget table(String title, Map<String, int> m, [String Function(String)? name]) => m.isEmpty
        ? const SizedBox.shrink()
        : Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(padding: const EdgeInsets.fromLTRB(16, 12, 16, 4), child: Text(title, style: Theme.of(context).textTheme.titleMedium)),
                for (final e in m.entries)
                  ListTile(dense: true, title: Text(name?.call(e.key) ?? e.key, style: const TextStyle(fontSize: 17)), trailing: Text('${e.value}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900))),
              ],
            ),
          );
    return Scaffold(
      appBar: AppBar(
        title: Text(l.summary),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.share),
            tooltip: l.share,
            onSelected: (v) async {
              final base = s.name.replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_');
              switch (v) {
                case 'text':
                  await shareText(text, subject: s.name);
                case 'csv':
                  await shareFiles({'$base.csv': summaryCsv(_entries, sum, bags)});
                case 'print':
                  await shareFiles({'$base.txt': text});
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(value: 'text', child: Text(l.shareText)),
              PopupMenuItem(value: 'csv', child: Text(l.shareCsv)),
              PopupMenuItem(value: 'print', child: Text(l.sharePrintable)),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Card(
            child: ListTile(
              title: Text(s.name, style: const TextStyle(fontWeight: FontWeight.w800)),
              subtitle: Text('${s.date} · ${categoryLabel(l, s.category)} · ${s.schemeName}'),
              trailing: Text('${sum.total}', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
            ),
          ),
          table(l.bags, sum.byBag, (k) => bags[k]?.label ?? k),
          table(l.airCodes, sum.byAir),
          table(l.fConnectivity, sum.byConnectivity, (k) => k == Connectivity.air.label ? l.badgeAir : l.badgeSurface),
          table(l.hubRoute, sum.byHub),
          if (sum.unresolved.isNotEmpty) table(l.unresolved, {for (final e in sum.unresolved) e.raw: 1}),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () async {
              await context.services.user.reopenSession(s.id);
              if (!context.mounted) return;
              await Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => BulkSessionScreen(sessionId: s.id)));
            },
            icon: const Icon(Icons.play_arrow),
            label: Text(l.continueSession),
          ),
        ],
      ),
    );
  }
}
