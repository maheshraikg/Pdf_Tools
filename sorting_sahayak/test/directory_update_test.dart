import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sorting_sahayak/data/directory_repo.dart';
import 'package:sorting_sahayak/data/directory_update.dart';

import 'helpers/fixture.dart';

void main() {
  test('rebuilds the directory from a CSV in an isolate with progress', () async {
    final dir = Directory.systemTemp.createTempSync('dirupd');
    final target = '${dir.path}/new.db';
    final events = await buildDirectoryFromCsv(
      csvPath: 'test/fixtures/directory.csv',
      targetPath: target,
      openDb: (p) => ffiFactory().openDatabase(p),
      stateFilter: 'Karnataka',
    ).toList();
    expect(events.last.stage, 'done');
    expect(events.last.rows, 21);
    final ps = events.map((e) => e.progress).toList();
    for (var i = 1; i < ps.length; i++) {
      expect(ps[i], greaterThanOrEqualTo(ps[i - 1]));
    }
    final db = await ffiFactory().openDatabase(target);
    final repo = DirectoryRepo(db);
    expect((await repo.officesForPin(574201)).single.officeName, 'Puttur');
    expect((await repo.meta()).stateFilter, 'Karnataka');
    await db.close();
    dir.deleteSync(recursive: true);
  });

  test('reports an error for a CSV without the needed columns', () async {
    final dir = Directory.systemTemp.createTempSync('dirupd');
    final bad = File('${dir.path}/bad.csv')..writeAsStringSync('a,b\n1,2\n');
    final events = await buildDirectoryFromCsv(
      csvPath: bad.path,
      targetPath: '${dir.path}/x.db',
      openDb: (p) => ffiFactory().openDatabase(p),
    ).toList();
    expect(events.last.stage, 'error');
    dir.deleteSync(recursive: true);
  });
}
