import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_lock.dart';
import '../../core/settings.dart';
import '../common/widgets.dart';
import 'pin_pad.dart';

class LockScreen extends StatefulWidget {
  const LockScreen({super.key});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  String? _error;
  bool _bioTried = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_bioTried && context.read<AppSettings>().biometric) {
      _bioTried = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _bio());
    }
  }

  Future<void> _bio() async {
    if (!mounted) return;
    await context.read<AppLock>().unlockWithBiometric(context.l.unlockReason);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final lock = context.watch<AppLock>();
    final bio = context.watch<AppSettings>().biometric;
    final blocked = lock.blockedUntil != null && DateTime.now().isBefore(lock.blockedUntil!);
    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock_outline, size: 56, color: Theme.of(context).colorScheme.primary),
                const SizedBox(height: 8),
                Text(l.appName, style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 8),
                Text(l.enterPin, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 16),
                PinPad(
                  error: blocked ? l.tooManyTries : _error,
                  onDone: (pin) async {
                    final ok = await lock.unlockWithPin(pin);
                    if (!ok && mounted) setState(() => _error = l.wrongPin);
                    if (ok) _error = null;
                    return ok;
                  },
                  extraKey: bio
                      ? IconButton(
                          icon: const Icon(Icons.fingerprint, size: 40),
                          tooltip: l.useFingerprint,
                          onPressed: _bio,
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
