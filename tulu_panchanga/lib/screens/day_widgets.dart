import 'package:flutter/material.dart';

import '../app/scope.dart';
import '../app/theme.dart';
import '../art/festival_art.dart';
import 'fancy.dart';
import '../panchanga/engine.dart';
import '../panchanga/festivals.dart';
import '../panchanga/names.dart';

/// Colours shared by the timeline and the kaala list.
class KaalaColors {
  static const rahu = Color(0xFFD32F2F);
  static const yama = Color(0xFFEF6C00);
  static const gulika = Color(0xFF6D4C41);
  static const durmuhurta = Color(0xFFAD1457);
  static const abhijit = Color(0xFF2E7D32);
  static const brahma = Color(0xFF1565C0);
}

/// A titled card section.
class Section extends StatelessWidget {
  const Section({
    super.key,
    required this.title,
    required this.children,
    this.icon,
    this.accent,
  });
  final String title;
  final List<Widget> children;
  final IconData? icon;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final accent = this.accent ?? t.colorScheme.primary;
    return Card(
      margin: const EdgeInsets.fromLTRB(12, 6, 12, 6),
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          border: Border(left: BorderSide(color: accent, width: 4)),
        ),
        padding: const EdgeInsets.fromLTRB(14, 12, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (icon != null) ...[
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.14),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, size: 18, color: accent),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: LipiText(
                    title,
                    style: t.textTheme.titleMedium?.copyWith(
                      color: accent,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }
}

/// Label / value row.
class InfoRow extends StatelessWidget {
  const InfoRow(
    this.label,
    this.value, {
    super.key,
    this.sub,
    this.color,
    this.highlight = false,
  });
  final String label;
  final String value;
  final String? sub;
  final Color? color;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Container(
      decoration: highlight
          ? BoxDecoration(
              color: t.colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(6),
            )
          : null,
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (color != null)
            Container(
              width: 10,
              height: 10,
              margin: const EdgeInsets.only(top: 5, right: 8),
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
          SizedBox(
            width: 120,
            child: LipiText(
              label,
              style: t.textTheme.bodyMedium?.copyWith(
                color: t.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LipiText(
                  value,
                  style: t.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (sub != null)
                  LipiText(
                    sub!,
                    style: t.textTheme.bodySmall?.copyWith(
                      color: t.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Day header: weekday, Gregorian date, Tulu date and lunar date.
class DayHeader extends StatelessWidget {
  const DayHeader({super.key, required this.day});
  final DayPanchanga day;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final lang = context.lang;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Column(
        children: [
          LipiText(
            varaNames[day.weekday].of(lang),
            style: t.textTheme.titleMedium,
          ),
          Text(longDate(lang, day.date), style: t.textTheme.headlineSmall),
          const SizedBox(height: 4),
          LipiText(
            '${tuluDate(lang, day)} · ${lunarMonthLabel(lang, day.lunarMonth)} '
            '${tithiLabel(lang, day.tithi)}',
            textAlign: TextAlign.center,
            style: t.textTheme.titleMedium?.copyWith(
              color: t.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}

String _spanEnd(
  BuildContext context,
  PanchangaEngine e,
  DayPanchanga d,
  Span s,
) {
  if (s.end >= d.nextSunrise) return context.s.untilNextSunrise;
  return context.s.untilTime(hmDay(context, e, s.end, d.date));
}

/// Tithi, nakshatra, yoga, karana, rashi with end times.
class ElementsCard extends StatelessWidget {
  const ElementsCard({super.key, required this.day, this.full = false});
  final DayPanchanga day;
  final bool full;

  @override
  Widget build(BuildContext context) {
    final s = context.s, lang = context.lang, e = context.repo.engine;
    final d = day;
    Widget spans(String label, List<Span> list, String Function(int) name) {
      final shown = full ? list : list.take(2).toList();
      return InfoRow(
        label,
        name(shown.first.index),
        sub: [
          _spanEnd(context, e, d, shown.first),
          for (final x in shown.skip(1))
            '→ ${name(x.index)}'
                '${x.end < d.nextSunrise ? ' (${_spanEnd(context, e, d, x)})' : ''}',
        ].join('\n'),
      );
    }

    return Section(
      title: s.panchanga,
      icon: Icons.auto_awesome_rounded,
      children: [
        spans(s.tithi, d.tithis, (i) => tithiLabel(lang, i)),
        spans(s.nakshatra, d.nakshatras, (i) => nakshatraNames[i].of(lang)),
        spans(s.yoga, d.yogas, (i) => yogaNames[i].of(lang)),
        spans(s.karana, d.karanas, (i) => karanaNames[karanaIndex(i)].of(lang)),
        if (full) ...[
          spans(s.rashi, d.moonRashis, (i) => rashiNames[i].of(lang)),
          InfoRow(s.sunSign, rashiNames[d.sunRashi].of(lang)),
          InfoRow(s.paksha, pakshaNames[d.paksha].of(lang)),
          InfoRow('${s.nakshatra} ${s.pada}', '${d.nakshatraPada}'),
        ],
      ],
    );
  }
}

class SunMoonCard extends StatelessWidget {
  const SunMoonCard({super.key, required this.day});
  final DayPanchanga day;

  @override
  Widget build(BuildContext context) {
    final s = context.s, e = context.repo.engine, d = day;
    return Section(
      title: s.sunMoon,
      icon: Icons.wb_twilight_rounded,
      accent: TuluColors.gold,
      children: [
        Row(
          children: [
            _SkyTile(
              Icons.wb_sunny_rounded,
              s.sunrise,
              hm(e, d.sunrise),
              const [Color(0xFFFFE08A), Color(0xFFFFB74D)],
            ),
            const SizedBox(width: 8),
            _SkyTile(
              Icons.wb_twilight_rounded,
              s.sunset,
              hm(e, d.sunset),
              const [Color(0xFFFFAB91), Color(0xFFE57373)],
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _SkyTile(
              Icons.nightlight_round,
              s.moonrise,
              d.moonrise == null
                  ? s.noMoonrise
                  : hmDay(context, e, d.moonrise!, d.date),
              const [Color(0xFFB39DDB), Color(0xFF7986CB)],
            ),
            const SizedBox(width: 8),
            _SkyTile(
              Icons.bedtime_rounded,
              s.moonset,
              d.moonset == null
                  ? s.noMoonset
                  : hmDay(context, e, d.moonset!, d.date),
              const [Color(0xFF90A4AE), Color(0xFF5C6BC0)],
            ),
          ],
        ),
      ],
    );
  }
}

class KaalaCard extends StatelessWidget {
  const KaalaCard({super.key, required this.day, this.full = false});
  final DayPanchanga day;
  final bool full;

  @override
  Widget build(BuildContext context) {
    final s = context.s, e = context.repo.engine, k = day.kaalas;
    final now = jdNow();
    String w(Window x) => '${hm(e, x.start)} – ${hm(e, x.end)}';
    InfoRow row(String label, Window x, Color c) =>
        InfoRow(label, w(x), color: c, highlight: x.contains(now));
    return Section(
      title: '${s.inauspicious} / ${s.auspicious}',
      icon: Icons.schedule_rounded,
      accent: TuluColors.terracotta,
      children: [
        row(s.rahu, k.rahu, KaalaColors.rahu),
        row(s.yamaganda, k.yamaganda, KaalaColors.yama),
        row(s.gulika, k.gulika, KaalaColors.gulika),
        for (final dm in k.durmuhurta)
          row(s.durmuhurta, dm, KaalaColors.durmuhurta),
        if (day.weekday != 3) row(s.abhijit, k.abhijit, KaalaColors.abhijit),
        if (full) row(s.brahma, k.brahma, KaalaColors.brahma),
      ],
    );
  }
}

class YearCard extends StatelessWidget {
  const YearCard({super.key, required this.day});
  final DayPanchanga day;

  @override
  Widget build(BuildContext context) {
    final s = context.s, lang = context.lang, d = day, e = context.repo.engine;
    return Section(
      title: s.yearAndMonth,
      icon: Icons.event_note_rounded,
      accent: TuluColors.areca,
      children: [
        InfoRow(
          s.samvatsara,
          samvatsaraNames[d.samvatsara].of(lang),
          sub: '${s.shaka} ${d.shakaYear} · ${s.kali} ${d.kaliYear}',
        ),
        if (d.sauraSamvatsara != d.samvatsara)
          InfoRow(
            s.sauraSamvatsara,
            samvatsaraNames[d.sauraSamvatsara].of(lang),
          ),
        InfoRow(
          s.lunarMonth,
          lunarMonthLabel(lang, d.lunarMonth),
          sub: pakshaNames[d.paksha].of(lang),
        ),
        InfoRow(
          s.tuluMonth,
          tuluDate(lang, d),
          sub:
              '${rashiNames[d.solar.month].of(lang)} · '
              '${longDate(lang, d.solar.monthStart)}',
        ),
        InfoRow(s.ayana, ayanaNames[d.ayana].of(lang)),
        InfoRow(s.ritu, rituNames[d.ritu].of(lang)),
        if (d.sankrantiToday != null)
          InfoRow(
            s.sankramana,
            '${rashiNames[(d.sunRashi + 1) % 12].of(lang)} ${hmDay(context, e, d.sankrantiToday!, d.date)}',
          ),
      ],
    );
  }
}

class FestivalsCard extends StatelessWidget {
  const FestivalsCard({super.key, required this.date});
  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return FutureBuilder<List<FestivalOccurrence>>(
      future: context.repo.festivalsOn(date),
      builder: (context, snap) {
        final list = snap.data;
        if (list == null || list.isEmpty) return const SizedBox.shrink();
        return Section(
          title: s.festivalsToday,
          icon: Icons.celebration_rounded,
          children: [for (final o in list) FestivalTile(o: o, dense: true)],
        );
      },
    );
  }
}

class FestivalTile extends StatelessWidget {
  const FestivalTile({
    super.key,
    required this.o,
    this.dense = false,
    this.onTap,
  });
  final FestivalOccurrence o;
  final bool dense;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final lang = context.lang, s = context.s;
    final f = o.festival;
    final details = <String>[
      if (o.instant != null) hm(context.repo.engine, o.instant!),
      if (o.detail.isNotEmpty && f.category == FestivalCategory.vrata) o.detail,
      if (f.confidence == Confidence.low) s.confidenceLow,
    ];
    return ListTile(
      dense: dense,
      contentPadding: dense ? EdgeInsets.zero : null,
      leading: FestivalArt.of(
        o.festival,
        size: 44,
        animate: false,
        circle: true,
      ),
      title: LipiText(f.name.of(lang)),
      subtitle: details.isEmpty ? null : Text(details.join(' · ')),
      onTap: onTap ?? () => showFestivalSheet(context, o),
    );
  }
}

class _SkyTile extends StatelessWidget {
  const _SkyTile(this.icon, this.label, this.value, this.colors);
  final IconData icon;
  final String label;
  final String value;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: colors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 26),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LipiText(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: t.labelMedium?.copyWith(color: Colors.white),
                  ),
                  Text(
                    value,
                    maxLines: 2,
                    style: t.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Current instant as a Julian Day.
double jdNow() =>
    DateTime.now().toUtc().millisecondsSinceEpoch / 86400000.0 + 2440587.5;
