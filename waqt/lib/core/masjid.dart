/// Mosque profiles: each has its own name, a short description, its own
/// Iqama times and its own place and time source (calculation or the
/// mosque's yearly chart); the active one drives the alerts and the display.
library;

import 'alerts.dart';
import 'place.dart';
import 'prayer_calc.dart';

class Masjid {
  const Masjid({
    required this.name,
    this.description = '',
    this.iqama = const {},
    this.jumuahDelay = 30,
    this.jumuahFixed,
    this.adjustments,
    this.source,
  });

  final String name;
  final String description;

  /// Per prayer: minutes after Azan and the optional fixed clock time.
  final Map<Prayer, ({int delay, int? fixed})> iqama;
  final int jumuahDelay;
  final int? jumuahFixed;

  /// This mosque's ± minutes per time (null: older profile, keep current).
  final Map<Prayer, int>? adjustments;

  /// This mosque's place and time source (null: older profile, keep current).
  final MasjidSource? source;

  /// A profile holding the Iqama settings of [c].
  factory Masjid.fromAlerts(
    String name,
    String description,
    AlertConfig c, [
    Map<Prayer, int>? adjustments,
    MasjidSource? source,
  ]) => Masjid(
    adjustments: adjustments == null ? null : Map.of(adjustments),
    source: source,
    name: name,
    description: description,
    iqama: {
      for (final p in Prayer.fard)
        p: (delay: c.of(p).iqamaDelay, fixed: c.of(p).fixedIqama),
    },
    jumuahDelay: c.jumuahIqamaDelay,
    jumuahFixed: c.jumuahFixedIqama,
  );

  /// The same profile with the Iqama settings of [c].
  Masjid withIqamaFrom(
    AlertConfig c, [
    Map<Prayer, int>? adjustments,
    MasjidSource? source,
  ]) => Masjid.fromAlerts(
    name,
    description,
    c,
    adjustments ?? this.adjustments,
    source ?? this.source,
  );

  Masjid copyWith({String? name, String? description}) => Masjid(
    name: name ?? this.name,
    description: description ?? this.description,
    iqama: iqama,
    jumuahDelay: jumuahDelay,
    jumuahFixed: jumuahFixed,
    adjustments: adjustments,
    source: source,
  );

  /// [c] with this mosque's Iqama times (alert switches are kept).
  AlertConfig applyTo(AlertConfig c) {
    var out = c.copyWith(
      jumuahIqamaDelay: jumuahDelay,
      jumuahFixedIqama: jumuahFixed,
    );
    for (final e in iqama.entries) {
      out = out.withPrayer(
        e.key,
        out
            .of(e.key)
            .copyWith(iqamaDelay: e.value.delay, fixedIqama: e.value.fixed),
      );
    }
    return out;
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'description': description,
    'iqama': {
      for (final e in iqama.entries)
        e.key.name: {'delay': e.value.delay, 'fixed': e.value.fixed},
    },
    'jumuahDelay': jumuahDelay,
    'jumuahFixed': jumuahFixed,
    if (adjustments != null)
      'adjust': {for (final e in adjustments!.entries) e.key.name: e.value},
    if (source != null) 'source': source!.toJson(),
  };

  factory Masjid.fromJson(Map<String, dynamic> j) {
    final raw = (j['iqama'] as Map?) ?? const {};
    return Masjid(
      name: j['name'] as String? ?? '',
      description: j['description'] as String? ?? '',
      iqama: {
        for (final e in raw.entries)
          if (Prayer.values.asNameMap()[e.key] != null && e.value is Map)
            Prayer.values.asNameMap()[e.key]!: (
              delay: (e.value as Map)['delay'] as int? ?? 15,
              fixed: (e.value as Map)['fixed'] as int?,
            ),
      },
      jumuahDelay: j['jumuahDelay'] as int? ?? 30,
      jumuahFixed: j['jumuahFixed'] as int?,
      adjustments: j['adjust'] is Map
          ? {
              for (final e in (j['adjust'] as Map).entries)
                if (Prayer.values.asNameMap()[e.key] != null && e.value is int)
                  Prayer.values.asNameMap()[e.key]!: e.value as int,
            }
          : null,
      source: j['source'] is Map
          ? MasjidSource.fromJson((j['source'] as Map).cast<String, dynamic>())
          : null,
    );
  }
}

/// Where a mosque's times come from: its place with a calculation method,
/// or its yearly chart (timetable CSV) when [timetableEnabled].
class MasjidSource {
  const MasjidSource({
    required this.place,
    required this.methodId,
    required this.asr,
    this.timetableCsv,
    this.timetableEnabled = false,
  });

  final Place place;
  final String methodId;
  final AsrMethod asr;
  final String? timetableCsv;
  final bool timetableEnabled;

  Map<String, dynamic> toJson() => {
    'place': place.toJson(),
    'method': methodId,
    'asr': asr.name,
    if (timetableCsv != null) 'timetable': timetableCsv,
    'timetableEnabled': timetableEnabled,
  };

  static MasjidSource? fromJson(Map<String, dynamic> j) {
    if (j['place'] is! Map) return null;
    return MasjidSource(
      place: Place.fromJson((j['place'] as Map).cast<String, dynamic>()),
      methodId: j['method'] as String? ?? 'kerala',
      asr: AsrMethod.values.asNameMap()[j['asr']] ?? AsrMethod.shafii,
      timetableCsv: j['timetable'] as String?,
      timetableEnabled: j['timetableEnabled'] as bool? ?? false,
    );
  }
}
