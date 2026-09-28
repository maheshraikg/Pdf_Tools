# Tulu Nighantu (ತುಳು ನಿಘಂಟು)

An offline Tulu ⇄ Kannada ⇄ English dictionary for Android, built with Flutter.
It also teaches Tulu lipi (Tulu-Tigalari script) with finger-tracing practice and
includes a Kannada → Tulu lipi converter.

- **ನಿಘಂಟು · Dictionary**: search in Tulu (Kannada script), Kannada, English or
  romanised Tulu; categories; word of the day; favourites.
- **ಲಿಪಿ · Lipi**: the alphabet grouped by vowels, yogavahas, the five vargas and
  avargiya consonants, with a barakhadi (ಕಾಗುಣಿತ) row for each consonant.
- **ಬರೆಯಿರಿ · Writing tutorial**: for every letter, *Watch* an animated pen
  write it (numbered strokes with direction arrows), then *Trace* over the
  faint letter and *Free write* it; the app scores coverage and precision and
  gives 0–3 stars. Words can be traced too.
- **ಕೇಳಿ · Pronunciation**: listen buttons on letters, barakhadi tiles, words,
  the word of the day and the converter.
- **ಬದಲಿಸಿ · Convert**:
  - *ಅನುವಾದ · Translate*: type Kannada or English and get Tulu (Kannada script,
    Tulu lipi and romanised), with listen / copy / share and a word-by-word
    breakdown. Whole phrases from the dictionary are matched first; other text
    is translated word by word (English plurals and common Kannada case endings
    are handled). It is dictionary-based: no grammar or word-order changes, and
    unknown words are highlighted.
  - *ಲಿಪಿ · Script*: live Kannada → Tulu-Tigalari with copy and share-as-image.
- **ಉಳಿಸಿದವು · Saved**: favourites, progress and about.

The app does not use the network. Everything is bundled; pronunciation uses the
phone's own text-to-speech engine.

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

## Adding your own words (in the app)

When a search finds nothing, tap **ಈ ಪದ ಸೇರಿಸಿ · Add "…"** (or the **+** in the
dictionary header, or a red "tap to add" word in Translate). Enter the Tulu word
in Kannada script plus a Kannada and/or English meaning. The word is saved on
the phone, marked *yours / not verified*, and is immediately searchable and
used by Translate. **Saved › My words › Export** shares the words as JSON in
the `words.json` entry format, so they can be reviewed and merged into the
bundled list for everyone.

## Adding words (bundled list)

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

## Pronunciation (sound)

Listen buttons call `Speaker.instance.speak()` (`lib/audio/speaker.dart`), which
uses Android text-to-speech via [`flutter_tts`](https://pub.dev/packages/flutter_tts)
with a **Kannada (kn-IN)** voice. Because Tulu is stored in Kannada script, this
gives a close but *approximate* pronunciation. If the phone has no Kannada voice
the app shows how to install one (Settings › Text-to-speech › Speech Services by
Google › Install voice data › ಕನ್ನಡ). Voices downloaded that way work offline.

### Adding native-speaker recordings later

1. Put recordings in `assets/audio/<id>.opus` (one per word id) and letters in
   `assets/audio/letters/<kannada>.opus`.
2. Add `assets/audio/` to `flutter: assets:` in `pubspec.yaml`.
3. Add the [`audioplayers`](https://pub.dev/packages/audioplayers) package and,
   in `Speaker.speak`, play the recording when it exists
   (`AudioPlayer().play(AssetSource('audio/${word.id}.opus'))`), falling back
   to text-to-speech.

## Writing tutorial data

The *Watch* animation uses `assets/data/strokes.json`, generated from the font
by `tool/gen_strokes.py` (needs Python with pillow, scikit-image and numpy):

```sh
python3 tool/gen_strokes.py
```

Each glyph is rendered, thinned to its centre line and traced into pen strokes,
ordered left to right. This is a helpful guide, **not** a verified traditional
stroke order; to use expert data, replace the strokes for a letter in the JSON
(points are normalised 0–1 to the glyph's ink box).

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
- Tutorial pen paths are auto-generated from the font, not expert-verified.
- Pronunciation is an approximation by a Kannada text-to-speech voice.
- Translation is word-for-word from the dictionary; it only knows the words in
  `words.json` and does not apply Tulu grammar.
- The word list is a small, unverified sample.

## Roadmap (next phase)

- Native-speaker audio for every word and letter
- Phrasebook expansion
- Proverbs (ಗಾದೆಗಳು) with share cards
- Expert-verified stroke order for the writing tutorial
- Daily practice streaks
- "Suggest a word" form
- Remote word-list updates
