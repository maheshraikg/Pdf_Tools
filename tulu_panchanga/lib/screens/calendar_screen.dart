import 'package:flutter/material.dart';

import '../app/scope.dart';
import '../art/festival_art.dart';
import '../panchanga/engine.dart';
import '../panchanga/festivals.dart';
import '../panchanga/names.dart';
import 'day_detail_screen.dart';

/// Month grid in Gregorian or Tulu (solar) months.
class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  bool _tulu = false;

  /// Any date inside the shown month.
  DateTime? _anchor;

  @override
  Widget build(BuildContext context) {
    final s = context.s, repo = context.repo;
    final anchor = _anchor ?? todayAt(repo.engine);
    return Scaffold(
      appBar: AppBar(
        title: LipiText(s.calendar),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: SegmentedButton<bool>(
              segments: [
                ButtonSegment(value: false, label: LipiText(s.gregorian)),
                ButtonSegment(value: true, label: LipiText(s.tuluCalendar)),
              ],
              selected: {_tulu},
              onSelectionChanged: (v) => setState(() => _tulu = v.first),
            ),
          ),
        ),
      ),
      body: _tulu
          ? _TuluMonth(
              anchor: anchor,
              onMove: (d) => setState(() => _anchor = d),
            )
          : _GregorianMonth(
              anchor: anchor,
              onMove: (d) => setState(() => _anchor = d),
            ),
    );
  }
}

class _MonthNav extends StatelessWidget {
  const _MonthNav({
    required this.title,
    this.subtitle,
    required this.onPrev,
    required this.onNext,
  });
  final String title;
  final String? subtitle;
  final VoidCallback onPrev, onNext;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Row(
      children: [
        IconButton(icon: const Icon(Icons.chevron_left), onPressed: onPrev),
        Expanded(
          child: Column(
            children: [
              LipiText(title, style: t.textTheme.titleLarge),
              if (subtitle != null)
                LipiText(
                  subtitle!,
                  style: t.textTheme.bodySmall?.copyWith(
                    color: t.colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
        IconButton(icon: const Icon(Icons.chevron_right), onPressed: onNext),
      ],
    );
  }
}

/// Loads the days and that year's festivals, then builds the grid.
class _MonthData extends StatelessWidget {
  const _MonthData({
    required this.from,
    required this.count,
    required this.builder,
  });
  final DateTime from;
  final int count;
  final Widget Function(
    List<DayPanchanga>,
    Map<DateTime, List<FestivalOccurrence>>,
  )
  builder;

  @override
  Widget build(BuildContext context) {
    final repo = context.repo;
    final last = PanchangaEngine.addDays(from, count - 1);
    final future = Future.wait([
      repo.days(from, count),
      repo.festivals(from.year),
      if (last.year != from.year) repo.festivals(last.year),
    ]);
    return FutureBuilder<List<Object>>(
      future: future,
      builder: (context, snap) {
        if (snap.hasError) return Center(child: Text('${snap.error}'));
        if (!snap.hasData) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 8),
                LipiText(context.s.loading),
              ],
            ),
          );
        }
        final days = snap.data![0] as List<DayPanchanga>;
        final fest = <DateTime, List<FestivalOccurrence>>{};
        for (final list in snap.data!.skip(1)) {
          for (final o in list as List<FestivalOccurrence>) {
            if (o.festival.category == FestivalCategory.vrata &&
                o.festival.id != 'ekadashi') {
              continue;
            }
            (fest[o.date] ??= []).add(o);
          }
        }
        return builder(days, fest);
      },
    );
  }
}

class _GregorianMonth extends StatelessWidget {
  const _GregorianMonth({required this.anchor, required this.onMove});
  final DateTime anchor;
  final ValueChanged<DateTime> onMove;

