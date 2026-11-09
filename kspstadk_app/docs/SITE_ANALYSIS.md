# KSPSTADK — Site analysis (Phase 0)

Source data: a read-only run of `tool/inspect_site.py` on GitHub Actions on
2026-10-05. It made GET requests only, and nothing on the site changed. The raw
responses are in `test/fixtures/`, and the full generated report is in
[`site_inspection.md`](site_inspection.md). The run covered 20 recent posts plus a
deeper sample of 114 posts from the content-heavy categories and LBA hub pages.

## 1. REST API status

| Item | Result |
|---|---|
| `/wp-json/wp/v2/` | ✅ 200, public, no security plugin blocking it (LiteSpeed cache + Hostinger CDN `hcdn`) |
| posts | ✅ 1,853 posts. `_embed` works (author, `wp:featuredmedia`, `wp:term`) |
| categories | ✅ 94 categories, **all flat (`parent = 0`)** |
| tags | ✅ 1,926 tags |
| pages | ✅ 7 pages: HOME, About us, Contact Us, Privacy Policy, Disclaimer, Copyright Policy, Akshara Dasoha calculator |
| media | ✅ 8,280 items. Featured image sizes: `thumbnail`, `medium`, `medium_large`, `large`, `1536x1536`, `full` (+ web-stories sizes) |
| search | ✅ `/wp/v2/search?search=LBA` returns 132 hits |
| menu-items / menus | ❌ 401 (needs login, which is normal WordPress behaviour) |
| navigation (block menu) | ✅ public. The `primary` menu has 10 links, listed below |
| users | ⚠️ public (4 users). This is harmless for the app, but see **Suggestions for the site** below |

Theme and plugins (from REST namespaces): GeneratePress Pro + GenerateBlocks Pro,
Ultimate Blocks, Rank Math, LiteSpeed Cache, Site Kit, Ad Inserter, Contact Form 7,
Web Stories, Akismet. The theme also adds `featured_image_src` and `author_info`
to every post object.

Primary menu: Home · UNION ACTIVITIES · INFORMATION · LATEST NEWS · MORE ·
STUDY MATERIALS · JOIN WHATS APP (`/official-whats-app-gropu-link-for-teachers-dk/`) ·
ಗುರುಸೇವೆ · ಗುರುಭ್ಯೋ ನಮಃ · DAILY NEWS PAPERS (external: topmahithi.com).

## 2. Category map

The site has **no parent/child hierarchy**. Instead, almost every concept exists
twice, as a Kannada-named category and an English-named one, and a post is filed
in both (e.g. `4 ನೇ ತರಗತಿ` + `4 TH STANDARD`). The app will merge each pair of
twins into a single concept and show the Kannada or English label depending on
the language setting. The **Class → Subject → Medium** drill-down is built by
intersecting categories on the device. Each class has at most about 50 posts,
so one request for `?categories=<twin ids>&per_page=100&_fields=…` returns the
whole class.

### Classes (merged twins, id and post count)

| Class | Categories |
|---|---|
| 1 | 1 ನೇ ತರಗತಿ `1365` (2) + 1ST STANDARD `1364` (2) |
| 2 | 2 ನೇ ತರಗತಿ `1363` (0) + 2ND STANDARD `1362` (0) |
| 3 | 3 ನೇ ತರಗತಿ `1279` (4) + 3RD STANDARD `1361` (0) + Class 3 `1282` (2) |
| 4 | 4 ನೇ ತರಗತಿ `408` (50) + 4 TH STANDARD `409` (50) + Class 4 `1306` (1) |
| 5 | 5 ನೇ ತರಗತಿ `410` (44) + 5 TH STANDARD `411` (44) |
| 6 | 6 ನೇ ತರಗತಿ `1360` (19) + 6TH STANDARD `1359` (19) |
| 7 | 7 ನೇ ತರಗತಿ `474` (18) + 7 TH STANDARD `473` (18) |
| 8 | 8 ನೇ ತರಗತಿ `288` (11) + 8TH STANDARD `287` (11) |
| 9 | 9 ನೇ ತರಗತಿ `290` (12) + 9TH STANDARD `289` (11) |
| 10 | 10 ನೇ ತರಗತಿ `286` (13) + 10TH STANDARD `285` (12) |

### Subjects (colour per subject in the app)

