import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../app_state.dart';
import '../../core/article_number.dart';
import '../../core/geo.dart';
import '../../core/l10n/app_localizations.dart';
import '../../data/models.dart';
import '../../data/repos/article_repo.dart';
import '../common/widgets.dart';

/// Pure summary of one day (unit-testable).
class DaySummary {
  DaySummary(this.date, this.articles, {this.plannedMeters = 0, this.placeTitles = const {}});
  final String date;
  final List<Article> articles;
  final double plannedMeters;
  final Map<int, String> placeTitles;

  int count(ArticleStatus s, [ArticleType? t]) =>
      articles.where((a) => a.status == s && (t == null || a.type == t)).length;

  List<ArticleType> get types => ArticleType.values.where((t) => articles.any((a) => a.type == t)).toList();
  List<Article> get notDelivered => articles.where((a) => a.status == ArticleStatus.notDelivered).toList();
  List<Article> get reattempts => notDelivered.where((a) => reattemptReasons.contains(a.reason)).toList();
  List<Article> get pending => articles.where((a) => a.status == ArticleStatus.pending).toList();

  /// Straight-line distance between the recorded GPS points of the actions.
  double get recordedMeters {
    final pts = articles.where((a) => a.lat != null && a.deliveredAt != null).toList()
      ..sort((a, b) => a.deliveredAt!.compareTo(b.deliveredAt!));
    var total = 0.0;
    for (var i = 1; i < pts.length; i++) {
      total += haversineMeters(GeoPoint(pts[i - 1].lat!, pts[i - 1].lng!), GeoPoint(pts[i].lat!, pts[i].lng!));
    }
    return total;
  }

  String label(Article a) {
    final where = a.placeId != null ? placeTitles[a.placeId] : null;
    return [if (a.articleNo.isNotEmpty) a.articleNo, ?where].join(' – ');
  }

  /// Plain text for the postman's own reporting. Addressee names are not
  /// included.
  String toText(AppLocalizations l) {
    final b = StringBuffer()
      ..writeln('${l.appName} – ${l.daySummary} $date')
      ..writeln(
        l.summaryTotals(
          articles.length,
          count(ArticleStatus.delivered),
          count(ArticleStatus.notDelivered),
          count(ArticleStatus.pending),
        ),
      );
    for (final t in types) {
      b.writeln(
        l.summaryTypeLine(
          articleTypeLabel(l, t),
          count(ArticleStatus.delivered, t),
          articles.where((a) => a.type == t).length,
        ),
      );
    }
    if (notDelivered.isNotEmpty) {
      b.writeln('\n${l.notDeliveredList}:');
      for (final a in notDelivered) {
        b.writeln('• ${label(a)} – ${reasonLabel(l, a.reason)}${a.note.isNotEmpty ? ' (${a.note})' : ''}');
      }
    }
    if (plannedMeters > 0 || recordedMeters > 0) {
      b.writeln('\n${l.distanceLine(formatDistance(plannedMeters), formatDistance(recordedMeters))}');
    }
    return b.toString().trim();
  }
}

/// Day summary + calendar history.
class SummaryScreen extends StatefulWidget {
  const SummaryScreen({super.key, this.date});
  final String? date;

  @override
  State<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen> {
  late String _date = widget.date ?? dayKey(DateTime.now());
  DaySummary? _sum;
  Map<String, int> _history = {};
  int _version = -1;

  Future<void> _load() async {
    final s = context.services;
    final list = await s.articles.forDate(_date);
    final places = await s.places.detailsForIds(list.map((a) => a.placeId).whereType<int>().toSet().toList());
    final planned = await s.articles.dayDistance(_date);
    final hist = await s.articles.history();
    if (!mounted) return;
    setState(() {
      _history = hist;
      _sum = DaySummary(
        _date,
        list,
        plannedMeters: planned,
        placeTitles: {for (final d in places) d.place.id!: d.title},
      );
    });
  }

  Future<void> _pickDate() async {
    final days = _history.keys.map(DateTime.parse).toList();
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.parse(_date),
      firstDate: days.isEmpty ? now : days.reduce((a, b) => a.isBefore(b) ? a : b),
      lastDate: now.add(const Duration(days: 1)),
      selectableDayPredicate: (d) => _history.containsKey(dayKey(d)) || dayKey(d) == dayKey(now),
    );
    if (picked != null) {
      _date = dayKey(picked);
      _load();
    }
  }

