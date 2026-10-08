import 'package:flutter_test/flutter_test.dart';
import 'package:sorting_sahayak/core/pin_utils.dart';

void main() {
  group('validation', () {
    test('accepts 6 digits starting 1-9', () {
      expect(PinUtils.isValid('574201'), isTrue);
      expect(PinUtils.isValid('110001'), isTrue);
      expect(PinUtils.isValid('999999'), isTrue);
    });
    test('rejects bad input', () {
      for (final bad in ['074201', '57420', '5742011', '57420a', '', ' 574201', '574 201', null]) {
        expect(PinUtils.isValid(bad), isFalse, reason: '$bad');
      }
    });
    test('valid prefix', () {
      expect(PinUtils.isValidPrefix(''), isTrue);
      expect(PinUtils.isValidPrefix('5'), isTrue);
      expect(PinUtils.isValidPrefix('574'), isTrue);
      expect(PinUtils.isValidPrefix('0'), isFalse);
      expect(PinUtils.isValidPrefix('5742011'), isFalse);
    });
  });

  group('digits', () {
    test('Kannada and Devanagari digits', () {
      expect(PinUtils.normalizeDigits('೫೭೪೨೦೧'), '574201');
      expect(PinUtils.normalizeDigits('५७४२०१'), '574201');
      expect(PinUtils.normalizeDigits('೦೧೨೩೪೫೬೭೮೯'), '0123456789');
      expect(PinUtils.normalizeDigits('०१२३४५६७८९'), '0123456789');
      expect(PinUtils.digitsOnly('೫೭೪-೨೦೧'), '574201');
    });
  });

  group('breakdown', () {
    test('full PIN', () {
      final b = PinUtils.breakdown('574201')!;
      expect(b.zoneDigit, '5');
      expect(b.zoneName, contains('Southern'));
      expect(b.circleCode, '57');
      expect(b.circleName, 'Karnataka');
      expect(b.sortingDistrict, '574');
      expect(b.deliveryOffice, '201');
      expect(b.isComplete, isTrue);
    });
    test('partial PIN', () {
      final b = PinUtils.breakdown('57')!;
      expect(b.circleName, 'Karnataka');
      expect(b.sortingDistrict, isNull);
      expect(b.deliveryOffice, isNull);
      expect(PinUtils.breakdown('5')!.circleCode, isNull);
    });
    test('circle table and overrides', () {
      expect(PinUtils.circleForPin('110001'), 'Delhi');
      expect(PinUtils.circleForPin('403001'), 'Goa');
      expect(PinUtils.circleForPin('400001'), 'Maharashtra');
      expect(PinUtils.circleForPin('600001'), 'Tamil Nadu');
      expect(PinUtils.circleForPin('682001'), contains('Kerala'));
      expect(PinUtils.circleForPin('560001'), 'Karnataka');
      expect(PinUtils.circleForPin('500001'), 'Telangana');
      expect(PinUtils.circleForPin('700001'), 'West Bengal');
      expect(PinUtils.circleForPin('900001'), 'Army Postal Service');
      expect(PinUtils.circleForPin('540001'), isNull);
    });
    test('invalid breakdown', () {
      expect(PinUtils.breakdown(''), isNull);
      expect(PinUtils.breakdown('012'), isNull);
      expect(PinUtils.breakdown('೫೭೪')!.sortingDistrict, '574');
    });
  });

  group('extraction', () {
    test('plain and separated forms', () {
      expect(PinUtils.extractPins('Puttur 574201'), ['574201']);
      expect(PinUtils.extractPins('Puttur 574 201 DK'), ['574201']);
      expect(PinUtils.extractPins('Puttur-574-201'), ['574201']);
      expect(PinUtils.extractPins('Puttur 574 - 201'), ['574201']);
      expect(PinUtils.extractPins('PIN:574201'), ['574201']);
      expect(PinUtils.extractPins('PIN574201'), ['574201']);
      expect(PinUtils.extractPins('Pin Code - 574201'), ['574201']);
      expect(PinUtils.extractPins('P.I.N. 574201'), ['574201']);
    });
    test('Indic digits and labels', () {
      expect(PinUtils.extractPins('ಪುತ್ತೂರು ೫೭೪೨೦೧'), ['574201']);
      expect(PinUtils.extractPins('ಪಿನ್: ೫೭೪೨೦೧'), ['574201']);
      expect(PinUtils.extractPins('पिन कोड ५६०००१'), ['560001']);
    });
    test('OCR confusions inside digit-like tokens', () {
      expect(PinUtils.extractPins('Puttur 57420I'), ['574201']);
      expect(PinUtils.extractPins('Puttur 5742Ol'), ['574201']);
      expect(PinUtils.extractPins('Mangaluru S75OO1'), ['575001']);
      expect(PinUtils.extractPins('Bengaluru 56OO8B'), ['560088']);
    });
    test('does not turn words into PINs', () {
      expect(PinUtils.extractPins('BOSS SOIL BOB'), isEmpty);
      expect(PinUtils.extractPins('SOLIDS'), isEmpty);
      expect(PinUtils.extractPins('Mobile 9845012345'), isEmpty);
      expect(PinUtils.extractPins('Door no 12, 4th cross'), isEmpty);
      expect(PinUtils.extractPins('074201'), isEmpty);
    });
    test('ranks labelled PIN first and dedupes', () {
      final text = 'From: 560001 Bengaluru\nTo: Puttur PIN 574201\nRef 574201';
      expect(PinUtils.extractPins(text), ['574201', '560001']);
    });
  });
}
