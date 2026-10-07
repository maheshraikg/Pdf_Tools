# Ads and in-app purchase (optional, off by default)

The standard build has **no ads, no billing library and no Google Play
Services**. Two compile-time flags exist so a Play Store build can add
them later without touching game code:

| Flag | Default | Effect today |
|---|---|---|
| `--dart-define=ENABLE_ADS=true` | false | Enables the ad frequency policy; `createAdsService()` still returns the no-op service until a real one is wired. |
| `--dart-define=ENABLE_IAP=true` | false | Shows "Support the artists" in Settings; disabled ("not available") until a real store service is wired. |
| `--dart-define=SHOW_REVIEW_FLAGS=false` | true | Hides "Draft – awaiting expert review" labels. Turn off only after review. |

Policy built into the code (`lib/monetization/ads.dart`):

- never during a puzzle; at most one interstitial after every 3rd
  completion; never on install day; never for supporters;
- the audience includes children → use child-directed / Families-policy
  settings and non-personalised ads only;
- nothing (puzzles, stories, dress-up) is ever locked behind payment. The
  only product is a one-time **Support the artists** purchase
  (`support_the_artists`) that removes ads.

To wire real services, add `google_mobile_ads` / `in_app_purchase` to
`pubspec.yaml`, implement `AdsService` / `IapService`, return them from
`createAdsService()` / `createIapService()` when the flag is on, and keep
an F-Droid/open-source build without those dependencies (see the
repository's AGENTS.md: FOSS flavours must not include Play Services).
