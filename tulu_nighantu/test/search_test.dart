import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tulu_nighantu/app_state.dart';

void main() {
  final state = AppState.instance
    ..loadFromJson(File('assets/data/words.json').readAsStringSync());

  test('word list loads and every word converts to Tulu lipi', () {
    expect(state.words, isNotEmpty);
    for (final w in state.words) {
      expect(
        w.lipi.runes.any((r) => r >= 0x11380 && r <= 0x113FF),
        isTrue,
        reason: w.tulu,
      );
    }
    expect(state.words.map((w) => w.id).toSet().length, state.words.length);
  });

  test('Kannada-script query matches Tulu word first', () {
    final r = state.search('ನೀರ್');
    expect(r.first.roman, 'nīr');
  });

  test('Kannada meaning query matches', () {
    expect(state.search('ತಾಯಿ').first.roman, 'appe');
  });

  test('Latin query collapses doubled letters', () {
    expect(state.search('neer').first.roman, 'nīr');
  });

  test('English meaning query matches', () {
    expect(state.search('mother').first.roman, 'appe');
  });

  test('category filter and empty query', () {
    final nums = state.search('', category: 'numbers');
    expect(nums, isNotEmpty);
    expect(nums.every((w) => w.cat == 'numbers'), isTrue);
  });

  test('word of the day is never a phrase', () {
    expect(state.wordOfTheDay!.isPhrase, isFalse);
  });
}
