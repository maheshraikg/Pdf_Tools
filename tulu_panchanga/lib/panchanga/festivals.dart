/// Festival rules for Tulunadu and their evaluation for a Gregorian year.
///
/// Every rule names the kaala (time of day) at which the tithi must prevail;
/// when the tithi touches that kaala on two days the larger overlap wins, and
/// a full overlap on both days is resolved by [PanchangaConfig.tiePreference].
/// The rules and their confidence are listed in docs/VERIFY.md.
library;

import 'engine.dart';
import 'names.dart';
import 'place.dart';

enum Kaala {
  sunrise,
  arunodaya,
  madhyahna,
  aparahna,
  pradosha,
  nishita,
  moonrise;

  Name get label => switch (this) {
    sunrise => const Name('at sunrise', 'ಸೂರ್ಯೋದಯದಲ್ಲಿ'),
    arunodaya => const Name('at arunodaya', 'ಅರುಣೋದಯದಲ್ಲಿ'),
    madhyahna => const Name('at madhyahna', 'ಮಧ್ಯಾಹ್ನದಲ್ಲಿ'),
    aparahna => const Name('at aparahna', 'ಅಪರಾಹ್ಣದಲ್ಲಿ'),
    pradosha => const Name('at pradosha', 'ಪ್ರದೋಷದಲ್ಲಿ'),
    nishita => const Name('at midnight (nishita)', 'ನಿಶೀಥ ಕಾಲದಲ್ಲಿ'),
    moonrise => const Name('at moonrise', 'ಚಂದ್ರೋದಯದಲ್ಲಿ'),
  };
}

enum FestivalCategory {
  major(
    Name(
      'Festivals',
      'ಹಬ್ಬಗಳು',
      'ಪರ್ಬೊಲು',
      null,
      'ಸಣಾಂ',
      'त्योहार',
      'ഉത്സവങ്ങൾ',
      'పండుగలు',
    ),
  ),
  tulu(
    Name(
      'Tulunadu',
      'ತುಳುನಾಡು',
      null,
      null,
      null,
      'तुलुनाडु',
      'തുളുനാട്',
      'తుళునాడు',
    ),
  ),
  vrata(
    Name(
      'Vratas',
      'ವ್ರತಗಳು',
      null,
      null,
      'ವ್ರತಾಂ',
      'व्रत',
      'വ്രതങ്ങൾ',
      'వ్రతాలు',
    ),
  ),
  sankramana(
    Name(
      'Sankramana',
      'ಸಂಕ್ರಮಣ',
      null,
      null,
      null,
      'संक्रांति',
      'സംക്രമം',
      'సంక్రమణం',
    ),
  );

  const FestivalCategory(this.label);
  final Name label;
}

/// How sure we are that the rule matches local (Mangaluru/Udupi) practice.
enum Confidence { high, medium, low }

sealed class FestivalRule {
  const FestivalRule();

  /// Human-readable rule (English) for the verification CSV.
  String describe();
}

/// Tithi [tithi] (0..29) of nija lunar month [month] (0 = Chaitra).
class LunarTithiRule extends FestivalRule {
  const LunarTithiRule(this.month, this.tithi, this.kaala);
  final int month;
  final int tithi;
  final Kaala kaala;

  /// [month] −1 means every month (recurring vratas).
  @override
  String describe() => month < 0
      ? '${tithiName(tithi).en} ${kaala.label.en}, every paksha/month'
      : '${lunarMonthNames[month].en} ${_tithiLabel(tithi)} ${kaala.label.en} (amanta, nija masa)';
}

/// Tithi [tithi] falling in solar month [solarMonth] (0 = Mesha).
class SolarMonthTithiRule extends FestivalRule {
  const SolarMonthTithiRule(this.solarMonth, this.tithi, this.kaala);
  final int solarMonth;
  final int tithi;
  final Kaala kaala;

  @override
  String describe() =>
      '${_tithiLabel(tithi)} ${kaala.label.en} in solar month ${rashiNames[solarMonth].en} (${tuluMonthNames[solarMonth].en})';
}

/// Day [day] of solar month [solarMonth] (month start per SolarMonthRule).
class SolarDayRule extends FestivalRule {
  const SolarDayRule(this.solarMonth, this.day);
  final int solarMonth;
  final int day;

