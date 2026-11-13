import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ganita_aata/data/curriculum.dart';
import 'package:ganita_aata/data/languages.dart';
import 'package:ganita_aata/l10n/app_localizations.dart';
import 'package:ganita_aata/models/question.dart';
import 'package:ganita_aata/widgets/l10n_ext.dart';

void main() {
  test('every app language has translations', () {
    expect(Languages.all.length, 12);
    final supported = AppLocalizations.supportedLocales.map((l) => l.languageCode).toSet();
    for (final lang in Languages.all) {
      expect(supported, contains(lang.code));
    }
  });

  for (final lang in Languages.all) {
    test('${lang.code}: strings are filled in and differ from English', () {
      final l = lookupAppLocalizations(Locale(lang.code));
      final en = lookupAppLocalizations(const Locale('en'));
      for (final t in Curriculum.topics) {
        expect(l.topicName(t.id), isNot(t.id));
      }
      expect(l.praise.split('|').length, greaterThanOrEqualTo(4));
      expect(l.encourage.split('|').length, greaterThanOrEqualTo(3));
      expect(l.streakDays(1), contains('1'));
      expect(l.streakDays(5), contains('5'));
      expect(l.chestsOpened(3), contains('3'));
      expect(l.questionText(Question.fromParts('num100', Op.after, 47)), contains('47'));
      expect(l.helloName('Asha'), contains('Asha'));
      if (lang.code != 'en') expect(l.play, isNot(en.play));
    });
  }
}
