/// Ad abstraction. The app only ever calls [AdsService]; the default is a
/// no-op. Rules for any real implementation (kept in code so they are not
/// forgotten): never during a puzzle, at most one interstitial per 3
/// completions, never on the first day, never to users who bought
/// "Support the artists", and child-directed settings (COPPA / Families
/// policy) must be enabled because the audience includes children.
library;

import 'flags.dart';

abstract class AdsService {
  bool get enabled;

  /// Called after a completion screen closes.
  Future<void> maybeShowInterstitial({required int completionsSoFar});
}

class NoAdsService implements AdsService {
  const NoAdsService();
  @override
  bool get enabled => false;
  @override
  Future<void> maybeShowInterstitial({required int completionsSoFar}) async {}
}

/// Frequency policy, shared by any real implementation and tested.
bool shouldShowInterstitial({
  required int completionsSoFar,
  required bool supporter,
  required int daysSinceInstall,
}) =>
    kEnableAds &&
    !supporter &&
    daysSinceInstall >= 1 &&
    completionsSoFar > 0 &&
    completionsSoFar % 3 == 0;

AdsService createAdsService() => const NoAdsService();
