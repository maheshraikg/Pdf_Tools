/// In-progress games: one save per puzzle (or per daily date).
library;

import 'dart:convert';

import '../app/storage.dart';
import '../jigsaw/board.dart';
import '../jigsaw/cut.dart';

class SavedGame {
  SavedGame({
    required this.key,
    required this.puzzleId,
    required this.difficulty,
    required this.board,
    required this.elapsedMs,
    required this.hints,
    required this.moves,
    required this.savedAt,
  });

  final String key;
  final String puzzleId;
  final Difficulty difficulty;
  final Map<String, Object?> board;
  final int elapsedMs;
  final int hints;
  final int moves;
  final DateTime savedAt;

  /// Fraction of pieces placed.
  double get fraction {
    try {
      final b = JigsawBoard.fromJson(board);
      return b.placedCount / b.cut.count;
    } catch (_) {
      return 0;
    }
  }

  Map<String, Object?> toJson() => {
    'puzzle': puzzleId,
    'difficulty': difficulty.name,
    'board': board,
    'ms': elapsedMs,
    'hints': hints,
    'moves': moves,
    'at': savedAt.toIso8601String(),
  };

  static SavedGame? fromJson(String key, Map json) {
    try {
      return SavedGame(
        key: key,
        puzzleId: json['puzzle'] as String,
        difficulty: DifficultyInfo.parse(json['difficulty'] as String?),
        board: (json['board'] as Map).cast<String, Object?>(),
        elapsedMs: (json['ms'] as num).toInt(),
        hints: (json['hints'] as num).toInt(),
        moves: (json['moves'] as num?)?.toInt() ?? 0,
        savedAt: DateTime.tryParse('${json['at']}') ?? DateTime.now(),
      );
    } catch (_) {
      return null;
    }
  }
}

class SaveStore {
  SaveStore(this.store);
  final KeyValueStore store;
  static const _prefix = 'save.';

  SavedGame? load(String key) {
    final raw = store.getString('$_prefix$key');
    if (raw == null) return null;
    try {
      return SavedGame.fromJson(key, jsonDecode(raw) as Map);
    } catch (_) {
      return null;
    }
  }

  Future<void> save(SavedGame g) =>
      store.setString('$_prefix${g.key}', jsonEncode(g.toJson()));

  Future<void> delete(String key) => store.remove('$_prefix$key');

  bool has(String key) => store.getString('$_prefix$key') != null;

  /// Removes daily saves older than [keepFrom].
  Future<void> pruneDaily(String todayKey) async {
    for (final k in store.keys.toList()) {
      if (k.startsWith('${_prefix}daily-') &&
          k != '${_prefix}daily-$todayKey') {
        await store.remove(k);
      }
    }
  }
}
