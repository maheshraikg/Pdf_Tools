# What to verify with a priest or a printed panchanga

The astronomy is checked against the Swiss Ephemeris (see
`test/astro_test.dart`). What follows are the **conventions**: choices a
priest, a matha calendar or a printed Tulu/Kannada panchanga (e.g. Udupi or
Mangaluru almanacs) should confirm. Each convention that can vary is a setting
in the app (Settings › Conventions), so a correction is a change of setting or
a one-line rule change in `lib/panchanga/festivals.dart`.

Fill in the `priest_date` / `priest_comment` columns of
`docs/csv/festivals_mangaluru_<year>.csv` while checking.

## 1. Day and time conventions

| # | Convention used | Alternatives | Where |
|---|---|---|---|
| 1 | **Sunrise = upper limb with standard refraction (−0.833°)**, as most modern printed panchangas and drikpanchang.com do. | Centre of the disc without refraction (traditional), about 2–3 min later. | Settings › Sunrise definition |
| 2 | **Hindu day runs sunrise to sunrise**; the tithi/nakshatra *of the day* is the one at sunrise (udaya). | — | engine |
| 3 | **Lahiri (Chitrapaksha) ayanamsa**, mean (Swiss Ephemeris `SIDM_LAHIRI`). | Raman, KP, true-Chitra. Affects nakshatra, rashi and sankramana times (about 1 min per 2.5″). | `lahiriAyanamsa()` |
| 4 | **Lunar months are amanta** (new moon to new moon); named after the rashi the Sun is in at the opening new moon (+1); **adhika** when the Sun does not change rashi during the month (e.g. Adhika Jyeshtha, 17 May – 15 Jun 2026). | Purnimanta (north India). | `lunarMonthAt()` |
| 5 | **Tulu month day 1**: if the sankramana is **before sunset**, that day is day 1; otherwise the next day. Example: Makara sankramana 2026 at 15:07 on 14 Jan, so Puyintel 1 = 14 Jan. | (a) before the end of madhyahna (3/5 of daytime): Kerala rule; (b) always the next day. **This decides Bisu, Pattanaje and Keddasa, and every Tulu date.** | Settings › Tulu month day 1 |
| 6 | Samvatsara changes at Chandramana Ugadi; a **Sauramana samvatsara** (changes at Bisu) is shown separately when it differs. | — | `DayPanchanga.samvatsara` |
| 7 | **Ritu** by lunar month (Chaitra–Vaishakha = Vasanta, …); **ayana** by sidereal Sun (Uttarayana from Makara sankramana). | Ritu by solar month; tropical ayana (from 21/22 Dec). | `DayPanchanga.ritu/ayana` |
| 8 | **Rahu kaala / Yamaganda / Gulika**: daytime split into 8 equal parts. Rahu: Sun 8, Mon 2, Tue 7, Wed 5, Thu 6, Fri 4, Sat 3; Yamaganda: 5,4,3,2,1,7,6; Gulika: 7,6,5,4,3,2,1. | Some panchangas use fixed 06:00–18:00 clock times (e.g. Rahu Sun 16:30–18:00). | `_rahuPart` etc. |
| 9 | **Abhijit** = 8th of 15 daytime muhurtas, not shown on Wednesdays. | — | `_kaalas()` |
| 10 | **Durmuhurta** (1-based daytime muhurta numbers): Sun 14; Mon 9, 12; Tue 4 + 7th night muhurta; Wed 8; Thu 6, 12; Fri 4, 9; Sat 1, 2. | Tables differ between sources: **please verify**. | `_durmuhurta` |
| 11 | **Brahma muhurta** = 14th muhurta of the preceding night (two night-muhurtas before sunrise). | Fixed 96/48 minutes before sunrise. | `_kaalas()` |
| 12 | **Kaala windows for festivals**: madhyahna = 3rd fifth of daytime, aparahna = 4th fifth, pradosha = sunset + 1/5 of the night, nishita = 8th night muhurta, arunodaya = two night-muhurtas before sunrise. | Pradosha is sometimes taken as 3 muhurtas (≈ 2 h 24 m) after sunset. | `_kaalas()` |
| 13 | **Tithi on two days at the required kaala**: the larger overlap wins; if both days are fully covered, the **first** day is chosen. If the tithi never touches the kaala, the day it begins is used. | "Second day" preference (setting). | Settings › Tithi on two days |
| 14 | **Moonrise/moonset** within the Hindu day (an after-midnight moonrise belongs to the previous date). Upper limb + refraction + parallax. | — | engine |
| 15 | **Ekadashi**: Smarta (Ekadashi at sunrise). When Dashami touches arunodaya, the list notes that **Madhwa/Vaishnava** observance is the next day. Udupi (Madhwa) users should check each Ekadashi. | Full Madhwa rules (Vaishnava/Smarta lists, Mahadwadashi). | `festivals.dart` |

