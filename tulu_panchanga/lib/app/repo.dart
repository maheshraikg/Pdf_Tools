import 'dart:isolate';

import '../panchanga/engine.dart';
import '../panchanga/festivals.dart';
import '../panchanga/muhurta.dart';
import '../panchanga/place.dart';

/// Caches panchanga results for the current place/conventions. Day data for
/// the visible screen is computed on the UI isolate (a few ms per day);
/// months, festival years and muhurta searches run in a background isolate.
class PanchangaRepo {
  PanchangaRepo(this.place, this.config)
    : engine = PanchangaEngine(place, config);

  final Place place;
  final PanchangaConfig config;
  final PanchangaEngine engine;

  final Map<int, Future<List<FestivalOccurrence>>> _years = {};
  final Map<String, Future<List<DayPanchanga>>> _ranges = {};
  final Map<DateTime, DayPanchanga> _days = {};

  /// Single day (synchronous; cached).
  DayPanchanga day(DateTime date) {
    final d = PanchangaEngine.dateOnly(date);
    return _days[d] ??= engine.day(d);
  }

  /// [count] days from [from], computed in a background isolate.
  Future<List<DayPanchanga>> days(DateTime from, int count) {
    final f = PanchangaEngine.dateOnly(from);
    final key = '${f.toIso8601String()}/$count';
    return _ranges[key] ??= _daysInIsolate(place, config, f, count).then((
      list,
    ) {
      for (final d in list) {
        _days.putIfAbsent(d.date, () => d);
      }
      return list;
    });
  }

  /// Festivals of a Gregorian year (background isolate).
  Future<List<FestivalOccurrence>> festivals(int year) =>
      _years[year] ??= _festivalsInIsolate(place, config, year);

  /// Festivals on [date] (from the year cache).
  Future<List<FestivalOccurrence>> festivalsOn(DateTime date) async {
    final d = PanchangaEngine.dateOnly(date);
    final all = await festivals(d.year);
    return all.where((o) => o.date == d).toList();
  }

  Future<List<MuhurtaWindow>> muhurtas(
    MuhurtaPreset preset,
    DateTime from,
    int count,
    Janma janma,
  ) => _muhurtasInIsolate(place, config, preset, from, count, janma);
}

// Top-level so the isolate closures capture only sendable values.

Future<List<DayPanchanga>> _daysInIsolate(
  Place place,
  PanchangaConfig config,
  DateTime from,
  int count,
) => Isolate.run(() => PanchangaEngine(place, config).days(from, count));

Future<List<FestivalOccurrence>> _festivalsInIsolate(
  Place place,
  PanchangaConfig config,
  int year,
) => Isolate.run(
  () => FestivalCalculator(PanchangaEngine(place, config)).forYear(year),
);

Future<List<MuhurtaWindow>> _muhurtasInIsolate(
  Place place,
  PanchangaConfig config,
  MuhurtaPreset preset,
  DateTime from,
  int count,
  Janma janma,
) => Isolate.run(
  () =>
      MuhurtaFinder(PanchangaEngine(place, config))
          .find(preset, from, count, janma: janma),
);
