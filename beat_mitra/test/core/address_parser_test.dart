import 'package:beat_mitra/core/address_parser.dart';
import 'package:flutter_test/flutter_test.dart';

/// OCR-like fixture texts (as ML Kit returns them: one line per block line).
const englishLetter = '''
To,
Shri Ramesh Kumar
No. 12/3, 4th Cross, 2nd Main
HAL 2nd Stage, Indiranagar
Near Ganesha Temple
Bengaluru - 560 038
Ph: 9876543210
''';

const speedPostLabel = '''
SPEED POST
EK123456785IN
Mrs. Lakshmi Devi
#221, 1st Floor, 8th Main Road
Jayanagar 4th Block
BANGALORE 560011
''';

const hindiLetter = '''
सेवा में,
श्रीमती सुनीता शर्मा
मकान नं. 45, गली नं. 3
शास्त्री नगर
जयपुर 302016
''';

const hindiNoDoorWord = '''
श्री रमेश वर्मा
12/7 राम मार्ग
सिविल लाइंस, जयपुर - 302006
मो. 9812345678
''';

const noisyOcr = '''
REGD
To
Manjunath Gowda
H.No 7-2 Temple Road
Malleshwaram Bangalore560003
''';

const typedOneLine = 'Kavya Rao, 40 1st Main, Basavanagudi 560004';

void main() {
  test('English letter', () {
    final p = parseAddress(englishLetter);
    expect(p.names, ['Ramesh Kumar']);
    expect(p.doorNo, '12/3');
    expect(p.street, contains('4th Cross'));
    expect(p.street, contains('2nd Main'));
    expect(p.area, contains('Indiranagar'));
    expect(p.landmark, 'Ganesha Temple');
    expect(p.pin, '560038');
    expect(p.phone, '9876543210');
  });

  test('Speed post label with article number', () {
    final p = parseAddress(speedPostLabel);
    expect(p.articleNo, 'EK123456785IN');
    expect(p.names, ['Lakshmi Devi']);
    expect(p.doorNo, '221');
    expect(p.street, contains('8th Main Road'));
    expect(p.area, contains('Jayanagar'));
    expect(p.pin, '560011');
  });

  test('Hindi letter', () {
    final p = parseAddress(hindiLetter);
    expect(p.names, ['सुनीता शर्मा']);
    expect(p.doorNo, '45');
    expect(p.street, isNotNull);
    expect(p.pin, '302016');
    expect(p.toQuery(), contains('45'));
  });

  test('Hindi address with leading door number and phone', () {
    final p = parseAddress(hindiNoDoorWord);
    expect(p.names, ['रमेश वर्मा']);
    expect(p.doorNo, '12/7');
    expect(p.street, isNotNull);
    expect(p.pin, '302006');
    expect(p.phone, '9812345678');
  });

  test('Noisy OCR: PIN glued to city, H.No with dash', () {
    final p = parseAddress(noisyOcr);
    expect(p.names, ['Manjunath Gowda']);
    expect(p.doorNo, '7/2');
    expect(p.street, contains('Temple Road'));
    expect(p.pin, '560003');
  });

  test('typed one-line address', () {
    final p = parseAddress(typedOneLine.replaceAll(', ', '\n'));
    expect(p.names, ['Kavya Rao']);
    expect(p.doorNo, '40');
    expect(p.pin, '560004');
  });

  test('empty input', () {
    expect(parseAddress('').isEmpty, isTrue);
  });
}
