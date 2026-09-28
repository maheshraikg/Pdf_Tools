import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'ai/gemini_client.dart';
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
  static const _customKey = 'custom_words';
  static const _aiKeyKey = 'gemini_api_key';
  static const _aiModelKey = 'gemini_model';

  /// User's Gemini API key (stored only on this phone) and model name.
  String aiKey = '';
  String aiModel = kDefaultGeminiModel;

  bool get hasAiKey => aiKey.trim().isNotEmpty;

  /// Saves the AI settings.
  void setAiSettings({required String key, required String model}) {
    aiKey = key.trim();
    aiModel = model.trim().isEmpty ? kDefaultGeminiModel : model.trim();
    _save(() => _prefs?.setString(_aiKeyKey, aiKey));
    _save(() => _prefs?.setString(_aiModelKey, aiModel));
    notifyListeners();
  }

  /// True when the app was built with the built-in AI server.
  static bool get hasBuiltInAi => kAiProxyUrl.isNotEmpty;

  /// Whether "Ask AI" can work (own key or built-in server).
  bool get hasAi => hasAiKey || hasBuiltInAi;

  /// A Gemini client: the user's own key if set, otherwise the built-in
  /// server; null when neither is available.
  GeminiClient? aiClient() {
    if (hasAiKey) return GeminiClient(apiKey: aiKey, model: aiModel);
    if (hasBuiltInAi) return GeminiClient.proxy(proxyUrl: kAiProxyUrl);
    return null;
  }

  SharedPreferences? _prefs;

  List<WordCategory> categories = const [];

  /// Bundled words followed by the user's own words (new list instance
  /// whenever either changes, so caches keyed on identity refresh).
  List<Word> words = const [];
  List<Word> _bundled = const [];
  List<Word> _custom = const [];
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
      aiKey = _prefs!.getString(_aiKeyKey) ?? '';
      aiModel = _prefs!.getString(_aiModelKey) ?? kDefaultGeminiModel;
      final c = _prefs!.getString(_customKey);
      if (c != null) {
        _custom = [
          for (final w in jsonDecode(c) as List)
            Word.fromJson({...w as Map<String, dynamic>, 'custom': true}),
        ];
        _rebuildWords();
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
    _bundled = [
      for (final w in j['words'] as List)
        Word.fromJson(w as Map<String, dynamic>),
    ];
    _rebuildWords();
  }

  void _rebuildWords() => words = [..._bundled, ..._custom];

  // ------------------------------------------------------- user's own words

  /// Words the user added on this phone.
  List<Word> get customWords => List.unmodifiable(_custom);

  /// Creates an id for a new user word.
  static String newCustomId() => 'u:${DateTime.now().microsecondsSinceEpoch}';

  /// Adds a user word (marked custom) and makes it searchable at once.
  void addCustomWord(Word w) {
    _custom = [..._custom, _asCustom(w)];
    _customChanged();
  }

  /// Replaces the user word with the same id.
  void updateCustomWord(Word w) {
    _custom = [for (final c in _custom) c.id == w.id ? _asCustom(w) : c];
    _customChanged();
  }

  /// Deletes a user word (and its favourite mark).
  void deleteCustomWord(String id) {
    _custom = _custom.where((c) => c.id != id).toList();
    if (favourites.remove(id)) {
      _save(() => _prefs?.setStringList(_favKey, favourites.toList()));
    }
    _customChanged();
  }

  /// The user's words as JSON entries, ready to merge into words.json.
  String exportCustomWords() =>
      const JsonEncoder.withIndent('  ')
          .convert([for (final w in _custom) (w.toJson()..remove('custom'))]);

  static Word _asCustom(Word w) => w.custom
      ? w
      : Word(
          id: w.id,
          tulu: w.tulu,
          roman: w.roman,
          kn: w.kn,
          en: w.en,
          cat: w.cat,
          custom: true,
        );

  void _customChanged() {
    _rebuildWords();
    _save(
      () => _prefs?.setString(
        _customKey,
        jsonEncode([for (final w in _custom) w.toJson()]),
      ),
    );
    notifyListeners();
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
    final pool = _bundled.where((w) => !w.isPhrase).toList();
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

  /// Drops one trailing vowel ("raje" → "raj").
  static String _stem(String s) =>
      s.length > 2 && 'aeiou'.contains(s[s.length - 1])
      ? s.substring(0, s.length - 1)
      : s;

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
        final romanN = normalizeLatin(w.roman);
        final r = _matchScore(romanN, nq);
        if (r != null) {
          cands.add(r);
        } else if (_stem(romanN) == _stem(nq) && nq.length >= 3) {
          // Tulu often ends in -e where Kannada/Hindi end in -a
          // ("raja" ≈ raaje, "anna" ≈ anne): accept a different last vowel.
          cands.add(2);
        }
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
