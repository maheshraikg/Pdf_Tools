import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'constants.dart';

/// User preferences, persisted with shared_preferences (local only).
class Settings extends ChangeNotifier {
  Settings._(this._prefs);

  final SharedPreferences _prefs;

  static Future<Settings> load() async => Settings._(await SharedPreferences.getInstance());

  /// null = follow the device language (fallback English).
  Locale? get locale {
    final code = _prefs.getString('locale');
    return code == null || code.isEmpty ? null : Locale(code);
  }

  set locale(Locale? l) {
    if (l == null) {
      _prefs.remove('locale');
    } else {
      _prefs.setString('locale', l.languageCode);
    }
    notifyListeners();
  }

  ThemeMode get themeMode => ThemeMode.values.firstWhere(
    (m) => m.name == _prefs.getString('themeMode'),
    orElse: () => ThemeMode.system,
  );

  set themeMode(ThemeMode m) {
    _prefs.setString('themeMode', m.name);
    notifyListeners();
  }

  /// Keypad key height multiplier: 0.8 (compact) … 1.4 (extra large).
  double get keypadScale => _prefs.getDouble('keypadScale') ?? 1.0;

  set keypadScale(double v) {
    _prefs.setDouble('keypadScale', v);
    notifyListeners();
  }

  bool get ttsEnabled => _prefs.getBool('tts') ?? false;

  set ttsEnabled(bool v) {
    _prefs.setBool('tts', v);
    notifyListeners();
  }

  bool get hapticsEnabled => _prefs.getBool('haptics') ?? true;

  set hapticsEnabled(bool v) {
    _prefs.setBool('haptics', v);
    notifyListeners();
  }

  /// Last mail category chosen on the Sort screen.
  String get category => _prefs.getString('category') ?? kCatTD;

  set category(String v) {
    _prefs.setString('category', v);
    notifyListeners();
  }

  bool get showMismatchField => _prefs.getBool('mismatchField') ?? false;

  set showMismatchField(bool v) {
    _prefs.setBool('mismatchField', v);
    notifyListeners();
  }
}