  Future<void> _carry() async {
    final next = dayKey(DateTime.parse(_date).add(const Duration(days: 1)));
    final n = await context.services.articles.carryForward(_date, next);
    if (!mounted) return;
    context.toast(context.l.carriedCount(n));
    context.app.touch();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final v = context.watch<AppState>().version;
    if (v != _version) {
      _version = v;
      _load();
    }
    final sum = _sum;
    final t = Theme.of(context).textTheme;
    final dateLabel = DateFormat.yMMMEd(context.lang).format(DateTime.parse(_date));
    return Scaffold(
      appBar: AppBar(
        title: Text(l.daySummary),
        actions: [
          IconButton(tooltip: l.history, icon: const Icon(Icons.calendar_month), onPressed: _pickDate),
          if (sum != null && sum.articles.isNotEmpty)
            IconButton(
              tooltip: l.share,
              icon: const Icon(Icons.share),
              onPressed: () => SharePlus.instance.share(ShareParams(text: sum.toText(l))),
            ),
        ],
      ),
      body: sum == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 40),
              children: [
                OutlinedButton.icon(onPressed: _pickDate, icon: const Icon(Icons.event), label: Text(dateLabel)),
                const SizedBox(height: 8),
                if (sum.articles.isEmpty)
                  EmptyState(icon: Icons.inbox_outlined, text: l.noArticlesThatDay)
                else ...[
                  Row(
                    children: [
                      _Stat(l.statusDelivered, sum.count(ArticleStatus.delivered), Colors.green.shade700),
                      _Stat(
                        l.statusNotDelivered,
                        sum.count(ArticleStatus.notDelivered),
                        Theme.of(context).colorScheme.error,
                      ),
                      _Stat(l.statusPending, sum.count(ArticleStatus.pending), Theme.of(context).colorScheme.outline),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Table(
                        columnWidths: const {0: FlexColumnWidth(3)},
                        children: [
                          TableRow(
                            children: [
                              Text(l.type, style: t.titleSmall),
                              const Icon(Icons.check, color: Colors.green),
                              const Icon(Icons.close, color: Colors.red),
                              const Icon(Icons.hourglass_empty),
                            ],
                          ),
                          for (final ty in sum.types)
                            TableRow(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 6),
                                  child: Row(
                                    children: [
                                      Icon(articleTypeIcon(ty), size: 20),
                                      const SizedBox(width: 6),
                                      Flexible(child: Text(articleTypeLabel(l, ty), style: t.bodyLarge)),
                                    ],
                                  ),
                                ),
                                Text('${sum.count(ArticleStatus.delivered, ty)}', style: t.titleMedium),
                                Text('${sum.count(ArticleStatus.notDelivered, ty)}', style: t.titleMedium),
                                Text('${sum.count(ArticleStatus.pending, ty)}', style: t.titleMedium),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.directions_walk),
                    title: Text(l.distanceLine(formatDistance(sum.plannedMeters), formatDistance(sum.recordedMeters))),
                  ),
                  if (sum.notDelivered.isNotEmpty) ...[
                    Text(l.notDeliveredList, style: t.titleLarge),
                    for (final a in sum.notDelivered)
                      ListTile(
                        leading: Icon(articleTypeIcon(a.type)),
                        title: Text(sum.label(a).isEmpty ? articleTypeLabel(l, a.type) : sum.label(a)),
                        subtitle: Text([reasonLabel(l, a.reason), if (a.note.isNotEmpty) a.note].join(' · ')),
                      ),
                  ],
                  if (sum.reattempts.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: FilledButton.icon(
                        onPressed: _carry,
                        icon: const Icon(Icons.replay),
                        label: Text(l.carryToTomorrow(sum.reattempts.length)),
                      ),
                    ),
                ],
              ],
            ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.label, this.value, this.color);
  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: Column(
          children: [
            Text(
              '$value',
              style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: color),
            ),
            Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 15)),
          ],
        ),
      ),
    ),
  );
}