| Subject | Categories | Colour |
|---|---|---|
| Kannada | ಕನ್ನಡ `1358` + KANNADA `1357` | pink |
| English | ಇಂಗ್ಲೀಷ್ `1356` + ENGLISH `255` | violet |
| Hindi | ಹಿಂದಿ `1367` + HINDI `1366` | orange |
| Maths | ಗಣಿತ `283` + MATHS `282` + MATHEMATICS `1348` | blue |
| Science | ವಿಜ್ಞಾನ `469` + SCIENCE `468` | green |
| Social Science | ಸಮಾಜ ವಿಜ್ಞಾನ `1369` + SOCIAL SCIENCE `1368` | amber |
| EVS | ಪರಿಸರ ಅಧ್ಯಯನ `1370` + ENVIRONMENTAL STUDIES `1371` | teal |

### Medium

ಕನ್ನಡ ಮಾಧ್ಯಮ `1286` + KANNADA MEDIUM `1349` · ಇಂಗ್ಲೀಷ್ ಮಾಧ್ಯಮ `1287` + ENGLISH MEDIUM `1350`

### Sections (the other big categories)

| Section | Categories (posts) |
|---|---|
| Latest news / ಇತ್ತೀಚಿನ ಸುದ್ದಿ | LATEST NEWS `10` (1569), NEWS `1` (591) |
| Information & orders / ಮಾಹಿತಿ–ಆದೇಶ | INFORMATION `8` (863). There is **no separate "Circulars" category**, so this one stands in for it |
| LBA ಪ್ರಶ್ನಾ ಕೋಶ | LBA `1341` (89) |
| Study materials | STUDY MATERIALS `43` (127), PDF MATERIALS `66` (100), PDF BOOKS `77` (9), KARNATAKA TEXTBOOKS `76`, TEXT BOOK `1552` |
| Question papers (FA/SA) | ಪ್ರಶ್ನೆಪತ್ರಿಕೆ (FA, SA) `1275` (9), PDF QUESTION PAPER `1277` |
| Teacher articles | TEACHERS ARTICLES `391` + ಶಿಕ್ಷಕರ ಲೇಖನಗಳು `390` (85), ಗುರುಭ್ಯೋ ನಮಃ `22`, ಗುರುಸೇವೆ `32` |
| Quiz | QUIZ `444` (43), MYGOV QUIZ `490` (23), ರಸಪ್ರಶ್ನೆ `1355` |
| Video | ವಿಡಿಯೋ ಮಾಹಿತಿ `143` + VIDEO INFORMATION `145`, VIDEO LESSONS `89` |
| Odu Karnataka | ODU KARNATAKA `413` + ಓದು ಕರ್ನಾಟಕ `412` |
| Nali Kali | NALI KALI `135` + ನಲಿ ಕಲಿ `134` |
| Kalika Chetarike | KALIKA CHETARIKE `584` + ಕಲಿಕಾ ಚೇತರಿಕೆ `585` |
| Tools | TOOLS `1536` (7). Online calculators/forms, plus `tools.kspstadk.com` |
| Newspapers | TODAY NEWS PAPERS `949` (40) |
| Scholarship | SCHOLORSHIP `215` |
| Union activities | UNION ACTIVITIES `3` |

Categories with 0 posts are hidden automatically. If you create a new category
on the site, it shows up in **Browse → All categories** with no app update.
Adding it to a home tile only needs an edit to `assets/config/home_sections.json`.

## 3. Content patterns found (134 posts sampled)

