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
    expect(r.first.tulu, 'ನೀರ್');
  });

  test('Kannada meaning query matches', () {
    expect(state.search('ತಾಯಿ').first.tulu, 'ಅಪ್ಪೆ');
  });

  test('Latin query collapses doubled letters', () {
    expect(state.search('neer').first.tulu, 'ನೀರ್');
  });

  test('English meaning query matches', () {
    expect(state.search('mother').first.tulu, 'ಅಪ್ಪೆ');
  });

  test('expanded list: new entries are searchable', () {
    expect(state.words.length, greaterThanOrEqualTo(200));
    expect(state.search('elephant').first.tulu, 'ಆನೆ');
    expect(state.search('ಹನ್ನೊಂದು').first.tulu, 'ಪದ್ನೊಂಜಿ');
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
