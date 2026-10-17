import 'package:flutter/material.dart';

import '../../core/geo.dart';
import '../../core/route_planner.dart';
import '../../data/models.dart';
import '../common/widgets.dart';
import 'run_screen.dart';

/// Orders today's matched places (nearest neighbour + 2-opt, or the beat's
/// street walking order). The user can drag to reorder; the manual order
/// inside each street is remembered for next time.
class RouteScreen extends StatefulWidget {
  const RouteScreen({super.key});

  @override
  State<RouteScreen> createState() => _RouteScreenState();
}

class _RouteScreenState extends State<RouteScreen> {
  final String _date = dayKey(DateTime.now());
  final Map<int, PlaceDetails> _places = {};
  final Map<int, int> _counts = {};
  final Map<int, int> _streetOrder = {};
  List<int> _order = [];
  int _unmatched = 0;
  GeoPoint? _start;
  bool _loading = true;
  late RouteMode _mode;

  @override
  void initState() {
    super.initState();
    _mode = context.services.settings.routeMode == 'street' ? RouteMode.streetOrder : RouteMode.shortest;
    _load();
  }

  Future<void> _load() async {
    final s = context.services;
    final articles = (await s.articles.forDate(_date)).where((a) => a.status == ArticleStatus.pending).toList();
    _counts.clear();
    _unmatched = 0;
    for (final a in articles) {
      if (a.placeId == null) {
        _unmatched++;
      } else {
        _counts[a.placeId!] = (_counts[a.placeId!] ?? 0) + 1;
      }
    }
    final details = await s.places.detailsForIds(_counts.keys.toList());
    _places
      ..clear()
      ..addAll({for (final d in details) d.place.id!: d});
    _unmatched += _counts.keys.where((id) => !_places.containsKey(id)).fold(0, (n, id) => n + _counts[id]!);
    _counts.removeWhere((id, _) => !_places.containsKey(id));
    final beatIds = _places.values.map((d) => d.place.beatId).toSet();
    _streetOrder.clear();
    for (final b in beatIds) {
      for (final st in await s.beats.streets(b)) {
        _streetOrder[st.id!] = st.orderIndex;
      }
    }
    _start = await _startPoint();
    final saved = s.settings.runOrder(_date);
    if (saved != null && saved.toSet().containsAll(_places.keys)) {
      _order = saved.where(_places.containsKey).toList();
    } else {
      _plan(save: false);
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<GeoPoint?> _startPoint() async {
    final st = context.services.settings;
    if (st.startMode == 'office' && st.officeLat != null && st.officeLng != null) {
      return GeoPoint(st.officeLat!, st.officeLng!);
    }
    return (await context.services.location.current())?.point;
  }

  void _plan({bool save = true}) {
    final stops = [
      for (final d in _places.values)
        RouteStop(
          id: d.place.id!,
          point: d.place.point,
          streetId: d.place.streetId,
          streetOrder: d.place.streetId == null ? null : _streetOrder[d.place.streetId],
          walkOrder: d.place.walkOrder,
          doorNo: d.place.doorNo,
        ),
    ];
    _order = planRoute(stops, start: _start, mode: _mode).ids;
    if (save) context.services.settings.setRunOrder(_date, _order);
    setState(() {});
  }

  double get _total =>
      pathLength(_start, [for (final id in _order) RouteStop(id: id, point: _places[id]?.place.point)]);

  Future<void> _onReorder(int oldI, int newI) async {
    setState(() => _order.insert(newI, _order.removeAt(oldI)));
    final s = context.services;
    await s.settings.setRunOrder(_date, _order);
    // Remember the order of places inside each street for next time.
    final byStreet = <int, List<int>>{};
    for (final id in _order) {
      final sid = _places[id]?.place.streetId;
      if (sid != null) byStreet.putIfAbsent(sid, () => []).add(id);
    }
    for (final ids in byStreet.values) {
      if (ids.length > 1) await s.places.saveWalkOrder(ids);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final t = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: Text(l.routePlan)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _order.isEmpty
          ? EmptyState(icon: Icons.alt_route, text: _unmatched > 0 ? l.allUnmatched(_unmatched) : l.nothingToDeliver)
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                  child: SegmentedButton<RouteMode>(
                    segments: [
                      ButtonSegment(
                        value: RouteMode.shortest,
                        icon: const Icon(Icons.timeline),
                        label: Text(l.modeShortest),
                      ),
                      ButtonSegment(
                        value: RouteMode.streetOrder,
                        icon: const Icon(Icons.signpost),
                        label: Text(l.modeStreet),
                      ),
                    ],
                    selected: {_mode},
                    onSelectionChanged: (v) {
                      _mode = v.first;
                      context.services.settings.routeMode = _mode == RouteMode.streetOrder ? 'street' : 'shortest';
                      _plan();
                    },
                  ),
                ),
                ListTile(
                  title: Text(l.routeSummary(_order.length, formatDistance(_total)), style: t.titleMedium),
                  subtitle: Text(
                    [
                      _start == null
                          ? l.startUnknown
                          : l.startFrom(
                              context.services.settings.startMode == 'office' ? l.startOffice : l.startCurrent,
                            ),
                      if (_unmatched > 0) l.unmatchedNotInRoute(_unmatched),
                    ].join('\n'),
                  ),
                  trailing: IconButton(tooltip: l.replan, icon: const Icon(Icons.refresh), onPressed: _plan),
                ),
                Expanded(
                  child: ReorderableListView.builder(
                    padding: const EdgeInsets.only(bottom: 100),
                    itemCount: _order.length,
                    onReorderItem: _onReorder,
                    itemBuilder: (c, i) {
                      final d = _places[_order[i]]!;
                      final prev = i == 0 ? _start : _places[_order[i - 1]]?.place.point;
                      final p = d.place.point;
                      final leg = (prev != null && p != null) ? formatDistance(haversineMeters(prev, p)) : '—';
                      return Card(
                        key: ValueKey(d.place.id),
                        child: ListTile(
                          leading: CircleAvatar(child: Text('${i + 1}')),
                          title: Text(d.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                          subtitle: Text(
                            [
                              l.articlesCount(_counts[d.place.id] ?? 0),
                              p == null ? l.noGps : '+$leg',
                              if (d.place.landmark.isNotEmpty) d.place.landmark,
                            ].join(' · '),
                          ),
                          trailing: ReorderableDragStartListener(
                            index: i,
                            child: const Padding(padding: EdgeInsets.all(12), child: Icon(Icons.drag_handle, size: 30)),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
      floatingActionButton: _order.isEmpty
          ? null
          : FloatingActionButton.extended(
              heroTag: 'startRun',
              onPressed: () async {
                final s = context.services;
                await s.settings.setRunOrder(_date, _order);
                await s.articles.setDayDistance(_date, _total);
                if (!context.mounted) return;
                await Navigator.push(context, MaterialPageRoute(builder: (_) => RunScreen(order: _order)));
                if (mounted) _load();
              },
              icon: const Icon(Icons.play_arrow, size: 32),
              label: Text(l.startRun),
            ),
    );
  }
}
