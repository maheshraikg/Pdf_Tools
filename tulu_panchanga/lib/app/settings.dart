import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../panchanga/names.dart';
import '../panchanga/place.dart';

/// User preferences, persisted with shared_preferences.
class AppSettings extends ChangeNotifier {
  AppSettings._(this._prefs);

  final SharedPreferences? _prefs;

  /// In-memory settings (tests, previews).
  AppSettings.memory() : _prefs = null;

  static Future<AppSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    return AppSettings._(prefs).._read();
  }

  Lang lang = Lang.en;
  bool tuluLipi = false;
  Place place = presetPlaces.first;
  PanchangaConfig config = const PanchangaConfig();
  ThemeMode themeMode = ThemeMode.system;

  bool dailyNotification = false;
  int notifyHour = 6;
  int notifyMinute = 0;
  bool festivalReminder = false;
  bool rahuReminder = false;

  int? janmaNakshatra;
  int? janmaRashi;

  void _read() {
    final p = _prefs!;
    lang = Lang.fromCode(p.getString('lang'));
    tuluLipi = p.getBool('tuluLipi') ?? false;
    final placeJson = p.getString('place');
    if (placeJson != null) {
      try {
        place = Place.fromJson(jsonDecode(placeJson) as Map<String, dynamic>);
      } catch (_) {}
    }
    config = PanchangaConfig(
      sunrise:
          SunriseConvention.values.asNameMap()[p.getString('sunrise')] ??
          SunriseConvention.upperLimb,
      solarMonthRule:
          SolarMonthRule.values.asNameMap()[p.getString('monthRule')] ??
          SolarMonthRule.sunset,
      tiePreference:
          TiePreference.values.asNameMap()[p.getString('tie')] ??
          TiePreference.first,
    );
    themeMode =
        ThemeMode.values.asNameMap()[p.getString('theme')] ?? ThemeMode.system;
    dailyNotification = p.getBool('daily') ?? false;
    notifyHour = p.getInt('notifyHour') ?? 6;
    notifyMinute = p.getInt('notifyMinute') ?? 0;
    festivalReminder = p.getBool('festivalReminder') ?? false;
    rahuReminder = p.getBool('rahuReminder') ?? false;
    janmaNakshatra = p.getInt('janmaNakshatra');
    janmaRashi = p.getInt('janmaRashi');
  }

  Future<void> _save() async {
    final p = _prefs;
    notifyListeners();
    if (p == null) return;
    await p.setString('lang', lang.name);
    await p.setBool('tuluLipi', tuluLipi);
    await p.setString('place', jsonEncode(place.toJson()));
    await p.setString('sunrise', config.sunrise.name);
    await p.setString('monthRule', config.solarMonthRule.name);
    await p.setString('tie', config.tiePreference.name);
    await p.setString('theme', themeMode.name);
    await p.setBool('daily', dailyNotification);
    await p.setInt('notifyHour', notifyHour);
    await p.setInt('notifyMinute', notifyMinute);
    await p.setBool('festivalReminder', festivalReminder);
    await p.setBool('rahuReminder', rahuReminder);
    if (janmaNakshatra == null) {
      await p.remove('janmaNakshatra');
    } else {
      await p.setInt('janmaNakshatra', janmaNakshatra!);
    }
    if (janmaRashi == null) {
      await p.remove('janmaRashi');
    } else {
      await p.setInt('janmaRashi', janmaRashi!);
    }
  }

  /// Applies [change] and persists.
  Future<void> update(void Function(AppSettings s) change) {
    change(this);
    return _save();
  }

  /// Whether Kannada-script Tulu text should be shown in Tulu lipi.
  bool get useTuluLipi => lang == Lang.tcy && tuluLipi;
}
