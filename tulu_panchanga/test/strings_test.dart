import 'package:flutter_test/flutter_test.dart';
import 'package:tulu_panchanga/app/strings.dart';
import 'package:tulu_panchanga/lipi/tulu_lipi.dart';
import 'package:tulu_panchanga/panchanga/names.dart';

void main() {
  List<String> all(S s) => [
    s.appTitle,
    s.today,
    s.calendar,
    s.festivals,
    s.muhurta,
    s.settings,
    s.sunrise,
    s.sunset,
    s.tithi,
    s.nakshatra,
    s.yoga,
    s.karana,
    s.lunarMonth,
    s.tuluMonth,
    s.rahu,
    s.yamaganda,
    s.gulika,
    s.until,
    s.nextDay,
    s.fullDetails,
    s.timeline,
    s.language,
    s.chooseLanguage,
    s.location,
    s.notifications,
    s.listen,
    s.todayFestival,
    s.comingUp,
    s.inDays(3),
    s.muhurtaDisclaimer,
    s.aboutText,
  ];

  test('Kannada is the default and every language has its own words', () {
    expect(Lang.values.first, Lang.kn);
    final en = all(const S(Lang.en));
    for (final l in [Lang.hi, Lang.ml, Lang.te]) {
      final t = all(S(l));
      for (var i = 0; i < t.length; i++) {
        expect(t[i], isNot(en[i]), reason: '$l #$i "${en[i]}" untranslated');
        expect(TuluLipi.hasKannada(t[i]), isFalse, reason: '$l #$i');
      }
    }
    for (final l in [Lang.kn, Lang.tcy, Lang.kok]) {
      for (final x in all(S(l))) {
        expect(TuluLipi.hasKannada(x), isTrue, reason: '$l "$x"');
      }
    }
  });
}
