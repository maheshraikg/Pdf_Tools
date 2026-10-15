import 'package:flutter/material.dart';

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
  return '$h:${_two(w.minute)} ${w.hour < 12 ? 'AM' : 'PM'}';
}

/// "1h 05m" / "12m" / "45s".
String countdown(S s, Duration d) {
  if (d.isNegative) d = Duration.zero;
  final h = d.inHours, m = d.inMinutes % 60, sec = d.inSeconds % 60;
  if (h > 0) return '$h${s.hoursShort} ${_two(m)}${s.minutesShort}';
  if (m > 0) return '$m${s.minutesShort} ${_two(sec)}s';
  return '${sec}s';
}

/// mm:ss countdown (display mode).
String clockCountdown(Duration d) {
  if (d.isNegative) d = Duration.zero;
  final h = d.inHours;
  final m = d.inMinutes % 60, s = d.inSeconds % 60;
  return h > 0 ? '$h:${_two(m)}:${_two(s)}' : '${_two(m)}:${_two(s)}';
}

const _monthsEn = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];
const _monthsMl = [
  'ജനുവരി',
  'ഫെബ്രുവരി',
  'മാർച്ച്',
  'ഏപ്രിൽ',
  'മേയ്',
  'ജൂൺ',
  'ജൂലൈ',
  'ഓഗസ്റ്റ്',
  'സെപ്റ്റംബർ',
  'ഒക്ടോബർ',
  'നവംബർ',
  'ഡിസംബർ',
];
const _weekdaysEn = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];
const _weekdaysMl = [
  'തിങ്കൾ',
  'ചൊവ്വ',
  'ബുധൻ',
  'വ്യാഴം',
  'വെള്ളി',
  'ശനി',
  'ഞായർ',
];

String monthName(Lang lang, int month) =>
    (lang == Lang.ml ? _monthsMl : _monthsEn)[month - 1];

String weekdayName(Lang lang, int weekday) =>
    (lang == Lang.ml ? _weekdaysMl : _weekdaysEn)[weekday - 1];

String longDate(Lang lang, DateTime d) =>
    '${weekdayName(lang, d.weekday)}, ${d.day} ${monthName(lang, d.month)} ${d.year}';
