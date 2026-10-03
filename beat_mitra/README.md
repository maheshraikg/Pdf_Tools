# Beat Mitra (ಬೀಟ್ ಮಿತ್ರ · बीट मित्र)

A personal, offline helper for postmen: learn a delivery beat fast, find
addresses, plan the day's route and record deliveries.

> **Independent helper tool for postmen. Not an official Department of Posts
> app. Follow your office's rules on customer information.**

- 100 % free and open tools. No server, no login, no ads, no analytics, no
  crash reporting.
- Works with no internet. The default build has **no INTERNET permission**.
- Languages: ಕನ್ನಡ, English, हिन्दी (follows the phone language by default).
- Big text and buttons, light / dark theme and a high-contrast **sunlight mode**.

## Builds

| Flavor | File | Network |
|---|---|---|
| `offline` (default) | `app-offline-release.apk` | none: INTERNET is removed from the manifest |
| `map` | `app-map-release.apk` | INTERNET, used only by the optional OpenStreetMap view (OFF by default) |

Both flavors can be installed side by side (`com.beatmitra.beat_mitra` and
`com.beatmitra.beat_mitra.map`).

```bash
flutter pub get
flutter run                                   # offline flavor (default-flavor in pubspec)
flutter run --flavor map                      # with the optional map
flutter build apk --release --flavor offline  # build/app/outputs/flutter-apk/app-offline-release.apk
flutter build apk --release --flavor map
flutter analyze && flutter test
```

The GitHub Actions workflow `.github/workflows/beat-mitra.yml` runs analyze,
tests, builds both APKs, checks that the offline APK has no INTERNET permission
and uploads the APKs as the `beat-mitra-apks` artifact.

Release APKs are signed with the Flutter debug key so they install directly.
For a Play Store release create your own keystore and signing config in
`android/app/build.gradle.kts`.

### Install on your phone

1. Download `app-offline-release.apk` (from the workflow artifact or your own
   build) to the phone.
2. Allow "Install unknown apps" for your file manager / browser when asked.
3. Open the APK and install. Or with a USB cable: `adb install app-offline-release.apk`,
   or `flutter run --release` with the phone connected.

## How to use

1. **First start**: choose language, read the privacy notes, create a 4-digit
   PIN (fingerprint / face can be turned on in Settings).
2. **Create your beat** (you can keep more than one: own beat + relief beats).
3. **Beat & streets**: add streets and drag them into your usual walking
   order. Add *area notes* such as "cross numbers increase towards the lake".
4. **Add here** (big yellow button) while standing at a door: GPS starts at
   once (auto-accepted at ≤ 20 m, or tap "Use this location"), the camera
   opens for 1–3 photos, then a short form: door no., street, names (voice
   input), landmark, notes ("dog", "gate"), delivery preference. Saved places
   within 30 m are shown so you don't create duplicates; duplicates can be
   merged later.
5. **Search** (most-used screen): type or speak a name, door no., street,
   building, landmark, area or PIN. "ರಮೇಶ್", "Ramesh", "Rameshh", "रमेश" all
   match; "12/3", "12-3", "#12/3" all match. Results show the photo, distance
   and a direction arrow, and buttons for Navigate, Google Maps, Call, Edit.
6. **Navigate**: a big arrow (GPS bearing + compass) and metres to the house.
   The phone vibrates within 20 m. No internet needed.
7. **Today's articles**: scan barcodes (S10 numbers like `EK123456785IN` are
   validated, including the check digit; other formats are allowed), photograph
   the address (on-device OCR) or type it. Each article is matched to a place
   with up to 3 suggestions; unmatched ones are listed with "Add new place".
   Registered / Speed Post / money orders are labelled "Needs signature / OTP".
8. **Route & delivery**: plan the route (shortest: nearest-neighbour + 2-opt on
   straight-line distance; or your street walking order), drag to reorder
   (the order inside each street is remembered), then **Start delivery**:
   ✅ Delivered, ❌ Not delivered (reason chips), ➡️ Skip, 🧭 Navigate. Time and
   GPS of each action are stored on the phone. Optional read-aloud of the next
   stop.
9. **Day summary**: counts by type and status, not-delivered reasons,
   carry re-attempts to the next day, distance, share as plain text (without
   addressee names). History calendar; history older than 90 days (setting) is
   deleted automatically.
