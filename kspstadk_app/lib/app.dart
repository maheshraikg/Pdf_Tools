import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/theme.dart';
import 'l10n/app_localizations.dart';
import 'state/app_state.dart';
import 'ui/shell.dart';

/// Used for navigation from outside the widget tree (notifications, links).
final navigatorKey = GlobalKey<NavigatorState>();

class KspstadkApp extends StatelessWidget {
  const KspstadkApp({super.key, required this.services, this.home});

  final AppServices services;

  /// Overrides the start screen (tests).
  final Widget? home;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      services: services,
      child: ListenableBuilder(
        listenable: services.settings,
        builder: (context, _) => MaterialApp(
          navigatorKey: navigatorKey,
          debugShowCheckedModeBanner: false,
          onGenerateTitle: (c) => AppLocalizations.of(c).appTitle,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: services.settings.themeMode,
          locale: services.settings.locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: home ?? const AppShell(),
        ),
      ),
    );
  }
}