  @override
  String describe() =>
      'Day $day of ${tuluMonthNames[solarMonth].en} (${rashiNames[solarMonth].en} solar month)';
}

/// The Hindu day (sunrise to sunrise) in which the Sun enters [rashi].
class SankrantiRule extends FestivalRule {
  const SankrantiRule(this.rashi);
  final int rashi;

  @override
  String describe() =>
      'Day of ${rashiNames[rashi].en} sankramana (Sun enters sidereal ${rashiNames[rashi].en})';
}

/// The day in Shukla [fromTithi]..[toTithi] of lunar [month] on which
/// [nakshatra] prevails longest during daytime.
class NakshatraRule extends FestivalRule {
  const NakshatraRule(this.month, this.fromTithi, this.toTithi, this.nakshatra);
  final int month;
  final int fromTithi;
  final int toTithi;
  final int nakshatra;

  @override
  String describe() =>
      '${nakshatraNames[nakshatra].en} nakshatra (longest in daytime) between ${_tithiLabel(fromTithi)} and ${_tithiLabel(toTithi)} of ${lunarMonthNames[month].en}';
}

/// The last [weekday] (0 = Sunday) on or before the day of the given tithi.
class WeekdayBeforeRule extends FestivalRule {
  const WeekdayBeforeRule(this.weekday, this.base);
  final int weekday;
  final LunarTithiRule base;

  @override
  String describe() =>
      'Last ${varaNames[weekday].en} on or before ${base.describe()}';
}

String _tithiLabel(int t) {
  if (t == 29) return 'Amavasya';
  if (t == 14) return 'Purnima';
  return '${t < 15 ? 'Shukla' : 'Krishna'} ${tithiNames[t % 15].en}';
}

class Festival {
  const Festival({
    required this.id,
    required this.name,
    required this.category,
    required this.rule,
    this.confidence = Confidence.medium,
    this.note = '',
  });

  final String id;
  final Name name;
  final FestivalCategory category;
  final FestivalRule rule;
  final Confidence confidence;
  final String note;
}

class FestivalOccurrence {
  const FestivalOccurrence({
    required this.date,
    required this.festival,
    this.detail = '',
    this.instant,
  });

  final DateTime date;
  final Festival festival;

  /// Extra information (e.g. why a day was chosen, or a Madhwa variant).
  final String detail;

  /// A relevant instant, e.g. the sankramana time.
  final double? instant;
}

// ---------------------------------------------------------------------------
// Festival list
// ---------------------------------------------------------------------------

// Tithi indices: Shukla n → n−1, Krishna n → 14+n, Amavasya → 29.
const int _s = -1;
const int _k = 14;

