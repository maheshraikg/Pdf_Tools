# Sorting Sahayak (ಸಾರ್ಟಿಂಗ್ ಸಹಾಯಕ)

A fully offline Android helper for postal sorting assistants in India. It sorts
articles by PIN code and place name using **your own office's sorting scheme**,
finds a PIN from an address, catches PIN–city mismatches, scans addresses with
the camera, counts articles per bag, and lets you practise the scheme.

> **Independent helper tool for postal staff. Not an official Department of Posts app.**
> It does not use the India Post name, logo, colours or branding.

- 100 % free: no paid APIs, no server, no login, no ads, no analytics.
- Works with no internet and no SIM. The release APK has **no INTERNET permission**.
- English, ಕನ್ನಡ and हिन्दी (follows the device language; change it in Settings).

---

## Features

| Tab | What it does |
|---|---|
| **Sort (ಸಾರ್ಟ್)** | Big custom keypad; the result updates as you type. After 3 digits you get the sorting district and the likely bag (prefix rules). After 6 digits you get the final bag in huge text on the bag colour, plus code, section, remarks, the delivery office(s) and the PIN structure. Mail category toggle (Letters / Parcel / Air Parcel / Speed Post / your own). **Air Parcel** mode shows the air label code in very large letters (copy + read-out), the YELLOW **AIR** / BLUE **SURFACE** badge, the **L2 → L1 hub** route from the active DMSL, and the bag. Also: voice input, camera scan, recent lookups, optional "place on address" mismatch check, **Label view** (big label card, share as image or text), haptics and optional TTS. |
| **Find PIN (ಪಿನ್ ಹುಡುಕಿ)** | Search office, village, city, taluk or district in English, Kannada or Hindi. It tolerates spelling mistakes: `Puttoor`, `Putur`, `ಪುತ್ತೂರು` and `पुत्तूर` all find Puttur. Filter chips (state, district, delivery only). Each result shows the bag from the active scheme. **PIN ↔ place check**: ✅ match · ⚠️ same district, different PIN (suggests the right PIN) · ❌ different district/state (suggests likely PINs). |
| **Bulk (ಗುಂಪು)** | Sessions (name, date, scheme, category). Enter PINs quickly with the keypad or scanner. Each entry flashes its bag colour, and you can undo the last entry. Live counts per bag, per air code, per hub and per Air/Surface, plus a list of unresolved entries to fix. The summary can be shared as text, CSV or a printable text file. |
| **Learn (ಅಭ್ಯಾಸ)** | Flashcards with Leitner spaced repetition, a timed 20-question quiz (4 options, score, articles per minute, history chart), weak areas, and a PIN basics lesson with the circle table. Air-code and hub cards too. After a new DMSL you can practise only the PINs whose hub changed. It works with the SAMPLE scheme. |
| **More** | Schemes (import, create/edit, export, set active, delete), PIN directory info and update from CSV, favourites, airport codes, settings, help, about. |

---

## Build

Requirements: Flutter 3.47+ (Dart 3.13+), Android SDK (platform 36), JDK 17+.

```bash
cd sorting_sahayak
flutter pub get
flutter analyze
flutter test
flutter build apk --release --split-per-abi   # recommended: one APK per CPU type
# or a single universal APK:
flutter build apk --release
```

The APKs are written to `build/app/outputs/flutter-apk/` (for example
`app-arm64-v8a-release.apk`). Most phones need the arm64 one.

Release builds are signed with the debug key so the command works out of the
box. For distribution, create a keystore and set `signingConfig` in
`android/app/build.gradle.kts`.

### APK size

The address scanner bundles **only the English (Latin) ML Kit model**; the
Hindi (Devanagari) model was dropped to save space, because addresses are
mainly written in English.

First CI measurement (`flutter build apk --release --split-per-abi`), taken
**with the Hindi model still included** and only a 27-row test directory:

| APK | Size |
|---|---|
| `app-arm64-v8a-release.apk` | 35.5 MB |
| `app-armeabi-v7a-release.apk` | 29.3 MB |
| `app-x86_64-release.apk` | 37.5 MB |

