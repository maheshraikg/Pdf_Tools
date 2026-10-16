/// Plans Azan / Iqama / reminder notifications and auto-silent windows.
/// Pure Dart so it can be unit tested; the app turns the plan into Android
/// alarms.
library;

import 'day.dart';
import 'prayer_calc.dart';

enum AlertKind { reminder, azan, iqama }

/// Alert settings of one fard prayer.
class PrayerAlert {
  const PrayerAlert({
    this.azan = true,
    this.iqama = true,
    this.iqamaDelay = 15,
    this.reminderMinutes = 0,
    this.fixedIqama,
  });

  final bool azan;
  final bool iqama;

  /// Minutes from Azan to Iqama.
  final int iqamaDelay;

  /// Minutes before Azan for a reminder (0 = off).
  final int reminderMinutes;

  /// Fixed local Iqama time (minutes after midnight), as many mosques
  /// announce; null = [iqamaDelay] after Azan.
  final int? fixedIqama;

  PrayerAlert copyWith({
    bool? azan,
    bool? iqama,
    int? iqamaDelay,
    int? reminderMinutes,
    Object? fixedIqama = _keep,
  }) => PrayerAlert(
    azan: azan ?? this.azan,
    iqama: iqama ?? this.iqama,
    iqamaDelay: iqamaDelay ?? this.iqamaDelay,
    reminderMinutes: reminderMinutes ?? this.reminderMinutes,
    fixedIqama: identical(fixedIqama, _keep)
        ? this.fixedIqama
        : fixedIqama as int?,
  );

  Map<String, dynamic> toJson() => {
    'azan': azan,
    'iqama': iqama,
    'delay': iqamaDelay,
    'reminder': reminderMinutes,
    if (fixedIqama != null) 'fixed': fixedIqama,
  };

  factory PrayerAlert.fromJson(Map<String, dynamic> j, PrayerAlert d) =>
      PrayerAlert(
        azan: j['azan'] as bool? ?? d.azan,
        iqama: j['iqama'] as bool? ?? d.iqama,
        iqamaDelay: j['delay'] as int? ?? d.iqamaDelay,
        reminderMinutes: j['reminder'] as int? ?? d.reminderMinutes,
        fixedIqama: j['fixed'] as int?,
      );
}

/// Marks "argument not given" in copyWith for nullable fields.
const Object _keep = Object();

/// How the phone is quietened.
enum SilentMode { vibrate, silent }

class AlertConfig {
  const AlertConfig({
    this.prayers = defaultPrayerAlerts,
    this.jumuahIqamaDelay = 30,
    this.jumuahFixedIqama,
    this.silentEnabled = false,
    this.silentMode = SilentMode.vibrate,
    this.silentMinutesAfterIqama = 20,
    this.jumuahSilentMinutes = 45,
    this.tahajjudAlert = false,
    this.imsakAlert = false,
  });

  final Map<Prayer, PrayerAlert> prayers;

  /// On Friday the Dhuhr Iqama is this long after Azan (khutbah).
  final int jumuahIqamaDelay;

  /// Fixed local Jumu'ah Iqama time (minutes after midnight), or null.
  final int? jumuahFixedIqama;
  final bool silentEnabled;
  final SilentMode silentMode;

  /// The phone stays quiet from Azan until this long after Iqama.
  final int silentMinutesAfterIqama;

  /// On Friday it stays quiet this long after Jumu'ah Iqama.
  final int jumuahSilentMinutes;
  final bool tahajjudAlert;
  final bool imsakAlert;

  static const Map<Prayer, PrayerAlert> defaultPrayerAlerts = {
    Prayer.fajr: PrayerAlert(iqamaDelay: 20),
    Prayer.dhuhr: PrayerAlert(iqamaDelay: 15),
    Prayer.asr: PrayerAlert(iqamaDelay: 15),
    Prayer.maghrib: PrayerAlert(iqamaDelay: 5),
    Prayer.isha: PrayerAlert(iqamaDelay: 15),
  };