const List<Festival> festivals = [
  // --- Chandramana (lunar) -------------------------------------------------
  Festival(
    id: 'ugadi',
    name: Name('Chandramana Ugadi', 'ಚಾಂದ್ರಮಾನ ಯುಗಾದಿ'),
    category: FestivalCategory.major,
    rule: LunarTithiRule(0, _s + 1, Kaala.sunrise),
    confidence: Confidence.high,
    note: 'Lunar new year. Tulunadu mainly celebrates Bisu (solar).',
  ),
  Festival(
    id: 'ramanavami',
    name: Name('Sri Rama Navami', 'ಶ್ರೀ ರಾಮ ನವಮಿ'),
    category: FestivalCategory.major,
    rule: LunarTithiRule(0, _s + 9, Kaala.madhyahna),
    confidence: Confidence.high,
  ),
  Festival(
    id: 'akshaya_tritiya',
    name: Name('Akshaya Tritiya', 'ಅಕ್ಷಯ ತೃತೀಯ', null, 'ಅಕ್ಷಯ ತೃತೀಯಾ'),
    category: FestivalCategory.major,
    rule: LunarTithiRule(1, _s + 3, Kaala.sunrise),
  ),
  Festival(
    id: 'guru_purnima',
    name: Name('Guru Purnima', 'ಗುರು ಪೂರ್ಣಿಮೆ', null, 'ಗುರು ಪೂರ್ಣಿಮಾ'),
    category: FestivalCategory.major,
    rule: LunarTithiRule(3, _s + 15, Kaala.sunrise),
  ),
  Festival(
    id: 'nagara_panchami',
    name: Name('Nagara Panchami', 'ನಾಗರ ಪಂಚಮಿ', null, 'ನಾಗ ಪಂಚಮೀ'),
    category: FestivalCategory.tulu,
    rule: LunarTithiRule(4, _s + 5, Kaala.sunrise),
    note: 'Naga worship at nagabana; check local temple announcement.',
  ),
  Festival(
    id: 'varamahalakshmi',
    name: Name('Varamahalakshmi Vrata', 'ವರಮಹಾಲಕ್ಷ್ಮೀ ವ್ರತ'),
    category: FestivalCategory.major,
    rule: WeekdayBeforeRule(5, LunarTithiRule(4, _s + 15, Kaala.sunrise)),
  ),
  Festival(
    id: 'nooli_hunnime',
    name: Name(
      'Nooli Hunnime / Upakarma',
      'ನೂಲ ಹುಣ್ಣಿಮೆ / ಉಪಾಕರ್ಮ',
      'ನೂಲ ಪುಣ್ಣಮೆ / ಉಪಾಕರ್ಮ',
      'ಶ್ರಾವಣ ಪೂರ್ಣಿಮಾ / ಉಪಾಕರ್ಮ',
    ),
    category: FestivalCategory.major,
    rule: LunarTithiRule(4, _s + 15, Kaala.sunrise),
    note: 'Rig/Yajur upakarma dates can differ (nakshatra based).',
  ),
  Festival(
    id: 'janmashtami',
    name: Name(
      'Sri Krishna Janmashtami (Chandramana)',
      'ಶ್ರೀ ಕೃಷ್ಣ ಜನ್ಮಾಷ್ಟಮಿ (ಚಾಂದ್ರಮಾನ)',
      'ಅಷ್ಟೆಮಿ (ಚಾಂದ್ರಮಾನ)',
      'ಶ್ರೀ ಕೃಷ್ಣ ಜನ್ಮಾಷ್ಟಮೀ (ಚಾಂದ್ರಮಾನ)',
    ),
    category: FestivalCategory.major,
    rule: LunarTithiRule(4, _k + 8, Kaala.nishita),
    confidence: Confidence.high,
  ),
  Festival(
    id: 'krishna_jayanti_udupi',
    name: Name(
      'Sri Krishna Jayanti (Sauramana, Udupi)',
      'ಶ್ರೀ ಕೃಷ್ಣ ಜಯಂತಿ (ಸೌರಮಾನ, ಉಡುಪಿ)',
      'ಅಷ್ಟೆಮಿ (ಸೌರಮಾನ, ಒಡಿಪು)',
      'ಶ್ರೀ ಕೃಷ್ಣ ಜಯಂತೀ (ಸೌರಮಾನ, ಉಡುಪಿ)',
    ),
    category: FestivalCategory.tulu,
    rule: SolarMonthTithiRule(4, _k + 8, Kaala.nishita),
    confidence: Confidence.low,
    note:
        'Udupi follows Simha masa; Rohini nakshatra may also be '
        'considered. Confirm with Udupi Sri Krishna Matha calendar.',
  ),
  Festival(
    id: 'swarna_gowri',
    name: Name(
      'Swarna Gowri Vrata',
      'ಸ್ವರ್ಣ ಗೌರಿ ವ್ರತ',
      null,
      'ಸ್ವರ್ಣ ಗೌರೀ ವ್ರತ',
    ),
    category: FestivalCategory.major,
    rule: LunarTithiRule(5, _s + 3, Kaala.sunrise),
  ),
  Festival(
    id: 'ganesh_chaturthi',
    name: Name('Ganesha Chaturthi', 'ಗಣೇಶ ಚತುರ್ಥಿ', 'ಚೌತಿ', 'ಗಣೇಶ ಚತುರ್ಥೀ'),
    category: FestivalCategory.major,
    rule: LunarTithiRule(5, _s + 4, Kaala.madhyahna),
    confidence: Confidence.high,
  ),
  Festival(
    id: 'ananta_chaturdashi',
    name: Name('Ananta Chaturdashi', 'ಅನಂತ ಚತುರ್ದಶಿ', null, 'ಅನಂತ ಚತುರ್ದಶೀ'),
    category: FestivalCategory.major,
    rule: LunarTithiRule(5, _s + 14, Kaala.sunrise),
  ),
  Festival(
    id: 'mahalaya_amavasya',
    name: Name(
      'Mahalaya Amavasya',
      'ಮಹಾಲಯ ಅಮಾವಾಸ್ಯೆ',
      'ಮಹಾಲಯ ಅಮಾಸೆ',
      'ಮಹಾಲಯ ಅಮಾವಸ್ಯಾ',
    ),
    category: FestivalCategory.major,
    rule: LunarTithiRule(5, 29, Kaala.aparahna),
  ),
  Festival(
    id: 'navaratri',
    name: Name('Navaratri begins', 'ನವರಾತ್ರಿ ಆರಂಭ'),
    category: FestivalCategory.major,
    rule: LunarTithiRule(6, _s + 1, Kaala.sunrise),
    confidence: Confidence.high,
    note: 'Mangaluru Dasara begins.',
  ),
  Festival(
    id: 'sharada_puja',
    name: Name(
      'Sharada Puja (Saraswati Puja)',
      'ಶಾರದಾ ಪೂಜೆ',
      null,
      'ಶಾರದಾ ಪೂಜಾ (ಸರಸ್ವತೀ ಪೂಜಾ)',
    ),
    category: FestivalCategory.major,
    rule: NakshatraRule(6, _s + 5, _s + 9, 18),
    note: 'Mula nakshatra during Navaratri.',
  ),
  Festival(
    id: 'durgashtami',
    name: Name('Durgashtami', 'ದುರ್ಗಾಷ್ಟಮಿ', null, 'ದುರ್ಗಾಷ್ಟಮೀ'),
    category: FestivalCategory.major,
    rule: LunarTithiRule(6, _s + 8, Kaala.sunrise),
  ),
  Festival(
    id: 'mahanavami',
    name: Name(
      'Mahanavami / Ayudha Puja',
      'ಮಹಾನವಮಿ / ಆಯುಧ ಪೂಜೆ',
      null,
      'ಮಹಾನವಮೀ / ಆಯುಧ ಪೂಜಾ',
    ),
    category: FestivalCategory.major,
    rule: LunarTithiRule(6, _s + 9, Kaala.sunrise),
  ),
  Festival(
    id: 'vijayadashami',
    name: Name('Vijayadashami', 'ವಿಜಯದಶಮಿ', null, 'ವಿಜಯದಶಮೀ'),
    category: FestivalCategory.major,
    rule: LunarTithiRule(6, _s + 10, Kaala.aparahna),
    confidence: Confidence.high,
  ),
  Festival(
    id: 'naraka_chaturdashi',
    name: Name('Naraka Chaturdashi', 'ನರಕ ಚತುರ್ದಶಿ', null, 'ನರಕ ಚತುರ್ದಶೀ'),
    category: FestivalCategory.major,
    rule: LunarTithiRule(6, _k + 14, Kaala.arunodaya),
    note: 'Deepavali oil bath (abhyanga) day.',
  ),
  Festival(
    id: 'deepavali_amavasya',
    name: Name(
      'Deepavali Amavasya (Lakshmi Puja)',
      'ದೀಪಾವಳಿ ಅಮಾವಾಸ್ಯೆ (ಲಕ್ಷ್ಮೀ ಪೂಜೆ)',
      'ದೀಪಾವಳಿ ಅಮಾಸೆ',
      'ದೀಪಾವಲೀ ಅಮಾವಸ್ಯಾ (ಲಕ್ಷ್ಮೀ ಪೂಜಾ)',
    ),
    category: FestivalCategory.major,
    rule: LunarTithiRule(6, 29, Kaala.pradosha),
    confidence: Confidence.high,
  ),
  Festival(
    id: 'bali_padyami',
    name: Name(
      'Bali Padyami (Balindra Puja)',
      'ಬಲಿಪಾಡ್ಯಮಿ',
      'ಬಲೀಂದ್ರ ಪೂಜೆ',
      'ಬಲಿ ಪ್ರತಿಪದಾ',
    ),
    category: FestivalCategory.tulu,
    rule: LunarTithiRule(7, _s + 1, Kaala.sunrise),
    confidence: Confidence.high,
  ),
  Festival(
    id: 'tulasi_puja',
    name: Name(
      'Tulasi Puja (Utthana Dwadashi)',
      'ತುಳಸಿ ಪೂಜೆ',
      'ತುಲಸಿ ಪೂಜೆ',
      'ತುಲಸೀ ಪೂಜಾ (ಉತ್ಥಾನ ದ್ವಾದಶೀ)',
    ),
    category: FestivalCategory.tulu,
    rule: LunarTithiRule(7, _s + 12, Kaala.pradosha),
    confidence: Confidence.low,
    note:
        'Puja is in the evening; some households use the sunrise '
        'Dwadashi day.',
  ),
  Festival(
    id: 'subrahmanya_shashti',
    name: Name(
      'Subrahmanya Shashti (Champa Shashti)',
      'ಸುಬ್ರಹ್ಮಣ್ಯ ಷಷ್ಠಿ',
      'ಷಷ್ಠಿ',
      'ಸುಬ್ರಹ್ಮಣ್ಯ ಷಷ್ಠೀ',
    ),
    category: FestivalCategory.tulu,
    rule: LunarTithiRule(8, _s + 6, Kaala.sunrise),
    note: 'Kukke Subrahmanya and naga temples.',
  ),
  Festival(
    id: 'hanumad_vrata',
    name: Name('Hanumad Vrata', 'ಹನುಮದ್ವ್ರತ', null, 'ಹನುಮದ್ ವ್ರತ'),
    category: FestivalCategory.vrata,
    rule: LunarTithiRule(8, _s + 13, Kaala.sunrise),
  ),
  Festival(
    id: 'vaikuntha_ekadashi',
    name: Name('Vaikuntha Ekadashi', 'ವೈಕುಂಠ ಏಕಾದಶಿ', null, 'ವೈಕುಂಠ ಏಕಾದಶೀ'),
    category: FestivalCategory.major,
    rule: SolarMonthTithiRule(8, _s + 11, Kaala.sunrise),
    note: 'Shukla Ekadashi in Dhanu masa.',
  ),
  Festival(
    id: 'ratha_saptami',
    name: Name('Ratha Saptami', 'ರಥಸಪ್ತಮಿ', null, 'ರಥ ಸಪ್ತಮೀ'),
    category: FestivalCategory.major,
    rule: LunarTithiRule(10, _s + 7, Kaala.sunrise),
  ),
  Festival(
    id: 'shivaratri',
    name: Name('Maha Shivaratri', 'ಮಹಾ ಶಿವರಾತ್ರಿ', 'ಶಿವರಾತ್ರೆ'),
    category: FestivalCategory.major,
    rule: LunarTithiRule(10, _k + 14, Kaala.nishita),
    confidence: Confidence.high,
  ),
  Festival(
    id: 'holi',
    name: Name('Holi / Kama Dahana', 'ಹೋಳಿ / ಕಾಮದಹನ', null, 'ಹೋಲೀ / ಕಾಮದಹನ'),
    category: FestivalCategory.major,
    rule: LunarTithiRule(11, _s + 15, Kaala.pradosha),
  ),

  // --- Sauramana (solar) / Tulunadu -----------------------------------------
  Festival(
    id: 'bisu',
    name: Name(
      'Bisu (Tulu New Year)',
      'ಬಿಸು (ಸೌರಮಾನ ಯುಗಾದಿ)',
      'ಬಿಸು ಪರ್ಬ',
      'ಬಿಸು (ತುಲು ನವವರ್ಷ)',
    ),
    category: FestivalCategory.tulu,
    rule: SolarDayRule(0, 1),
    confidence: Confidence.high,
    note: 'First day of Paggu. Depends on the solar-month day-1 rule.',
  ),
  Festival(
    id: 'pattanaje',
    name: Name('Pattanaje', 'ಪತ್ತನಾಜೆ'),
    category: FestivalCategory.tulu,
    rule: SolarDayRule(1, 10),
    note: '10th day of Beshe.',
  ),
  Festival(
    id: 'aati_amavasye',
    name: Name('Aati Amavasye', 'ಆಟಿ ಅಮಾವಾಸ್ಯೆ', 'ಆಟಿ ಅಮಾಸೆ', 'ಆಟಿ ಅಮಾವಸ್ಯಾ'),
    category: FestivalCategory.tulu,
    rule: SolarMonthTithiRule(3, 29, Kaala.sunrise),
    note: 'Pale kashaya (Alstonia bark) drink at dawn.',
  ),
  Festival(
    id: 'tula_sankramana',
    name: Name(
      'Tula Sankramana (Kaveri Sankramana)',
      'ತುಲಾ ಸಂಕ್ರಮಣ (ಕಾವೇರಿ ಸಂಕ್ರಮಣ)',
      null,
      'ತುಲಾ ಸಂಕ್ರಾಂತಿ (ಕಾವೇರೀ ಸಂಕ್ರಮಣ)',
    ),
    category: FestivalCategory.tulu,
    rule: SankrantiRule(6),
    confidence: Confidence.high,
  ),
  Festival(
    id: 'makara_sankranti',
    name: Name('Makara Sankranti', 'ಮಕರ ಸಂಕ್ರಾಂತಿ', 'ಮಕರ ಸಂಕ್ರಮಣ'),
    category: FestivalCategory.major,
    rule: SankrantiRule(9),
    confidence: Confidence.high,
  ),
  Festival(
    id: 'keddasa',
    name: Name('Keddasa', 'ಕೆಡ್ಡಸ'),
    category: FestivalCategory.tulu,
    rule: SolarDayRule(9, 27),
    confidence: Confidence.low,
    note:
        'Bhumi (earth) festival, about 10 February. The exact day '
        'reckoning (Puyintel 27) needs confirmation.',
  ),
];