| # | Pattern (real markup) | Where | Native rendering |
|---|---|---|---|
| 1 | **LBA download grid**: `<section class="kspstadk-lba">` → `.kl-grid` → `.kl-card` (`.kl-num` "01", `.kl-title h3`) → `.kl-btns` with `a.kl-btn.q` (ಪ್ರಶ್ನೆಗಳು) / `a.kl-btn.a` (ಉತ್ತರಗಳು) → `drive.google.com/uc?export=download&id=…` | All new LBA subject posts (19/134; up to 66 cards in one post) | **Native lesson cards**: lesson number badge, title, two buttons, *Questions* and *Answers*. Each opens the in-app PDF viewer, downloads, or shares. Progress ring, "Saved offline" tick |
| 2 | **Ultimate Blocks buttons**: `.wp-block-ub-button` → `a.ub-button-block-main` → `drive.google.com/file/d/ID/view` with a label like "ಕನ್ನಡ ನೋಟ್ಸ್ 1 ಇಲ್ಲಿ ಕ್ಲಿಕ್ ಮಾಡಿ" | Older PDF-materials / question-paper posts (32/134; 1,627 buttons; up to 81 Drive links in one post) | **Native download card** per Drive/PDF link. The label is cleaned up ("ಇಲ್ಲಿ ಕ್ಲಿಕ್ ಮಾಡಿ" is dropped) and the nearest preceding `h2`/`h3` (e.g. "4 ನೇ ತರಗತಿ") becomes the group header |
| 3 | **Class hub**: `<section class="ksp-hub">` → `.kh-group` (Languages / Bilingual / Kannada medium / English medium) → `a.kh-card` (name, sub, lesson-count chip) linking to subject posts | The "N ನೇ ತರಗತಿ ಎಲ್ಲಾ ವಿಷಯಗಳ LBA ಪ್ರಶ್ನಾ ಕೋಶ" posts for classes 4–10 | **Native subject tiles** in a 2-column grid with group headers. A tap opens the linked post natively (looked up via `/posts?slug=`) |
| 4 | **Related block "ಇವುಗಳನ್ನೂ ಓದಿ"**: three variants: `section.kspstadk-related` → `a.kr-row` (badge + `.kr-title`); `div.sec.rel` → `a[style*=--c:linear-gradient]` (`.tt`); `.also-read-container` → `a.also-read-link` | 19/134 posts | **Rainbow related chips** (red→orange, green→cyan, blue→purple … in a rotating palette). If a post has none, the app adds "related by category" from the API |
| 5 | **Share box**: `div.share` with `wa.me/?text=` and `t.me/share/url` + inline `<script>` | New posts | Removed; replaced by the app's own share button (site URL + Kannada text) |
| 6 | **WhatsApp/Telegram join buttons**: UB buttons to `chat.whatsapp.com/…` and `t.me/joinchat/…` | 50/134 older posts | **Native join card** (green WhatsApp / blue Telegram pill) |
| 7 | **YouTube embeds**: `figure.wp-block-embed-youtube` → `iframe src=youtube.com/embed/ID` | 27/134 | Thumbnail card (`img.youtube.com/vi/ID/hqdefault.jpg`) with a play button. Opens the YouTube app |
| 8 | Other iframes (Google Forms/Maps etc.) | a few | Link card that opens in a Custom Tab |
| 9 | **Tables**: `figure.wp-block-table` (e.g. a lesson list with page numbers) | 11/134 | Horizontally scrollable, zebra-striped, rounded table |
| 10 | **Images**: `wp-image-*` with `srcset` | 24/134 | Cached image picked from `srcset` at screen width, tap for pinch-zoom viewer |
| 11 | **Accordions**: `wp-block-ub-content-toggle-accordion` | FAQ sections | Native `ExpansionTile` |
| 12 | `<details><summary>` FAQs | new posts | Native `ExpansionTile` |
| 13 | Direct `.pdf` links (`wp-content/uploads/…pdf`) | 4/134 (old DSERT practice books) | Same native download card as Drive |
| 14 | Heavy inline `<style>`/`<script>`, decorative blobs/orbs, SVG icons, hero `.kh-hero` stats | most new posts | Stripped. The hero is shown as a native gradient header with the stat pills |
| 15 | Interactive tool posts (calculators with `<script>`, e.g. mid-day-meal calculator) | TOOLS category | These can't work natively. The app shows the intro text plus an **"Open tool"** button (Custom Tab to the post URL) |
| 16 | MyGov / external quiz posts (`quiz.mygov.in`, Google Forms) | QUIZ, MYGOV QUIZ | Rendered natively. The external quiz button opens in a Custom Tab |
| 17 | Shortcode leftovers `[...]` | 1/134 | Regex-stripped |

Not found: `kl-grid` with direct `.zip` links (0/134), Drive folders (0),
`drive.google.com/open?id=` (0). The link extractor handles them anyway
(`uc?export=download&id=`, `/file/d/ID/view`, `open?id=`, `drive.usercontent.google.com`,
`docs.google.com/…/d/ID`, `.pdf`, `.zip`, `.doc[x]`, `.xls[x]`, `.ppt[x]`).

Drive files are public "anyone with the link" files. The app downloads them via
`https://drive.usercontent.google.com/download?id=ID&export=download&confirm=t`,
which skips the virus-scan page for big files. It falls back to parsing the
confirm form if Google returns HTML.

## 4. Data plan (what the app requests)

