import 'package:flutter_test/flutter_test.dart';
import 'package:sorting_sahayak/features/scan/address_parser.dart';

import 'helpers/fixture.dart';

void main() {
  const ocr = 'To\nSri Ramesh K\nDoor No 4-112, Temple Road\nDarbe Post, Puttur\nDakshina Kannada 574 2O1\nMobile 9845012345';

  test('finds PIN and nearby place candidates', () {
    final c = parseAddress(ocr);
    expect(c.pins, ['574201']);
    expect(c.places.first, 'Dakshina Kannada');
    expect(c.places, contains('Puttur'));
  });

  test('best place is matched against the directory', () async {
    final dir = await fixtureRepo();
    final c = parseAddress(ocr);
    final best = await bestPlace(dir, c.places, pin: c.pins.first);
    expect(best, isNotNull);
    expect(['Dakshina Kannada', 'Puttur', 'Darbe Puttur', 'Darbe'], contains(best!.place));
  });

  test('no PIN', () {
    final c = parseAddress('Manipal\nUdupi district');
    expect(c.pins, isEmpty);
    expect(c.places, containsAll(['Manipal', 'Udupi']));
  });
}
