import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/alerts.dart';
import '../core/day.dart';
import '../core/place.dart';
import '../core/prayer_calc.dart';
import '../core/tasbih.dart';
import '../core/timetable.dart';
import '../core/tracker.dart';

enum Lang {
  en('English'),
  ml('മലയാളം'),
  ar('العربية', rtl: true),
  ur('اردو', rtl: true),
  hi('हिन्दी'),
  ta('தமிழ்'),
  kn('ಕನ್ನಡ'),
  bn('বাংলা'),
  id('Bahasa Indonesia'),
  ms('Bahasa Melayu'),
  tr('Türkçe'),
  fr('Français');

  const Lang(this.nativeName, {this.rtl = false});

  /// Name of the language in itself (for the picker).
  final String nativeName;

  /// Right-to-left script.
  final bool rtl;

  /// ISO 639-1 code (also the Flutter locale).
  String get code => name;

  static Lang? tryCode(String? c) => values.asNameMap()[c];

  static Lang fromCode(String? c) => tryCode(c) ?? en;
}

/// User preferences, persisted with shared_preferences.
class AppSettings extends ChangeNotifier {
  AppSettings._(this._prefs);

  final SharedPreferences? _prefs;

  /// In-memory settings (tests).
  AppSettings.memory() : _prefs = null;

