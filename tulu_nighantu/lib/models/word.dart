import '../lipi/tulu_lipi.dart';

/// A dictionary category (e.g. family, food, phrases).
class WordCategory {
  const WordCategory({required this.id, required this.kn, required this.en});

  factory WordCategory.fromJson(Map<String, dynamic> j) => WordCategory(
    id: j['id'] as String,
    kn: j['kn'] as String,
    en: j['en'] as String,
  );

  final String id;
  final String kn;
  final String en;
}

/// A single dictionary entry.
class Word {
  Word({
    required this.id,
    required this.tulu,
    required this.roman,
    required this.kn,
    required this.en,
    required this.cat,
  }) : lipi = TuluLipi.fromKannada(tulu);

  factory Word.fromJson(Map<String, dynamic> j) => Word(
    id: j['id'] as String,
    tulu: j['tulu'] as String,
    roman: (j['roman'] as String?) ?? '',
    kn: (j['kn'] as String?) ?? '',
    en: (j['en'] as String?) ?? '',
    cat: (j['cat'] as String?) ?? 'words',
  );

  final String id;

  /// Tulu word written in Kannada script.
  final String tulu;

  /// Romanised Tulu.
  final String roman;

  /// Kannada meaning.
  final String kn;

  /// English meaning.
  final String en;

  /// Category id.
  final String cat;

  /// Tulu word in Tulu-Tigalari script (derived).
  final String lipi;

  /// Whether this entry is a sentence/phrase.
  bool get isPhrase => cat == 'phrases';

  /// Key used to store tracing stars.
  String get starKey => 'W:$id';
}