  @override
  Widget build(BuildContext context) {
    final lang = context.lang;
    final first = DateTime.utc(anchor.year, anchor.month, 1);
    final n = DateTime.utc(
      anchor.year,
      anchor.month + 1,
      1,
    ).difference(first).inDays;
    return Column(
      children: [
        _MonthNav(
          title: '${gregMonthName(lang, anchor.month)} ${anchor.year}',
          onPrev: () => onMove(DateTime.utc(anchor.year, anchor.month - 1, 1)),
          onNext: () => onMove(DateTime.utc(anchor.year, anchor.month + 1, 1)),
        ),
        Expanded(
          child: _MonthData(
            from: first,
            count: n,
            builder: (days, fest) {
              final mid = days[days.length ~/ 2];
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: LipiText(
                      '${lunarMonthLabel(lang, days.first.lunarMonth)} – '
                      '${lunarMonthLabel(lang, days.last.lunarMonth)} · '
                      '${samvatsaraNames[mid.samvatsara].of(lang)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  Expanded(
                    child: _Grid(
                      days: days,
                      fest: fest,
                      leading: first.weekday % 7,
                      big: (d) => '${d.date.day}',
                      small: (d) =>
                          '${tuluMonthNames[d.solar.month].of(lang)} ${d.solar.day}',
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _TuluMonth extends StatelessWidget {
  const _TuluMonth({required this.anchor, required this.onMove});
  final DateTime anchor;
  final ValueChanged<DateTime> onMove;

  @override
  Widget build(BuildContext context) {
    final lang = context.lang, repo = context.repo;
    final solar = repo.day(anchor).solar;
    final start = solar.monthStart;
    return Column(
      children: [
        _MonthNav(
          title:
              '${tuluMonthNames[solar.month].of(lang)} '
              '(${rashiNames[solar.month].of(lang)})',
          subtitle: samvatsaraNames[repo.day(start).sauraSamvatsara].of(lang),
          onPrev: () => onMove(PanchangaEngine.addDays(start, -3)),
          onNext: () => onMove(PanchangaEngine.addDays(start, 33)),
        ),
        Expanded(
          child: _MonthData(
            from: start,
            count: 33,
            builder: (all, fest) {
              final days = all
                  .takeWhile((d) => d.solar.month == solar.month)
                  .toList();
              return _Grid(
                days: days,
                fest: fest,
                leading: start.weekday % 7,
                big: (d) => '${d.solar.day}',
                small: (d) => '${d.date.day}/${d.date.month}',
              );
            },
          ),
        ),
      ],
    );
  }
}

class _Grid extends StatelessWidget {
  const _Grid({
    required this.days,
    required this.fest,
    required this.leading,
    required this.big,
    required this.small,
  });

  final List<DayPanchanga> days;
  final Map<DateTime, List<FestivalOccurrence>> fest;
  final int leading;
  final String Function(DayPanchanga) big;
  final String Function(DayPanchanga) small;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context), lang = context.lang;
    final today = todayAt(context.repo.engine);
    final cells = <Widget>[
      for (var i = 0; i < leading; i++) const SizedBox.shrink(),
      for (final d in days) _cell(context, d, today),
    ];
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          child: Row(
            children: [
              for (var i = 0; i < 7; i++)
                Expanded(
                  child: Center(
                    child: LipiText(
                      varaShort[i].of(lang),
                      style: t.textTheme.labelSmall?.copyWith(
                        color: i == 0 ? t.colorScheme.error : null,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: GridView.count(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
            crossAxisCount: 7,
            childAspectRatio: 0.5,
            children: cells,
          ),
        ),
      ],
    );
  }

  Widget _cell(BuildContext context, DayPanchanga d, DateTime today) {
    final t = Theme.of(context), lang = context.lang;
    final f = fest[d.date] ?? const [];
    final isToday = d.date == today;
    final special = d.tithi == 14
        ? '○'
        : d.tithi == 29
        ? '●'
        : '';
    final major = f.where((o) => o.festival.category != FestivalCategory.vrata);
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => DayDetailScreen(date: d.date)),
      ),
      child: Container(
        margin: const EdgeInsets.all(1.5),
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: isToday
              ? t.colorScheme.primaryContainer
              : major.isNotEmpty
              ? t.colorScheme.tertiaryContainer.withValues(alpha: 0.5)
              : null,
          border: Border.all(color: t.colorScheme.outlineVariant),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Text(
                  big(d),
                  style: t.textTheme.titleMedium?.copyWith(
                    color: d.weekday == 0 ? t.colorScheme.error : null,
                  ),
                ),
                const Spacer(),
                Text(special, style: t.textTheme.labelSmall),
              ],
            ),
            LipiText(
              small(d),
              maxLines: 1,
              overflow: TextOverflow.fade,
              style: t.textTheme.labelSmall?.copyWith(
                color: t.colorScheme.onSurfaceVariant,
              ),
            ),
            LipiText(
              tithiName(d.tithi).of(lang),
              maxLines: 1,
              overflow: TextOverflow.fade,
              style: t.textTheme.labelSmall,
            ),
            const Spacer(),
            if (major.isNotEmpty) ...[
              FestivalArt.of(
                major.first.festival,
                size: 24,
                animate: false,
                circle: true,
              ),
              const SizedBox(height: 1),
              LipiText(
                major.first.festival.name.of(lang),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: t.textTheme.labelSmall?.copyWith(
                  fontSize: 9,
                  color: t.colorScheme.onTertiaryContainer,
                ),
              ),
            ] else if (f.isNotEmpty)
              Icon(Icons.brightness_3, size: 10, color: t.colorScheme.primary),
          ],
        ),
      ),
    );
  }
}
