# KSPSTADK — native Android app (Flutter)

ಶಿಕ್ಷಕರ ಸೇವೆಯೇ ಸಂಘದ ಗುರಿ · Kannada-first study materials, LBA question banks,
PDFs, orders and quizzes for Karnataka teachers. The app shows
[kspstadk.com](https://kspstadk.com) **natively** using the site's free,
built-in WordPress REST API. It is not a WebView wrapper.

* 100 % free stack: Flutter, the WordPress REST API, Hive, pdfrx (MIT), Firebase
  Cloud Messaging on the free Spark plan, GitHub Actions.
* There are no passwords, API keys or secrets in the app. Firebase client config is public by design.
* Nothing on the website needs changing for the app to work.

---

## How the app reads the site

| What | Endpoint (read-only, public) |
|---|---|
| Lists | `/wp-json/wp/v2/posts?per_page=20&page=N&_embed=wp:featuredmedia,wp:term&_fields=…` (+ `categories=`) |
| A post | `/wp-json/wp/v2/posts/<id>?_embed=…` · internal links: `/posts?slug=<slug>` |
| Categories | `/wp-json/wp/v2/categories?per_page=100&hide_empty=true` |
| Search | `/wp-json/wp/v2/posts?search=<q>` (debounced 400 ms) |

* **Offline cache (Hive):** every response is stored with a timestamp. The
  cached copy is shown instantly, then refreshed in the background
  (stale-while-revalidate). Bookmarked posts keep their full content, and
  downloaded PDFs live in app storage, so both work with no internet.
* **Native rendering:** `lib/content/post_content.dart` turns the site's custom
  HTML into native widgets:

  | Site markup | In the app |
  |---|---|
  | `section.kspstadk-lba .kl-grid .kl-card` (LBA lesson cards with Drive Q/A links) | Numbered lesson cards with *Questions* / *Answers* rows: Open (in-app PDF) · Download · Share |
  | Ultimate Blocks buttons / plain links to Drive, `.pdf`, `.zip` | Download list grouped under the nearest heading |
  | `section.ksp-hub` (class hub) | Gradient hero + subject tiles that open the linked posts natively |
  | "ಇವುಗಳನ್ನೂ ಓದಿ" (`kspstadk-related`, `sec rel`, `also-read`) | Rainbow related-post chips. If a post has none, related posts are fetched by category |
  | `chat.whatsapp.com`, `t.me/…` buttons | WhatsApp / Telegram join pills |
  | YouTube iframes | Thumbnail card → YouTube app |
  | Tables, FAQ accordions, `<details>` | Scrollable styled table, expansion tiles |
  | Calculator/tool posts with scripts | "Open tool" button (Custom Tab) |
  | `<style>`, `<script>`, share widgets, ads, shortcodes | Removed |

* **Google Drive links:** all link styles are handled (`uc?export=download&id=`,
  `/file/d/ID/view`, `open?id=`, `drive.usercontent…`, Docs). Files are downloaded
  from `drive.usercontent.google.com/download?id=ID&export=download&confirm=t`,
  and the "can't scan for viruses" page of large files is followed
  automatically. Files must be shared as *Anyone with the link*.

## How new categories appear automatically

The site's categories are flat Kannada/English twins (e.g. `4 ನೇ ತರಗತಿ` +
`4 TH STANDARD`). See [`docs/SITE_ANALYSIS.md`](docs/SITE_ANALYSIS.md).

* **Browse → More categories** lists every non-empty category from the API, so a
  new category shows up there on its own (cached for 24 h).
* Classes, subjects, mediums, home tiles and twin pairs are mapped in
  `assets/config/home_sections.json`.

## Changing the home screen (config JSON)

Edit [`assets/config/home_sections.json`](assets/config/home_sections.json):

```jsonc
{
  "join":    { "whatsapp": "<url>", "telegram": "<url>" },   // join card
  "classes": [{ "n": 4, "ids": [408, 409, 1306] }, …],          // class → category ids
  "subjects":[{ "key": "science", "kn": "ವಿಜ್ಞಾನ", "en": "Science", "color": "#059669", "ids": [469, 468] }],
  "mediums": [ … ],
  "tiles":   [{ "key": "lba", "kn": "LBA ಪ್ರಶ್ನಾ ಕೋಶ", "en": "LBA Question Bank", "icon": "quiz", "color": "#16A34A", "ids": [1341] }],
  "popular": [{ "post": 57951 }, …],                             // "Popular downloads" (post ids)
  "twins":   [[413, 412], …],                                    // extra Kannada/English pairs
  "sections":[ {"type": "latest", "count": 8}, {"type": "tiles"}, {"type": "classes"},
               {"type": "continue"}, {"type": "popular"},
               {"type": "category", "kn": "…", "en": "…", "ids": [1341], "count": 6},
               {"type": "join"} ],
  "tools_url": "https://tools.kspstadk.com/"
}
```

* Category ids: open `https://kspstadk.com/wp-json/wp/v2/categories?per_page=100`.
* Icons: names listed in `lib/ui/widgets/icons.dart` (Material Symbols style).
* **No app update needed:** with `remoteHomeConfig` on (in `lib/config.dart`),
  the app downloads this file from the `master` branch of this repo and applies
  it on the next start. `test/site_config_test.dart` checks that every id
  exists on the site.

## Push notifications (free)

**Option A (built in; no WordPress plugin).** `.github/workflows/kspstadk-notify.yml`
runs every 30 minutes and calls `tool/notify.py`:

1. It reads the last post it saw from `notify/state.json` (committed back by the workflow).
2. It GETs `/wp-json/wp/v2/posts?after=<last date>`.
3. For each new post (up to 5 per run) it sends **one** FCM HTTP v1 message to
   a topic condition such as `'all' in topics || 'lba' in topics || 'class_4' in topics`.
   Each phone gets one notification even if it follows several matching topics.
4. The first run only records the newest post, so old posts are never pushed.

Topics are `all`, `lba`, `info` (information/orders), `study`, `quiz`, and
`class_1` … `class_10`. Users pick them in **More → Notification topics**.
Tapping a notification opens the post (`data.post_id`).

### One-time setup (Firebase Spark plan, free)

1. Go to <https://console.firebase.google.com> → **Add project** (Analytics not needed).
2. **Add app → Android**, package `com.kspstadk.app`. Copy *API key*, *App ID*,
   *Sender ID* and *Project ID* into `lib/firebase_options.dart` (these are public),
   or run `dart pub global activate flutterfire_cli && flutterfire configure`.
   You do **not** need `google-services.json`.
3. Go to **Project settings → Service accounts → Generate new private key**. This downloads a JSON file.
4. In GitHub, open this repo → **Settings → Secrets and variables → Actions → New repository secret**.
   Name it `FIREBASE_SERVICE_ACCOUNT` and paste the whole JSON file as the value. Never put this file in the app.
5. Merge to `master` (scheduled workflows run only on the default branch). Then run
   **Actions → KSPSTADK push notifications → Run workflow** once to initialise.

Without the secret the workflow runs in *dry-run* mode and only prints the messages.
Without `firebase_options.dart` values the app runs with push turned off.

**Option B (WordPress plugin, not installed).** A free plugin such as
*OneSignal – Web Push Notifications* or *Firebase Push Notifications for
WordPress* could send pushes when a post is published. It would need
installing on the site and an extra account, so Option A is the default. Ask
before installing anything.

## Deep links (Android App Links)

The app opens `https://kspstadk.com/...` links from WhatsApp etc. once the site
publishes `/.well-known/assetlinks.json`:

1. In Play Console → your app → **Test and release → App integrity → App signing**,
   copy the **SHA-256 certificate fingerprint** (and the upload key's fingerprint).
2. Put both in [`web_upload/.well-known/assetlinks.json`](web_upload/.well-known/assetlinks.json).
3. Upload it to `https://kspstadk.com/.well-known/assetlinks.json`. You can use
   Hostinger File Manager → `public_html/.well-known/` (create the folder if
   needed); no plugin is required. It must be served as JSON with HTTP 200 and no redirect.
4. Verify with <https://developers.google.com/digital-asset-links/tools/generator>.

Also supported: `https://kspstadk.com/?p=123`, `kspstadk://post/123`.

## Build and release

Requirements: Flutter (stable), JDK 17, Android SDK. CI does this on every push
(`.github/workflows/kspstadk-app.yml`) and uploads the APK and AAB as artifacts.

```bash
cd kspstadk_app
flutter pub get
flutter analyze
flutter test
python3 -m unittest discover -s tool        # notifier tests
flutter build apk --release                 # build/app/outputs/flutter-apk/app-release.apk
flutter build appbundle --release           # build/app/outputs/bundle/release/app-release.aab
```

**Signing.** Create `android/key.properties` (git-ignored) with `storeFile`,
`storePassword`, `keyAlias`, `keyPassword`. Without it, release builds are
signed with the debug key, which is fine for testing but not for Play.

```bash
keytool -genkey -v -keystore ~/kspstadk-upload.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

**Versioning.** Bump `version:` in `pubspec.yaml` (e.g. `1.0.1+2`) and
`AppConfig.appVersion`.

**Icons.** `python3 tool/make_icons.py` regenerates the launcher, adaptive,
notification and store icons (`store/icon-512.png`, `store/feature-graphic-1024x500.png`).

**Refresh test fixtures from the live site.** Run the *KSPSTADK site
inspection* workflow, or `python3 tool/inspect_site.py`.

## Optional features (OFF by default, in `lib/config.dart`)

* `inAppReviewEnabled`: asks for a Play review after `reviewAfterDownloads` (5) downloads.
* `adsEnabled`: an AdMob banner on list screens only (no interstitials). The
  `google_mobile_ads` package is deliberately **not** included, so the default
  app has no ads SDK. To enable it: `flutter pub add google_mobile_ads`, add your
  AdMob App ID to `AndroidManifest.xml`, and render a `BannerAd` in
  `PostListScreen` when the flag is on.

## Project layout

```
lib/
  config.dart               flags, URLs
  data/                     REST client, models, Hive store, SWR repository, site config
  content/                  link classifier (Drive/PDF/YouTube/…), HTML → native blocks
  downloads/                download manager (Drive confirm flow, offline library)
  notifications/            FCM push service, deep-link parsing, topics
  state/                    settings, bookmarks, history, inbox, network
  ui/                       shell, screens, post blocks, widgets, theme usage
  l10n/                     app_kn.arb (default), app_en.arb
tool/                       inspect_site.py, notify.py (+tests), make_icons.py
docs/                       SITE_ANALYSIS.md, PRIVACY_POLICY.md, PLAY_STORE_LISTING.md
```

## Roadmap

* Native quiz engine with leaderboard (currently quiz posts + Custom Tab).
* Teacher login for members.
* Offline packs per class: download every lesson PDF of a class at once.
* iOS build.
* Home-screen widget showing the latest post.
