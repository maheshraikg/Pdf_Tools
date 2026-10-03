# Publishing PO Sorting on Google Play

Everything the Play Console asks for, in order. Texts are in
`listing-en.txt`, `listing-kn.txt`, `listing-hi.txt`; graphics in `graphics/`.

## 1. One-time setup
1. Create a Google Play developer account (one-time fee US$25) at
   https://play.google.com/console. Personal accounts need identity
   verification.
2. **Upload key** – the GitHub build signs the app with it once these four
   repository secrets exist (Settings → Secrets and variables → Actions):
   `UPLOAD_KEYSTORE_BASE64`, `UPLOAD_KEYSTORE_PASSWORD`, `UPLOAD_KEY_ALIAS`,
   `UPLOAD_KEY_PASSWORD`. Keep the keystore file and passwords safe: every
   future update must be signed with the same upload key (Google can reset a
   lost upload key, but only after a support request).
3. Turn on **Play App Signing** when creating the app (the default).

## 2. Create the app
- App name: `PO Sorting – PIN Sort Helper` · Default language: English (India)
- App or game: App · Free · Category: **Productivity** (or Tools)
- Package name (fixed forever): `com.sortingsahayak.sorting_sahayak`

## 3. Store listing
- Short and full description: `listing-en.txt` (add Kannada and Hindi
  translations from the other two files).
- App icon: `graphics/icon-512.png` (512 × 512)
- Feature graphic: `graphics/feature-graphic-1024x500.png`
- Phone screenshots: at least 2 (up to 8), taken on a phone: Sort screen
  with a result, Non-TD line with air code, Lines, Scan address, Find PIN.
- Contact email: required (shown publicly).
- Privacy policy URL:
  https://github.com/maheshraikg/Pdf_Tools/blob/master/sorting_sahayak/PRIVACY.md
  (after the PR is merged; until then use the branch link).

## 4. App content (policy forms)
- **Privacy policy**: the URL above.
- **Ads**: No ads.
- **App access**: All functionality available without special access (no login).
- **Content rating** (IARC questionnaire): category *Reference, news, or
  educational* / *Utility*; answer **No** to violence, sexual content,
  language, drugs, gambling, user interaction / sharing, location sharing,
  digital purchases → rating **Everyone / 3+**.
- **Target audience**: 18 and over (tool for postal staff). Not designed for
  children.
- **News app**: No. **Government app**: **No** – it is an independent tool;
  the listing and the in-app disclaimer say it is not an official
  Department of Posts app (needed to avoid the impersonation policy).
- **Financial features / Health / COVID**: None.
- **Data safety**:
  - Does the app collect or share user data? **No.**
    The release build has no internet permission; camera frames, photos and
    schemes stay on the phone; nothing is sent to the developer or third
    parties.
  - Voice search uses the phone's own speech service (system / Google app);
    the app itself does not collect audio. (Covered in the privacy policy.)
  - Encrypted in transit: not applicable (no data transferred).
  - Users can delete data: yes – uninstall, or delete schemes in the app.
- **Permissions**: Camera (address scan), Microphone (voice search). No
  sensitive permissions needing a declaration form.

## 5. Testing before production (new personal accounts)
Google requires a **closed test with at least 12 testers for 14 days in a
row** before a new personal developer account can publish to production.
1. Testing → Closed testing → create a track, add testers' Gmail addresses
   (colleagues), upload the AAB.
2. Share the opt-in link; testers install from Play and keep it installed
   for 14 days.
3. Then apply for production access and roll out.

## 6. Each release
1. Raise `version:` in `pubspec.yaml` (e.g. `1.0.1+2` – the number after `+`
   must go up every upload).
2. Push; the GitHub build makes `po-sorting-release.aab` (signed with the
   upload key) and checks 16 KB page alignment.
3. Play Console → the track → Create new release → upload the AAB → add
   release notes → review → roll out.