  PrayerAlert of(Prayer p) =>
      prayers[p] ?? defaultPrayerAlerts[p] ?? const PrayerAlert();

  int iqamaDelay(Prayer p, bool friday) =>
      p == Prayer.dhuhr && friday ? jumuahIqamaDelay : of(p).iqamaDelay;

  /// Fixed local Iqama time for [p], or null.
  int? fixedIqama(Prayer p, bool friday) =>
      p == Prayer.dhuhr && friday ? jumuahFixedIqama : of(p).fixedIqama;

  AlertConfig copyWith({
    Map<Prayer, PrayerAlert>? prayers,
    int? jumuahIqamaDelay,
    Object? jumuahFixedIqama = _keep,
    bool? silentEnabled,
    SilentMode? silentMode,
    int? silentMinutesAfterIqama,
    int? jumuahSilentMinutes,
    bool? tahajjudAlert,
    bool? imsakAlert,
  }) => AlertConfig(
    prayers: prayers ?? this.prayers,
    jumuahIqamaDelay: jumuahIqamaDelay ?? this.jumuahIqamaDelay,
    jumuahFixedIqama: identical(jumuahFixedIqama, _keep)
        ? this.jumuahFixedIqama
        : jumuahFixedIqama as int?,
    silentEnabled: silentEnabled ?? this.silentEnabled,
    silentMode: silentMode ?? this.silentMode,
    silentMinutesAfterIqama:
        silentMinutesAfterIqama ?? this.silentMinutesAfterIqama,
    jumuahSilentMinutes: jumuahSilentMinutes ?? this.jumuahSilentMinutes,
    tahajjudAlert: tahajjudAlert ?? this.tahajjudAlert,
    imsakAlert: imsakAlert ?? this.imsakAlert,
  );

  AlertConfig withPrayer(Prayer p, PrayerAlert a) =>
      copyWith(prayers: {...prayers, p: a});

  Map<String, dynamic> toJson() => {
    'prayers': {for (final e in prayers.entries) e.key.name: e.value.toJson()},
    'jumuahDelay': jumuahIqamaDelay,
    if (jumuahFixedIqama != null) 'jumuahFixed': jumuahFixedIqama,
    'silent': silentEnabled,
    'silentMode': silentMode.name,
    'silentAfter': silentMinutesAfterIqama,
    'jumuahSilent': jumuahSilentMinutes,
    'tahajjud': tahajjudAlert,
    'imsak': imsakAlert,
  };

  factory AlertConfig.fromJson(Map<String, dynamic> j) {
    const d = AlertConfig();
    final p = (j['prayers'] as Map?)?.cast<String, dynamic>() ?? {};
    return AlertConfig(
      prayers: {
        for (final pr in Prayer.fard)
          pr: p[pr.name] is Map
              ? PrayerAlert.fromJson(
                  (p[pr.name] as Map).cast<String, dynamic>(),
                  d.of(pr),
                )
              : d.of(pr),
      },
      jumuahIqamaDelay: j['jumuahDelay'] as int? ?? d.jumuahIqamaDelay,
      jumuahFixedIqama: j['jumuahFixed'] as int?,
      silentEnabled: j['silent'] as bool? ?? d.silentEnabled,
      silentMode:
          SilentMode.values.asNameMap()[j['silentMode']] ?? d.silentMode,
      silentMinutesAfterIqama:
          j['silentAfter'] as int? ?? d.silentMinutesAfterIqama,
      jumuahSilentMinutes: j['jumuahSilent'] as int? ?? d.jumuahSilentMinutes,
      tahajjudAlert: j['tahajjud'] as bool? ?? d.tahajjudAlert,
      imsakAlert: j['imsak'] as bool? ?? d.imsakAlert,
    );
  }
}

class PlannedAlert {
  const PlannedAlert({
    required this.id,
    required this.at,
    required this.kind,
    required this.prayer,
    required this.friday,
    this.minutesBefore = 0,
  });

