import 'package:flutter/material.dart';

import 'app_state.dart';
import 'screens/home_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppState.instance.load();
  runApp(const TuluNighantuApp());
}

/// Tulu flag red.
const Color kSeedRed = Color(0xFFB3261E);

/// Yellow accent for light / dark themes.
const Color kAccentLight = Color(0xFF8A6D00);
const Color kAccentDark = Color(0xFFFFD54F);

/// Root widget: Material 3 light + dark themes.
class TuluNighantuApp extends StatelessWidget {
  const TuluNighantuApp({super.key});

  ThemeData _theme(Brightness b) {
    final scheme = ColorScheme.fromSeed(
      seedColor: kSeedRed,
      brightness: b,
    ).copyWith(tertiary: b == Brightness.light ? kAccentLight : kAccentDark);
    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      cardTheme: const CardThemeData(clipBehavior: Clip.antiAlias),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tulu Nighantu',
      debugShowCheckedModeBanner: false,
      theme: _theme(Brightness.light),
      darkTheme: _theme(Brightness.dark),
      home: const HomeShell(),
    );
  }
}
