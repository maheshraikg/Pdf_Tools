# Tulu Nighantu (ತುಳು ನಿಘಂಟು)

An offline Tulu ⇄ Kannada ⇄ English dictionary for Android, built with Flutter.
It also teaches Tulu lipi (Tulu-Tigalari script) with finger-tracing practice and
includes a Kannada → Tulu lipi converter.

- **ನಿಘಂಟು · Dictionary**: search in Tulu (Kannada script), Kannada, English or
  romanised Tulu; categories; word of the day; favourites.
- **ಲಿಪಿ · Lipi**: the alphabet grouped by vowels, yogavahas, the five vargas and
  avargiya consonants, with a barakhadi (ಕಾಗುಣಿತ) row for each consonant.
- **ಬರೆಯಿರಿ · Trace**: trace or free-write any letter or word; the app scores
  coverage and precision and gives 0–3 stars.
- **ಬದಲಿಸಿ · Converter**: live Kannada → Tulu-Tigalari with copy and share-as-image.
- **ಉಳಿಸಿದವು · Saved**: favourites, progress and about.

The app does not use the network. Everything is bundled.

## Run

Requires the Flutter stable SDK (3.47+ / Dart 3.13+), JDK 17+ and an Android SDK.

```sh
cd tulu_nighantu
flutter pub get
flutter run                 # on a connected device / emulator
flutter test                # unit + widget tests
flutter build apk --debug   # build/app/outputs/flutter-apk/app-debug.apk
```

CI (`.github/workflows/tulu-nighantu.yml`) runs analyze, test and a debug
build, and uploads the APK as the `tulu-nighantu-debug-apk` artifact.

## Project layout

```
lib/main.dart                 app + Material 3 themes (seed #B3261E, yellow accent)
lib/app_state.dart            word list, search, favourites, tracing stars
lib/models/word.dart          Word / WordCategory
lib/lipi/tulu_lipi.dart       Kannada → Tulu-Tigalari converter, alphabet lists
lib/screens/*.dart            one file per screen
lib/widgets/common.dart       shared widgets (TuluText, WordTile, ShareCard…)
assets/data/words.json        dictionary data
assets/fonts/                 Mallige Tulu-Tigalari font + OFL licence
```

## Adding words

Edit `assets/data/words.json`:

```json
{
  "version": 1,
  "note": "Sample list – verified by native speakers before publishing",
  "categories": [{ "id": "food", "kn": "ಆಹಾರ", "en": "Food" }],
  "words": [
    { "id": "w025", "tulu": "ನೀರ್", "roman": "neer", "kn": "ನೀರು", "en": "water", "cat": "food" }
  ]
}
```

- `id` must be unique and stable (favourites and tracing stars are keyed on it).
- `tulu` is the Tulu word in **Kannada script**; the Tulu lipi is generated.
- `kn` / `en` are the meanings. Separate alternatives with `;` – each part is
  searched separately.
- `cat` is a category id; use `phrases` for sentences (phrases are never picked
  as word of the day).

The bundled list is a small sample. **Have native speakers verify every entry
before publishing.**

## Adding audio later

1. Put native-speaker recordings in `assets/audio/<id>.opus` (one per word id).
2. Add `assets/audio/` to `flutter: assets:` in `pubspec.yaml`.
3. Add the [`audioplayers`](https://pub.dev/packages/audioplayers) package and a
   play button on the word detail screen:
   `AudioPlayer().play(AssetSource('audio/${word.id}.opus'))`.
   Hide the button when the asset is missing.

## Font and licence

Tulu lipi is rendered with **Mallige** by the OpenTuluFont project
(<https://github.com/OpenTuluFont/mallige>), licensed under the
**SIL Open Font License 1.1** – see `assets/fonts/OFL.txt`. It covers the
Unicode 16.0 Tulu-Tigalari block (U+11380–U+113FF).

To swap the font, replace the asset registered under the `TuluTigalari`
family in `pubspec.yaml`; all Tulu text uses the single constant
`kTuluFontFamily` in `lib/lipi/tulu_lipi.dart`.

## Known limitations

- **No conjunct shaping**: the font has no advanced shaping, so conjuncts are
  shown as consonant + visible virama (e.g. ಕ್ಕ → 𑎒𑏎𑎒).
- **Short ಎ / ಒ**: Unicode 16 Tulu-Tigalari has no short E/O, so ಎ/ಏ both map to
  EE and ಒ/ಓ to OO (vowels and vowel signs).
- Trace scoring compares shapes only; it does not check stroke order or direction.
- The word list is a small, unverified sample.

## Roadmap (next phase)

- Native-speaker audio for every word
- Phrasebook expansion
- Proverbs (ಗಾದೆಗಳು) with share cards
- Stroke-order animations (needs verified stroke data)
- Daily practice streaks
- "Suggest a word" form
- Remote word-list updates
