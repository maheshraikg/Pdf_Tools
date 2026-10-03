/// Builds flashcards and quiz questions from the active scheme.
library;

import 'dart:math';

import '../../data/models/scheme.dart';
import '../../data/resolver.dart';
import '../../data/scheme_repo.dart';

enum FlashMode { bag, air, hub }

class LearnCard {
  const LearnCard({
    required this.key,
    required this.prompt,
    required this.answer,
    this.answerDetail = '',
    this.prefix,
    this.isPin = true,
    this.category,
  });

  /// Mode the question is asked in (TD / Non-TD); null = any.
  final String? category;

  /// Stable id for Leitner boxes, e.g. "bag:574201".
  final String key;

  /// PIN or place name shown on the card.
  final String prompt;

  /// Bag code / air code / hub route.
  final String answer;
  final String answerDetail;

  /// First three digits (for weak-area stats).
  final String? prefix;
  final bool isPin;
}

class QuizQuestion {
  const QuizQuestion(this.card, this.options);

  final LearnCard card;
  final List<String> options;
}

/// Leitner intervals by box (1 = new / wrong, 5 = well known).
const List<Duration> kLeitnerIntervals = [
  Duration.zero,
  Duration.zero,
  Duration(days: 1),
  Duration(days: 3),
  Duration(days: 7),
  Duration(days: 14),
];

int nextBox(int box, bool correct) => correct ? min(box + 1, 5) : 1;

int dueAfter(int box, DateTime now) => now.add(kLeitnerIntervals[box]).millisecondsSinceEpoch;

class LearnEngine {
  LearnEngine(this.scheme, {Iterable<int> directoryPins = const [], this._regions = const {}, Random? random})
    : _pins = directoryPins.toList()..sort(),
      _rnd = random ?? Random();

  final ActiveScheme scheme;
  final List<int> _pins;
  final Map<int, ({List<String> districts, List<String> states})> _regions;
  final Random _rnd;

  List<int> _pinsIn(int lo, int hi) {
    var a = _lowerBound(lo);
    final out = <int>[];
    while (a < _pins.length && _pins[a] <= hi) {
      out.add(_pins[a++]);
    }
    return out;
  }

  int _lowerBound(int v) {
    var lo = 0, hi = _pins.length;
    while (lo < hi) {
      final m = (lo + hi) >> 1;
      if (_pins[m] < v) {
        lo = m + 1;
      } else {
        hi = m;
      }
    }
    return lo;
  }

  /// Representative PINs for a rule (up to [n]).
  List<int> _samplePins(MatchSpec m, {int n = 2}) {
    List<int> pool;
    switch (m.type) {
      case RuleType.exact:
        return [m.pin!];
      case RuleType.range:
        pool = _pinsIn(m.pinFrom!, m.pinTo!);
        if (pool.isEmpty) pool = {m.pinFrom!, m.pinTo!}.toList();
      case RuleType.prefix:
        final p = m.prefix!;
        pool = _pinsIn(int.parse(p.padRight(6, '0')), int.parse(p.padRight(6, '9')));
      default:
        return const [];
    }
    pool.shuffle(_rnd);
    return pool.take(n).toList();
  }

  ResolveQuery _q(int pin, String? category) {
    final r = _regions[pin];
    return ResolveQuery(pin: pin, districtNorms: r?.districts ?? const [], stateNorms: r?.states ?? const [], category: category);
  }

  List<LearnCard> cards(FlashMode mode, {Set<int>? onlyPins}) {
    final out = <String, LearnCard>{};
    // A card is asked in the mode (TD / Non-TD / …) of the rule it came from.
    void addPin(int pin, [String? category]) {
      final key = '${mode.name}:${category ?? ''}:$pin';
      if (out.containsKey(key)) return;
      final q = _q(pin, category);
      switch (mode) {
        case FlashMode.bag:
          final r = scheme.bagResolver.resolve(q);
          if (r == null || r.level == RuleType.fallback) return;
          final bag = scheme.bagFor(r.rule);
          out[key] = LearnCard(key: key, prompt: '$pin', answer: bag.code, answerDetail: bag.name, prefix: '$pin'.substring(0, 3), category: category);
        case FlashMode.air:
          final r = scheme.airResolver.resolve(q);
          if (r == null) return;
          out[key] = LearnCard(key: key, prompt: '$pin', answer: r.rule.airCode, answerDetail: r.rule.stationName, prefix: '$pin'.substring(0, 3));
        case FlashMode.hub:
          final r = scheme.hubResolver.resolve(q);
          if (r == null) return;
          out[key] = LearnCard(key: key, prompt: '$pin', answer: r.rule.route, answerDetail: r.rule.remarks, prefix: '$pin'.substring(0, 3));
      }
    }

    if (onlyPins != null) {
      for (final p in onlyPins) {
        addPin(p);
      }
      return out.values.toList();
    }
    final rules = switch (mode) {
      FlashMode.bag => scheme.bagResolver.rules,
      FlashMode.air => scheme.airResolver.rules,
      FlashMode.hub => scheme.hubResolver.rules,
    };
    for (final Matchable r in rules) {
      final m = r.match;
      final cat = r.category == null || r.category!.isEmpty ? null : r.category;
      for (final p in _samplePins(m)) {
        addPin(p, cat);
      }
      // Name-based rules: office / district / state prompts.
      final name = switch (r) {
        BagRule b => b.officeName ?? b.district ?? b.state,
        AirCodeRule a => a.district ?? a.state,
        HubRule h => h.officeName ?? h.district ?? h.state,
        _ => null,
      };
      if (name != null && (m.type == RuleType.office || m.type == RuleType.district || m.type == RuleType.state)) {
        final key = '${mode.name}:${cat ?? ''}:${m.key}';
        final answer = switch (r) {
          BagRule b => (scheme.bagFor(b).code, scheme.bagFor(b).name),
          AirCodeRule a => (a.airCode, a.stationName),
          HubRule h => (h.route, h.remarks),
          _ => ('', ''),
        };
        out[key] = LearnCard(key: key, prompt: name, answer: answer.$1, answerDetail: answer.$2, isPin: false, category: cat);
      }
    }
    return out.values.toList();
  }

  /// [count] questions with 4 options each (fewer when the scheme has fewer
  /// distinct answers).
  List<QuizQuestion> quiz(FlashMode mode, {int count = 20}) {
    final all = cards(mode)..shuffle(_rnd);
    final answers = all.map((c) => c.answer).toSet().toList();
    if (answers.length < 2) return const [];
    final picked = <LearnCard>[];
    while (picked.length < count && all.isNotEmpty) {
      picked.addAll(all.take(count - picked.length));
      if (all.length < count) break;
    }
    return [
      for (final c in picked)
        () {
          final others = answers.where((a) => a != c.answer).toList()..shuffle(_rnd);
          final opts = [c.answer, ...others.take(3)]..shuffle(_rnd);
          return QuizQuestion(c, opts);
        }(),
    ];
  }
}
