import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/app_state.dart';
import '../widgets/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/language_grid.dart';
import '../widgets/l10n_ext.dart';
import 'home_screen.dart';
import 'profile_setup_screen.dart';

/// First-launch language choice (Kannada is the default).
class LanguageScreen extends StatelessWidget {
  const LanguageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    context.watch<AppState>();
    final l = context.l10n;
    return Scaffold(
      body: GameBackground(
        scene: Scene.grass,
        clouds: true,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        l.welcome,
                        textAlign: TextAlign.center,
                        style: display(38, color: AppColors.primaryDark),
                      ),
                      const SizedBox(height: 10),
                      const MascotBubble(text: 'ಭಾಷೆ ಆರಿಸಿ · भाषा चुनें · Choose a language', size: 64),
                      const SizedBox(height: 16),
                      const LanguageGrid(),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                child: ChunkyButton(
                  key: const ValueKey('lang_continue'),
                  color: AppColors.good,
                  onTap: () {
                    final a = context.read<AppState>();
                    a.setLanguage(a.lang);
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            a.active == null ? const ProfileSetupScreen(firstRun: true) : const HomeScreen(),
                      ),
                    );
                  },
                  child: Text(l.continueBtn, style: display(26, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
