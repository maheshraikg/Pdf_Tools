import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'strings.dart';

/// Language and theme, stored in shared_preferences.
class AppSettings extends ChangeNotifier {
  AppSettings._(this._prefs, this._lang, this._theme);

  static Future<AppSettings> load() async {
    final p = await SharedPreferences.getInstance();
    return AppSettings._(
      p,
      Lang.values.asNameMap()[p.getString('lang')] ?? Lang.kn,
      ThemeMode.values.asNameMap()[p.getString('theme')] ?? ThemeMode.system,
    );
  }

  final SharedPreferences _prefs;
  Lang _lang;
  ThemeMode _theme;

  Lang get lang => _lang;
  ThemeMode get themeMode => _theme;

  set lang(Lang v) {
    _lang = v;
    _prefs.setString('lang', v.name);
    notifyListeners();
  }

  set themeMode(ThemeMode v) {
    _theme = v;
    _prefs.setString('theme', v.name);
    notifyListeners();
  }
}
