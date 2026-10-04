import 'package:flutter_test/flutter_test.dart';
import 'package:tulu_panchanga/lipi/tulu_lipi.dart';
import 'package:tulu_panchanga/panchanga/festivals.dart';
import 'package:tulu_panchanga/panchanga/names.dart';

void main() {
  test('name tables have the expected sizes', () {
    expect(tithiNames.length, 15);
    expect(nakshatraNames.length, 27);
    expect(yogaNames.length, 27);
    expect(karanaNames.length, 11);
    expect(varaNames.length, 7);
    expect(varaShort.length, 7);
    expect(rashiNames.length, 12);
    expect(lunarMonthNames.length, 12);
    expect(tuluMonthNames.length, 12);
    expect(samvatsaraNames.length, 60);
    expect(rituNames.length, 6);
  });

  test(
    'every name is non-empty in all languages and Kannada-script for kn/tcy',
    () {
      final all = [
        ...tithiNames,
        amavasyaName,
        ...nakshatraNames,
        ...yogaNames,
        ...karanaNames,
        ...varaNames,
        ...rashiNames,
        ...lunarMonthNames,
        ...tuluMonthNames,
        ...samvatsaraNames,
        ...rituNames,
        for (final f in allFestivals) f.name,
      ];
      for (final n in all) {
        for (final l in Lang.values) {
          expect(n.of(l).trim(), isNotEmpty, reason: '${n.en} / $l');
        }
        expect(TuluLipi.hasKannada(n.kn), isTrue, reason: n.en);
        expect(TuluLipi.hasKannada(n.tcy), isTrue, reason: n.en);
      }
    },
  );

  test('Tulu month names (Paggu … Suggi) and Tulu weekdays', () {
    expect(tuluMonthNames.map((n) => n.en).toList(), [
      'Paggu', 'Beshe', 'Kartel', 'Aati', 'Sona', 'Nirnal', 'Bontel', //
      'Jaarde', 'Perarde', 'Puyintel', 'Maayi', 'Suggi',
    ]);
    expect(tuluMonthNames[3].tcy, 'ಆಟಿ');
    expect(varaNames[0].of(Lang.tcy), 'ಐತಾರ');
    expect(varaNames[0].of(Lang.kn), 'ಭಾನುವಾರ');
    expect(tithiName(29).of(Lang.tcy), 'ಅಮಾಸೆ');
    expect(tithiName(29).of(Lang.kn), 'ಅಮಾವಾಸ್ಯೆ');
    expect(tithiName(14).of(Lang.tcy), 'ಪುಣ್ಣಮೆ');
  });

  test('karana sequence over a lunar month', () {
    expect(karanaIndex(0), 10); // Kimstughna
    expect(karanaIndex(1), 0); // Bava
    expect(karanaIndex(7), 6); // Vishti
    expect(karanaIndex(8), 0);
    expect(karanaIndex(56), 6);
    expect([karanaIndex(57), karanaIndex(58), karanaIndex(59)], [7, 8, 9]);
  });

  test('Tulu lipi conversion of month names', () {
    final aati = TuluLipi.fromKannada('ಆಟಿ');
    expect(aati.runes.toList(), [0x11381, 0x1139C, 0x113B9]);
    for (final n in tuluMonthNames) {
      final t = TuluLipi.fromKannada(n.tcy);
      expect(TuluLipi.hasKannada(t), isFalse, reason: n.en);
    }
  });

  test('Lang codes round-trip', () {
    for (final l in Lang.values) {
      expect(Lang.fromCode(l.name), l);
    }
    expect(Lang.fromCode('xx'), Lang.en);
  });
}