The app now bundles the real all-India directory (27.3 MB on disk,
157,000 offices). Each CI run prints the current APK sizes in its job
summary. A Karnataka-only directory would be ~1.5 MB instead. Further ways
to shrink:

* build a state-only DB: `dart run tool/build_directory_db.dart --state Karnataka`;
* publish an App Bundle (`flutter build appbundle`) so each phone downloads
  only its own ABI.

The CI job also checks that the merged release manifest has no INTERNET
permission (passes).

---

## PIN directory (bundled, offline)

Source: **"All India Pincode Directory"** open dataset, data.gov.in
(Open Government Data Licence – India).

1. Download the CSV from
   <https://www.data.gov.in/resource/all-india-pincode-directory-till-last-month>
   (also on the catalogue page <https://www.data.gov.in/catalog/all-india-pincode-directory>).
2. Save it as `sorting_sahayak/data/pincode_directory.csv` (git-ignored).
3. Build the database:

   ```bash
   dart run tool/build_directory_db.dart                       # full India (default)
   dart run tool/build_directory_db.dart --state Karnataka     # one state only
   dart run tool/build_directory_db.dart --no-fts              # skip FTS5 index
   ```

   This writes `assets/db/pincode_directory.db`. If you ship a newer DB in an
   app update, bump `kBundledDirectoryVersion` in `lib/data/db.dart`.

> **Bundled data:** `assets/db/pincode_directory.db` was built from the
> data.gov.in "All India Pincode Directory" file as republished unchanged at
> <https://github.com/dropdevrahul/pincodes-india> (`pincode.csv`, committed
> 2024-05-05; 157,126 rows → 157,000 unique offices, 19,300 PINs), because
> data.gov.in itself was not reachable from the build machine. To refresh it,
> download the latest CSV from data.gov.in and rebuild with the command above
> (or import it in the app).

The builder does the following:

* detects columns (circlename, regionname, divisionname, officename, pincode,
  officetype, delivery/Deliverystatus, district/Districtname, statename, Taluk,
  latitude, longitude) and supports both data.gov.in layouts;
* trims values, title-cases names, and moves " B.O" / " S.O" / " H.O" / " G.P.O"
  suffixes into `office_type`;
