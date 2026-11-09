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
            app.lang == code
                ? const AppImage('check', size: 40)
                : const Icon(Icons.circle_outlined, size: 40, color: Colors.black26),
            const SizedBox(width: 16),
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(label, style: display(36, color: app.lang == code ? Colors.white : AppColors.ink)),
              ),
            ),
          ],
        ),
      ),
    );
    return Scaffold(
      body: GameBackground(
        colors: const [Color(0xFFFFE3B3), Color(0xFFFFF7EA)],
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, box) => SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: box.maxHeight - 48),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Spacer(),
                      Text(
                        l.welcome,
                        textAlign: TextAlign.center,
                        style: display(40, color: AppColors.primaryDark),
                      ),
                      const SizedBox(height: 12),
                      const MascotBubble(text: 'ಭಾಷೆ ಆರಿಸಿ · Choose a language', size: 84),
                      const SizedBox(height: 24),
                      option('kn', 'ಕನ್ನಡ', AppColors.primary),
                      option('en', 'English', AppColors.secondary),
                      const Spacer(),
                      ChunkyButton(
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
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
