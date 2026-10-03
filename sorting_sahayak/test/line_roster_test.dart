import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sorting_sahayak/data/import/scheme_import.dart';
import 'package:sorting_sahayak/data/import/scheme_io.dart';
import 'package:sorting_sahayak/data/import/table_reader.dart';
import 'package:sorting_sahayak/data/live_search.dart';
import 'package:sorting_sahayak/data/models/scheme.dart';

void main() {
  final t = readTable(File('assets/schemes/mangaluru_default.csv').readAsBytesSync(), 'x.csv');
  final rules = autoImport<BagRule>(t.sheets[t.defaultSheet]!, ImportKind.bagRules).rules;

  test('full line lists every office in position order with its PIN', () {
    final karkala = lineRoster(rules, 'Karkala Line', category: 'TD');
    expect(karkala.first.name, 'Hebri');
    expect(karkala.first.pins, ['576112']);
    expect(karkala.last.name, 'Vamanjoor');
    expect(karkala.last.pins, ['575028']);
    final naravi = karkala.firstWhere((s) => s.name == 'Naravi');
    expect(naravi.position, '5');
    expect(naravi.pins, ['574109']);
    // Every office from the line list has a PIN on all the named lines.
    for (final line in [
      'Puttur Line',
      'Karkala Line',
      'Charmadi Line',
      'Subramany Line',
      'Belman Line',
      'Kulashekhara Line',
      'Kotekar Line',
    ]) {
      final stops = lineRoster(rules, line, category: 'TD');
      expect(stops.where((s) => s.officeRule != null && s.pins.isEmpty).map((s) => s.name), isEmpty, reason: line);
    }
    // Different spellings join: Sulia ↔ Sullia SO, Bykampadi ↔ Baikampady SO, GV Kere ↔ Guruvanayakere.
    expect(lineRoster(rules, 'Puttur Line', category: 'TD').firstWhere((s) => s.name == 'Sulia').pins, ['574239']);
    expect(lineRoster(rules, 'Belman Line', category: 'TD').firstWhere((s) => s.name == 'Bykampadi').pins, ['575011']);
    expect(lineRoster(rules, 'Charmadi Line', category: 'TD').firstWhere((s) => s.name == 'GV Kere').pins, ['574217']);
  });
}
