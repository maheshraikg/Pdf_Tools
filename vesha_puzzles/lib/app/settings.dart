import 'package:flutter/material.dart';

import '../packs/content.dart';

class Settings {
  Settings({
    this.lang = Lang.en,
    this.sfx = true,
    this.music = false,
    this.volume = 0.8,
    this.haptics = true,
    this.ghostByDefault = false,
    this.reduceMotion = false,
    this.themeMode = ThemeMode.system,
    this.guideTips = true,
  });

  Lang lang;
  bool sfx;
  bool music;
  double volume;
  bool haptics;
  bool ghostByDefault;
  bool reduceMotion;
  ThemeMode themeMode;
  bool guideTips;

  Map<String, Object?> toJson() => {
    'lang': lang.name,
    'sfx': sfx,
    'music': music,
    'volume': volume,
    'haptics': haptics,
    'ghost': ghostByDefault,
    'reduceMotion': reduceMotion,
    'theme': themeMode.name,
    'tips': guideTips,
  };

  factory Settings.fromJson(Map json) => Settings(
    lang: LangInfo.parse(json['lang'] as String?),
    sfx: json['sfx'] != false,
    music: json['music'] == true,
    volume: ((json['volume'] as num?) ?? 0.8).toDouble().clamp(0, 1),
    haptics: json['haptics'] != false,
    ghostByDefault: json['ghost'] == true,
    reduceMotion: json['reduceMotion'] == true,
    themeMode: ThemeMode.values.firstWhere(
      (m) => m.name == json['theme'],
      orElse: () => ThemeMode.system,
    ),
    guideTips: json['tips'] != false,
  );
}
