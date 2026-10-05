/// Build-time feature flags. Both are OFF by default, so the standard
/// build contains no ads, no billing and no Google Play Services code.
///
///   flutter build apk --release --dart-define=ENABLE_ADS=true
///
/// turns the flag on, but the real SDK still has to be wired in
/// (see docs/MONETIZATION.md); with only the flag, the no-op services
/// below are used and nothing is shown.
library;

const bool kEnableAds = bool.fromEnvironment('ENABLE_ADS');
const bool kEnableIap = bool.fromEnvironment('ENABLE_IAP');

/// Shows expert-review badges on stories in release builds too.
const bool kShowReviewFlags = bool.fromEnvironment('SHOW_REVIEW_FLAGS', defaultValue: true);