## 2. Festival rules (Mangaluru defaults)

Confidence is my own estimate of how well the rule matches local practice.

| Festival | Rule | Confidence |
|---|---|---|
| Makara Sankranti, Tula (Kaveri) Sankramana, monthly sankramanas | Hindu day containing the sankramana | high |
| Bisu (Tulu new year) | Paggu 1 (depends on convention 5) | high |
| Pattanaje | Beshe 10 | medium |
| **Keddasa** | **Puyintel 27** (about 10 Feb), a guess at the reckoning | **low** |
| Aati Amavasye | Amavasya at sunrise in Aati (Karka) solar month | medium |
| Chandramana Ugadi | Chaitra Shukla Pratipada at sunrise | high |
| Sri Rama Navami | Chaitra Shukla Navami at madhyahna | high |
| Akshaya Tritiya | Vaishakha Shukla Tritiya at sunrise | medium |
| Guru Purnima | Ashadha Purnima at sunrise | medium |
| Nagara Panchami | Shravana Shukla Panchami at sunrise | medium |
| Varamahalakshmi | last Friday on/before Shravana Purnima | medium |
| Nooli Hunnime / Upakarma | Shravana Purnima at sunrise (Rig/Yajur upakarma can differ by nakshatra) | medium |
| Krishna Janmashtami (Chandramana) | Shravana Krishna Ashtami at nishita | high |
| **Sri Krishna Jayanti, Udupi (Sauramana)** | Krishna Ashtami at nishita in **Simha** solar month; Rohini nakshatra not considered | **low** |
| Swarna Gowri | Bhadrapada Shukla Tritiya at sunrise. **In 2026 this gives 14 Sep, the same day as Ganesha Chaturthi**: please check. | medium |
| Ganesha Chaturthi | Bhadrapada Shukla Chaturthi at madhyahna | high |
| Ananta Chaturdashi | Bhadrapada Shukla Chaturdashi at sunrise | medium |
| Mahalaya Amavasya | Bhadrapada Amavasya at aparahna | medium |
| Navaratri begins (Mangaluru Dasara) | Ashvayuja Shukla Pratipada at sunrise | high |
| Sharada Puja | Mula nakshatra (longest in daytime) between Shukla 4 and 9 of Ashvayuja | medium |
| Durgashtami / Mahanavami | Ashvayuja Shukla 8 / 9 at sunrise. **2026: Mahanavami and Vijayadashami both fall on 20 Oct**: please check. | medium |
| Vijayadashami | Ashvayuja Shukla Dashami at aparahna | high |
| Naraka Chaturdashi | Ashvayuja Krishna Chaturdashi at arunodaya (**2026: same day as Deepavali Amavasya, 8 Nov**) | medium |
| Deepavali Amavasya (Lakshmi puja) | Ashvayuja Amavasya at pradosha | high |
| Bali Padyami (Balindra puja) | Kartika Shukla Pratipada at sunrise | high |
| **Tulasi Puja** | Kartika Shukla Dwadashi at **pradosha** (evening) | **low** |
| Subrahmanya (Champa) Shashti | Margashira Shukla Shashti at sunrise | medium |
| Hanumad Vrata | Margashira Shukla Trayodashi at sunrise | medium |
| Vaikuntha Ekadashi | Shukla Ekadashi in **Dhanu** solar month | medium |
| Ratha Saptami | Magha Shukla Saptami at sunrise | medium |
| Maha Shivaratri | Magha (amanta) Krishna Chaturdashi at nishita | high |
| Holi / Kama Dahana | Phalguna Purnima at pradosha | medium |
| Sankashti Chaturthi | Krishna Chaturthi at moonrise | medium |
| Pradosha | Trayodashi at pradosha | medium |

