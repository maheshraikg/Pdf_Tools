import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:share_plus/share_plus.dart';

import '../app/scope.dart';
import '../app/settings.dart';
import '../core/day.dart';
import '../core/prayer_calc.dart';
import '../app/strings.dart';
import '../ui/theme.dart';
import '../ui/widgets.dart';

/// A day's prayer times as a poster image to send to others (WhatsApp …):
/// pick the day, then share the picture with the times also as text.
class ShareScreen extends StatefulWidget {
  const ShareScreen({super.key, required this.date});

  /// The first day shown (the Today screen's day).
  final DateTime date;

  @override
  State<ShareScreen> createState() => _ShareScreenState();
}

class _ShareScreenState extends State<ShareScreen> {
  final _poster = GlobalKey();
  late DateTime _date = widget.date;
  bool _busy = false;

  /// Poster language; the app's language until another is picked.
  Lang? _lang;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Decoded before the first capture, so the icon is in the picture.
    precacheImage(const AssetImage(_icon), context);
  }

  Future<void> _share(PrayerDay day, Lang lang) async {
    final settings = context.settings;
    setState(() => _busy = true);
    try {
      final boundary =
          _poster.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3);
      final png = await image.toByteData(format: ui.ImageByteFormat.png);
      final name =
          'azan_times_${day.year}-${day.month.toString().padLeft(2, '0')}-'
          '${day.day.toString().padLeft(2, '0')}.png';
      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile.fromData(
              png!.buffer.asUint8List(),
              mimeType: 'image/png',
              name: name,
            ),
          ],
          fileNameOverrides: [name],
          text: posterText(settings, lang, day),
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.settings, s = context.s;
    final day = settings.calculator.day(_date.year, _date.month, _date.day);
    final today = settings.today;
    final offset = _date.difference(today).inDays;
    final lang = _lang ?? settings.lang;
    return Scaffold(
      appBar: AppBar(title: Text(s.shareTimes)),
      // Everything on one screen: the poster shrinks to the space left.
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        child: Column(
          children: [
            Row(
              children: [
                IconButton.filledTonal(
                  tooltip: s.previousDay,
                  onPressed: () => setState(
                    () => _date = _date.subtract(const Duration(days: 1)),
                  ),
                  icon: const Icon(Icons.chevron_left),
                ),
                Expanded(
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    children: [
                      ChoiceChip(
                        label: Text(s.today),
                        selected: offset == 0,
                        onSelected: (_) => setState(() => _date = today),
                      ),
                      ChoiceChip(
                        label: Text(s.tomorrow),
                        selected: offset == 1,
                        onSelected: (_) => setState(
                          () => _date = today.add(const Duration(days: 1)),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton.filledTonal(
                  tooltip: s.nextDay,
                  onPressed: () => setState(
                    () => _date = _date.add(const Duration(days: 1)),
                  ),
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 48,
              child: ListView(
                key: const Key('poster-languages'),
                scrollDirection: Axis.horizontal,
                children: [
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: 8),
                    child: Row(
                      children: [
                        const Icon(Icons.translate, size: 18),
                        const SizedBox(width: 4),
                        Text(s.language),
                      ],
                    ),
                  ),
                  for (final l in Lang.values)
                    Padding(
                      padding: const EdgeInsetsDirectional.only(end: 6),
                      child: ChoiceChip(
                        key: ValueKey('poster-${l.name}'),
                        label: Text(l.nativeName),
                        selected: lang == l,
                        onSelected: (_) => setState(() => _lang = l),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: FittedBox(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: RepaintBoundary(
                      key: _poster,
                      child: KeyedSubtree(
                        key: ValueKey((_date, lang)),
                        child: SizedBox(
                          width: 360,
                          child: PrayerPoster(day: day, lang: lang),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 4, 16, 12),
        child: FilledButton.icon(
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(54)),
          icon: _busy
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.share),
          label: Text(s.shareTimes),
          onPressed: _busy ? null : () => _share(day, lang),
        ),
      ),
    );
  }
}

const _icon = 'assets/app_icon.png';

const _rows = [
  Prayer.fajr,
  Prayer.sunrise,
  Prayer.dhuhr,
  Prayer.asr,
  Prayer.maghrib,
  Prayer.isha,
];

/// Arabic names as on the mosque calendars.
String _arabic(Prayer p, bool friday) => switch (p) {
  Prayer.fajr => 'صبح',
  Prayer.sunrise => 'طلوع',
  Prayer.dhuhr => friday ? 'جمعة' : 'ظهر',
  Prayer.asr => 'عصر',
  Prayer.maghrib => 'مغرب',
  Prayer.isha => 'عشاء',
  _ => '',
};

/// "5:05" / "17:05" (the poster has no room for AM/PM).
String _short(AppSettings settings, DateTime utc) {
  final w = settings.wall(utc);
  final m = w.minute.toString().padLeft(2, '0');
  if (settings.use24h) return '${w.hour.toString().padLeft(2, '0')}:$m';
  return '${w.hour % 12 == 0 ? 12 : w.hour % 12}:$m';
}

/// The times as plain text, sent with the picture.
String posterText(AppSettings settings, Lang lang, PrayerDay day) {
  final s = S(lang);
  String time(DateTime utc) => settings.use24h
      ? _short(settings, utc)
      : '${_short(settings, utc)} ${amPm(lang, settings.wall(utc).hour)}';
  final b = StringBuffer()
    ..writeln('🕌 ${s.azanTimings} · ${settings.place.label(s.ml)}')
    ..writeln(
      '${longDate(lang, day.date)} · '
      '${hijriLabel(lang, day.hijri)}',
    );
  for (final p in _rows) {
    b.writeln('${s.prayer(p, friday: day.isFriday)}: ${time(day[p])}');
  }
  return b.toString().trim();
}

/// The poster: dark green with gold, like the printed Azan timing cards.
class PrayerPoster extends StatelessWidget {
  const PrayerPoster({super.key, required this.day, this.lang});

  final PrayerDay day;

  /// Language of the poster; the app's when null.
  final Lang? lang;

  @override
  Widget build(BuildContext context) {
    final settings = context.settings;
    final lang = this.lang ?? settings.lang, s = S(lang);
    // An Arabic poster already names the prayers in Arabic.
    final arabicColumn = lang != Lang.ar;
    const gold = kGold;
    const deep = Color(0xFF062A2C);
    const teal = Color(0xFF0B4D4A);
    final t = Theme.of(context).textTheme;
    final goldText = t.titleLarge?.copyWith(
      color: gold,
      fontWeight: FontWeight.w800,
      fontFeatures: const [FontFeature.tabularFigures()],
    );

    Widget cell(Widget child, {AlignmentGeometry? align}) => Container(
      alignment: align ?? Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      child: child,
    );

    return Directionality(
      textDirection: lang.rtl ? TextDirection.rtl : TextDirection.ltr,
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [teal, deep],
          ),
          border: Border.all(color: gold, width: 2),
          borderRadius: BorderRadius.circular(18),
        ),
        child: CustomPaint(
          painter: IslamicPatternPainter(color: gold.withValues(alpha: 0.07)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'إِنَّ الصَّلَاةَ كَانَتْ عَلَى الْمُؤْمِنِينَ كِتَابًا مَوْقُوتًا',
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.center,
                  style: t.titleSmall?.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  s.azanTimings.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: t.headlineSmall?.copyWith(
                    color: gold,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    for (final text in [
                      longDate(lang, day.date),
                      hijriLabel(lang, day.hijri),
                    ])
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: gold.withValues(alpha: 0.7),
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          text,
                          style: t.labelLarge?.copyWith(
                            color: gold,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.place, color: gold, size: 16),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        settings.place.label(s.ml),
                        overflow: TextOverflow.ellipsis,
                        style: t.titleSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Table(
                  border: TableBorder.all(
                    color: gold.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                  columnWidths: {
                    0: const FlexColumnWidth(1.1),
                    1: const FlexColumnWidth(1.6),
                    if (arabicColumn) 2: const FlexColumnWidth(1),
                  },
                  children: [
                    for (final p in _rows)
                      TableRow(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(
                            alpha: p == Prayer.sunrise ? 0.18 : 0.08,
                          ),
                        ),
                        children: [
                          cell(Text(_short(settings, day[p]), style: goldText)),
                          cell(
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                s.prayer(p, friday: day.isFriday),
                                style: t.titleSmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                          if (arabicColumn)
                            cell(
                              Text(
                                _arabic(p, day.isFriday),
                                textDirection: TextDirection.rtl,
                                style: t.titleMedium?.copyWith(
                                  color: gold,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: gold, width: 1.5),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(9),
                        child: Image.asset(
                          _icon,
                          width: 34,
                          height: 34,
                          gaplessPlayback: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      s.appTitle,
                      style: t.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
