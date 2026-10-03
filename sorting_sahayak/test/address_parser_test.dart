import 'package:flutter_test/flutter_test.dart';
import 'package:sorting_sahayak/features/scan/address_parser.dart';

import 'helpers/fixture.dart';

void main() {
  const ocr = 'To\nSri Ramesh K\nDoor No 4-112, Temple Road\nDarbe Post, Puttur\nDakshina Kannada 574 2O1\nMobile 9845012345';

  test('finds PIN and nearby place candidates', () {
    final c = parseAddress(ocr);
    expect(c.pins, ['574201']);
    // "Darbe Post" names the delivery office: it comes first.
    expect(c.postNames, contains('Darbe'));
    expect(c.places.first, 'Darbe');
    expect(c.places, contains('Dakshina Kannada'));
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

  test('short noise words are not cut out of place names', () {
    final c = parseAddress('Mattur\nKarnataka 577201');
    expect(c.places, containsAll(['Mattur', 'Karnataka']));
  });

  test('names written with post / P.O. are the delivery office', () {
    expect(parseAddress('Sulkeri post\nBelthangady Tq 574214').postNames, contains('Sulkeri'));
    expect(parseAddress('At & PO: Kabaka\nPuttur').postNames, contains('Kabaka'));
    expect(parseAddress('Ujire (P.O.)\n574240').postNames, contains('Ujire'));
    expect(parseAddress('Belthangady Tq\n574214').postNames, isEmpty);
    // Searched first.
    expect(parseAddress('Sulkeri post\nBelthangady 574214').places.first, 'Sulkeri');
  });

  test('Kannada address: digits, post name, taluk word dropped', () {
    final c = parseAddress('ಶ್ರೀ ರಮೇಶ್\nಕಬಕ ಅಂಚೆ, ಪುತ್ತೂರು ತಾಲೂಕು\nದ.ಕ. ೫೭೪೨೨೦');
    expect(c.pins, ['574220']);
    expect(c.postNames, contains('ಕಬಕ'));
    expect(c.places.first, 'ಕಬಕ');
    expect(c.places, contains('ಪುತ್ತೂರು'));
    expect(c.places.any((p) => p.contains('ತಾಲೂಕು')), isFalse);
  });
}
