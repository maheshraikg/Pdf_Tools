import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app/scope.dart';
import 'app/storage.dart';
import 'app/theme.dart';
import 'packs/content.dart';
import 'packs/loader.dart';
import 'screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final results = await Future.wait([
    PrefsStore.open(),
    ContentLoader(rootBundle).load(),
  ]);
  final state = AppState(
    store: results[0] as PrefsStore,
    content: results[1] as Content,
  );
  for (final w in state.content.warnings) {
    debugPrint('content: $w');
  }
  runApp(VeshaApp(state: state));
}

class VeshaApp extends StatefulWidget {
  const VeshaApp({super.key, required this.state});
  final AppState state;

  @override
  State<VeshaApp> createState() => _VeshaAppState();
}

class _VeshaAppState extends State<VeshaApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState s) {
    widget.state.audio.onBackground(s != AppLifecycleState.resumed);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      state: widget.state,
      child: ListenableBuilder(
        listenable: widget.state,
        builder: (context, _) {
          final s = widget.state.settings;
          return MaterialApp(
            title: 'Vesha Puzzles',
            debugShowCheckedModeBanner: false,
            theme: buildTheme(Brightness.light),
            darkTheme: buildTheme(Brightness.dark),
            themeMode: s.themeMode,
            builder: (context, child) {
              if (!s.reduceMotion) return child!;
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(disableAnimations: true),
                child: child!,
              );
            },
            home: const HomeScreen(),
          );
        },
      ),
    );
  }
}
