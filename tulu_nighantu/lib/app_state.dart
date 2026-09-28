import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'lipi/stroke_guide.dart';
import 'lipi/tulu_lipi.dart';
import 'models/word.dart';
import 'translate/translator.dart';

/// Global app state: word list, favourites and tracing progress.
class AppState extends ChangeNotifier {
  AppState._();

  /// The singleton instance.
  static final AppState instance = AppState._();

  static const _favKey = 'favourites';
  static const _starsKey = 'stars';

  SharedPreferences? _prefs;

  List<WordCategory> categories = const [];
  List<Word> words = const [];
  String dataNote = '';
  final Set<String> favourites = {};
  final Map<String, int> stars = {};

  /// Loads the bundled word list and persisted user data.
  Future<void> load() async {
    final raw = await rootBundle.loadString('assets/data/words.json');
    loadFromJson(raw);
    await StrokeGuide.load();
    try {
      _prefs = await SharedPreferences.getInstance();
      favourites.addAll(_prefs!.getStringList(_favKey) ?? const []);
      final s = _prefs!.getString(_starsKey);
      if (s != null) {
        (jsonDecode(s) as Map<String, dynamic>).forEach(
          (k, v) => stars[k] = (v as num).toInt().clamp(0, 3),
        );
      }
    } catch (e) {
      debugPrint('Preferences unavailable: $e');
    }
    notifyListeners();
  }

  /// Parses the words.json format. Exposed for tests.
  @visibleForTesting
  void loadFromJson(String raw) {
    final j = jsonDecode(raw) as Map<String, dynamic>;
    dataNote = (j['note'] as String?) ?? '';
    categories = [
      for (final c in j['categories'] as List)
        WordCategory.fromJson(c as Map<String, dynamic>),
    ];
    words = [
      for (final w in j['words'] as List)
        Word.fromJson(w as Map<String, dynamic>),
    ];
  }

  WordCategory? categoryById(String id) {
    for (final c in categories) {
      if (c.id == id) return c;
    }
    return null;
  }

  Word? wordById(String id) {
    for (final w in words) {
      if (w.id == id) return w;
    }
    return null;
  }

  /// Word of the day: a non-phrase word chosen by days since 2024-01-01.
  Word? get wordOfTheDay {
    final pool = words.where((w) => !w.isPhrase).toList();
    if (pool.isEmpty) return null;
    final now = DateTime.now();
    final days = DateTime.utc(
      now.year,
      now.month,
      now.day,
    ).difference(DateTime.utc(2024, 1, 1)).inDays;
    return pool[days % pool.length];
  }

  Translator? _translator;
  List<Word>? _translatorWords;

  /// Dictionary-based Kannada/English → Tulu translator (rebuilt if the
  /// word list changes).
  Translator get translator {
    if (_translator == null || !identical(_translatorWords, words)) {
      _translatorWords = words;
      _translator = Translator(words);
    }
    return _translator!;
  }

  bool isFavourite(String id) => favourites.contains(id);

  void toggleFavourite(String id) {
    if (!favourites.remove(id)) favourites.add(id);
    _save(() => _prefs?.setStringList(_favKey, favourites.toList()));
    notifyListeners();
  }

  List<Word> get favouriteWords =>
      words.where((w) => favourites.contains(w.id)).toList();

  int starsFor(String key) => stars[key] ?? 0;

  /// Stores [value] stars for [key] if it beats the previous best.
  void recordStars(String key, int value) {
    final v = value.clamp(0, 3);
    if (v <= starsFor(key)) return;
    stars[key] = v;
    _save(() => _prefs?.setString(_starsKey, jsonEncode(stars)));
    notifyListeners();
  }

  /// Number of alphabet letters with at least one star.
  int get lettersPractised =>
      kLipiLetters.where((l) => starsFor(l.starKey) > 0).length;

  /// Sum of stars across all alphabet letters.
  int get letterStars =>
      kLipiLetters.fold(0, (sum, l) => sum + starsFor(l.starKey));

  void _save(Future<bool>? Function() op) {
    try {
      op()?.catchError((Object e) {
        debugPrint('Could not save preferences: $e');
        return false;
      });
    } catch (e) {
      debugPrint('Could not save preferences: $e');
    }
  }

  // ---------------------------------------------------------------- search

  static final RegExp _punct = RegExp(r'''[\s.,;:!?'"()\[\]/\-–—…?]+''');
  static final RegExp _enSplit = RegExp(r'[;,/()\s]+');

  /// Normalises Kannada-script text: drops virama, joiners and punctuation.
  static String normalizeKannada(String s) =>
      TuluLipi.normalizeKannada(s).replaceAll('್', '').replaceAll(_punct, '');

  /// Normalises Latin text: lowercase, strip diacritics/punctuation, read
  /// "ee"/"oo" as long ī/ū and collapse doubled letters ("neer" ≈ "nīr",
  /// "appe" ≈ "ape").
  static String normalizeLatin(String s) {
    const from = 'āīūēōṛṝḷṅñṭḍṇśṣṁḥ';
    const to = 'aiueorrlnntdnssmh';
    final buf = StringBuffer();
    for (final ch in s.toLowerCase().split('')) {
      final i = from.indexOf(ch);
      buf.write(i >= 0 ? to[i] : ch);
    }
    return buf
        .toString()
        .replaceAll(RegExp(r'[^a-z0-9]'), '')
        .replaceAll('ee', 'i')
        .replaceAll('oo', 'u')
        .replaceAllMapped(RegExp(r'([a-z])\1+'), (m) => m[1]!);
  }

  static int? _matchScore(String target, String q) {
    if (q.isEmpty || target.isEmpty) return null;
    if (target == q) return 0;
    if (target.startsWith(q)) return 1;
    if (target.contains(q)) return 3;
    return null;
  }

  /// Searches the dictionary. Empty [query] returns the category's words
  /// (or all words when [category] is null).
  List<Word> search(String query, {String? category}) {
    final pool = category == null
        ? words
        : words.where((w) => w.cat == category).toList();
    final q = query.trim();
    if (q.isEmpty) return pool;

    final scored = <(Word, int)>[];
    if (TuluLipi.hasKannada(q)) {
      final nq = normalizeKannada(q);
      if (nq.isEmpty) return const [];
      for (final w in pool) {
        final a = _matchScore(normalizeKannada(w.tulu), nq);
        final b = _matchScore(normalizeKannada(w.kn), nq);
        final best = [?a, if (b != null) b + 1];
        if (best.isNotEmpty) {
          scored.add((w, best.reduce((x, y) => x < y ? x : y)));
        }
      }
    } else {
      final nq = normalizeLatin(q);
      final lq = q.toLowerCase();
      if (nq.isEmpty) return const [];
      for (final w in pool) {
        final cands = <int>[];
        final r = _matchScore(normalizeLatin(w.roman), nq);
        if (r != null) cands.add(r);
        final en = w.en.toLowerCase();
        if (en == lq) {
          cands.add(1);
        } else {
          for (final part in en.split(_enSplit)) {
            final s = _matchScore(part, lq);
            if (s != null) cands.add(s == 0 ? 1 : s + 2);
          }
        }
        if (cands.isNotEmpty) {
          scored.add((w, cands.reduce((x, y) => x < y ? x : y)));
        }
      }
    }
    scored.sort((a, b) {
      final c = a.$2.compareTo(b.$2);
      return c != 0 ? c : a.$1.tulu.length.compareTo(b.$1.tulu.length);
    });
    return [for (final s in scored) s.$1];
  }
}
