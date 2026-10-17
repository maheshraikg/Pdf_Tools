import 'package:flutter/foundation.dart';

import 'core/app_lock.dart';
import 'core/article_matcher.dart';
import 'core/address_parser.dart';
import 'core/fuzzy.dart';
import 'core/services/location_service.dart';
import 'core/services/photo_store.dart';
import 'core/services/voice_service.dart';
import 'core/settings.dart';
import 'data/db.dart';
import 'data/models.dart';
import 'data/repos/article_repo.dart';
import 'data/repos/beat_repo.dart';
import 'data/repos/learn_repo.dart';
import 'data/repos/place_repo.dart';

/// Everything the screens need, created once at start-up (or with fakes in
/// widget tests).
class AppServices {
  AppServices({
    required this.database,
    required this.settings,
    required this.lock,
    required this.location,
    required this.photos,
    required this.voice,
  }) : beats = BeatRepo(database.db),
       places = PlaceRepo(database.db),
       articles = ArticleRepo(database.db),
       learn = LearnRepo(database.db);

  final AppDatabase database;
  final AppSettings settings;
  final AppLock lock;
  final LocationService location;
  final PhotoStore photos;
  final VoiceService voice;
  final BeatRepo beats;
  final PlaceRepo places;
  final ArticleRepo articles;
  final LearnRepo learn;
}

/// App-wide state: the active beat and the in-memory search index.
class AppState extends ChangeNotifier {
  AppState(this.s);
  final AppServices s;

  List<Beat> beats = [];
  Beat? activeBeat;
  final SearchIndex index = SearchIndex();
  final Map<int, int> _placeBeat = {};
  final Map<int, String> _placePin = {};
  bool ready = false;

  /// Bumped whenever data changes so screens can reload.
  int version = 0;

  Future<void> init() async {
    await reloadBeats();
    await rebuildIndex();
    await _cleanupHistory();
    ready = true;
    notifyListeners();
  }

  Future<void> reloadBeats() async {
    beats = await s.beats.beats();
    final id = s.settings.activeBeatId;
    activeBeat = beats.where((b) => b.id == id).firstOrNull ?? beats.firstOrNull;
    if (activeBeat != null && activeBeat!.id != id) s.settings.activeBeatId = activeBeat!.id;
    touch();
  }

  void setActiveBeat(Beat b) {
    activeBeat = b;
    s.settings.activeBeatId = b.id;
    touch();
  }

  void touch() {
    version++;
    notifyListeners();
  }

  Future<void> rebuildIndex() async {
    final all = await s.places.allDetails();
    index.clear();
    _placeBeat.clear();
    _placePin.clear();
    for (final d in all) {
      _put(d);
    }
    touch();
  }

  void _put(PlaceDetails d) {
    index.put(searchDocFor(d));
    _placeBeat[d.place.id!] = d.place.beatId;
    _placePin[d.place.id!] = d.place.pin;
  }

  Future<void> placeChanged(int id) async {
    final d = await s.places.details(id);
    if (d == null) {
      placeRemoved(id);
      return;
    }
    _put(d);
    touch();
  }

  void placeRemoved(int id) {
    index.remove(id);
    _placeBeat.remove(id);
    _placePin.remove(id);
    touch();
  }

  int? beatOf(int placeId) => _placeBeat[placeId];

  /// Fuzzy search in the active beat (or all beats).
  List<SearchHit> search(String q, {bool allBeats = false, int limit = 50}) {
    final hits = index.search(q, limit: allBeats ? limit : limit * 4);
    if (allBeats || activeBeat == null) return hits.take(limit).toList();
    return hits.where((h) => _placeBeat[h.id] == activeBeat!.id).take(limit).toList();
  }

  List<MatchSuggestion> match(ParsedAddress parsed, String raw, {bool allBeats = false}) => matchAddress(
    parsed,
    index,
    rawText: raw,
    pinOf: _placePin,
    filter: allBeats || activeBeat == null ? null : (id) => _placeBeat[id] == activeBeat!.id,
  );

  Future<void> _cleanupHistory() async {
    final today = dayKey(DateTime.now());
    if (s.settings.lastCleanup == today) return;
    await s.articles.deleteOlderThan(s.settings.historyDays);
    s.settings.lastCleanup = today;
  }
}
