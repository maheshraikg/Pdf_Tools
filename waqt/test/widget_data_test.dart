import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:waqt/app/settings.dart';
import 'package:waqt/app/widget_data.dart';

void main() {
  test('widget JSON has five prayers per day with epoch times', () {
    final settings = AppSettings.memory();
    final days = settings.calculator.days(DateTime.utc(2026, 10, 16), 2);
    final j = jsonDecode(widgetJson(settings, days)) as Map<String, dynamic>;
    expect(j['place'], 'Kozhikode');
    expect(j['format'], contains('%s'));
    final list = j['days'] as List;
    expect(list, hasLength(2));
    final first = list.first as Map<String, dynamic>;
    expect(first['title'], startsWith('Friday 16 October'));
    final p = first['p'] as List;
    expect(p, hasLength(5));
    expect((p[1] as Map)['n'], "Jumu'ah");
    expect((p[0] as Map)['s'], matches(RegExp(r'^\d{1,2}:\d{2}a$')));
    final times = p.map((e) => (e as Map)['t'] as int).toList();
    for (var i = 1; i < times.length; i++) {
      expect(times[i], greaterThan(times[i - 1]));
    }

    settings.lang = Lang.ml;
    final ml = jsonDecode(widgetJson(settings, days)) as Map<String, dynamic>;
    expect(ml['format'], '%s കഴിഞ്ഞ്');
    expect(ml['place'], 'കോഴിക്കോട്');
  });
}