  /// Stable notification id.
  final int id;
  final DateTime at;
  final AlertKind kind;
  final Prayer prayer;
  final bool friday;
  final int minutesBefore;

  @override
  String toString() => '${kind.name} ${prayer.name} at $at';
}

class SilentWindow {
  const SilentWindow(this.start, this.end);
  final DateTime start, end;
  @override
  String toString() => 'silent $start → $end';
}

/// Iqama instant of a prayer.
/// A fixed time is used when it falls after Azan (and within 3 hours);
/// otherwise, e.g. when Azan moves past it with the seasons, the delay.
DateTime iqamaTime(PrayerDay d, Prayer p, AlertConfig c) {
  final azan = d[p];
  final fixed = c.fixedIqama(p, d.isFriday);
  if (fixed != null) {
    final at = d.atLocal(fixed);
    if (at.isAfter(azan) && at.difference(azan) <= const Duration(hours: 3)) {
      return at;
    }
  }
  return azan.add(Duration(minutes: c.iqamaDelay(p, d.isFriday)));
}

/// Alerts after [now] for [days], sorted by time.
List<PlannedAlert> planAlerts(
  List<PrayerDay> days,
  AlertConfig config,
  DateTime now,
) {
  final out = <PlannedAlert>[];
  for (var di = 0; di < days.length; di++) {
    final d = days[di];
    void add(AlertKind kind, Prayer p, DateTime at, [int before = 0]) {
      if (!at.isAfter(now)) return;
      out.add(
        PlannedAlert(
          id: 1000 + di * 40 + p.index * 4 + kind.index,
          at: at,
          kind: kind,
          prayer: p,
          friday: d.isFriday,
          minutesBefore: before,
        ),
      );
    }

    for (final p in Prayer.fard) {
      final a = config.of(p);
      if (a.reminderMinutes > 0) {
        add(
          AlertKind.reminder,
          p,
          d[p].subtract(Duration(minutes: a.reminderMinutes)),
          a.reminderMinutes,
        );
      }
      if (a.azan) add(AlertKind.azan, p, d[p]);
      if (a.iqama) add(AlertKind.iqama, p, iqamaTime(d, p, config));
    }
    if (config.imsakAlert) {
      add(AlertKind.reminder, Prayer.imsak, d[Prayer.imsak]);
    }
    if (config.tahajjudAlert) {
      add(AlertKind.reminder, Prayer.tahajjud, d[Prayer.tahajjud]);
    }
  }
  out.sort((a, b) => a.at.compareTo(b.at));
  return out;
}

/// Auto-silent windows (Azan → Iqama + N minutes) ending after [now],
/// merged when they overlap.
List<SilentWindow> planSilent(
  List<PrayerDay> days,
  AlertConfig config,
  DateTime now,
) {
  if (!config.silentEnabled) return const [];
  final raw = <SilentWindow>[];
  for (final d in days) {
    for (final p in Prayer.fard) {
      final friday = p == Prayer.dhuhr && d.isFriday;
      final after = friday
          ? config.jumuahSilentMinutes
          : config.silentMinutesAfterIqama;
      final end = iqamaTime(d, p, config).add(Duration(minutes: after));
      if (end.isAfter(now)) raw.add(SilentWindow(d[p], end));
    }
  }
  raw.sort((a, b) => a.start.compareTo(b.start));
  final merged = <SilentWindow>[];
  for (final w in raw) {
    if (merged.isNotEmpty && !w.start.isAfter(merged.last.end)) {
      final last = merged.removeLast();
      merged.add(
        SilentWindow(last.start, w.end.isAfter(last.end) ? w.end : last.end),
      );
    } else {
      merged.add(w);
    }
  }
  return merged;
}

/// The next fard prayer after [now] (looking into the following days).
({Prayer prayer, DateTime at, PrayerDay day})? nextPrayer(
  List<PrayerDay> days,
  DateTime now,
) {
  for (final d in days) {
    for (final p in Prayer.fard) {
      if (d[p].isAfter(now)) return (prayer: p, at: d[p], day: d);
    }
  }
  return null;
}