  static Future<AppSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    return AppSettings._(prefs).._read();
  }

  Lang lang = Lang.en;
  ThemeMode themeMode = ThemeMode.system;
  bool use24h = false;
  bool showExtras = true;

  Place place = presetPlaces.firstWhere((p) => p.id == 'kozhikode');

  /// True once the user has picked a place (first-run prompt).
  bool placeChosen = false;

  /// Follow the phone's GPS position (on when "Use my location" is picked).
  bool autoLocation = false;

  /// First-run setup done (existing users who picked a place skip it).
  bool onboarded = true;

  CalcMethod method = CalcMethod.kerala;
  AsrMethod asr = AsrMethod.shafii;
  HighLatitudeRule highLatitude = HighLatitudeRule.angleBased;
  Map<Prayer, int> adjustments = {};
  int imsakMinutes = 10;
  int ishraqMinutes = 15;
  int hijriAdjust = 0;

  AlertConfig alerts = const AlertConfig();

  /// Prayer tracker (saved with the other settings).
  PrayerLog log = PrayerLog();

  TasbihState tasbih = TasbihState();

  /// Mosque display: optional name, the big next-prayer page, seconds per
  /// page and up to [maxAnnouncements] announcement pages.
  String mosqueName = '';
  bool displayNextPage = true;
  int displaySeconds = 12;
  List<String> announcements = [];
  static const int maxAnnouncements = 5;

  /// Pages the mosque display rotates through.
  int get displayPageCount =>
      1 + (displayNextPage ? 1 : 0) + announcements.length;

  /// Imported timetable CSV and whether it is used.
  String? timetableCsv;
  bool timetableEnabled = false;

  Timetable? _timetable;
  String? _timetableParsedFrom;

  /// The active timetable, or null.
  Timetable? get timetable {
    if (!timetableEnabled || timetableCsv == null) return null;
    if (_timetableParsedFrom != timetableCsv) {
      _timetableParsedFrom = timetableCsv;
      try {
        _timetable = Timetable.parse(timetableCsv!);
      } on TimetableFormatException {
        _timetable = null;
      }
    }
    return _timetable;
  }

  CalcParams get params => CalcParams(
    method: method,
    asr: asr,
    highLatitude: highLatitude,
    adjustments: adjustments,
    imsakMinutesBeforeFajr: imsakMinutes,
    ishraqMinutesAfterSunrise: ishraqMinutes,
  );

  DayCalculator? _calc;
  Object? _calcKey;

  /// Calculator for the current settings (cached until they change).
  DayCalculator get calculator {
    final key = Object.hashAll([
      place,
      method.id,
      asr,
      highLatitude,
      jsonEncode({for (final e in adjustments.entries) e.key.name: e.value}),
      imsakMinutes,
      ishraqMinutes,
      hijriAdjust,
      timetableEnabled,
      timetableCsv,
    ]);
    if (_calc == null || _calcKey != key) {
      _calcKey = key;
      _calc = DayCalculator(
        place: place,
        params: params,
        timetable: timetable,
        hijriAdjustDays: hijriAdjust,
      );
    }
    return _calc!;
  }

  /// Minutes east of UTC used to show times (the place's zone, else the
  /// phone's).
  int get displayOffsetMinutes => place.offsetMinutesAt(DateTime.now().toUtc());

  /// Wall-clock time at the place for a UTC instant (as a UTC DateTime whose
  /// fields are the local clock).
  DateTime wall(DateTime utc) =>
      utc.toUtc().add(Duration(minutes: place.offsetMinutesAt(utc.toUtc())));

  /// Today's civil date at the place.
  DateTime get today {
    final w = wall(DateTime.now());
    return DateTime.utc(w.year, w.month, w.day);
  }

  void _read() {
    final p = _prefs!;
    // First run: the phone's language when we have it, else English.
    lang =
        Lang.tryCode(p.getString('lang')) ??
        Lang.fromCode(ui.PlatformDispatcher.instance.locale.languageCode);
    themeMode =
        ThemeMode.values.asNameMap()[p.getString('theme')] ?? ThemeMode.system;
    use24h = p.getBool('use24h') ?? false;
    showExtras = p.getBool('showExtras') ?? true;
    final placeJson = p.getString('place');
    if (placeJson != null) {
      try {
        place = Place.fromJson(jsonDecode(placeJson) as Map<String, dynamic>);
      } catch (_) {}
    }
    placeChosen = p.getBool('placeChosen') ?? false;
    onboarded = p.getBool('onboarded') ?? placeChosen;
    autoLocation = p.getBool('autoLocation') ?? false;
    method = CalcMethod.byId(p.getString('method'));
    asr = AsrMethod.values.asNameMap()[p.getString('asr')] ?? AsrMethod.shafii;
    highLatitude =
        HighLatitudeRule.values.asNameMap()[p.getString('highLat')] ??
        HighLatitudeRule.angleBased;
    final adj = p.getString('adjustments');
    if (adj != null) {
      try {
        final m = (jsonDecode(adj) as Map).cast<String, dynamic>();
        adjustments = {
          for (final e in m.entries)
            if (Prayer.values.asNameMap()[e.key] != null)
              Prayer.values.asNameMap()[e.key]!: e.value as int,
        };
      } catch (_) {}
    }
    imsakMinutes = p.getInt('imsak') ?? 10;
    ishraqMinutes = p.getInt('ishraq') ?? 15;
    hijriAdjust = p.getInt('hijriAdjust') ?? 0;
    final al = p.getString('alerts');
    if (al != null) {
      try {
        alerts = AlertConfig.fromJson(
          (jsonDecode(al) as Map).cast<String, dynamic>(),
        );
      } catch (_) {}
    }
    final tr = p.getString('tracker');
    if (tr != null) {
      try {
        log = PrayerLog.fromJson(
          (jsonDecode(tr) as Map).cast<String, dynamic>(),
        );
      } catch (_) {}
    }
    final tb = p.getString('tasbih');
    if (tb != null) {
      try {
        tasbih = TasbihState.fromJson(
          (jsonDecode(tb) as Map).cast<String, dynamic>(),
        );
      } catch (_) {}
    }
    final disp = p.getString('display');
    if (disp != null) {
      try {
        final j = (jsonDecode(disp) as Map).cast<String, dynamic>();
        mosqueName = j['name'] as String? ?? '';
        displayNextPage = j['nextPage'] as bool? ?? true;
        displaySeconds = j['seconds'] as int? ?? 12;
        announcements = [
          for (final a in (j['announcements'] as List? ?? const []))
            if (a is String && a.trim().isNotEmpty) a,
        ].take(maxAnnouncements).toList();
      } catch (_) {}
    }
    timetableCsv = p.getString('timetable');
    timetableEnabled = p.getBool('timetableEnabled') ?? false;
  }

  Future<void> _save() async {
    final p = _prefs;
    notifyListeners();
    if (p == null) return;
    await p.setString('lang', lang.name);
    await p.setString('theme', themeMode.name);
    await p.setBool('use24h', use24h);
    await p.setBool('showExtras', showExtras);
    await p.setString('place', jsonEncode(place.toJson()));
    await p.setBool('placeChosen', placeChosen);
    await p.setBool('onboarded', onboarded);
    await p.setBool('autoLocation', autoLocation);
    await p.setString('method', method.id);
    await p.setString('asr', asr.name);
    await p.setString('highLat', highLatitude.name);
    await p.setString(
      'adjustments',
      jsonEncode({for (final e in adjustments.entries) e.key.name: e.value}),
    );
    await p.setInt('imsak', imsakMinutes);
    await p.setInt('ishraq', ishraqMinutes);
    await p.setInt('hijriAdjust', hijriAdjust);
    await p.setString('alerts', jsonEncode(alerts.toJson()));
    await p.setString('tracker', jsonEncode(log.toJson(today)));
    await p.setString('tasbih', jsonEncode(tasbih.toJson()));
    await p.setString(
      'display',
      jsonEncode({
        'name': mosqueName,
        'nextPage': displayNextPage,
        'seconds': displaySeconds,
        'announcements': announcements,
      }),
    );
    if (timetableCsv == null) {
      await p.remove('timetable');
    } else {
      await p.setString('timetable', timetableCsv!);
    }
    await p.setBool('timetableEnabled', timetableEnabled);
  }

  bool _quiet = false;

  /// True (once) when the last change does not affect alarms, so they need
  /// not be rescheduled (e.g. ticking a prayer in the tracker).
  bool takeQuietChange() {
    final q = _quiet;
    _quiet = false;
    return q;
  }

  /// Like [update], for changes that do not affect alerts.
  Future<void> updateQuietly(void Function(AppSettings s) change) {
    _quiet = true;
    return update(change);
  }

  /// Applies [change] and persists.
  Future<void> update(void Function(AppSettings s) change) {
    change(this);
    return _save();
  }

  /// Picks [p] and applies its suggested method and Asr school.
  Future<void> choosePlace(Place p, {bool applySuggestions = true}) =>
      update((s) {
        s.place = p;
        s.placeChosen = true;
        s.autoLocation = p.id == 'gps';
        if (applySuggestions) {
          s.method = CalcMethod.byId(p.methodId);
          s.asr = p.asr;
        }
      });
}
