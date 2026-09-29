import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sorting_sahayak/core/constants.dart';
import 'package:sorting_sahayak/data/import/scheme_io.dart';
import 'package:sorting_sahayak/data/scheme_repo.dart';
import 'package:sorting_sahayak/data/sort_engine.dart';
import 'package:sorting_sahayak/data/user_repo.dart';
import 'package:sorting_sahayak/features/bulk/bulk_counter.dart';

import 'helpers/fixture.dart';

void main() {
  late SortEngine engine;
  late UserRepo user;
  late ActiveScheme scheme;

  setUp(() async {
    final db = await memoryUserDb();
    final repo = SchemeRepo(db);
    user = UserRepo(db);
    await installSampleScheme(repo, (p) async => File(p).readAsBytesSync(), withParcelExtras: true);
    scheme = (await repo.loadActive())!;
    engine = SortEngine(await fixtureRepo(), scheme);
  });

  test('counts per bag, unresolved entries, undo', () async {
    final id = await user.startSession(name: 'Morning', date: '2026-09-29', category: kCatTD);
    for (final p in ['574201', '574202', '576101', '12345', '574201', '999999']) {
      await user.addEntry(id, await makeBulkEntry(engine, p, kCatTD));
    }
    var entries = await user.entries(id);
    var s = summarize(entries, bagOrder: scheme.bagOrder);
    expect(s.total, 6);
    expect(s.byBag['Bag 12'], 3);
    expect(s.byBag['Bag 21'], 1);
    // 12345 is not a PIN; 999999 has no TD rule (it is Non-TD).
    expect(s.unresolved.map((e) => e.raw), ['12345', '999999']);
    // undo last
    await user.deleteEntry(entries.last.id!);
    entries = await user.entries(id);
    s = summarize(entries, bagOrder: scheme.bagOrder);
    expect(s.total, 5);
    expect(s.unresolved.single.raw, '12345');
    final sessions = await user.sessions();
    expect(sessions.single.count, 5);
    final text = summaryText(sessions.single, s, bags: scheme.bags, labels: const {
      'title': 'Session', 'date': 'Date', 'scheme': 'Scheme', 'category': 'Category', 'total': 'Total', //
      'unresolved': 'Unresolved', 'bags': 'Bags', 'air': 'Air', 'connectivity': 'Conn', 'hubs': 'Hubs',
    });
    expect(text, contains('Bag 12 – Puttur Line'));
    expect(summaryCsv(entries, s, scheme.bags), contains('Bag 12,Puttur Line,3'));
  });

  test('air parcel mode counts per air code, hub and Air/Surface', () async {
    final entries = [
      for (final p in ['560001', '560038', '600001', '574201', '110001'])
        await makeBulkEntry(engine, p, kCatAirParcel),
    ];
    final s = summarize(entries, bagOrder: scheme.bagOrder);
    expect(s.byAir['BLR'], 2);
    expect(s.byAir['MAA'], 1);
    expect(s.byAir['DEL'], 1);
    expect(s.byConnectivity['Air'], 4);
    expect(s.byConnectivity['Surface'], 1);
    expect(s.byHub.keys, contains('→ Bengaluru L1 (demo) (direct)'));
    expect(s.byHub['Puttur L2 (demo) → Mangaluru L1 (demo)'], 1);
  });
}
