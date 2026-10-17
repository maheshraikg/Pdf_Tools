import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// User preferences. These are not personal data (no names / addresses),
/// so plain SharedPreferences in app-private storage is fine.
class AppSettings extends ChangeNotifier {
  AppSettings(this._prefs);

  final SharedPreferences _prefs;

  static Future<AppSettings> load() async => AppSettings(await SharedPreferences.getInstance());

  T _get<T>(String k, T def) {
    final v = _prefs.get(k);
    return v is T ? v : def;
  }

  Future<void> _set(String k, Object? v) async {
    if (v == null) {
      await _prefs.remove(k);
    } else if (v is bool) {
      await _prefs.setBool(k, v);
    } else if (v is int) {
      await _prefs.setInt(k, v);
    } else if (v is double) {
      await _prefs.setDouble(k, v);
    } else {
      await _prefs.setString(k, v.toString());
    }
    notifyListeners();
  }

  /// null = follow the device language.
  String? get localeCode => _prefs.getString('locale');
  set localeCode(String? v) => _set('locale', v);
  Locale? get locale => localeCode == null ? null : Locale(localeCode!);

  ThemeMode get themeMode =>
      ThemeMode.values.firstWhere((m) => m.name == _get<String>('theme', 'system'), orElse: () => ThemeMode.system);
  set themeMode(ThemeMode m) => _set('theme', m.name);

  /// High-contrast "sunlight mode".
  bool get sunlight => _get('sunlight', false);
  set sunlight(bool v) => _set('sunlight', v);

  /// 1.0 normal, 1.15 large (default), 1.3 extra large.
  double get textScale => _get('textScale', 1.15);
  set textScale(double v) => _set('textScale', v);

  bool get onboarded => _get('onboarded', false);
  set onboarded(bool v) => _set('onboarded', v);

  bool get biometric => _get('biometric', false);
  set biometric(bool v) => _set('biometric', v);

  /// Minutes in background before the app locks again (0 = immediately).
  int get lockTimeoutMin => _get('lockTimeout', 2);
  set lockTimeoutMin(int v) => _set('lockTimeout', v);

  bool get blockScreenshots => _get('blockScreenshots', false);
  set blockScreenshots(bool v) => _set('blockScreenshots', v);

  /// GPS accuracy (metres) accepted automatically when adding a place.
  int get gpsThresholdM => _get('gpsThreshold', 20);
  set gpsThresholdM(int v) => _set('gpsThreshold', v);

  /// 'current' or 'office'.
  String get startMode => _get('startMode', 'current');
  set startMode(String v) => _set('startMode', v);

  double? get officeLat => _prefs.getDouble('officeLat');
  double? get officeLng => _prefs.getDouble('officeLng');
  Future<void> setOffice(double? lat, double? lng) async {
    await _set('officeLat', lat);
    await _set('officeLng', lng);
  }

  int get historyDays => _get('historyDays', 90);
  set historyDays(int v) => _set('historyDays', v);

  bool get tts => _get('tts', false);
  set tts(bool v) => _set('tts', v);

  bool get vibrateNear => _get('vibrateNear', true);
  set vibrateNear(bool v) => _set('vibrateNear', v);

  /// Optional OpenStreetMap view. OFF by default.
  bool get onlineMap => _get('onlineMap', false);
  set onlineMap(bool v) => _set('onlineMap', v);

  /// 'shortest' or 'street'.
  String get routeMode => _get('routeMode', 'shortest');
  set routeMode(String v) => _set('routeMode', v);

  int? get activeBeatId => _prefs.getInt('activeBeat');
  set activeBeatId(int? v) => _set('activeBeat', v);

  int? get lastBackupAt => _prefs.getInt('lastBackup');
  set lastBackupAt(int? v) => _set('lastBackup', v);

  /// Day key of the last time old history was cleaned.
  String? get lastCleanup => _prefs.getString('lastCleanup');
  set lastCleanup(String? v) => _set('lastCleanup', v);

  bool get backupReminderDue {
    final last = lastBackupAt;
    if (last == null) return true;
    return DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(last)).inDays >= 7;
  }

  /// Planned / manually re-ordered stop order (place ids) for a day.
  List<int>? runOrder(String date) => _prefs.getStringList('run_$date')?.map(int.tryParse).whereType<int>().toList();
  Future<void> setRunOrder(String date, List<int> ids) async {
    // Keep only the latest few days.
    for (final k in _prefs.getKeys().where((k) => k.startsWith('run_') && k != 'run_$date').toList()) {
      if (k.compareTo('run_$date') < 0) await _prefs.remove(k);
    }
    await _prefs.setStringList('run_$date', ids.map((e) => '$e').toList());
  }

  Future<void> clearAll() async {
    await _prefs.clear();
    notifyListeners();
  }
}
