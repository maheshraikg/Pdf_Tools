// ignore_for_file: avoid_print

// Prints a year of calculated times as timetable CSV, to compare against a
// printed chart (or to make a starting timetable for a mosque).
//
//   dart run tool/print_times.dart <lat> <lng> <utcOffsetMinutes> [year] [method] [asr]
//   dart run tool/print_times.dart 11.2588 75.7804 330 2026 kerala shafii
import 'package:waqt/core/day.dart';
import 'package:waqt/core/place.dart';
import 'package:waqt/core/prayer_calc.dart';
import 'package:waqt/core/timetable.dart';

void main(List<String> args) {
  if (args.length < 3) {
    print('usage: <lat> <lng> <utcOffsetMinutes> [year] [method] [asr]');
    return;
  }
  final lat = double.parse(args[0]), lng = double.parse(args[1]);
  final offset = int.parse(args[2]);
  final year = args.length > 3 ? int.parse(args[3]) : DateTime.now().year;
  final method = CalcMethod.byId(args.length > 4 ? args[4] : 'kerala');
  final asr =
      AsrMethod.values.asNameMap()[args.length > 5 ? args[5] : ''] ??
      AsrMethod.shafii;
  final calc = DayCalculator(
    place: Place(
      id: 'cli',
      name: 'cli',
      latitude: lat,
      longitude: lng,
      utcOffsetMinutes: offset,
    ),
    params: CalcParams(method: method, asr: asr),
  );
  print('# name: $lat,$lng ${method.id} ${asr.name}');
  print('# utc_offset: ${formatUtcOffset(offset)}');
  print('date,${timetableColumns.join(',')}');
  final cols = [
    Prayer.fajr,
    Prayer.sunrise,
    Prayer.dhuhr,
    Prayer.asr,
    Prayer.maghrib,
    Prayer.isha,
  ];
  for (
    var d = DateTime.utc(year);
    d.year == year;
    d = d.add(const Duration(days: 1))
  ) {
    final day = calc.day(d.year, d.month, d.day);
    final local = cols.map((p) {
      final t = day[p].add(Duration(minutes: offset));
      return formatClock24(t.hour * 60 + t.minute);
    });
    print('$year-${_two(d.month)}-${_two(d.day)},${local.join(',')}');
  }
}

String _two(int v) => v.toString().padLeft(2, '0');
