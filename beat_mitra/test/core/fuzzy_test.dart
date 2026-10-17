import 'dart:math';

import 'package:beat_mitra/core/fuzzy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('normalizeDoorNo', () {
    test('separators', () {
      expect(normalizeDoorNo('12/3'), '12/3');
      expect(normalizeDoorNo('12-3'), '12/3');
      expect(normalizeDoorNo('12 / 3'), '12/3');
      expect(normalizeDoorNo('No. 12/3'), '12/3');
      expect(normalizeDoorNo('#12/3'), '12/3');
      expect(normalizeDoorNo('H.No 12-3'), '12/3');
      expect(normalizeDoorNo('Door No: 45'), '45');
    });
    test('ordinals are cross/main, not the door', () {
      expect(normalizeDoorNo('#12 3rd'), '12');
      expect(normalizeDoorNo('12, 4th cross'), '12');
    });
    test('letters', () {
      expect(normalizeDoorNo('12A'), '12a');
      expect(normalizeDoorNo('12 A'), '12a');
      expect(normalizeDoorNo('Flat 3B'), '3b');
    });
    test('Indic digits', () {
      expect(normalizeDoorNo('೧೨/೩'), '12/3');
      expect(normalizeDoorNo('४५'), '45');
    });
    test('empty', () {
      expect(normalizeDoorNo('near temple'), '');
    });
  });

  test('compareDoorNo natural order', () {
    final l = ['10', '2', '10/1', '1', '11', '10a']..sort(compareDoorNo);
    expect(l, ['1', '2', '10', '10/1', '10a', '11']);
  });

  test('tokenize removes stop words and punctuation', () {
    expect(tokenize('No. 12/3, 4th Cross'), ['12/3', '4th', 'cross']);
    expect(tokenize('#12 Flat'), ['12']);
    expect(tokenize('Shri Ramesh'), ['ramesh']);
  });

  test('levenshtein', () {
    expect(levenshtein('kitten', 'sitting'), 3);
    expect(levenshtein('abc', 'abc'), 0);
    expect(levenshtein('abc', 'xyzabc', max: 1), 2);
  });

  test('trigramSimilarity', () {
    expect(trigramSimilarity('ramesh', 'ramesh'), 1.0);
    expect(trigramSimilarity('ramesh', 'rameshh'), greaterThan(0.6));
    expect(trigramSimilarity('ramesh', 'xyz'), 0);
  });

  group('SearchIndex ranking', () {
    SearchIndex build() => SearchIndex([
      SearchDoc(
        id: 1,
        fields: {'name': 'Ramesh Kumar', 'door': '12/3', 'street': '4th Cross', 'area': 'HAL 2nd Stage'},
      ),
      SearchDoc(id: 2, fields: {'name': 'Suresh', 'door': '12', 'street': '5th Cross', 'landmark': 'Ganesha temple'}),
      SearchDoc(id: 3, fields: {'name': 'Lakshmi Devi', 'door': '221', 'street': '8th Main', 'area': 'Jayanagar'}),
      SearchDoc(id: 4, fields: {'name': 'Rajesh', 'door': '7', 'street': 'Temple Road', 'pin': '560038'}),
      SearchDoc(id: 5, fields: {'name': 'ರಮೇಶ ಭಟ್', 'door': '40', 'street': '1st Main'}),
    ]);

    test('Kannada, Latin and misspelt names all find Ramesh', () {
      final idx = build();
      for (final q in ['Ramesh', 'ರಮೇಶ್', 'Rameshh', 'रमेश']) {
        final hits = idx.search(q);
        expect(hits, isNotEmpty, reason: q);
        expect([1, 5], contains(hits.first.id), reason: q);
        expect(hits.map((h) => h.id), containsAll([1, 5]), reason: q);
      }
    });

    test('two names narrow the result', () {
      expect(build().search('ramesh kumar').first.id, 1);
    });

    test('door number variants', () {
      final idx = build();
      expect(idx.search('12-3').first.id, 1);
      expect(idx.search('#12/3').first.id, 1);
      expect(idx.search('12').first.id, 2); // exact door beats prefix 12/3
      expect(idx.search('12').map((h) => h.id), contains(1));
    });

    test('combined query: door + street', () {
      final idx = build();
      expect(idx.search('12 5th cross').first.id, 2);
      expect(idx.search('12 4th cross').first.id, 1);
    });

    test('landmark, area and PIN', () {
      final idx = build();
      expect(idx.search('ganesha').first.id, 2);
      expect(idx.search('jayanagar').first.id, 3);
      expect(idx.search('560038').first.id, 4);
      expect(idx.search('temple').map((h) => h.id).take(2), containsAll([2, 4]));
    });

    test('prefix typing', () {
      final idx = build();
      expect(idx.search('laks').first.id, 3);
      expect(idx.search('raj').first.id, 4);
    });

    test('no match returns empty', () {
      expect(build().search('zzzzqq'), isEmpty);
      expect(build().search('   '), isEmpty);
    });

    test('5,000 places search is fast', () {
      final rnd = Random(1);
      const first = [
        'Ramesh',
        'Suresh',
        'Lakshmi',
        'Gowda',
        'Manjunath',
        'Kavya',
        'Anil',
        'Prakash',
        'Shobha',
        'Nagaraj',
      ];
      const last = ['Kumar', 'Rao', 'Shetty', 'Bhat', 'Reddy', 'Devi', 'Naik', 'Hegde'];
      final docs = List.generate(5000, (i) {
        return SearchDoc(
          id: i,
          fields: {
            'name':
                '${first[rnd.nextInt(first.length)]} ${last[rnd.nextInt(last.length)]} '
                '${first[rnd.nextInt(first.length)]}',
            'door': '${rnd.nextInt(400)}/${rnd.nextInt(5)}',
            'street': '${rnd.nextInt(20) + 1}th Cross ${rnd.nextInt(10) + 1}th Main',
            'landmark': rnd.nextBool() ? 'Near Ganesha Temple' : 'Opp School',
            'area': 'HAL ${rnd.nextInt(3) + 1}nd Stage',
            'pin': '5600${rnd.nextInt(90) + 10}',
          },
        );
      });
      final idx = SearchIndex(docs);
      idx.search('warmup');
      final sw = Stopwatch()..start();
      const queries = ['ramesh', 'Rameshh kumar', '12/3', 'ganesha', 'ಲಕ್ಷ್ಮಿ', 'manju 14th cross'];
      for (final q in queries) {
        idx.search(q);
      }
      final perQuery = sw.elapsedMilliseconds / queries.length;
      // Release (AOT) builds are several times faster than the JIT test VM.
      // ignore: avoid_print
      print('Search 5000 places: ${perQuery.toStringAsFixed(1)} ms/query (JIT)');
      expect(perQuery, lessThan(400));
    });
  });
}