// Recurring observances generated for every month.
const Festival ekadashi = Festival(
  id: 'ekadashi',
  name: Name('Ekadashi', 'ಏಕಾದಶಿ', null, 'ಏಕಾದಶೀ'),
  category: FestivalCategory.vrata,
  rule: LunarTithiRule(-1, 10, Kaala.sunrise), // and Krishna (25)
  confidence: Confidence.medium,
  note:
      'Smarta reckoning (Ekadashi at sunrise). Madhwa (arunodaya) '
      'variant noted when it differs.',
);
const Festival sankashti = Festival(
  id: 'sankashti',
  name: Name('Sankashti Chaturthi', 'ಸಂಕಷ್ಟ ಚತುರ್ಥಿ', null, 'ಸಂಕಷ್ಟೀ ಚತುರ್ಥೀ'),
  category: FestivalCategory.vrata,
  rule: LunarTithiRule(-1, _k + 4, Kaala.moonrise),
);
const Festival pradosha = Festival(
  id: 'pradosha',
  name: Name('Pradosha', 'ಪ್ರದೋಷ'),
  category: FestivalCategory.vrata,
  rule: LunarTithiRule(-1, 12, Kaala.pradosha),
);
const Festival purnima = Festival(
  id: 'purnima',
  name: Name('Purnima', 'ಹುಣ್ಣಿಮೆ', 'ಪುಣ್ಣಮೆ', 'ಪೂರ್ಣಿಮಾ'),
  category: FestivalCategory.vrata,
  rule: LunarTithiRule(-1, 14, Kaala.sunrise),
  confidence: Confidence.high,
);
const Festival amavasya = Festival(
  id: 'amavasya',
  name: Name('Amavasya', 'ಅಮಾವಾಸ್ಯೆ', 'ಅಮಾಸೆ', 'ಅಮಾವಸ್ಯಾ'),
  category: FestivalCategory.vrata,
  rule: LunarTithiRule(-1, 29, Kaala.sunrise),
  confidence: Confidence.high,
);

