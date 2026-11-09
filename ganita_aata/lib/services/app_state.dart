import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';

import '../data/app_store.dart';
import '../data/curriculum.dart';
import '../data/shop_catalog.dart';
import '../engine/adaptive_engine.dart';
import '../engine/rewards.dart';
import '../engine/sum_generator.dart';
import '../models/game_result.dart';
import '../models/profile.dart';
import '../models/question.dart';
import '../models/stats.dart';
import 'audio_service.dart';
import 'notification_service.dart';

/// App-wide state: settings, children's profiles and the active child's
/// learning engine. Screens read it with `context.watch<AppState>()`.
class AppState extends ChangeNotifier {
  AppState({
    required this.store,
    required this.audio,
    required this.notifications,
    DateTime Function()? clock,
    Random? random,
  }) : _clock = clock ?? DateTime.now,
       _rng = random ?? Random() {
    _load();
  }

  final AppStore store;
  final AudioService audio;
  final NotificationService notifications;
  final DateTime Function() _clock;
  final Random _rng;

  // ---------------------------------------------------------------- settings
  late String _lang;
  late bool _languageChosen;
  late bool _soundOn;
  late bool _reminderOn;
  late int _reminderMinutes;
  String? _pinHash;
  String? _pinSalt;

  Locale get locale => Locale(_lang);
  String get lang => _lang;
  bool get languageChosen => _languageChosen;
  bool get soundOn => _soundOn;
  bool get reminderOn => _reminderOn;
  TimeOfDay get reminderTime => TimeOfDay(hour: _reminderMinutes ~/ 60, minute: _reminderMinutes % 60);
  bool get hasPin => _pinHash != null;

  // ---------------------------------------------------------------- profiles
  final List<Profile> _profiles = [];
  Profile? _active;
  AdaptiveEngine? _engine;

  List<Profile> get profiles => List.unmodifiable(_profiles);
  Profile? get active => _active;
  AdaptiveEngine get engine => _engine!;
  DateTime get now => _clock();

  void _load() {
    final s = store.loadSettings();
    _lang = s['lang'] as String? ?? 'kn';
    _languageChosen = s['langChosen'] as bool? ?? false;
    _soundOn = s['sound'] as bool? ?? true;
    _reminderOn = s['reminder'] as bool? ?? false;
    _reminderMinutes = s['reminderMin'] as int? ?? 17 * 60;
    _pinHash = s['pinHash'] as String?;
    _pinSalt = s['pinSalt'] as String?;
    audio.enabled = _soundOn;
    _profiles
      ..clear()
      ..addAll(store.loadProfiles());
    final activeId = s['activeProfile'] as String?;
    final a = _profiles.where((p) => p.id == activeId).firstOrNull ?? _profiles.firstOrNull;
    if (a != null) _activate(a);
  }

  void _activate(Profile p) {
    _active = p;
    _engine = AdaptiveEngine(profileId: p.id, store: store, unlocked: p.unlocked, clock: _clock, random: _rng);
    store.saveSetting('activeProfile', p.id);
  }

  /// Re-schedules the reminder (call once at start-up).
  Future<void> syncReminder() async {
    if (_reminderOn) {
      await notifications.scheduleDaily(hour: reminderTime.hour, minute: reminderTime.minute, locale: locale);
    }
  }

  void setLanguage(String lang) {
    _lang = lang;
    _languageChosen = true;
    store.saveSetting('lang', lang);
    store.saveSetting('langChosen', true);
    notifyListeners();
    syncReminder();
  }

  void setSound(bool on) {
    _soundOn = on;
    audio.enabled = on;
    store.saveSetting('sound', on);
    notifyListeners();
  }

  /// Turns the reminder on/off. Returns false if notification permission was
  /// refused.
  Future<bool> setReminder(bool on, [TimeOfDay? time]) async {
    if (time != null) {
      _reminderMinutes = time.hour * 60 + time.minute;
      store.saveSetting('reminderMin', _reminderMinutes);
    }
    var ok = true;
    if (on) ok = await notifications.requestPermission();
    _reminderOn = on;
    store.saveSetting('reminder', on);
    notifyListeners();
    if (on) {
      await syncReminder();
    } else {
      await notifications.cancelDaily();
    }
    return ok;
  }

