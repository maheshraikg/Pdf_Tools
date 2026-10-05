/// App-wide constants and feature flags.
///
/// Nothing in here is secret: the app only talks to the public WordPress
/// REST API of kspstadk.com and (optionally) Firebase, whose client config is
/// public by design.
class AppConfig {
  AppConfig._();

  static const siteUrl = 'https://kspstadk.com';
  static const apiBase = '$siteUrl/wp-json/wp/v2';
  static const siteHosts = {'kspstadk.com', 'www.kspstadk.com'};

  static const appName = 'KSPSTADK';
  static const contactEmail = 'kspstadk@gmail.com';
  static const privacyPolicyUrl = '$siteUrl/privacy-policy-2/';
  static const aboutUrl = '$siteUrl/about-us/';
  static const contactUrl = '$siteUrl/contact-us/';
  static const playStoreUrl =
      'https://play.google.com/store/apps/details?id=com.kspstadk.app';

  /// Home-screen layout. The bundled copy is always used first; if
  /// [remoteHomeConfig] is on, a fresher copy is fetched from GitHub (free,
  /// no backend) and cached, so sections can change without an app update.
  static const homeConfigAsset = 'assets/config/home_sections.json';
  static const remoteHomeConfig = true;
  static const remoteHomeConfigUrl =
      'https://raw.githubusercontent.com/maheshraikg/Pdf_Tools/master/kspstadk_app/assets/config/home_sections.json';

  static const pageSize = 20;

  /// How long cached responses count as fresh. Stale entries are still shown
  /// instantly and refreshed in the background (stale-while-revalidate).
  static const listFreshFor = Duration(minutes: 10);
  static const postFreshFor = Duration(hours: 6);
  static const categoriesFreshFor = Duration(hours: 24);

  // ---- Optional features (OFF by default) ----

  /// AdMob banner on list screens only. Needs the `google_mobile_ads`
  /// package and an AdMob app id; see README "Optional: ads".
  static const adsEnabled = false;

  /// Ask for a Play Store review after [reviewAfterDownloads] downloads.
  static const inAppReviewEnabled = false;
  static const reviewAfterDownloads = 5;
}
