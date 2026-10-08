import 'package:flutter_test/flutter_test.dart';
import 'package:sorting_sahayak/core/fuzzy.dart';

void main() {
  test('normalizePlace strips suffixes, dots and spaces', () {
    expect(normalizePlace('Puttur S.O'), 'puttur');
    expect(normalizePlace('Puttur B.O.'), 'puttur');
    expect(normalizePlace('Puttur Post'), 'puttur');
    expect(normalizePlace('PUTTUR (P.O)'), 'puttur');
    expect(normalizePlace('Mangalore H.O'), 'mangalore');
    expect(normalizePlace('Kodial Bail'), 'kodialbail');
    expect(normalizePlace('ಪುತ್ತೂರು'), 'puttur');
    expect(normalizePlace('Post'), 'post');
  });

  test('phonetic key collides spelling variants', () {
    final k = phoneticKey('puttur');
    expect(phoneticKey(normalizePlace('Puttoor')), k);
    expect(phoneticKey(normalizePlace('Putur')), k);
    expect(phoneticKey(normalizePlace('ಪುತ್ತೂರು')), k);
    expect(phoneticKey(normalizePlace('पुत्तूर')), k);
    expect(phoneticKey('hassan'), phoneticKey(normalizePlace('ಹಾಸನ')));
  });

  test('levenshtein', () {
    expect(levenshtein('kitten', 'sitting'), 3);
    expect(levenshtein('', 'abc'), 3);
    expect(levenshtein('abc', 'abc'), 0);
    expect(levenshtein('abcdef', 'x', max: 2), 3);
  });

  test('trigram similarity', () {
    expect(trigramSimilarity('puttur', 'puttur'), 1);
    expect(trigramSimilarity('puttur', 'putur'), greaterThan(0.3));
    expect(trigramSimilarity('puttur', 'delhi'), 0);
  });

  test('placeSimilarity ranks sensible matches', () {
    expect(placeSimilarity('puttur', 'puttur'), 1);
    expect(placeSimilarity('putt', 'puttur'), greaterThan(0.9));
    expect(placeSimilarity('puttoor', 'puttur'), greaterThan(0.9));
    expect(placeSimilarity('mysuru', 'mysore'), greaterThan(0.6));
    expect(placeSimilarity('puttur', 'udupi'), lessThan(0.4));
  });

  test('aliases', () {
    expect(canonicalAlias('bangalore'), 'bengaluru');
    expect(canonicalAlias('bengaluru'), isNull);
    expect(aliasVariants('mysore'), containsAll(['mysore', 'mysuru']));
  });
}