* drops exact duplicates and turns "NA" coordinates into null;
* writes `offices` (with a `units` lookup table for division/region/circle),
  indexes on pincode, normalised name, phonetic key and district, an FTS5
  table (the app falls back to LIKE if the phone's SQLite has no FTS5), and a
  `meta` table (source, file date, row count).

On first launch, the app copies the asset DB into app storage. You can load a
newer CSV later from **More → PIN directory → Update PIN directory from CSV**.
It is parsed in a background isolate with a progress bar and uses the same
cleaning code as the builder.

Performance, measured by `test/performance_test.dart` on a synthetic
165k-row directory on a desktop: PIN lookup averages **0.6 ms**, fuzzy place
search averages **~6 ms** (worst ~26 ms). Targets are < 50 ms and < 200 ms on a
low-end phone.

---

## Importing your sorting scheme

**More → Sorting schemes → Add → Import scheme.** Pick an `.xlsx` or `.csv`
file. The wizard then walks you through these steps:

1. **Preview** of the first 20 rows. Pick the sheet and the header row; title
   rows above the header are fine.
2. **Column mapping**, auto-detected from English, Kannada or Hindi headers,
   for example `PIN`, `PIN From`, `Bag No`, `ಪಿನ್`, `ಚೀಲ ಸಂಖ್ಯೆ`, `ಜಿಲ್ಲೆ`,
   `पिन कोड`, `थैला संख्या`. Change any wrong mapping.
3. **Validation report**: bad PINs, overlapping/nested ranges, duplicate and
   conflicting rules, rows with no bag, unknown colours.
4. **Save**. You can keep several schemes; only one is active at a time.

You can also **create or edit a scheme in the app**: add, edit and delete
rules and bags, and pick bag colours. To share a scheme with your team, use
**export as .xlsx / .csv**. **Download template** saves a blank template.
**Add SAMPLE scheme** installs the demo scheme, which is clearly marked
"SAMPLE – not real".

### Scheme file format (bag rules)

Columns can be in any order; only the ones you use are needed.

| Column | Meaning |
|---|---|
| `Type` | Optional: `PIN`, `Range`, `Prefix`, `Office`, `District`, `State`, `Default`. If blank, the type is inferred from the filled cells. |
| `PIN` | Exact PIN (`574201`). Also accepts `574201-574299` (range) or `575` / `575xxx` (prefix). |
| `PIN From`, `PIN To` | PIN range. |
| `Prefix` | First 1–5 digits (`57`, `575`, `5742`). |
| `Office` | Office / place name, for articles without a PIN. |
| `District`, `State` | District / state rules. |
| `Bag No` | Bag code (required, or `Bag Name`). |
| `Bag Name`, `Section`, `Remarks` | Shown with the result. |
| `Category` | `Ordinary/Letters`, `Parcel (surface)`, `Air Parcel`, `Speed Post` or your own; blank = all categories. |
| `Connectivity` | `Air` / `Surface`, used for the parcel label badge. If blank, the app assumes Surface and shows a warning. |
| `Colour` | `#D32F2F` or a colour name (`red`, `blue`, …). |

A row with no PIN/office/district/state (or with `All other` / `Default`) is
the **default bag**.

**Priority** when several rules match:
exact PIN > smallest range > longest prefix > office name > district > state > default.
Within one level, a rule for the selected category beats an all-categories rule.

Example (`assets/samples/sample_scheme.csv` has ~33 fake rules covering every type):

```csv
Type,PIN,PIN From,PIN To,Prefix,Office,District,State,Bag No,Bag Name,Section,Remarks,Category,Connectivity,Colour
PIN,574201,,,,,,,Bag 12,Puttur SO,A,,,,#D32F2F
Range,,574210,574219,,,,,Bag 15,Bantwal / Belthangady,A,,,,#D81B60
Prefix,,,,575,,,,Bag 02,Mangaluru NSH,B,,,,#0097A7
Office,,,,,Sullia,,,Bag 14,Sullia SO,,Articles without PIN,,,
District,,,,,,Udupi,,Bag 20,Udupi Division,,,,,
State,,,,,,,Kerala,Bag 61,Kerala – other,,,,,
Prefix,,,,56,,,,AP-01,Air parcel – Bengaluru,,,Air Parcel,Air,#FBC02D
Default,,,,,,,,Bag 99,All other – send to TMO,Z,Out of circle,,,#212121
```

### Air code sheet

Import it from the scheme's menu (**Import air code sheet**). Columns: `PIN`,
`PIN From`, `PIN To`, `Prefix`, `District`, `State`, `Air Code`, `Station`,
`Via`, `Remarks`. It uses the same priority: exact > range > prefix >
district > state > default. Codes are checked against the bundled airport
table, and unknown codes are **kept with a warning**, because offices may use
their own codes. The app **never** assigns an air code from the airport table.

```csv
Type,PIN,PIN From,PIN To,Prefix,District,State,Air Code,Station,Via,Remarks
Prefix,,,,56,,,BLR,Bengaluru (demo),,SAMPLE – not real
District,,,,,Mysuru,,MYQ,Mysuru (demo),Bengaluru (demo),SAMPLE – not real
```

### DMSL (Due Mail Sorting List) – L1/L2 parcel hubs

Import it from the scheme's menu (**Import DMSL**). Columns: `PIN` / `PIN From`
/ `PIN To` / `Prefix` / `Office` / `District` / `State`, `L2 Hub`, `L1 Hub`,
`Direct closure (Y/N)`, `Connectivity`, `Remarks`. Each import is stored as a
version with a name and a **valid from** date, and the newest one becomes
active. The app then shows a **diff against the previous version**: every PIN
whose L2/L1 hub, direct closure or connectivity changed, checked over all
directory PINs. From that screen you can practise just those PINs. Hub lists
are never hard-coded; the 7 Oct 2026 rationalisation (L1 79 → 60, L2 109 → 127)
is exactly the kind of change this handles.

```csv
Type,PIN,PIN From,PIN To,Prefix,Office,District,State,L2 Hub,L1 Hub,Direct closure (Y/N),Connectivity,Remarks
Prefix,,,,574,,,,Puttur L2 (demo),Mangaluru L1 (demo),N,Surface,SAMPLE – not real
Prefix,,,,56,,,,,Bengaluru L1 (demo),Y,Air,SAMPLE – not real
```

The Air/Surface badge comes from the DMSL rule if it has connectivity,
otherwise from the bag rule, otherwise Surface (with a warning).

Templates are in `assets/samples/template_*.xlsx|csv`. Regenerate the samples
and templates with `dart run tool/make_samples.dart`.

---

## Privacy

* No network access: `INTERNET`, `ACCESS_NETWORK_STATE` and
  `ACCESS_WIFI_STATE` are removed from the release manifest with
  `tools:node="remove"`. Only the debug build keeps INTERNET, for Flutter
  tooling.
* Camera scans are processed on-device by ML Kit (bundled models, no
  download). The photo file is deleted right after recognition and the
  recognised text is discarded. Nothing is stored or uploaded.
* Sorting schemes are department documents. The app ships with no scheme
  data, and schemes stay in the app's private database. App data is excluded
  from Android cloud backup and device transfer.
* Voice input uses the phone's speech recogniser. It works offline when the
  language pack is installed on the phone; otherwise Android's recogniser may
  need its own connection, outside this app.
* TTS read-out uses the phone's text-to-speech engine and is off by default.

---

## Known limitations

* **Kannada OCR:** ML Kit has no Kannada model. For Kannada-script
  addresses the scanner relies on the PIN digits, and you search the place
  by hand. Kannada/Devanagari digits are converted automatically. Only the
  English (Latin) recogniser is bundled, so Hindi-script addresses work the
  same way (PIN digits + manual search; typed Hindi search still works).
* The bundled directory is the May 2024 data.gov.in release. Offices opened or
  closed since then are missing or stale until you update it (More → PIN
  directory).
* Circle names from the first two PIN digits are approximate where small
  circles share digits (Goa, Chandigarh, Sikkim, … are refined by three digits).
* The transliteration is a simple table-based scheme tuned for place names,
  not a full romanisation. Renamed cities (Bangalore/Bengaluru,
  Mangalore/Mangaluru, …) are covered by an alias table.
* Android's system SQLite may lack FTS5; the app then falls back to LIKE
  (slower, still well within targets).
* Not verified on a real device from the development container: camera/ML
  Kit, speech recognition, TTS, file picker, share sheet and the release
  APK build.

## Tests

`flutter test` runs unit and widget tests: PIN utilities (validation,
extraction, OCR fixes, Kannada/Hindi digits), transliteration and fuzzy
search, directory builder and search (FTS5 and LIKE), mismatch checker,
scheme resolver priority, category rules, air codes, DMSL diff, import
column auto-detection and validation, the sample files, export round-trip,
bulk counter, learn engine, voice digit parsing, a 165k-row performance
test, and widget tests for the Sort screen (incl. Air Parcel mode and the
Air/Surface badge) and the Find PIN screen. Tests use a small fixture DB
(`test/fixtures/directory.csv`).

## Project layout

```
lib/main.dart
lib/core/      theme, l10n (ARB: en/kn/hi), constants, pin_utils, fuzzy, transliterate,
               settings, feedback (haptics/TTS), voice, files, shared widgets
lib/data/      db, user_db, directory_builder/repo/update, scheme_repo, resolver,
               sort_engine, mismatch, dmsl_diff, airports, user_repo, import/, models/
lib/features/  lookup/ find_pin/ scan/ bulk/ learn/ schemes/ settings/
tool/          build_directory_db.dart, make_samples.dart
assets/db/     pincode_directory.db
assets/samples/ sample_* and template_* (.xlsx/.csv) – SAMPLE, not real
test/
```

## Roadmap (not built yet)

* Supervisor mode: push scheme updates to the team through a shared file link.
* Bag label printing.
* Beat-wise sorting for postmen (delivery sequence by street).
* Richer Speed Post / parcel hub rules.
* Home-screen quick-lookup widget.

## Credits

PIN data: data.gov.in, Government of India, Open Government Data Licence.
Airport codes: public IATA codes.
