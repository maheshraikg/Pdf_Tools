import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../../app/format.dart';
import '../../app/scope.dart';
import '../../app/strings.dart';
import '../../app/theme.dart';
import '../../widgets/common.dart';

const String kAppVersion = '1.3.0';

/// Direct link to the newest APK.
const String kDownloadUrl =
    'https://github.com/maheshraikg/Pdf_Tools/releases/download/po-sahayak-keep-latest/po_sahayak.apk';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.s, settings = context.settings, rates = context.rates;
    final t = Theme.of(context).textTheme;
    return Scaffold(
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          GradientHeader(
            child: SafeArea(
              bottom: false,
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Brand.yellow,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.settings_rounded,
                      color: Brand.redDark,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      s.settings,
                      style: t.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SectionCard(
                  icon: Icons.translate_rounded,
                  title: s.language,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final l in Lang.values)
                        ChoiceChip(
                          label: Text(l.nativeName),
                          selected: settings.lang == l,
                          onSelected: (_) => settings.lang = l,
                        ),
                    ],
                  ),
                ),
                SectionCard(
                  icon: Icons.palette_rounded,
                  title: s.theme,
                  child: SegmentedButton<ThemeMode>(
                    segments: [
                      ButtonSegment(
                        value: ThemeMode.system,
                        icon: const Icon(Icons.brightness_auto_rounded),
                        label: Text(s.themeSystem),
                      ),
                      ButtonSegment(
                        value: ThemeMode.light,
                        icon: const Icon(Icons.light_mode_rounded),
                        label: Text(s.themeLight),
                      ),
                      ButtonSegment(
                        value: ThemeMode.dark,
                        icon: const Icon(Icons.dark_mode_rounded),
                        label: Text(s.themeDark),
                      ),
                    ],
                    showSelectedIcon: false,
                    selected: {settings.themeMode},
                    onSelectionChanged: (v) => settings.themeMode = v.first,
                  ),
                ),
                SectionCard(
                  icon: Icons.info_rounded,
                  title: s.about,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        '${s.appTitle} – ${s.tagline}',
                        style: t.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Note(s.notAffiliated, icon: Icons.gpp_maybe_outlined),
                      Note(
                        '${s.rateVersion}: ${rates.version} · '
                        '${s.validFrom(dmy(rates.validFrom))}',
                        icon: Icons.percent_rounded,
                      ),
                      Note('${s.version} $kAppVersion', icon: Icons.tag),
                      Note(s.estimateOnly),
                    ],
                  ),
                ),
                Card(
                  child: ListTile(
                    leading: const IconBadge(
                      Icons.share_rounded,
                      Brand.red,
                      size: 36,
                    ),
                    title: Text(s.shareApp),
                    subtitle: Text(s.shareAppSub),
                    trailing: IconButton(
                      tooltip: s.copyLink,
                      icon: const Icon(Icons.copy_rounded),
                      onPressed: () async {
                        await Clipboard.setData(
                          const ClipboardData(text: kDownloadUrl),
                        );
                        if (context.mounted) {
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text(s.linkCopied)));
                        }
                      },
                    ),
                    onTap: () async {
                      try {
                        await SharePlus.instance.share(
                          ShareParams(text: s.shareAppText(kDownloadUrl)),
                        );
                      } catch (_) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(s.shareFailed)),
                          );
                        }
                      }
                    },
                  ),
                ),
                Card(
                  child: ListTile(
                    leading: const IconBadge(
                      Icons.privacy_tip_rounded,
                      Brand.red,
                      size: 36,
                    ),
                    title: Text(s.privacy),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => showDialog<void>(
                      context: context,
                      builder: (c) => AlertDialog(
                        icon: const Icon(
                          Icons.privacy_tip_rounded,
                          color: Brand.red,
                        ),
                        title: Text(s.privacy),
                        content: Text(s.privacyText),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(c),
                            child: Text(s.ok),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
