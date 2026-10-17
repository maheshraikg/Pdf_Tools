/// Mosque profiles: each has its own name, a short description and its
/// own Iqama times; the active one drives the alerts and the display.
library;

import 'alerts.dart';
import 'prayer_calc.dart';

class Masjid {
  const Masjid({
    required this.name,
    this.description = '',
    this.iqama = const {},
    this.jumuahDelay = 30,
    this.jumuahFixed,
    this.adjustments,
  });

  final String name;
  final String description;

  /// Per prayer: minutes after Azan and the optional fixed clock time.
  final Map<Prayer, ({int delay, int? fixed})> iqama;
  final int jumuahDelay;
  final int? jumuahFixed;

  /// This mosque's ± minutes per time (null: older profile, keep current).
  final Map<Prayer, int>? adjustments;

  /// A profile holding the Iqama settings of [c].
  factory Masjid.fromAlerts(
    String name,
    String description,
    AlertConfig c, [
    Map<Prayer, int>? adjustments,
  ]) => Masjid(
    adjustments: adjustments == null ? null : Map.of(adjustments),
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
  Masjid withIqamaFrom(AlertConfig c, [Map<Prayer, int>? adjustments]) =>
      Masjid.fromAlerts(name, description, c, adjustments ?? this.adjustments);

  Masjid copyWith({String? name, String? description}) => Masjid(
    name: name ?? this.name,
    description: description ?? this.description,
    iqama: iqama,
    jumuahDelay: jumuahDelay,
    jumuahFixed: jumuahFixed,
    adjustments: adjustments,
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
    );
  }
}
