import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:sorting_sahayak/data/import/scheme_io.dart';
import 'package:sorting_sahayak/data/scheme_repo.dart';
import 'package:sorting_sahayak/features/learn/learn_engine.dart';

import 'helpers/fixture.dart';

void main() {
  late LearnEngine engine;
  setUp(() async {
    final repo = SchemeRepo(await memoryUserDb());
    await installSampleScheme(repo, (p) async => File(p).readAsBytesSync());
    final dir = await fixtureRepo();
    final regions = await dir.pinRegions();
    engine = LearnEngine((await repo.loadActive())!, directoryPins: regions.keys, regions: regions, random: Random(3));
  });

  test('bag flashcards follow resolver priority', () {
    final cards = engine.cards(FlashMode.bag);
    expect(cards, isNotEmpty);
    final c = cards.firstWhere((c) => c.prompt == '574201');
    expect(c.answer, 'Bag 12');
    expect(cards.any((c) => !c.isPin && c.prompt == 'Sullia'), isTrue);
    expect(cards.where((c) => c.prompt == '574215'), everyElement(predicate<LearnCard>((c) => c.answer == 'Bag 15')));
  });

  test('air and hub cards', () {
    final air = engine.cards(FlashMode.air);
    expect(air.firstWhere((c) => c.prompt == '110001').answer, 'DEL');
    final hub = engine.cards(FlashMode.hub, onlyPins: {576101, 574239});
    expect(hub.length, 2);
    expect(hub.firstWhere((c) => c.prompt == '574239').answer, contains('direct'));
  });

  test('quiz has 4 distinct options with the right answer', () {
    final q = engine.quiz(FlashMode.bag, count: 20);
    expect(q, isNotEmpty);
    for (final x in q) {
      expect(x.options, contains(x.card.answer));
      expect(x.options.toSet().length, x.options.length);
      expect(x.options.length, lessThanOrEqualTo(4));
    }
  });

  test('leitner boxes', () {
    expect(nextBox(1, true), 2);
    expect(nextBox(5, true), 5);
    expect(nextBox(4, false), 1);
    final now = DateTime(2026, 1, 1);
    expect(dueAfter(3, now), now.add(const Duration(days: 3)).millisecondsSinceEpoch);
  });
}
