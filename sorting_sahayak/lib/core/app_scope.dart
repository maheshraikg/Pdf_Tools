import 'package:flutter/widgets.dart';

import '../data/app_services.dart';
import 'settings.dart';

final Expando<Listenable> _merged = Expando();

Listenable _mergedFor(Settings s, AppServices a) {
  final existing = _merged[a];
  if (existing != null) return existing;
  return _merged[a] = Listenable.merge([s, a]);
}

/// Makes [Settings] and [AppServices] available to the widget tree and
/// rebuilds dependents when either changes (active scheme, categories,
/// recents, language…).
class AppScope extends InheritedNotifier<Listenable> {
  AppScope({super.key, required this.settings, required this.services, required super.child})
    : super(notifier: _mergedFor(settings, services));

  final Settings settings;
  final AppServices services;

  static AppScope of(BuildContext context) {
    final s = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(s != null, 'No AppScope found');
    return s!;
  }
}

extension AppScopeX on BuildContext {
  Settings get settings => AppScope.of(this).settings;
  AppServices get services => AppScope.of(this).services;
}