Festival sankramanaFestival(int rashi) => Festival(
  id: 'sankramana_$rashi',
  name: Name(
    '${rashiNames[rashi].en} Sankramana (${tuluMonthNames[rashi].en} begins)',
    '${rashiNames[rashi].kn} ಸಂಕ್ರಮಣ',
    '${rashiNames[rashi].kn} ಸಂಕ್ರಮಣ (${tuluMonthNames[rashi].tcy} ತಿಂಗೊಲು)',
    '${rashiNames[rashi].sa ?? rashiNames[rashi].kn} ಸಂಕ್ರಾಂತಿ',
  ),
  category: FestivalCategory.sankramana,
  rule: SankrantiRule(rashi),
  confidence: Confidence.high,
);

/// Every festival definition, including recurring ones (for settings/filters).
List<Festival> get allFestivals => [
  ...festivals,
  ekadashi,
  sankashti,
  pradosha,
  purnima,
  amavasya,
  for (var r = 0; r < 12; r++) sankramanaFestival(r),
];

// ---------------------------------------------------------------------------
// Evaluation
// ---------------------------------------------------------------------------

class FestivalCalculator {
  FestivalCalculator(this.engine);

  final PanchangaEngine engine;

  final Map<int, List<FestivalOccurrence>> _years = {};

