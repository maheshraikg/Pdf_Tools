# ಅಕ್ಷರ ಆಟ · Akshara Aata

A Kannada varnamala learning app for children aged 3–8. It is an installable, offline Progressive Web App: open it once in Chrome on a phone, tap **Add to Home screen**, and it runs like a normal app with no internet.

## Why it was built this way

Before building, we looked at the Kannada alphabet apps on Google Play and the App Store (Kannada Learning App for Kids, Kannada Alphabet (Aksharamale), Kannada Alphabet Game, Write Kannada Alphabets, Learn Kannada SmartApp) and at TinyTap's Kannada swaragalu activities. They cover some of these parts well: letter tracing, picture words, a memory game and offline use. The usual gaps are ads inside kids' apps, robotic or missing Kannada audio, only one or two games, and no kagunita practice. Akshara Aata puts all of these together:

| Area | What's in it |
| --- | --- |
| **Full varnamala** | All 49 letters: 13 ಸ್ವರಗಳು, 2 ಯೋಗವಾಹಗಳು, 34 ವ್ಯಂಜನಗಳು grouped by ವರ್ಗ (ಕ, ಚ, ಟ, ತ, ಪ, ಅವರ್ಗೀಯ) |
| **Letter cards** | Big letter, sound, picture word (ಆ → ಆನೆ 🐘) with the letter highlighted, English sound and meaning, swipe to move |
| **Kagunita** | Any consonant × 15 vowel signs (ಕ ಕಾ ಕಿ ಕೀ … ಕಂ ಕಃ), plus "hear all" read-along |
| **Numbers** | ೦–೧೦ with number words and counting pictures |
| **Tracing** | Draw with a finger over the letter on copybook lines. The app checks both how much of the letter is covered and how much of the drawing stays inside it, so scribbling does not pass |
| **7 games** | Listen & find, first-letter picture game, memory pairs, balloon pop, what comes next, kagunita builder (ಕ + ಇ = ?), counting |
| **Rewards** | Stars for right first answers and finished letters, a sticker unlocked every 10 stars, a progress bar |
| **Voice** | Uses the phone's Kannada text-to-speech. With no Kannada voice installed it falls back to the Hindi voice, which reads Kannada script closely when shifted to Devanagari. Parents can also **record their own voice** for any letter or word |
| **Parents area** | Behind a simple sum. Sound, speaking speed, English hints, record mode, progress reset |
| **Privacy** | No ads, no accounts, no analytics, no network calls. Progress and recordings stay on the device |

## Run it locally

```bash
cd kannada-varnamala
python3 -m http.server 8080
# open http://localhost:8080
```

Any static web host works (GitHub Pages, Netlify, Firebase Hosting). The service worker needs HTTPS or `localhost`.

## Put it on the Play Store

The app is a standard PWA, so it can be shipped to Google Play as a Trusted Web Activity without rewriting it:

1. Host this folder on HTTPS (for example GitHub Pages).
2. Run `npx @bubblewrap/cli init --manifest https://<your-host>/manifest.webmanifest`, then `bubblewrap build`.
3. Add the generated `assetlinks.json` to `https://<your-host>/.well-known/`.
4. Upload the `.aab` to Play Console. In the target audience section choose ages under 13 and fill in the Families policy form (no ads and no data collection make this simple).

## Files

```
index.html            app shell
css/app.css           styles (Channapatna-toy palette)
js/data.js            letters, words, pictures, numbers, vowel signs
js/app.js             screens, games, tracing, speech, recording
sw.js                 offline cache (bump VERSION after changing files)
manifest.webmanifest  install metadata
fonts/                Baloo Tamma 2 (SIL Open Font License, see OFL.txt)
icons/                app icons
```

## Adding or fixing content

Every letter lives in `js/data.js` as one line:

```js
L('ಆ', 'aa', 'swara', '', 'ಆನೆ', 'aane', '🐘', 'Elephant'),
```

Pass `false` as the last argument when the word doesn't start with that letter (like ಳ in ಬಾಳೆಹಣ್ಣು), so the first-letter game skips it.
