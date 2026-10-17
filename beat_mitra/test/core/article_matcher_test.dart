import 'package:beat_mitra/core/address_parser.dart';
import 'package:beat_mitra/core/article_matcher.dart';
import 'package:beat_mitra/core/fuzzy.dart';
import 'package:flutter_test/flutter_test.dart';

import 'address_parser_test.dart' show englishLetter, speedPostLabel;

void main() {
  final index = SearchIndex([
    SearchDoc(
      id: 1,
      fields: {
        'name': 'Ramesh Kumar',
        'door': '12/3',
        'street': '4th Cross 2nd Main',
        'area': 'HAL 2nd Stage Indiranagar',
      },
    ),
    SearchDoc(id: 2, fields: {'name': 'Suresh Kumar', 'door': '12', 'street': '4th Cross', 'area': 'Indiranagar'}),
    SearchDoc(
      id: 3,
      fields: {'name': 'Lakshmi Devi', 'door': '221', 'street': '8th Main Road', 'area': 'Jayanagar 4th Block'},
    ),
    SearchDoc(id: 4, fields: {'name': 'Ramesh', 'door': '99', 'street': 'Temple Road', 'area': 'Malleshwaram'}),
  ]);
  final pins = {1: '560038', 2: '560038', 3: '560011', 4: '560003'};

  test('English letter matches the right place first', () {
    final s = matchAddress(parseAddress(englishLetter), index, pinOf: pins);
    expect(s.first.placeId, 1);
    expect(s.length, lessThanOrEqualTo(3));
  });

  test('speed post label', () {
    final s = matchAddress(parseAddress(speedPostLabel), index, pinOf: pins);
    expect(s.first.placeId, 3);
    expect(s.first.score, greaterThan(0.8));
  });

  test('wrong PIN lowers the score', () {
    final good = matchAddress(parseAddress('Ramesh\n99 Temple Road\n560003'), index, pinOf: pins);
    final bad = matchAddress(parseAddress('Ramesh\n99 Temple Road\n560099'), index, pinOf: pins);
    expect(good.first.placeId, 4);
    expect(bad.isEmpty || bad.first.score < good.first.score, isTrue);
  });

  test('unknown address gives no suggestion', () {
    expect(matchAddress(parseAddress('Zebulon Xavier\n777 Unknown Street'), index), isEmpty);
  });

  test('filter limits to beat', () {
    final s = matchAddress(parseAddress(englishLetter), index, pinOf: pins, filter: (id) => id != 1);
    expect(s.map((m) => m.placeId), isNot(contains(1)));
  });
}
