/// App-wide state (settings, progress, content, services) and the
/// inherited widget that exposes it.
library;

import 'dart:convert';

import 'package:flutter/widgets.dart';

import '../game/achievements.dart';
import '../game/audio.dart';
import '../game/daily.dart';
import '../game/progress.dart';
import '../game/saves.dart';
import '../monetization/ads.dart';
import '../monetization/iap.dart';
import '../packs/content.dart';
import 'settings.dart';
import 'storage.dart';

class AppState extends ChangeNotifier {
  AppState({
    required this.store,
    required this.content,
    AudioService? audio,
    AdsService? ads,
    IapService? iap,
    DateTime Function()? clock,
  }) : audio = audio ?? AudioService(),
       ads = ads ?? createAdsService(),
       iap = iap ?? createIapService(),
       clock = clock ?? DateTime.now,
       saves = SaveStore(store) {
    settings = _read('settings', Settings.fromJson) ?? Settings();
    progress = _read('progress', Progress.fromJson) ?? Progress();
    _applyAudio();
    saves.pruneDaily(dayKey(this.clock()));
  }

  final KeyValueStore store;
  final Content content;
  final AudioService audio;
  final AdsService ads;
  final IapService iap;
  final DateTime Function() clock;
  final SaveStore saves;
  late Settings settings;
  late Progress progress;

  T? _read<T>(String key, T Function(Map) parse) {
    final raw = store.getString(key);
    if (raw == null) return null;
    try {
      return parse(jsonDecode(raw) as Map);
    } catch (_) {
      return null;
    }
  }

  DateTime get today {
    final n = clock();
    return DateTime(n.year, n.month, n.day);
  }

  void updateSettings(void Function(Settings s) change) {
    change(settings);
    store.setString('settings', jsonEncode(settings.toJson()));
    _applyAudio();
    notifyListeners();
  }

  void _applyAudio() => audio.configure(
    sfx: settings.sfx,
    music: settings.music,
    volume: settings.volume,
    haptics: settings.haptics,
  );

  Future<void> _saveProgress() =>
      store.setString('progress', jsonEncode(progress.toJson()));

  /// Records a finished puzzle; returns newly unlocked achievement ids and
  /// whether it was a best time.
  ({List<String> achievements, bool best}) complete(Completion c) {
    final best = progress.record(c);
    final fresh = unlockNew(progress, content, today);
    _saveProgress();
    notifyListeners();
    return (achievements: fresh, best: best);
  }

  List<String> markStoryRead(String id) {
    if (!progress.storiesRead.add(id)) return const [];
    final fresh = unlockNew(progress, content, today);
    _saveProgress();
    notifyListeners();
    return fresh;
  }

  List<String> lookSaved() {
    progress.looksSaved++;
    final fresh = unlockNew(progress, content, today);
    _saveProgress();
    notifyListeners();
    return fresh;
  }

  Future<void> resetProgress() async {
    for (final k in store.keys.toList()) {
      if (k != 'settings') await store.remove(k);
    }
    progress = Progress();
    notifyListeners();
  }

  /// A puzzle is playable if it is among the first three of its pack or
  /// the one before it has been finished.
  bool isUnlocked(PuzzleDef p) {
    if (p.index < 3) return true;
    final pack = content.pack(p.packId);
    if (pack == null) return true;
    return progress.completed(pack.puzzles[p.index - 1].id);
  }

  bool optionUnlocked(DressOption o) =>
      o.unlockPuzzle == null || progress.completed(o.unlockPuzzle!);

  DailyPick? get dailyPick => dailyFor(today, content.allPuzzles);

  List<EventDef> get activeEvents => [
    for (final e in content.events)
      if (e.activeOn(today)) e,
  ];

  /// Events in which [puzzleId] is featured today.
  List<String> eventsFeaturing(String puzzleId) => [
    for (final e in activeEvents)
      if (e.featured.contains(puzzleId)) e.id,
  ];

  void notifySaves() => notifyListeners();

  @override
  void dispose() {
    audio.dispose();
    super.dispose();
  }
}

class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child})
    : super(notifier: state);

  static AppState of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;

  /// Reads without subscribing to changes.
  static AppState read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<AppScope>()!.notifier!;
}
