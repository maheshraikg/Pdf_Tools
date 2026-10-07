import '../models/word.dart';

/// A themed learning chart (days, months, numbers…).
class LearnChart {
  const LearnChart({
    required this.id,
    required this.kn,
    required this.en,
    required this.icon,
    required this.items,
  });

  final String id;
  final String kn;
  final String en;

  /// Material icon code point name, resolved by the screen.
  final String icon;
  final List<Word> items;
}

Word _w(String chart, int i, String tulu, String roman, String kn, String en) =>
    Word(
      id: 'c:$chart:$i',
      tulu: tulu,
      roman: roman,
      kn: kn,
      en: en,
      cat: 'chart',
    );

/// Days of the week, starting on Sunday. Sample data – verify with native
/// speakers before publishing, like the dictionary.
final List<Word> kDays = [
  _w('days', 1, 'ಐತಾರ', 'aitaara', 'ಭಾನುವಾರ', 'Sunday'),
  _w('days', 2, 'ಸೋಮಾರ', 'somaara', 'ಸೋಮವಾರ', 'Monday'),
  _w('days', 3, 'ಅಂಗಾರೆ', 'angaare', 'ಮಂಗಳವಾರ', 'Tuesday'),
  _w('days', 4, 'ಬುದಾರ', 'budaara', 'ಬುಧವಾರ', 'Wednesday'),
  _w('days', 5, 'ಗುರುವಾರ', 'guruvaara', 'ಗುರುವಾರ', 'Thursday'),
  _w('days', 6, 'ಸುಕ್ರಾರ', 'sukraara', 'ಶುಕ್ರವಾರ', 'Friday'),
  _w('days', 7, 'ಸನಿವಾರ', 'sanivaara', 'ಶನಿವಾರ', 'Saturday'),
];

/// The twelve Tulu (solar) months, starting with Paggu (mid-April).
final List<Word> kMonths = [
  _w('months', 1, 'ಪಗ್ಗು', 'paggu', 'ಮೇಷ ಮಾಸ', 'Paggu (Apr–May)'),
  _w('months', 2, 'ಬೇಸ', 'besa', 'ವೃಷಭ ಮಾಸ', 'Besa (May–Jun)'),
  _w('months', 3, 'ಕಾರ್ತೆಲ್', 'kaartel', 'ಮಿಥುನ ಮಾಸ', 'Kartel (Jun–Jul)'),
  _w('months', 4, 'ಆಟಿ', 'aati', 'ಕರ್ಕಾಟಕ ಮಾಸ', 'Aati (Jul–Aug)'),
  _w('months', 5, 'ಸೋಣ', 'sona', 'ಸಿಂಹ ಮಾಸ', 'Sona (Aug–Sep)'),
  _w('months', 6, 'ನಿರ್ನಾಲ', 'nirnaala', 'ಕನ್ಯಾ ಮಾಸ', 'Nirnala (Sep–Oct)'),
  _w('months', 7, 'ಬೊಂತೆಲ್', 'bontel', 'ತುಲಾ ಮಾಸ', 'Bontel (Oct–Nov)'),
  _w('months', 8, 'ಜಾರ್ದೆ', 'jaarde', 'ವೃಶ್ಚಿಕ ಮಾಸ', 'Jarde (Nov–Dec)'),
  _w('months', 9, 'ಪೆರಾರ್ದೆ', 'peraarde', 'ಧನು ಮಾಸ', 'Perarde (Dec–Jan)'),
  _w('months', 10, 'ಪುಯಿಂತೆಲ್', 'puyintel', 'ಮಕರ ಮಾಸ', 'Puyintel (Jan–Feb)'),
  _w('months', 11, 'ಮಾಯಿ', 'maayi', 'ಕುಂಭ ಮಾಸ', 'Mayi (Feb–Mar)'),
  _w('months', 12, 'ಸುಗ್ಗಿ', 'suggi', 'ಮೀನ ಮಾಸ', 'Suggi (Mar–Apr)'),
];

/// The four directions.
final List<Word> kDirections = [
  _w('dirs', 1, 'ಮೂಡಾಯಿ', 'moodaayi', 'ಪೂರ್ವ', 'east'),
  _w('dirs', 2, 'ಪಡ್ಡಾಯಿ', 'paddaayi', 'ಪಶ್ಚಿಮ', 'west'),
  _w('dirs', 3, 'ಬಡಕಾಯಿ', 'badakaayi', 'ಉತ್ತರ', 'north'),
  _w('dirs', 4, 'ತೆನ್ಕಾಯಿ', 'tenkaayi', 'ದಕ್ಷಿಣ', 'south'),
];

final RegExp _number = RegExp(r'\((\d+)\)');

/// The numeric value in an English meaning like "ten (10)", or null.
int? numberValue(Word w) {
  final m = _number.firstMatch(w.en);
  return m == null ? null : int.parse(m.group(1)!);
}

/// Builds every chart. Numbers and colours come from the dictionary so they
/// stay in sync with `words.json`.
List<LearnChart> buildCharts(List<Word> dictionary) {
  final numbers =
      dictionary
          .where((w) => w.cat == 'numbers' && numberValue(w) != null)
          .toList()
        ..sort((a, b) => numberValue(a)!.compareTo(numberValue(b)!));
  const colourNames = {
    'red',
    'black',
    'green',
    'white',
    'yellow',
    'blue',
    'colour',
  };
  final colours = dictionary
      .where((w) => !w.custom && colourNames.contains(w.en.trim()))
      .toList();
  return [
    LearnChart(
      id: 'numbers',
      kn: 'ಸಂಖ್ಯೆಗಳು',
      en: 'Numbers',
      icon: 'numbers',
      items: numbers,
    ),
    LearnChart(
      id: 'days',
      kn: 'ವಾರದ ದಿನಗಳು',
      en: 'Days of the week',
      icon: 'days',
      items: kDays,
    ),
    LearnChart(
      id: 'months',
      kn: 'ತುಳು ತಿಂಗಳುಗಳು',
      en: 'Tulu months',
      icon: 'months',
      items: kMonths,
    ),
    LearnChart(
      id: 'dirs',
      kn: 'ದಿಕ್ಕುಗಳು',
      en: 'Directions',
      icon: 'dirs',
      items: kDirections,
    ),
    if (colours.isNotEmpty)
      LearnChart(
        id: 'colours',
        kn: 'ಬಣ್ಣಗಳು',
        en: 'Colours',
        icon: 'colours',
        items: colours,
      ),
  ];
}
