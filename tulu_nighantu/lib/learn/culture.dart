import 'dart:convert';

import 'package:flutter/services.dart';

import '../lipi/tulu_lipi.dart';

/// A festival or tradition of Tulunadu.
class CultureItem {
  const CultureItem({
    required this.id,
    required this.tulu,
    required this.roman,
    required this.en,
    required this.when,
    required this.about,
  });

  factory CultureItem.fromJson(Map<String, dynamic> j) => CultureItem(
    id: j['id'] as String,
    tulu: j['tulu'] as String,
    roman: (j['roman'] as String?) ?? '',
    en: (j['en'] as String?) ?? '',
    when: (j['when'] as String?) ?? '',
    about: (j['about'] as String?) ?? '',
  );

  final String id;
  final String tulu;
  final String roman;
  final String en;
  final String when;
  final String about;

  String get lipi => TuluLipi.fromKannada(tulu);
}

/// A Tulu proverb (ಗಾದೆ) with its meaning.
class Proverb {
  const Proverb({required this.tulu, required this.en, this.kn = ''});

  factory Proverb.fromJson(Map<String, dynamic> j) => Proverb(
    tulu: j['tulu'] as String,
    en: (j['en'] as String?) ?? '',
    kn: (j['kn'] as String?) ?? '',
  );

  final String tulu;
  final String en;
  final String kn;

  String get lipi => TuluLipi.fromKannada(tulu);
}

/// Festivals, traditions and proverbs from `assets/data/culture.json`.
class CultureData {
  const CultureData({required this.festivals, required this.proverbs});

  factory CultureData.fromJson(String raw) {
    final j = jsonDecode(raw) as Map<String, dynamic>;
    return CultureData(
      festivals: [
        for (final f in j['festivals'] as List? ?? const [])
          CultureItem.fromJson(f as Map<String, dynamic>),
      ],
      proverbs: [
        for (final p in j['proverbs'] as List? ?? const [])
          Proverb.fromJson(p as Map<String, dynamic>),
      ],
    );
  }

  static Future<CultureData> load() async => CultureData.fromJson(
    await rootBundle.loadString('assets/data/culture.json'),
  );

  final List<CultureItem> festivals;
  final List<Proverb> proverbs;
}
