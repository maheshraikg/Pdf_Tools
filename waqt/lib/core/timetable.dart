/// Yearly timetables (for example a mosque's or Samastha's printed chart),
/// imported as CSV.
///
/// Format (lines starting with `#` are header fields or comments):
///
/// ```
/// # name: Kozhikode
/// # utc_offset: +05:30
/// # source: Printed chart 2026
/// date,fajr,sunrise,dhuhr,asr,maghrib,isha
/// 01-01,05:28,06:51,12:36,15:51,18:17,19:32
/// 2027-01-01,05:29,06:52,12:37,15:52,18:18,19:33
/// ```
///
/// `date` is `MM-DD` (repeats every year) or `YYYY-MM-DD` (that year only,
/// takes priority). Times are local `HH:mm` (24 h) or `hh:mm AM/PM`.
/// `,`, `;` and tab separators are accepted.
library;

const List<String> timetableColumns = [
  'fajr',
  'sunrise',
  'dhuhr',
  'asr',
  'maghrib',
  'isha',
];

class TimetableFormatException implements Exception {
  TimetableFormatException(this.line, this.message);
  final int line;
  final String message;
  @override
  String toString() => 'Line $line: $message';
}

class Timetable {
  Timetable({
    required this.name,
    required this.utcOffsetMinutes,
    required Map<String, List<int>> rows,
    this.source = '',
  }) : _rows = rows; // ignore: prefer_initializing_formals

  final String name;
  final int utcOffsetMinutes;
  final String source;

  /// Key `MM-DD` or `YYYY-MM-DD` → six minute-of-day values.
  final Map<String, List<int>> _rows;

  int get length => _rows.length;

  /// Number of distinct days of the year covered (`MM-DD` rows).
  int get daysOfYear => _rows.keys.where((k) => k.length == 5).length;

  /// Local minutes-of-day [fajr, sunrise, dhuhr, asr, maghrib, isha] for a
  /// date, or null when the table has no row for it. A missing 29 February
  /// falls back to 28 February.
  List<int>? minutesFor(int year, int month, int day) {
    final md = '${_two(month)}-${_two(day)}';
    return _rows['$year-$md'] ??
        _rows[md] ??
        (month == 2 && day == 29 ? _rows['02-28'] : null);
  }

  /// The six times of a date as UTC instants, or null.
  List<DateTime>? utcFor(int year, int month, int day) {
    final m = minutesFor(year, month, day);
    if (m == null) return null;
    final base = DateTime.utc(year, month, day);
    return [
      for (final v in m) base.add(Duration(minutes: v - utcOffsetMinutes)),
    ];
  }

