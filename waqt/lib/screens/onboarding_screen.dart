import 'package:flutter/material.dart';

import '../app/background.dart';
import '../app/location.dart';
import '../app/native.dart';
import '../app/scope.dart';
import '../app/settings.dart';
import '../core/alerts.dart';
import '../ui/theme.dart';
import '../ui/widgets.dart';
import 'place_screen.dart';

/// First start: language, place and alerts in three short steps.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pages = PageController();
  int _page = 0;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _go(int page) {
    _pages.animateToPage(
      page,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _finish() => context.settings.update((x) => x.onboarded = true);

  @override
  Widget build(BuildContext context) {
    final settings = context.settings, s = context.s;
    final scheme = Theme.of(context).colorScheme;
    final canNext = _page != 1 || settings.placeChosen;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pages,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (p) => setState(() => _page = p),
                children: const [_Welcome(), _Location(), _Alerts()],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Row(
                children: [
                  for (var i = 0; i < 3; i++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      width: i == _page ? 22 : 8,
                      height: 8,
                      margin: const EdgeInsetsDirectional.only(end: 6),
                      decoration: BoxDecoration(
                        color: i == _page
                            ? scheme.primary
                            : scheme.primary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  const Spacer(),
                  if (_page > 0)
                    TextButton(
                      onPressed: () => _go(_page - 1),
                      child: Text(s.back),
                    ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: !canNext
                        ? null
                        : _page < 2
                        ? () => _go(_page + 1)
                        : _finish,
                    child: Text(_page < 2 ? s.continueLabel : s.start),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Welcome extends StatelessWidget {
  const _Welcome();

  @override
  Widget build(BuildContext context) {
    final settings = context.settings, s = context.s;
    final t = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      children: [
        Container(
          height: 180,
          decoration: BoxDecoration(
            gradient: heroGradient(Theme.of(context).brightness),
            borderRadius: BorderRadius.circular(28),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: CustomPaint(
              painter: IslamicPatternPainter(
                color: Colors.white.withValues(alpha: 0.07),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Image.asset(
                        'assets/app_icon.png',
                        width: 84,
                        height: 84,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      s.appTitle,
                      style: t.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      s.appSubtitle,
                      style: t.titleSmall?.copyWith(color: kGold),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          s.welcomeTitle,
          style: t.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Text(
          s.welcomeBody,
          style: t.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: 18),
        Text(
          s.language,
          style: t.labelLarge?.copyWith(
            color: scheme.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final l in Lang.values)
              ChoiceChip(
                label: Text(l.nativeName),
                selected: settings.lang == l,
                onSelected: (_) => settings.update((x) => x.lang = l),
              ),
          ],
        ),
      ],
    );
  }
}

class _Location extends StatelessWidget {
  const _Location();

  @override
  Widget build(BuildContext context) {
    final settings = context.settings, s = context.s;
    final t = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
      children: [
        const Center(child: _BigIcon(Icons.place)),
        const SizedBox(height: 20),
        Text(
          s.whereAreYou,
          textAlign: TextAlign.center,
          style: t.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Text(
          s.whereAreYouHelp,
          textAlign: TextAlign.center,
          style: t.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: 24),
        if (settings.placeChosen)
          Card(
            child: ListTile(
              leading: Icon(Icons.check_circle, color: scheme.primary),
              title: Text(
                settings.place.label(s.ml),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text(
                '${settings.method.name} · ${s.asrName(settings.asr)}',
              ),
            ),
          ),
        const SizedBox(height: 12),
        const _GpsButton(),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          icon: const Icon(Icons.search),
          label: Text(settings.placeChosen ? s.changePlace : s.choosePlace),
          onPressed: () => Navigator.of(
            context,
          ).push(MaterialPageRoute<void>(builder: (_) => const PlaceScreen())),
        ),
      ],
    );
  }
}

class _Alerts extends StatefulWidget {
  const _Alerts();

  @override
  State<_Alerts> createState() => _AlertsState();
}

class _AlertsState extends State<_Alerts> {
  bool _asked = false;

  @override
  Widget build(BuildContext context) {
    final settings = context.settings, s = context.s;
    final t = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final c = settings.alerts;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
      children: [
        const Center(child: _BigIcon(Icons.notifications_active)),
        const SizedBox(height: 20),
        Text(
          s.neverMissTitle,
          textAlign: TextAlign.center,
          style: t.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Text(
          s.neverMissBody,
          textAlign: TextAlign.center,
          style: t.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: 20),
        FilledButton.tonalIcon(
          icon: Icon(_asked ? Icons.check : Icons.notifications_outlined),
          label: Text(s.allowAlerts),
          onPressed: () async {
            await Background.requestNotifications();
            await Background.requestExactAlarms();
            if (mounted) setState(() => _asked = true);
          },
        ),
        const SizedBox(height: 20),
        Text(
          s.azanSoundTitle,
          style: t.labelLarge?.copyWith(
            color: scheme.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final k in [
              AzanSound.azan,
              AzanSound.chime,
              AzanSound.bell,
              AzanSound.system,
            ])
              ChoiceChip(
                label: Text(s.soundKindName(k)),
                selected: c.azanSound.sound == k,
                onSelected: (_) {
                  settings.update(
                    (x) =>
                        x.alerts = x.alerts.copyWith(azanSound: SoundChoice(k)),
                  );
                  final sound = SoundChoice(k).playerSound;
                  if (sound != null && Native.supported) {
                    Native.playSound(sound, s.azan, settings.place.label(s.ml));
                  }
                },
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          s.moreInAlerts,
          style: t.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _BigIcon extends StatelessWidget {
  const _BigIcon(this.icon);
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 48, color: scheme.primary),
    );
  }
}

/// Locates the phone (asks for permission) and keeps following it.
class _GpsButton extends StatefulWidget {
  const _GpsButton();

  @override
  State<_GpsButton> createState() => _GpsButtonState();
}

class _GpsButtonState extends State<_GpsButton> {
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    // First start: find the place by itself; the user can change it after.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && Native.supported && !context.settings.placeChosen) {
        _locate(quiet: true);
      }
    });
  }

  /// Locates the phone; [quiet] skips the error message (automatic try).
  Future<void> _locate({bool quiet = false}) async {
    final settings = context.settings, s = context.s;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    final err = await useMyLocation(settings);
    if (!mounted) return;
    setState(() => _busy = false);
    if (err != null && !quiet) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(switch (err) {
            LocationError.denied => s.locationDenied,
            LocationError.disabled => s.locationDisabled,
            LocationError.unavailable => s.locationUnavailable,
          }),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return FilledButton.icon(
      icon: _busy
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.my_location),
      label: Text(_busy ? s.locating : s.useMyLocation),
      onPressed: _busy ? null : _locate,
    );
  }
}