  /// All occurrences whose date falls in Gregorian [year], sorted by date.
  List<FestivalOccurrence> forYear(int year) =>
      _years.putIfAbsent(year, () => _compute(year));

  /// Occurrences on a given civil date.
  List<FestivalOccurrence> on(DateTime date) {
    final d = PanchangaEngine.dateOnly(date);
    return forYear(d.year).where((o) => o.date == d).toList();
  }

  Window _window(DayPanchanga d, Kaala k) => switch (k) {
    Kaala.sunrise => Window(d.sunrise, d.sunrise),
    Kaala.arunodaya => d.kaalas.arunodaya,
    Kaala.madhyahna => d.kaalas.madhyahna,
    Kaala.aparahna => d.kaalas.aparahna,
    Kaala.pradosha => d.kaalas.pradosha,
    Kaala.nishita => d.kaalas.nishita,
    Kaala.moonrise =>
      d.moonrise == null ? Window(-1, -1) : Window(d.moonrise!, d.moonrise!),
  };

  /// Picks the civil day on which tithi [span] is observed for kaala [k].
  ({DayPanchanga day, String why}) pickDay(
    Span span,
    Kaala k,
    List<DayPanchanga> days,
  ) {
    final scored = <(DayPanchanga, double, bool)>[];
    for (final d in days) {
      if (d.nextSunrise + 1 < span.start || d.sunrise - 1 > span.end) continue;
      final w = _window(d, k);
      if (w.start < 0) continue;
      if (w.length == 0) {
        if (span.contains(w.start)) scored.add((d, 1.0, true));
      } else {
        final o = span.overlap(w.start, w.end);
        if (o > 0) scored.add((d, o, o >= w.length - 1e-9));
      }
    }
    if (scored.isEmpty) {
      // The tithi never touches the kaala (kshaya at that time): observe it
      // on the day it begins.
      final d = days.firstWhere(
        (d) => span.start >= d.sunrise && span.start < d.nextSunrise,
        orElse: () => days.firstWhere((d) => d.nextSunrise > span.start),
      );
      return (day: d, why: 'tithi does not touch ${k.label.en}; day it begins');
    }
    if (scored.length == 1) return (day: scored.first.$1, why: '');
    final a = scored[0], b = scored[1];
    if (a.$3 && b.$3) {
      final second = engine.config.tiePreference == TiePreference.second;
      return (
        day: second ? b.$1 : a.$1,
        why:
            'tithi covers ${k.label.en} on two days; '
            '${second ? 'second' : 'first'} day chosen',
      );
    }
    return (
      day: a.$2 >= b.$2 ? a.$1 : b.$1,
      why: 'tithi touches ${k.label.en} on two days; larger share chosen',
    );
  }