  // --------------------------------------------------------------------- PIN
  String _hash(String pin, String salt) => sha256.convert(utf8.encode('$salt:$pin')).toString();

  void setPin(String pin) {
    final salt = base64Url.encode(List.generate(12, (_) => _rng.nextInt(256)));
    _pinSalt = salt;
    _pinHash = _hash(pin, salt);
    store.saveSetting('pinSalt', salt);
    store.saveSetting('pinHash', _pinHash);
    notifyListeners();
  }

  bool checkPin(String pin) => _pinHash != null && _hash(pin, _pinSalt ?? '') == _pinHash;

  // ---------------------------------------------------------------- profiles
  Profile createProfile({required String name, required int schoolClass, required String avatar}) {
    final unlocked = Curriculum.initialUnlocked(schoolClass);
    final level = Curriculum.levelForClass(schoolClass);
    final p = Profile(
      id: '${_clock().microsecondsSinceEpoch}${_rng.nextInt(1000)}',
      name: name.trim(),
      schoolClass: schoolClass,
      avatar: avatar,
      unlocked: unlocked,
      currentTopic: Curriculum.level(level).topics.first.id,
    );
    _profiles.add(p);
    store.saveProfile(p);
    _activate(p);
    notifyListeners();
    return p;
  }

  void updateProfile(Profile p, {String? name, int? schoolClass, String? avatar}) {
    if (name != null) p.name = name.trim();
    if (avatar != null) p.avatar = avatar;
    if (schoolClass != null && schoolClass != p.schoolClass) {
      p.schoolClass = schoolClass;
      p.unlocked.addAll(Curriculum.initialUnlocked(schoolClass));
    }
    store.saveProfile(p);
    notifyListeners();
  }

  void switchProfile(Profile p) {
    _activate(p);
    notifyListeners();
  }

  Future<void> deleteProfile(Profile p) async {
    _profiles.removeWhere((x) => x.id == p.id);
    await store.deleteProfile(p.id);
    if (_active?.id == p.id) {
      _active = null;
      _engine = null;
      if (_profiles.isNotEmpty) _activate(_profiles.first);
    }
    notifyListeners();
  }

  /// Clears the active child's scores, coins, badges, shop items and unlocks.
  Future<void> resetProgress() async {
    final p = _active;
    if (p == null) return;
    await engine.reset();
    p
      ..coins = 0
      ..owned.clear()
      ..badges.clear()
      ..speedBest.clear()
      ..streak = 0
      ..lastDailyDate = null
      ..carColor = 'car_red'
      ..balloonTheme = 'theme_rainbow'
      ..unlocked.clear()
      ..unlocked.addAll(Curriculum.initialUnlocked(p.schoolClass))
      ..currentTopic = Curriculum.level(Curriculum.levelForClass(p.schoolClass)).topics.first.id;
    if (!ShopCatalog.byId(p.avatar).isFree) p.avatar = ShopCatalog.freeAvatars.first.id;
    store.saveProfile(p);
    notifyListeners();
  }

  void setCurrentTopic(String topicId) {
    final p = _active!;
    p.currentTopic = topicId;
    store.saveProfile(p);
    notifyListeners();
  }

  bool isUnlocked(String topicId) => _active?.unlocked.contains(topicId) ?? false;

  bool isLevelUnlocked(int level) => Curriculum.level(level).topics.any((t) => isUnlocked(t.id));

  // ------------------------------------------------------------------- play
  final List<String> _roundUnlocks = [];

  /// Starts collecting unlocks for a new round.
  void beginRound() => _roundUnlocks.clear();

  /// Records one answer in the adaptive engine.
  AnswerOutcome recordAnswer(Question q, bool correct, int timeMs) {
    final o = engine.record(q, correct, timeMs);
    if (o.unlockedTopic != null) {
      _roundUnlocks.add(o.unlockedTopic!);
      store.saveProfile(_active!);
    }
    return o;
  }

  /// Next adaptive question for [topicId].
  Question nextQuestion(String topicId) => engine.next(topicId);

  /// Four shuffled answer choices.
  List<Answer> optionsFor(Question q) => engine.generator.options(q);

