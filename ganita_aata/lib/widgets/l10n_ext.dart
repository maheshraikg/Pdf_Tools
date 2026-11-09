import 'dart:math';

import 'package:flutter/widgets.dart';

import '../data/shop_catalog.dart';
import '../engine/rewards.dart';
import '../l10n/app_localizations.dart';
import '../models/game_result.dart';
import '../models/question.dart';

extension L10nContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

final _rng = Random();

extension AppStrings on AppLocalizations {
  String topicName(String id) => switch (id) {
    'num100' => topic_num100,
    'add1' => topic_add1,
    'sub1' => topic_sub1,
    'add2' => topic_add2,
    'sub2' => topic_sub2,
    'tab2_5' => topic_tab2_5,
    'tab6_10' => topic_tab6_10,
    'add3' => topic_add3,
    'sub3' => topic_sub3,
    'div1' => topic_div1,
    'tab11_20' => topic_tab11_20,
    'mul21' => topic_mul21,
    'divRem' => topic_divRem,
    'mixed' => topic_mixed,
    'squares' => topic_squares,
    'cubes' => topic_cubes,
    'percent' => topic_percent,
    'fractions' => topic_fractions,
    _ => id,
  };

  String gameName(GameMode m) => switch (m) {
    GameMode.balloon => gameBalloon,
    GameMode.race => gameRace,
    GameMode.treasure => gameTreasure,
    GameMode.tables => gameTables,
    GameMode.speed => gameSpeed,
    GameMode.daily => dailyChallenge,
  };

  String gameDesc(GameMode m) => switch (m) {
    GameMode.balloon => gameBalloonDesc,
    GameMode.race => gameRaceDesc,
    GameMode.treasure => gameTreasureDesc,
    GameMode.tables => gameTablesDesc,
    GameMode.speed => gameSpeedDesc,
    GameMode.daily => dailyChallengeDesc,
  };

  /// "3 R 2" for division with remainder, otherwise the number.
  String answerText(Answer a) => a.remainder == null ? '${a.value}' : '${a.value} $remainderShort ${a.remainder}';

  /// The question as shown in a game, e.g. "7 × 8 = ?" or a sentence.
  String questionText(Question q) {
    switch (q.op) {
      case Op.after:
        return qAfter(q.a);
      case Op.before:
        return qBefore(q.a);
      case Op.tenMore:
        return '${qTenMore(q.a)} = ?';
      case Op.tenLess:
        return '${qTenLess(q.a)} = ?';
      case Op.percent:
        return '${qPercentOf(q.a, q.b)} = ?';
      case Op.fracOf:
        return '${qFractionOf('${q.a}/${q.b}', q.c)} = ?';
      case Op.fracAdd:
        return '${q.a}/${q.c} + ${q.b}/${q.c} = ?/${q.c}';
      default:
        return '${q.expression} = ?';
    }
  }

  /// The question with its answer, e.g. "7 × 8 = 56".
  String solvedText(Question q) {
    final ans = answerText(q.answer);
    switch (q.op) {
      case Op.after:
      case Op.before:
        return '${questionText(q)} → $ans';
      case Op.fracAdd:
        return '${q.a}/${q.c} + ${q.b}/${q.c} = $ans/${q.c}';
      default:
        return questionText(q).replaceFirst('= ?', '= $ans');
    }
  }

  String praiseMessage() {
    final list = praise.split('|');
    return list[_rng.nextInt(list.length)];
  }

  String encourageMessage() {
    final list = encourage.split('|');
    return list[_rng.nextInt(list.length)];
  }

  String badgeName(String id) {
    final t = Badges.tableOf(id);
    if (t != null) return badgeTableMaster(t);
    return switch (id) {
      Badges.streak7 => badgeStreak7,
      Badges.streak30 => badgeStreak30,
      Badges.day100 => badgeDay100,
      Badges.speedStar => badgeSpeedStar,
      _ => id,
    };
  }

  String badgeDesc(String id) {
    final t = Badges.tableOf(id);
    if (t != null) return badgeTableMasterDesc(t);
    return switch (id) {
      Badges.streak7 => badgeStreak7Desc,
      Badges.streak30 => badgeStreak30Desc,
      Badges.day100 => badgeDay100Desc,
      Badges.speedStar => badgeSpeedStarDesc,
      _ => id,
    };
  }

  String itemName(ShopItem i) => switch (i.id) {
    'car_red' => color_red,
    'car_blue' => color_blue,
    'car_green' => color_green,
    'car_yellow' => color_yellow,
    'car_black' => color_black,
    'theme_rainbow' => theme_rainbow,
    'theme_pastel' => theme_pastel,
    'theme_ocean' => theme_ocean,
    'theme_sunset' => theme_sunset,
    'theme_candy' => theme_candy,
    _ => i.id,
  };
}

/// Illustration (assets/images) for a badge.
String badgeImage(String id) {
  if (Badges.tableOf(id) != null) return 'medal';
  return switch (id) {
    Badges.streak7 => 'fire',
    Badges.streak30 => 'crown',
    Badges.day100 => 'hundred',
    Badges.speedStar => 'speed',
    _ => 'trophy',
  };
}

/// Illustration (assets/images) for a game mode.
String modeImage(GameMode m) => switch (m) {
  GameMode.balloon => 'balloon',
  GameMode.race => 'race',
  GameMode.treasure => 'treasure',
  GameMode.tables => 'book',
  GameMode.speed => 'speed',
  GameMode.daily => 'calendar',
};
