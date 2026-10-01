import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sorting_sahayak/core/constants.dart';
import 'package:sorting_sahayak/data/air_lookup.dart';
import 'package:sorting_sahayak/data/import/scheme_io.dart';
import 'package:sorting_sahayak/data/resolver.dart';
import 'package:sorting_sahayak/data/scheme_repo.dart';
import 'package:sorting_sahayak/features/lookup/sort_screen.dart';

import 'helpers/app_harness.dart';
import 'helpers/fixture.dart';

Future<Uint8List> _asset(String p) async => File(p).readAsBytesSync();

void main() {
  test('default scheme carries the MR PH sheet air codes', () async {
    final repo = SchemeRepo(await memoryUserDb());
    await installDefaultScheme(repo, _asset);
    final s = (await repo.loadActive())!;
    expect(s.airResolver.rules.length, greaterThan(400));
    String? code(int pin) => s.airResolver.resolve(ResolveQuery(pin: pin))?.rule.airCode;
    expect(code(560001), 'BLR');
    expect(code(515001), 'BLR');
    expect(code(110001), 'DEL');
    expect(code(733101), 'CCU'); // 7331 Kolkata
    expect(code(733201), 'IXB'); // 7332 Siliguri
    expect(code(416001), 'BOM'); // same line as the scheme (MUMBAI)
    expect(code(411001), 'PNQ');
    expect(code(416515), 'NIL'); // Margaon, no air code
    expect(hasAirCode(code(416515)!), isFalse);
    expect(code(561202), 'NIL'); // Tumakuru
    expect(code(561201), 'BLR');
    expect(code(574201), isNull); // Mangaluru PH: no air code
  });

  test('an older default install gets the air codes added once', () async {
    final repo = SchemeRepo(await memoryUserDb());
    final id = await installDefaultScheme(repo, _asset);
    await repo.replaceAirCodes(id, const []);
    expect(await addDefaultAirCodes(repo, _asset), isTrue);
    expect((await repo.airCodes(id)).length, greaterThan(400));
    expect(await addDefaultAirCodes(repo, _asset), isFalse);
  });

  testWidgets('line card and bag card show the sheet air code, nothing without one', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.reset);
    final h = await Harness.create(tester, sample: false);
    await tester.runAsync(() async {
      await installDefaultScheme(h.services.schemes, _asset);
      await h.services.reloadActive();
    });
    h.settings.category = kCatNonTD;
    await tester.pumpWidget(h.wrap(const SortScreen()));
    await settle(tester);
    await tester.enterText(find.byKey(const ValueKey('pin_field')), '560');
    await settle(tester, rounds: 6);
    expect(find.byKey(const ValueKey('air_BLR')), findsWidgets);
    expect(find.text('BANGALORE'), findsWidgets);
    // Own district: no air code in the sheet → no badge, no guess.
    await tester.enterText(find.byKey(const ValueKey('pin_field')), '574239');
    await settle(tester, rounds: 6);
    expect(find.byKey(const ValueKey('air_IXE')), findsNothing);
  });
}
