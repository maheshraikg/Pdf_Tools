// Measures lookup / search latency on a synthetic 165k-row directory
// (the real all-India file has ~165k offices).
@Timeout(Duration(minutes: 5))
library;

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:sorting_sahayak/data/directory_builder.dart';
import 'package:sorting_sahayak/data/directory_repo.dart';

import 'helpers/fixture.dart';

void main() {
  const rows = 165000;
  late DirectoryRepo repo;
  final names = <String>[];

  setUpAll(() async {
    final rnd = Random(42);
    const syl = ['ka', 'ra', 'pu', 'ttu', 'ma', 'ga', 'la', 'na', 'di', 'hal', 'li', 'ko', 'te', 'va', 'da', 'sa', 'ban', 'gu', 'ru', 'pa', 'nur', 'ha', 'lli', 'kere', 'pet', 'gun', 'ja', 'be', 'ta', 'nga'];
    String name() {
      final n = 2 + rnd.nextInt(3);
      final s = List.generate(n, (_) => syl[rnd.nextInt(syl.length)]).join();
      return s[0].toUpperCase() + s.substring(1);
    }

    final recs = <OfficeRecord>[];
    for (var i = 0; i < rows; i++) {
      final nm = name();
      if (i % 1000 == 0) names.add(nm);
      recs.add(OfficeRecord(
        pincode: 110001 + rnd.nextInt(750000),
        officeName: nm,
        officeType: const ['BO', 'SO', 'HO'][rnd.nextInt(3)],
        delivery: rnd.nextInt(10) == 0 ? 'Non-Delivery' : 'Delivery',
        division: 'Division ${rnd.nextInt(400)}',
        region: 'Region ${rnd.nextInt(50)}',
        circle: 'Circle ${rnd.nextInt(23)}',
        district: 'District ${rnd.nextInt(750)}',
        state: 'State ${rnd.nextInt(36)}',
      ));
    }
    final db = await ffiFactory().openDatabase(':memory:');
    await writeDirectoryDb(db, recs);
    repo = DirectoryRepo(db);
    await repo.warmUp();
  });

  test('PIN lookup < 50 ms', () async {
    final rnd = Random(1);
    final sw = Stopwatch()..start();
    var worst = 0;
    for (var i = 0; i < 200; i++) {
      final t = sw.elapsedMicroseconds;
      await repo.officesForPin(110001 + rnd.nextInt(750000));
      worst = max(worst, sw.elapsedMicroseconds - t);
    }
    final avgMs = sw.elapsedMicroseconds / 200 / 1000;
    // ignore: avoid_print
    print('PIN lookup: avg ${avgMs.toStringAsFixed(2)} ms, worst ${(worst / 1000).toStringAsFixed(2)} ms');
    expect(avgMs, lessThan(50));
  });

  test('place search < 200 ms (exact, typo, prefix)', () async {
    final queries = <String>[];
    for (final n in names.take(40)) {
      queries
        ..add(n)
        ..add(n.substring(0, max(3, n.length - 2)))
        ..add('${n.substring(0, 2)}x${n.substring(3)}');
    }
    final sw = Stopwatch()..start();
    var worst = 0;
    for (final q in queries) {
      final t = sw.elapsedMicroseconds;
      await repo.search(q);
      worst = max(worst, sw.elapsedMicroseconds - t);
    }
    final avgMs = sw.elapsedMicroseconds / queries.length / 1000;
    // ignore: avoid_print
    print('Search: avg ${avgMs.toStringAsFixed(1)} ms, worst ${(worst / 1000).toStringAsFixed(1)} ms over ${queries.length} queries');
    expect(avgMs, lessThan(200));
  });
}
