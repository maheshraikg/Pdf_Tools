import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/app_state.dart';
import '../widgets/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/l10n_ext.dart';
import 'home_screen.dart';
import 'profile_setup_screen.dart';

/// First-launch language choice (Kannada is the default).
class LanguageScreen extends StatelessWidget {
  const LanguageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final l = context.l10n;
    Widget option(String code, String label, Color color) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: BigCard(
        key: ValueKey('lang_$code'),
        color: app.lang == code ? color : Colors.white,
        onTap: () => context.read<AppState>().setLanguage(code),
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
        child: Row(
          children: [
            Icon(
              app.lang == code ? Icons.check_circle_rounded : Icons.circle_outlined,
              size: 36,
              color: app.lang == code ? Colors.white : Colors.black26,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: app.lang == code ? Colors.white : AppColors.ink,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Text(l.welcome, textAlign: TextAlign.center, style: Theme.of(context).textTheme.displaySmall),
              const SizedBox(height: 8),
              Text(
                'ಭಾಷೆ ಆರಿಸಿ · Choose a language',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 24),
              option('kn', 'ಕನ್ನಡ', AppColors.primary),
              option('en', 'English', AppColors.secondary),
              const Spacer(),
              FilledButton(
                key: const ValueKey('lang_continue'),
                onPressed: () {
                  final a = context.read<AppState>();
                  a.setLanguage(a.lang);
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute<void>(
                      builder: (_) => a.active == null ? const ProfileSetupScreen(firstRun: true) : const HomeScreen(),
                    ),
                  );
                },
                child: Text(l.continueBtn),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
