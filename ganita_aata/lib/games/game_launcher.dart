import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/game_result.dart';
import '../screens/result_screen.dart';
import '../services/app_state.dart';
import 'balloon_pop_game.dart';
import 'daily_challenge_game.dart';
import 'race_car_game.dart';
import 'speed_challenge_game.dart';
import 'tables_master_screen.dart';
import 'treasure_hunt_game.dart';

/// Opens a game. [topicId] defaults to the child's current topic.
Future<void> startGame(BuildContext context, GameMode mode, {String? topicId, bool replace = false}) {
  final app = context.read<AppState>();
  final topic = topicId ?? app.active!.currentTopic;
  app.beginRound();
  final Widget page = switch (mode) {
    GameMode.balloon => BalloonPopGame(topicId: topic),
    GameMode.race => RaceCarGame(topicId: topic),
    GameMode.treasure => TreasureHuntGame(topicId: topic),
    GameMode.speed => SpeedChallengeGame(topicId: topic),
    GameMode.daily => const DailyChallengeGame(),
    GameMode.tables => const TablesMasterScreen(),
  };
  final route = MaterialPageRoute<void>(builder: (_) => page);
  final nav = Navigator.of(context);
  return replace ? nav.pushReplacement(route) : nav.push(route);
}

/// Applies rewards and replaces the game with the result screen.
void finishGame(BuildContext context, GameResult result, {required void Function(BuildContext context) onReplay}) {
  final summary = context.read<AppState>().finishRound(result);
  Navigator.of(context).pushReplacement(
    MaterialPageRoute<void>(
      builder: (_) => ResultScreen(result: result, summary: summary, onReplay: onReplay),
    ),
  );
}

/// A "Play again" action for [mode] on [topicId].
void Function(BuildContext) replayOf(GameMode mode, String topicId) =>
    (c) => startGame(c, mode, topicId: topicId, replace: true);
