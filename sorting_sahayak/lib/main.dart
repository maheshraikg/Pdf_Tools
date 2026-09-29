import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/app_scope.dart';
import 'core/l10n/app_localizations.dart';
import 'core/settings.dart';
import 'core/theme.dart';
import 'data/app_services.dart';
import 'data/db.dart';
import 'features/home_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final settings = await Settings.load();
  runApp(SortingSahayakApp(settings: settings, open: _openServices));
}

Future<AppServices> _openServices() async {
  final dbs = await AppDatabases.open();
  final s = AppServices(directoryDb: dbs.directory, userDb: dbs.user);
  await s.init();
  return s;
}

class SortingSahayakApp extends StatefulWidget {
  const SortingSahayakApp({super.key, required this.settings, required this.open});

  final Settings settings;
  final Future<AppServices> Function() open;

  @override
  State<SortingSahayakApp> createState() => _SortingSahayakAppState();
}

class _SortingSahayakAppState extends State<SortingSahayakApp> {
  AppServices? _services;
  Object? _error;

  @override
  void initState() {
    super.initState();
    widget.open().then(
      (s) => setState(() => _services = s),
      onError: (Object e) => setState(() => _error = e),
    );
  }

  @override
  Widget build(BuildContext context) {
    final services = _services;
    return ListenableBuilder(
      listenable: widget.settings,
      builder: (context, _) => MaterialApp(
        debugShowCheckedModeBanner: false,
        onGenerateTitle: (c) => AppLocalizations.of(c).appTitle,
        theme: buildTheme(Brightness.light),
        darkTheme: buildTheme(Brightness.dark),
        themeMode: widget.settings.themeMode,
        locale: widget.settings.locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        localeResolutionCallback: (device, supported) {
          for (final l in supported) {
            if (l.languageCode == device?.languageCode) return l;
          }
          return const Locale('en');
        },
        // AppScope wraps the Navigator so every pushed route can reach it.
        builder: (context, child) =>
            services == null ? child! : AppScope(settings: widget.settings, services: services, child: child!),
        home: _error != null
            ? Scaffold(body: Center(child: Padding(padding: const EdgeInsets.all(24), child: Text('$_error'))))
            : services == null
            ? const _Splash()
            : HomeShell(key: HomeShell.shellKey),
      ),
    );
  }
}

class _Splash extends StatelessWidget {
  const _Splash();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.local_post_office_outlined, size: 72, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 16),
            Text(l.appTitle, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 24),
            const CircularProgressIndicator(),
            const SizedBox(height: 12),
            Text(l.preparingDirectory),
          ],
        ),
      ),
    );
  }
}