* Lists: `/wp/v2/posts?per_page=20&page=N&_embed=wp:featuredmedia,wp:term&_fields=id,date,modified,slug,link,title,excerpt,categories,tags,featured_media,featured_image_src,_links,_embedded`
  (plus `categories=` for a section). Infinite scroll uses `X-WP-TotalPages`.
* Post: `/wp/v2/posts/ID?_embed=wp:featuredmedia,wp:term`. Internal links resolve via `/wp/v2/posts?slug=…`.
* Categories: `/wp/v2/categories?per_page=100&hide_empty=true&_fields=id,name,slug,parent,count` (cached for 24 h).
* Search: `/wp/v2/posts?search=q&per_page=20` (+ optional `categories=`), debounced 400 ms.
* Images: the `medium_large` size for cards (`medium` for thumbnails) from `_embedded`.
* Cache: Hive, keyed by URL with a timestamp. The cached copy is shown instantly and refreshed in the background.

## 5. Proposed home screen

1. **Gradient header** (green → blue): "ನಮಸ್ಕಾರ, ಶಿಕ್ಷಕರೇ 🙏" + KSPSTADK + search pill.
2. **Latest carousel**: 8 newest posts, large image cards, auto-advance off.
3. **Quick-access tiles** (2 rows, scrollable, from `home_sections.json`):
   ತರಗತಿ 1–10 · LBA ಪ್ರಶ್ನಾ ಕೋಶ · ಅಧ್ಯಯನ ಸಾಮಗ್ರಿ · ಪ್ರಶ್ನೆಪತ್ರಿಕೆ (FA/SA) · ಮಾಹಿತಿ / ಆದೇಶ ·
   ಶಿಕ್ಷಕರ ಲೇಖನಗಳು · ರಸಪ್ರಶ್ನೆ · ವಿಡಿಯೋ · ನಲಿ-ಕಲಿ · ಉಪಕರಣಗಳು (Tools).
4. **Classes strip**: ten round class chips (1…10) going straight to Class → Subject.
5. **Continue reading**: the last 5 opened posts (local).
6. **Popular downloads**: the REST API has no view counts. I suggest a curated list
   in `home_sections.json` (default: the 7 "ಎಲ್ಲಾ ವಿಷಯಗಳ LBA ಪ್ರಶ್ನಾ ಕೋಶ" class hubs),
   mixed with the files *you* open most on the device.
7. **LBA ಪ್ರಶ್ನಾ ಕೋಶ**: the latest 6 LBA posts.
8. **Join card**: WhatsApp + Telegram buttons. The links come from config, so they
   can be changed without an app update.
9. **Information / orders**: the latest 5 INFORMATION posts.

The home config is bundled as `assets/config/home_sections.json`. When the
remote-config flag is on, the app can also fetch the same file from this GitHub
repo, so home sections change without a Play Store update (free).

## 6. Decisions I need from you

1. **Official join links.** The menu points to the post `/official-whats-app-gropu-link-for-teachers-dk/`.
   In post bodies I found `chat.whatsapp.com/BylYTwTrzpB1IDHJ7HR8wV`, `…/HKCJNcjiSgZJDKa22esGrV`,
   `…/DRreIziNgxt6XNbjCBIRjv`, and Telegram `t.me/joinchat/T0UhHpW1`. Which ones are current?
   (Default: the join card opens that menu post natively.)
2. **Quiz web app.** Where is your KSPSTADK quiz web app? I saw `tools.kspstadk.com` (tools)
   and quiz *posts*, but no separate quiz-app URL. (Default: Quizzes = QUIZ + MYGOV QUIZ posts,
   plus a "KSPSTADK Tools" Custom Tab to `tools.kspstadk.com`.)
3. **Circulars/Orders.** There is no dedicated category, so I'm using INFORMATION. OK?
4. **Package name** `com.kspstadk.app` (same `com.kspstadk.*` prefix as your Tulu apps). OK?

## 7. Suggestions for the site (nothing done; each needs your OK)

* **Nothing is required** for the app: the REST API is open and fast.
* Later (Phase 5): upload `/.well-known/assetlinks.json` (I'll generate it) so links open the app.
* Optional hardening: `/wp-json/wp/v2/users` lists 4 author accounts publicly. Rank Math or a
  small `rest_endpoints` snippet can hide it. The app doesn't use it.
* Optional: the privacy-policy page needs a short "Mobile app" paragraph (I'll write the text).