## 3. Muhurta helper presets

The nakshatra/weekday/month sets in `lib/panchanga/muhurta.dart` are commonly
quoted lists (Muhurta Chintamani style), simplified:

- **General**: Mon/Wed/Thu/Fri; no Rikta tithi (4, 9, 14), no Amavasya, no
  Vishti karana, no Vyatipata/Vaidhriti yoga; outside Rahu/Yamaganda/Gulika/
  Durmuhurta; adhika masa skipped.
- **Griha pravesha**: Rohini, Mrigashira, Uttara Phalguni, Chitra, Anuradha,
  Uttara Ashadha, Uttara Bhadrapada, Revati, Dhanishta, Shatabhisha; months
  Vaishakha, Jyeshtha, Magha, Phalguna.
- **Vehicle, business, travel, namakarana**: see the file.
- **Tarabala** (taras 3, 5, 7 avoided) and **Chandrabala** (moon in 1, 3, 6, 7,
  10, 11 from janma rashi) when the birth star/rashi is set.

**Not checked**: Varjyam, Amrita kaala, Guru/Shukra asta (combustion),
Chaturmasa, Disha shoola, Panchaka, lagna and Kartari dosha. Marriage and
upanayana are not offered.

## 4. Tulu words to check with a native speaker

- **Months** (romanised / Kannada script): Paggu ಪಗ್ಗು, Beshe ಬೇಸ, Kartel ಕಾರ್ತೆಲ್,
  Aati ಆಟಿ, Sona ಸೋಣ, Nirnal ನಿರ್ನಾಲ್, Bontel ಬೊಂತೆಲ್, Jaarde ಜಾರ್ದೆ, Perarde
  ಪೆರಾರ್ದೆ, Puyintel ಪುಯಿಂತೆಲ್, Maayi ಮಾಯಿ, Suggi ಸುಗ್ಗಿ (spellings vary).
- **Weekdays**: ಐತಾರ, ಸೋಮಾರ, ಅಂಗಾರೆ, ಬುದಾರ, ಗುರುವಾರ, ಸುಕ್ರಾರ, ಸನಿವಾರ.
- **Tithis**: Amavasya ಅಮಾಸೆ, Purnima ಪುಣ್ಣಮೆ; other tithis use the Kannada names.
- **Places**: ಕುಡ್ಲ (Mangaluru), ಒಡಿಪು (Udupi), ಬೆದ್ರ (Moodbidri), ಬೊಂಬಾಯಿ (Mumbai).
- **UI words**: ಇನಿ (today), ಪರ್ಬೊಲು (festivals), ಮುಟ್ಟ (until), ಎಲ್ಲೆ
  (tomorrow / next day), ಇತ್ತೆ (now), ಜಾಗೆ (place), ಬಾಸೆ (language), ಪುದರ್
  (name), ವರ್ಸ (year), ದಿನೊಕುಲು (days), ದಾಲ ಇಜ್ಜಿ (nothing), ಮಾತ (all),
  ತಿಂಗೊಲು (month), ತುಳು ಲಿಪಿಡ್ ತೋಜಾಲೆ (show in Tulu lipi). Everything else
  in Tulu mode uses the Kannada word.
- **Tulu lipi**: Kannada → Tulu-Tigalari transliteration is shared with Tulu
  Nighantu; Unicode 16 has no short e/o, so ಎ/ಒ map to ಏ/ಓ forms.

## 5. Not verified (and why)

- **No comparison with a printed Tulu panchanga or drikpanchang.com was
  possible**: the build machine had no access to those sources. The
  astronomy is verified against the Swiss Ephemeris; the festival dates in
  `test/panchanga_test.dart` are widely published Karnataka dates I am
  confident of (Ugadi, Shivaratri, Janmashtami, Ganesha Chaturthi,
  Vijayadashami, Deepavali for 2026/2027). All other rows need the checks
  above.
- **Posa Puttari / Kurale Parba** (new-rice festival), **Udupi Paryaya**,
  temple jatres, kambala dates and Bhuta kola calendars are local
  announcements, not computed.
- **Keddasa** reckoning and the **Udupi Sauramana Krishna Jayanti** rule.
- **Android device behaviour** (widget, scheduled notifications, sharing)
  could not be run on a device here; it is built in CI only.
