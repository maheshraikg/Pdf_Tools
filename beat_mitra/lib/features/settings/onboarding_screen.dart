import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_lock.dart';
import '../../core/settings.dart';
import '../common/widgets.dart';
import 'pin_pad.dart';

/// First start: language, disclaimer + privacy, then a 4-digit PIN.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _step = 0;
  String? _firstPin;
  String? _error;

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final settings = context.watch<AppSettings>();
    return Scaffold(
      appBar: AppBar(title: Text(l.welcomeTitle)),
      body: SafeArea(
        child: switch (_step) {
          0 => _language(settings),
          1 => _privacy(),
          _ => _pin(),
        },
      ),
    );
  }

  Widget _language(AppSettings settings) {
    final l = context.l;
    final current = Localizations.localeOf(context).languageCode;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Icon(Icons.markunread_mailbox, size: 80, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 12),
        Text(l.appName, textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineMedium),
        Text(l.appTagline, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 24),
        Text(l.chooseLanguage, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        for (final (code, name) in const [('kn', 'ಕನ್ನಡ'), ('en', 'English'), ('hi', 'हिन्दी')])
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: current == code
                ? FilledButton(onPressed: () => settings.localeCode = code, child: Text(name))
                : OutlinedButton(onPressed: () => settings.localeCode = code, child: Text(name)),
          ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: () => setState(() => _step = 1),
          icon: const Icon(Icons.arrow_forward),
          label: Text(l.next),
        ),
      ],
    );
  }

  Widget _privacy() {
    final l = context.l;
    final t = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Card(
          color: Theme.of(context).colorScheme.secondaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(l.disclaimer, style: t.titleMedium),
          ),
        ),
        const SizedBox(height: 16),
        for (final (icon, text) in [
          (Icons.phone_android, l.privacyOnDevice),
          (Icons.lock, l.privacyEncrypted),
          (Icons.cloud_off, l.privacyNoCloud),
          (Icons.save_alt, l.privacyBackupAdvice),
        ])
          ListTile(
            leading: Icon(icon, size: 32),
            title: Text(text, style: t.bodyLarge),
          ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: () => setState(() => _step = 2),
          icon: const Icon(Icons.check),
          label: Text(l.iUnderstand),
        ),
      ],
    );
  }

  Widget _pin() {
    final l = context.l;
    return Center(
      child: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                _firstPin == null ? l.createPin : l.confirmPin,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            PinPad(
              key: ValueKey(_firstPin == null),
              error: _error,
              onDone: (pin) async {
                if (_firstPin == null) {
                  setState(() {
                    _firstPin = pin;
                    _error = null;
                  });
                  return true;
                }
                if (pin != _firstPin) {
                  setState(() {
                    _firstPin = null;
                    _error = l.pinMismatch;
                  });
                  return false;
                }
                final settings = context.read<AppSettings>();
                await context.read<AppLock>().setPin(pin);
                settings.onboarded = true;
                return true;
              },
            ),
          ],
        ),
      ),
    );
  }
}