  List<FestivalOccurrence> _compute(int year) {
    final from = DateTime.utc(year, 1, 1).subtract(const Duration(days: 40));
    final count =
        DateTime.utc(
          year + 1,
          1,
          1,
        ).difference(DateTime.utc(year, 1, 1)).inDays +
        80;
    final days = engine.days(from, count);
    bool inYear(DateTime d) => d.year == year;

    // Unique tithi spans across the range.
    final tithis = <Span>[];
    for (final d in days) {
      for (final s in d.tithis) {
        if (tithis.isEmpty || s.start > tithis.last.start + 0.01) {
          tithis.add(s);
        }
      }
    }
    final dayIndex = {for (final d in days) d.date: d};
    LunarMonth monthOf(Span s) => engine.lunarMonthAt((s.start + s.end) / 2);

    final out = <FestivalOccurrence>[];
    void add(DayPanchanga d, Festival f, [String detail = '', double? at]) {
      if (inYear(d.date)) {
        out.add(
          FestivalOccurrence(
            date: d.date,
            festival: f,
            detail: detail,
            instant: at,
          ),
        );
      }
    }

    for (final f in festivals) {
      switch (f.rule) {
        case LunarTithiRule(:final month, :final tithi, :final kaala):
          for (final s in tithis.where((s) => s.index == tithi)) {
            final m = monthOf(s);
            if (m.index != month || m.adhika) continue;
            final p = pickDay(s, kaala, days);
            add(p.day, f, p.why);
          }
        case SolarMonthTithiRule(:final solarMonth, :final tithi, :final kaala):
          for (final s in tithis.where((s) => s.index == tithi)) {
            final p = pickDay(s, kaala, days);
            if (p.day.solar.month == solarMonth) add(p.day, f, p.why);
          }
        case SolarDayRule(:final solarMonth, :final day):
          for (final d in days) {
            if (d.solar.month == solarMonth && d.solar.day == day) {
              add(d, f, '', day == 1 ? d.solar.sankranti : null);
            }
          }
        case SankrantiRule(:final rashi):
          for (final d in days) {
            if (d.sankrantiToday != null && (d.sunRashi + 1) % 12 == rashi) {
              add(d, f, '', d.sankrantiToday);
            }
          }
        case NakshatraRule(
          :final month,
          :final fromTithi,
          :final toTithi,
          :final nakshatra,
        ):
          DayPanchanga? best;
          var bestO = 0.0;
          for (final d in days) {
            if (d.lunarMonth.index != month || d.lunarMonth.adhika) continue;
            if (d.tithi < fromTithi - 1 || d.tithi > toTithi) continue;
            for (final n in d.nakshatras.where((n) => n.index == nakshatra)) {
              final o = n.overlap(d.sunrise, d.sunset);
              if (o > bestO) {
                bestO = o;
                best = d;
              }
            }
          }
          if (best != null) add(best, f);
        case WeekdayBeforeRule(:final weekday, :final base):
          for (final s in tithis.where((s) => s.index == base.tithi)) {
            final m = monthOf(s);
            if (m.index != base.month || m.adhika) continue;
            var d = pickDay(s, base.kaala, days).day.date;
            while (d.weekday % 7 != weekday) {
              d = PanchangaEngine.addDays(d, -1);
            }
            final day = dayIndex[d];
            if (day != null) add(day, f);
          }
      }
    }

    // Recurring vratas.
    for (final s in tithis) {
      final rec = switch (s.index) {
        10 || 25 => ekadashi,
        18 => sankashti,
        12 || 27 => pradosha,
        14 => purnima,
        29 => amavasya,
        _ => null,
      };
      if (rec == null) continue;
      final rule = rec.rule as LunarTithiRule;
      final p = pickDay(s, rule.kaala, days);
      final m = monthOf(s);
      final paksha = s.index < 15 ? 'Shukla' : 'Krishna';
      var detail =
          '${m.adhika ? 'Adhika ' : ''}${lunarMonthNames[m.index].en} $paksha';
      if (rec == ekadashi) {
        // Madhwa / Vaishnava: Ekadashi touched by Dashami at arunodaya is
        // observed the next day.
        final aru = p.day.kaalas.arunodaya.start;
        if (aru < s.start) {
          detail += '; Madhwa (arunodaya) observance: next day';
        }
      }
      add(p.day, rec, detail);
    }

    // Monthly sankramanas (skipping those already listed by name).
    final named = {
      for (final f in festivals)
        if (f.rule case SankrantiRule(:final rashi)) rashi,
    };
    for (final d in days) {
      final sk = d.sankrantiToday;
      final r = (d.sunRashi + 1) % 12;
      if (sk != null && !named.contains(r)) {
        add(d, sankramanaFestival(r), '', sk);
      }
    }

    out.sort((a, b) {
      final c = a.date.compareTo(b.date);
      if (c != 0) return c;
      return a.festival.category.index.compareTo(b.festival.category.index);
    });
    return out;
  }
}

/// Convenience: festivals for [year] at [place].
List<FestivalOccurrence> festivalsFor(
  int year,
  Place place, [
  PanchangaConfig config = const PanchangaConfig(),
]) => FestivalCalculator(PanchangaEngine(place, config)).forYear(year);
