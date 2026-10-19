import 'package:flutter_test/flutter_test.dart';
import 'package:waqt/app/scope.dart';
import 'package:waqt/app/settings.dart';
import 'package:waqt/app/strings.dart';
import 'package:waqt/core/alerts.dart';
import 'package:waqt/core/prayer_calc.dart';
import 'package:waqt/l10n/tables.dart';

void main() {
  test('every non-English/Malayalam language has a full table', () {
    final sizes = {for (final e in translations.entries) e.key: e.value.length};
    expect(
      translations.keys.toSet(),
      Lang.values.where((l) => l != Lang.en && l != Lang.ml).toSet(),
    );
    expect(sizes.values.toSet(), hasLength(1), reason: '$sizes');
    for (final l in hijriMonthNames.values) {
      expect(l, hasLength(12));
    }
  });

  test('strings are translated, templates filled, main words translated', () {
    for (final lang in Lang.values.where((l) => l != Lang.en)) {
      final s = S(lang);
      final en = S(Lang.en);
      expect(s.today, isNot(en.today), reason: '$lang');
      final filled = [
        s.inTime('5m'),
        s.reminderTitle(Prayer.asr, false, 10),
        s.timetableInfo(365, '+05:30'),
        s.days(2),
      ];
      for (final f in filled) {
        expect(f, isNot(contains('{')), reason: '$lang: $f');
      }
      expect(s.reminderTitle(Prayer.asr, false, 10), contains('10'));
      expect(s.widgetCountdown, contains('%s'));
      expect(s.silentModeName(SilentMode.vibrate), isNotEmpty);
    }
  });

  test('dates, Hijri months and AM/PM are localised', () {
    expect(monthName(Lang.en, 10), 'October');
    expect(weekdayName(Lang.en, DateTime.friday), 'Friday');
    expect(weekdayName(Lang.en, DateTime.sunday), 'Sunday');
    expect(monthName(Lang.ar, 10), isNot('October'));
    expect(weekdayName(Lang.fr, DateTime.monday), 'lundi');
    expect(hijriMonthName(Lang.tr, 9), 'Ramazan');
    expect(hijriMonthName(Lang.en, 9), 'Ramadan');
    expect(amPm(Lang.en, 9), 'AM');
    expect(amPm(Lang.en, 21), 'PM');
    expect(amPm(Lang.ar, 21), isNot('PM'));
    for (final l in Lang.values) {
      for (var m = 1; m <= 12; m++) {
        expect(monthName(l, m), isNotEmpty);
        expect(hijriMonthName(l, m), isNotEmpty);
      }
    }
  });

  test('language codes round-trip and unknown codes fall back', () {
    for (final l in Lang.values) {
      expect(Lang.fromCode(l.code), l);
    }
    expect(Lang.fromCode('xx'), Lang.en);
    expect(Lang.tryCode(null), isNull);
    expect(Lang.ar.rtl && Lang.ur.rtl && !Lang.hi.rtl, isTrue);
  });
}
