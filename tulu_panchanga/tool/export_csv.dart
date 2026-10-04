// Exports panchanga and festival tables as CSV, for checking against a
// printed panchanga.
//
//   dart run tool/export_csv.dart --year 2026 --place mangaluru --out docs/csv
//
// Writes <out>/panchanga_<place>_<year>.csv (one row per day) and
// <out>/festivals_<place>_<year>.csv (the verification sheet, with blank
// columns for a priest's corrections).
//
// Options: --sunrise upperLimb|discCentre, --month-rule sunset|aparahna|nextDay
import 'dart:io';

import 'package:tulu_panchanga/panchanga/engine.dart';
import 'package:tulu_panchanga/panchanga/festivals.dart';
import 'package:tulu_panchanga/panchanga/names.dart';
import 'package:tulu_panchanga/panchanga/place.dart';

void main(List<String> args) {
  String opt(String name, String def) {
    final i = args.indexOf('--$name');
    return i >= 0 && i + 1 < args.length ? args[i + 1] : def;
  }

  final year = int.parse(opt('year', '${DateTime.now().year}'));
  final place = placeById(opt('place', 'mangaluru'));
  final out = Directory(opt('out', '.'))..createSync(recursive: true);
  final config = PanchangaConfig(
    sunrise: SunriseConvention.values.byName(opt('sunrise', 'upperLimb')),
    solarMonthRule: SolarMonthRule.values.byName(opt('month-rule', 'sunset')),
  );
  final engine = PanchangaEngine(place, config);

  final days = File('${out.path}/panchanga_${place.id}_$year.csv');
  days.writeAsStringSync(panchangaCsv(engine, year));
  final fest = File('${out.path}/festivals_${place.id}_$year.csv');
  fest.writeAsStringSync(festivalCsv(engine, year));
  stdout.writeln('Wrote ${days.path} and ${fest.path}');
}

String _csv(List<Object?> row) => row
    .map((v) {
      final s = v?.toString() ?? '';
      return s.contains(RegExp('[",\n]')) ? '"${s.replaceAll('"', '""')}"' : s;
    })
    .join(',');

String _hm(PanchangaEngine e, double? jd, DateTime day) {
  if (jd == null) return '';
  final w = e.wall(jd);
  final t =
      '${w.hour.toString().padLeft(2, '0')}:${w.minute.toString().padLeft(2, '0')}';
  final diff = PanchangaEngine.dateOnly(w).difference(day).inDays;
  return diff == 0 ? t : '$t (+$diff)';
}

String _date(DateTime d) => d.toIso8601String().substring(0, 10);

String _spans(
  PanchangaEngine e,
  DayPanchanga d,
  List<Span> spans,
  String Function(int) name,
) => spans
    .map(
      (s) => s.end < d.nextSunrise
          ? '${name(s.index)} till ${_hm(e, s.end, d.date)}'
          : '${name(s.index)} (past next sunrise)',
    )
    .join('; ');

String _tithi(int i) => '${i < 15 ? 'S' : 'K'}-${tithiName(i).en}';

String panchangaCsv(PanchangaEngine e, int year) {
  final b = StringBuffer()
    ..writeln(
      _csv([
        'date', 'weekday', 'sunrise', 'sunset', 'moonrise', 'moonset', //
        'tithi', 'nakshatra', 'yoga', 'karana', 'paksha', 'lunar_month',
        'tulu_month', 'tulu_day', 'sankramana', 'samvatsara', 'shaka',
        'rahu_kaala', 'yamaganda', 'gulika', 'abhijit',
      ]),
    );
  final first = DateTime.utc(year, 1, 1);
  final n = DateTime.utc(year + 1, 1, 1).difference(first).inDays;
  for (final d in e.days(first, n)) {
    String win(Window w) =>
        '${_hm(e, w.start, d.date)}-${_hm(e, w.end, d.date)}';
    final lm = d.lunarMonth;
    b.writeln(
      _csv([
        _date(d.date),
        varaNames[d.weekday].en,
        _hm(e, d.sunrise, d.date),
        _hm(e, d.sunset, d.date),
        _hm(e, d.moonrise, d.date),
        _hm(e, d.moonset, d.date),
        _spans(e, d, d.tithis, _tithi),
        _spans(e, d, d.nakshatras, (i) => nakshatraNames[i].en),
        _spans(e, d, d.yogas, (i) => yogaNames[i].en),
        _spans(e, d, d.karanas, (i) => karanaNames[karanaIndex(i)].en),
        pakshaNames[d.paksha].en,
        '${lm.adhika ? 'Adhika ' : ''}${lunarMonthNames[lm.index].en}',
        tuluMonthNames[d.solar.month].en,
        d.solar.day,
        d.sankrantiToday == null
            ? ''
            : '${rashiNames[(d.sunRashi + 1) % 12].en} ${_hm(e, d.sankrantiToday, d.date)}',
        samvatsaraNames[d.samvatsara].en,
        d.shakaYear,
        win(d.kaalas.rahu),
        win(d.kaalas.yamaganda),
        win(d.kaalas.gulika),
        win(d.kaalas.abhijit),
      ]),
    );
  }
  return b.toString();
}

String festivalCsv(PanchangaEngine e, int year) {
  final b = StringBuffer()
    ..writeln(
      _csv([
        'date', 'weekday', 'festival', 'festival_kn', 'category', 'rule', //
        'tithi_at_sunrise', 'lunar_month', 'tulu_date', 'how_chosen',
        'confidence', 'note', 'priest_date', 'priest_comment',
      ]),
    );
  for (final o in FestivalCalculator(e).forYear(year)) {
    final d = e.day(o.date);
    final lm = d.lunarMonth;
    final how = [
      if (o.detail.isNotEmpty) o.detail,
      if (o.instant != null) 'instant ${_hm(e, o.instant, o.date)}',
    ].join('; ');
    b.writeln(
      _csv([
        _date(o.date),
        varaNames[d.weekday].en,
        o.festival.name.en,
        o.festival.name.kn,
        o.festival.category.name,
        o.festival.rule.describe(),
        '${_tithi(d.tithi)} (till ${_hm(e, d.tithis.first.end, d.date)})',
        '${lm.adhika ? 'Adhika ' : ''}${lunarMonthNames[lm.index].en}',
        '${tuluMonthNames[d.solar.month].en} ${d.solar.day}',
        how,
        o.festival.confidence.name,
        o.festival.note,
        '',
        '',
      ]),
    );
  }
  return b.toString();
}
