import '../panchanga/engine.dart';
import '../panchanga/names.dart';
import 'scope.dart';
import 'strings.dart';

/// "06:19" or "05:40 (next day)" for an instant relative to civil [day].
String hmPlain(S s, PanchangaEngine e, double jd, DateTime day) {
  final w = e.wall(jd);
  final diff = PanchangaEngine.dateOnly(w).difference(day).inDays;
  return diff == 0 ? hm(e, jd) : '${hm(e, jd)} (${s.nextDay})';
}

String _end(S s, PanchangaEngine e, DayPanchanga d, Span x) =>
    x.end >= d.nextSunrise
    ? s.untilNextSunrise
    : s.untilTime(hmPlain(s, e, x.end, d.date));

/// One-line headline: "Paggu 12 · Chaitra Shukla Navami".
String dayHeadline(Lang lang, DayPanchanga d) =>
    '${tuluDate(lang, d)} · ${lunarMonthLabel(lang, d.lunarMonth)} '
    '${tithiLabel(lang, d.tithi)}';

/// Multi-line plain-text summary of a day (share text, notifications).
String daySummary(
  S s,
  Lang lang,
  PanchangaEngine e,
  DayPanchanga d, {
  bool withHeader = true,
}) {
  final t = d.tithis.first, n = d.nakshatras.first;
  return [
    if (withHeader) ...[
      '${varaNames[d.weekday].of(lang)}, ${longDate(lang, d.date)}',
      '${dayHeadline(lang, d)} · ${samvatsaraNames[d.samvatsara].of(lang)}',
    ],
    '${s.tithi}: ${tithiLabel(lang, t.index)} (${_end(s, e, d, t)})',
    '${s.nakshatra}: ${nakshatraNames[n.index].of(lang)} (${_end(s, e, d, n)})',
    '${s.yoga}: ${yogaNames[d.yoga].of(lang)}',
    '${s.sunrise} ${hm(e, d.sunrise)} · ${s.sunset} ${hm(e, d.sunset)}',
    '${s.rahu}: ${hm(e, d.kaalas.rahu.start)}–${hm(e, d.kaalas.rahu.end)}',
  ].join('\n');
}
