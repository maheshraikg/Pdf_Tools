import 'package:flutter_test/flutter_test.dart';
import 'package:waqt/core/timetable.dart';

const _csv = '''
# name: Test Masjid
# utc_offset: +05:30
# source: unit test
date,fajr,sunrise,dhuhr,asr,maghrib,isha
01-01,05:28,06:51,12:36,15:51,18:17,19:32
02-28,05:20,06:40,12:40,16:00,18:30,19:40
2027-01-01,05:30,06:52,12:37,15:52,18:18,19:33
''';

void main() {
  test('parses header, rows and per-year overrides', () {
    final t = Timetable.parse(_csv);
    expect(t.name, 'Test Masjid');
    expect(t.source, 'unit test');
    expect(t.utcOffsetMinutes, 330);
    expect(t.daysOfYear, 2);
    expect(t.minutesFor(2026, 1, 1), [328, 411, 756, 951, 1097, 1172]);
    expect(t.minutesFor(2027, 1, 1)!.first, 330);
    expect(t.minutesFor(2026, 1, 2), isNull);
  });

  test('29 February falls back to 28 February', () {
    final t = Timetable.parse(_csv);
    expect(t.minutesFor(2028, 2, 29), t.minutesFor(2028, 2, 28));
  });

  test('converts local times to UTC', () {
    final t = Timetable.parse(_csv);
    final u = t.utcFor(2026, 1, 1)!;
    expect(u.first, DateTime.utc(2025, 12, 31, 23, 58)); // 05:28 IST
    expect(u.last, DateTime.utc(2026, 1, 1, 14, 2)); // 19:32 IST
  });

  test('accepts AM/PM, semicolons, BOM and reordered columns', () {
    const text =
        '﻿date;isha;maghrib;asr;dhuhr;sunrise;fajr\r\n'
        '3-5;7:40 PM;6:30 pm;3:55 PM;12:35 PM;6:45 AM;5:25 am\r\n';
    final t = Timetable.parse(text, fallbackName: 'Mine');
    expect(t.name, 'Mine');
    expect(t.utcOffsetMinutes, 330);
    expect(t.minutesFor(2026, 3, 5), [325, 405, 755, 955, 1110, 1180]);
  });

  test('rejects bad input with the line number', () {
    expect(
      () => Timetable.parse('fajr,sunrise\n'),
      throwsA(isA<TimetableFormatException>()),
    );
    expect(
      () => Timetable.parse('date,fajr,sunrise,dhuhr,asr,maghrib\n'),
      throwsA(isA<TimetableFormatException>()),
    );
    // 12-hour times without AM/PM put Asr before Dhuhr.
    try {
      Timetable.parse(
        'date,fajr,sunrise,dhuhr,asr,maghrib,isha\n'
        '01-01,5:28,6:51,12:36,3:51,6:17,7:32\n',
      );
      fail('should throw');
    } on TimetableFormatException catch (e) {
      expect(e.line, 2);
      expect(e.message, contains('asr'));
    }
    expect(
      () => Timetable.parse(
        '# utc_offset: banana\ndate,fajr,sunrise,dhuhr,asr,maghrib,isha\n',
      ),
      throwsA(isA<TimetableFormatException>()),
    );
    expect(
      () => Timetable.parse(
        'date,fajr,sunrise,dhuhr,asr,maghrib,isha\n13-01,05:28,06:51,12:36,15:51,18:17,19:32\n',
      ),
      throwsA(isA<TimetableFormatException>()),
    );
  });

  test('CSV round trip', () {
    final t = Timetable.parse(_csv);
    final u = Timetable.parse(t.toCsv());
    expect(u.name, t.name);
    expect(u.utcOffsetMinutes, t.utcOffsetMinutes);
    expect(u.length, t.length);
    expect(u.minutesFor(2027, 1, 1), t.minutesFor(2027, 1, 1));
  });

  test('clock and offset parsing', () {
    expect(parseClock('00:00'), 0);
    expect(parseClock('12:00 AM'), 0);
    expect(parseClock('12:30 PM'), 750);
    expect(parseClock('5.07'), 307);
    expect(parseClock('24:00'), isNull);
    expect(parseClock('13:00 PM'), isNull);
    expect(parseUtcOffset('+05:30'), 330);
    expect(parseUtcOffset('UTC+4'), 240);
    expect(parseUtcOffset('-0330'), -210);
    expect(parseUtcOffset('+15:00'), isNull);
    expect(formatUtcOffset(-210), '-03:30');
  });
}