  /// The level used for today's Daily Challenge.
  int get dailyLevel => Curriculum.levelForClass(_active?.schoolClass ?? 1);

  List<Question> get dailyQuestions => SumGenerator.dailyChallenge(_clock(), dailyLevel);

  bool get dailyDoneToday => _active?.lastDailyDate == dayKey(_clock());

  int get currentStreak {
    final p = _active;
    if (p == null) return 0;
    return Streak.current(
      streak: p.streak,
      lastDay: p.lastDailyDate == null ? null : parseDayKey(p.lastDailyDate!),
      today: _clock(),
    );
  }

  /// Applies stars, coins, streak and badges for a finished round.
  RoundSummary finishRound(GameResult r) {
    final p = _active!;
    final stars = Rewards.stars(r.correct, r.total);
    var coins = Rewards.coins(r.correct, stars) + r.chests * Rewards.chestCoins;
    if (r.raceWon == true) coins += Rewards.raceWinBonus;
    p.coins += coins;

    int? streak;
    if (r.mode == GameMode.daily && r.total > 0) {
      final s = Streak.afterCompletion(
        streak: p.streak,
        lastDay: p.lastDailyDate == null ? null : parseDayKey(p.lastDailyDate!),
        today: _clock(),
      );
      if (s != null) {
        p.streak = s;
        p.lastDailyDate = dayKey(_clock());
        streak = s;
      }
    }

    var newBest = false;
    int? best;
    if (r.mode == GameMode.speed) {
      final old = p.speedBest[r.topicId] ?? 0;
      if (r.correct > old) {
        p.speedBest[r.topicId] = r.correct;
        newBest = old > 0 || r.correct > 0;
      }
      best = p.speedBest[r.topicId] ?? 0;
    }

    final badges = _checkBadges(r);
    store.saveProfile(p);
    final unlocks = List.of(_roundUnlocks);
    _roundUnlocks.clear();
    notifyListeners();
    return RoundSummary(
      stars: stars,
      coins: coins,
      newBadges: badges,
      unlockedTopics: unlocks,
      newBest: newBest,
      best: best,
      streak: streak,
    );
  }

  List<String> _checkBadges(GameResult r) {
    final p = _active!;
    final earned = <String>[];
    void award(String id) {
      if (p.badges.add(id)) earned.add(id);
    }

    if (r.mode == GameMode.speed && r.correct >= Rewards.speedStarScore) award(Badges.speedStar);
    if (engine.sumsOn(_clock()) >= Rewards.sumsInADay) award(Badges.day100);
    if (p.streak >= 7 && currentStreak >= 7) award(Badges.streak7);
    if (p.streak >= 30 && currentStreak >= 30) award(Badges.streak30);
    final tables = <int>{
      for (final i in r.items)
        if (i.question.op == Op.mul && i.question.a >= 2 && i.question.a <= 20 && i.question.b <= 10) i.question.a,
    };
    for (final t in tables) {
      if (engine.isTableMastered(t)) award(Badges.table(t));
    }
    return earned;
  }

  // ------------------------------------------------------------------- shop
  bool owns(ShopItem i) => i.isFree || (_active?.owned.contains(i.id) ?? false);

  bool isEquipped(ShopItem i) {
    final p = _active;
    if (p == null) return false;
    return switch (i.kind) {
      ShopKind.avatar => p.avatar == i.id,
      ShopKind.car => p.carColor == i.id,
      ShopKind.balloon => p.balloonTheme == i.id,
    };
  }

  /// Buys [i] if the child has enough coins. Returns true on success.
  bool buy(ShopItem i) {
    final p = _active!;
    if (owns(i) || p.coins < i.price) return false;
    p.coins -= i.price;
    p.owned.add(i.id);
    equip(i);
    return true;
  }

  void equip(ShopItem i) {
    final p = _active!;
    if (!owns(i)) return;
    switch (i.kind) {
      case ShopKind.avatar:
        p.avatar = i.id;
      case ShopKind.car:
        p.carColor = i.id;
      case ShopKind.balloon:
        p.balloonTheme = i.id;
    }
    store.saveProfile(p);
    notifyListeners();
  }
}