10. **Learn the beat**: flashcards (photo → place, name → door no., door no. →
    landmark), *walk mode* that quizzes you about the nearest house, progress
    and weak streets.
11. **Handover & backup**: export a beat for a relief postman as a
    password-protected `.beatmitra` file (option to leave out phone numbers),
    import it on the other phone; full encrypted backup / restore.

## Privacy and security

- All data stays on the phone. Nothing is uploaded; there is no server.
- The database is encrypted with **SQLCipher (AES-256)**; its random key is
  kept in Android Keystore-backed `flutter_secure_storage`.
- Place photos are compressed to ≤ 200 KB and stored **AES-256-GCM encrypted**
  in app-private storage. They never appear in the gallery.
- `allowBackup=false` and data-extraction rules exclude everything from Google
  cloud backup and device transfer.
- App lock with PIN (PBKDF2-hashed) and optional biometrics; locks on start and
  after a background timeout (default 2 min). Optional screenshot blocking
  (FLAG_SECURE).
- `.beatmitra` files: zip of data + photos, encrypted with AES-256-GCM using a
  key derived from your password with PBKDF2-HMAC-SHA256 (210,000 iterations,
  random salt). Send the password separately from the file.
- "Delete all data" in Settings (double confirmation).
- The optional map (map build only, OFF by default) loads tiles from
  tile.openstreetmap.org following the OSM tile usage policy: visible
  "© OpenStreetMap contributors" attribution, an identifying User-Agent
  (package name), normal browsing only, **no bulk or offline tile downloading**.
  Names and addresses are never sent.

## Backup advice

Your beat data exists **only on this phone**. If the phone is lost, broken or
reset, only a backup can bring it back.

- Make a full backup at least **once a week** (the home screen reminds you
  after 7 days). Save it to an SD card, pen drive (OTG) or a computer.
- Use a password you will remember; without it the file cannot be opened.
- Keep a recent handover file for your beat with your office in-charge if your
  office rules allow it.

## Known limitations

- **Kannada OCR**: ML Kit has no Kannada text-recognition model, so photographed
  Kannada addresses are not read. Search by name / door no. instead (typing and
  voice search in Kannada work, and Kannada names match English spellings).
  English and Hindi (Devanagari) printed addresses are read on-device.
- Handwritten addresses are often not recognised by OCR.
- **Voice input** uses the phone's speech service. For offline use, install the
  offline speech pack for Kannada / Hindi / English (India) in the phone's
  Google voice typing settings; on some phones recognition may need internet.
- **Read-aloud** uses the phone's text-to-speech engine; Kannada voice must be
  installed on the phone.
- Route distances are straight-line (haversine) estimates, not road distances.
- The arrow needs a compass (magnetometer). Without one the app says so and
  the arrow assumes the top of the phone points north. Calibrate the compass
  by moving the phone in a figure 8.
- GPS accuracy near tall buildings can be 20–50 m; adjust the threshold in
  Settings.
- ML Kit and Google Play services may log usage internally; in the offline
  build they have no network permission, so nothing can be sent.
- Very large backups (thousands of photos) are built in memory and may be slow
  on low-end phones.
- Release APKs are signed with the debug key.

## Project layout

```
lib/core      theme, l10n (ARB), crypto, fuzzy.dart, transliterate.dart,
              route_planner.dart, address_parser.dart, article_matcher.dart,
              article_number.dart, geo.dart, settings, app lock, services/
lib/data      db.dart (schema), db_open.dart (SQLCipher), models, repos/,
              backup_codec.dart
lib/features  beat, places, search, today, run, summary, learn, backup,
              settings, home, common
test/         unit tests (transliteration, fuzzy ranking, door numbers,
              address parser, matcher, route planner, article numbers,
              encryption, backup round-trip, repos, quiz, summary) and widget
              tests (search, run, every screen in 3 languages)
tool/         strings.py (all UI strings in en/kn/hi) + gen_arb.py
```

Translations: edit `tool/strings.py`, run `python3 tool/gen_arb.py` then
`flutter gen-l10n`.

## Roadmap (not built yet)

- Shared beat updates between postmen of the same office (encrypted file sync).
- Speed Post / registered article OTP helper.
- PIN directory lookup (reuse from Sorting Sahayak).
- Home-screen widget for "next stop".
