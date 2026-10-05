import 'package:flutter/widgets.dart';

import '../data/saved_account_repository.dart';
import '../domain/rates/rate_repository.dart';
import 'settings.dart';
import 'strings.dart';

/// Gives every screen the settings, rate table and saved accounts.
class AppScope extends InheritedWidget {
  const AppScope({
    super.key,
    required this.settings,
    required this.rates,
    required this.accounts,
    required super.child,
  });

  final AppSettings settings;
  final RateRepository rates;
  final SavedAccountRepository accounts;

  static AppScope of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>()!;

  @override
  bool updateShouldNotify(AppScope old) =>
      settings != old.settings ||
      rates != old.rates ||
      accounts != old.accounts;
}

extension ScopeX on BuildContext {
  AppScope get scope => AppScope.of(this);
  AppSettings get settings => scope.settings;
  RateRepository get rates => scope.rates;
  SavedAccountRepository get accounts => scope.accounts;
  S get s => S(scope.settings.lang);
}