  static Timetable parse(String text, {String fallbackName = 'Timetable'}) {
    var name = fallbackName, source = '';
    int? offset;
    List<int>? columnIndex;
    final rows = <String, List<int>>{};
    final lines = text.split(RegExp(r'\r?\n'));
    for (var i = 0; i < lines.length; i++) {
      final lineNo = i + 1;
      var line = lines[i].trim();
      if (i == 0 && line.startsWith('﻿')) line = line.substring(1);
      if (line.isEmpty) continue;
      if (line.startsWith('#')) {
        final m = RegExp(r'^#\s*([a-zA-Z_ ]+?)\s*:\s*(.*)$').firstMatch(line);
        if (m == null) continue;
        final key = m[1]!.toLowerCase().replaceAll(' ', '_');
        final value = m[2]!.trim();
        if (key == 'name') name = value;
        if (key == 'source') source = value;
        if (key == 'utc_offset') {
          offset = parseUtcOffset(value);
          if (offset == null) {
            throw TimetableFormatException(lineNo, 'Bad utc_offset "$value"');
          }
        }
        continue;
      }
      final cells = line.split(RegExp(r'[,;\t]')).map((c) => c.trim()).toList();
      if (columnIndex == null) {
        final header = cells.map((c) => c.toLowerCase()).toList();
        if (header.first != 'date') {
          throw TimetableFormatException(
            lineNo,
            'Expected a header line starting with "date"',
          );
        }
        columnIndex = [
          for (final c in timetableColumns)
            header.contains(c)
                ? header.indexOf(c)
                : throw TimetableFormatException(lineNo, 'Missing column "$c"'),
        ];
        continue;
      }
      final key = _dateKey(cells.first);
      if (key == null) {
        throw TimetableFormatException(lineNo, 'Bad date "${cells.first}"');
      }
      final values = <int>[];
      for (final ci in columnIndex) {
        if (ci >= cells.length) {
          throw TimetableFormatException(lineNo, 'Too few columns');
        }
        final v = parseClock(cells[ci]);
        if (v == null) {
          throw TimetableFormatException(lineNo, 'Bad time "${cells[ci]}"');
        }
        values.add(v);
      }
      // Times must follow the order of the day.
      for (var k = 1; k < values.length; k++) {
        if (values[k] <= values[k - 1]) {
          throw TimetableFormatException(
            lineNo,
            '${timetableColumns[k]} is not after ${timetableColumns[k - 1]} '
            '(use 24-hour times or AM/PM)',
          );
        }
      }
      rows[key] = values;
    }
    if (rows.isEmpty) throw TimetableFormatException(0, 'No rows found');
    return Timetable(
      name: name,
      utcOffsetMinutes: offset ?? 330,
      rows: rows,
      source: source,
    );
  }

  /// Back to CSV (what is stored on the phone).
  String toCsv() {
    final b = StringBuffer()
      ..writeln('# name: $name')
      ..writeln('# utc_offset: ${formatUtcOffset(utcOffsetMinutes)}');
    if (source.isNotEmpty) b.writeln('# source: $source');
    b.writeln('date,${timetableColumns.join(',')}');
    final keys = _rows.keys.toList()..sort();
    for (final k in keys) {
      b.writeln('$k,${_rows[k]!.map(formatClock24).join(',')}');
    }
    return b.toString();
  }
}

String _two(int v) => v.toString().padLeft(2, '0');

String? _dateKey(String s) {
  final m = RegExp(r'^(?:(\d{4})-)?(\d{1,2})-(\d{1,2})$').firstMatch(s);
  if (m == null) return null;
  final month = int.parse(m[2]!), day = int.parse(m[3]!);
  if (month < 1 || month > 12 || day < 1 || day > 31) return null;
  final md = '${_two(month)}-${_two(day)}';
  return m[1] == null ? md : '${m[1]}-$md';
}

/// Parses `HH:mm`, `H:mm`, `hh:mm AM`, `hh.mm pm` into minutes of the day.
int? parseClock(String s) {
  final m = RegExp(r'^(\d{1,2})[:.](\d{2})\s*([aApP][mM])?$')
      .firstMatch(s.trim());
  if (m == null) return null;
  var h = int.parse(m[1]!);
  final min = int.parse(m[2]!);
  if (min > 59) return null;
  final ampm = m[3]?.toLowerCase();
  if (ampm != null) {
    if (h < 1 || h > 12) return null;
    h = h % 12 + (ampm == 'pm' ? 12 : 0);
  } else if (h > 23) {
    return null;
  }
  return h * 60 + min;
}

String formatClock24(int minutes) =>
    '${_two(minutes ~/ 60)}:${_two(minutes % 60)}';

int? parseUtcOffset(String s) {
  final m = RegExp(r'^(?:UTC|GMT)?\s*([+-])(\d{1,2})(?::?(\d{2}))?$')
      .firstMatch(s.trim());
  if (m == null) return null;
  final v = int.parse(m[2]!) * 60 + int.parse(m[3] ?? '0');
  if (v > 14 * 60) return null;
  return m[1] == '-' ? -v : v;
}

String formatUtcOffset(int minutes) {
  final sign = minutes < 0 ? '-' : '+';
  final a = minutes.abs();
  return '$sign${_two(a ~/ 60)}:${_two(a % 60)}';
}
