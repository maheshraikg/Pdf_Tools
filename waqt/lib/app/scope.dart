import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/date_symbols.dart';

import '../core/hijri.dart';
import '../l10n/tables.dart';

import 'settings.dart';
import 'strings.dart';

/// Gives widgets access to the settings and strings.
class AppScope extends InheritedNotifier<AppSettings> {
  const AppScope({
    super.key,
    required AppSettings settings,
    required super.child,
  }) : super(notifier: settings);

  static AppSettings settingsOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;
}

extension AppContext on BuildContext {
  AppSettings get settings => AppScope.settingsOf(this);
  S get s => S(settings.lang);
}

String _two(int v) => v.toString().padLeft(2, '0');

/// Clock time of a UTC instant at the place.
String hm(AppSettings settings, DateTime utc) {
  final w = settings.wall(utc);
  if (settings.use24h) return '${_two(w.hour)}:${_two(w.minute)}';
  final h = w.hour % 12 == 0 ? 12 : w.hour % 12;
  return '$h:${_two(w.minute)} ${amPm(settings.lang, w.hour)}';
}

/// "1h 05m" / "12m" / "45s".
String countdown(S s, Duration d) {
  if (d.isNegative) d = Duration.zero;
  final h = d.inHours, m = d.inMinutes % 60, sec = d.inSeconds % 60;
  // "5m", but "5 منٹ": longer units read better with a space.
  String u(String v, String unit) => unit.length > 2 ? '$v $unit' : '$v$unit';
  if (h > 0) return '${u('$h', s.hoursShort)} ${u(_two(m), s.minutesShort)}';
  if (m > 0) {
    return '${u('$m', s.minutesShort)} ${u(_two(sec), s.secondsShort)}';
  }
  return u('$sec', s.secondsShort);
}

/// mm:ss countdown (display mode).
String clockCountdown(Duration d) {
  if (d.isNegative) d = Duration.zero;
  final h = d.inHours;
  final m = d.inMinutes % 60, s = d.inSeconds % 60;
  return h > 0 ? '$h:${_two(m)}:${_two(s)}' : '${_two(m)}:${_two(s)}';
}

DateSymbols _symbols(Lang lang) {
  final map = dateTimeSymbolMap();
  return (map[lang.code] ?? map['en']) as DateSymbols;
}

/// Localised AM/PM marker for [hour] (0–23).
String amPm(Lang lang, int hour) {
  // intl's Urdu markers are just "a"/"p"; the English ones read better.
  final marks = lang == Lang.ur ? const ['AM', 'PM'] : _symbols(lang).AMPMS;
  return marks[hour < 12 ? 0 : 1];
}

/// Gregorian month name in [lang] (from the intl locale data).
String monthName(Lang lang, int month) => _symbols(lang).MONTHS[month - 1];

/// Weekday name in [lang]; [weekday] is DateTime.monday (1) … sunday (7).
String weekdayName(Lang lang, int weekday) =>
    _symbols(lang).WEEKDAYS[weekday % 7]; // intl lists Sunday first

/// Hijri month name in [lang].
String hijriMonthName(Lang lang, int month) => switch (lang) {
  Lang.en => HijriDate.monthsEn[month - 1],
  Lang.ml => HijriDate.monthsMl[month - 1],
  _ => (hijriMonthNames[lang] ?? HijriDate.monthsEn)[month - 1],
};

/// "4 Jumada al-Ula 1448" in [lang].
String hijriLabel(Lang lang, HijriDate h) =>
    '${h.day} ${hijriMonthName(lang, h.month)} ${h.year}';

String longDate(Lang lang, DateTime d) =>
    '${weekdayName(lang, d.weekday)}${lang.rtl ? '،' : ','} '
    '${d.day} ${monthName(lang, d.month)} ${d.year}';
