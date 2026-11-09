import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:share_plus/share_plus.dart';

import '../../config.dart';
import '../../core/text_utils.dart';
import '../../core/theme.dart';
import '../../l10n/app_localizations.dart';
import '../../notifications/deep_links.dart';
import '../../state/app_state.dart';
import '../routes.dart';
import '../widgets/common.dart';
import 'bookmarks_screen.dart';
import 'notifications_screen.dart';
import 'quizzes_screen.dart';

/// More: bookmarks, quizzes, notifications, settings and about.
class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final app = context.app;
    void push(Widget w) => Navigator.of(context).push(MaterialPageRoute(builder: (_) => w));

    return Scaffold(
      appBar: AppBar(title: Text(l.navMore)),
      body: ListenableBuilder(
        listenable: app.settings,
        builder: (context, _) => ListView(
          padding: const EdgeInsets.only(bottom: 32),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
              child: Row(children: [
                Expanded(child: _BigTile(icon: Icons.bookmark_rounded, label: l.bookmarks, gradient: Brand.rainbowAt(1), onTap: () => push(const BookmarksScreen()))),
                const SizedBox(width: 10),
                Expanded(child: _BigTile(icon: Icons.emoji_events_rounded, label: l.quizzes, gradient: Brand.rainbowAt(4), onTap: () => push(const QuizzesScreen()))),
                const SizedBox(width: 10),
                Expanded(
                  child: _BigTile(
                    icon: Icons.notifications_rounded,
                    label: l.notifications,
                    gradient: Brand.rainbowAt(2),
                    onTap: () => push(const NotificationsScreen()),
                  ),
                ),
              ]),
            ),
            _Group(title: l.appearance, children: [
              ListTile(
                leading: const Icon(Icons.translate_rounded),
                title: Text(l.language),
                subtitle: SegmentedButton<String>(
                  segments: [
                    ButtonSegment(value: 'kn', label: Text(l.kannada)),
                    ButtonSegment(value: 'en', label: Text(l.english)),
                  ],
                  selected: {app.settings.locale.languageCode},
                  onSelectionChanged: (s) => app.settings.setLocale(Locale(s.first)),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.palette_rounded),
                title: Text(l.theme),
                subtitle: SegmentedButton<ThemeMode>(
                  showSelectedIcon: false,
                  segments: [
                    ButtonSegment(value: ThemeMode.system, label: Text(l.themeSystem)),
                    ButtonSegment(value: ThemeMode.light, label: Text(l.themeLight)),
                    ButtonSegment(value: ThemeMode.dark, label: Text(l.themeDark)),
                  ],
                  selected: {app.settings.themeMode},
                  onSelectionChanged: (s) => app.settings.setThemeMode(s.first),
                ),
              ),
            ]),
            const _TopicsGroup(),
            const _StorageGroup(),
            _Group(title: l.general, children: [
              ListTile(
                leading: const Icon(Icons.star_rate_rounded),
                title: Text(l.rateApp),
                onTap: () => InAppReview.instance.openStoreListing(appStoreId: 'com.kspstadk.app'),
              ),
              ListTile(
                leading: const Icon(Icons.share_rounded),
                title: Text(l.shareApp),
                onTap: () => SharePlus.instance.share(ShareParams(text: l.shareAppText(AppConfig.playStoreUrl))),
              ),
              ListTile(
                leading: const Icon(Icons.info_outline_rounded),
                title: Text(l.about),
                onTap: () => _about(context),
              ),
              ListTile(
                leading: const Icon(Icons.mail_outline_rounded),
                title: Text(l.contact),
                subtitle: const Text(AppConfig.contactEmail),
                onTap: () => openExternal('mailto:${AppConfig.contactEmail}?subject=KSPSTADK%20App'),
              ),
              ListTile(
                leading: const Icon(Icons.privacy_tip_outlined),
                title: Text(l.privacyPolicy),
                onTap: () => openInApp(AppConfig.privacyPolicyUrl),
              ),
              ListTile(
                leading: const Icon(Icons.description_outlined),
                title: Text(l.licences),
                onTap: () => showLicensePage(
                  context: context,
                  applicationName: AppConfig.appName,
                  applicationVersion: AppConfig.appVersion,
                  applicationLegalese: '© KSPSTADK · kspstadk.com',
                ),
              ),
            ]),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Text(
                '${l.version(AppConfig.appVersion)}\n${l.contentWarning}',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _about(BuildContext context) {
    final l = AppLocalizations.of(context);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (c) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 64,
              height: 64,
              alignment: Alignment.center,
              decoration: BoxDecoration(gradient: Brand.headerGradient, borderRadius: BorderRadius.circular(20)),
              child: const Text('K', style: TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w800)),
            ),
            const SizedBox(height: 12),
            Text(l.appTitle, style: Theme.of(c).textTheme.titleLarge),
            Text(l.appSubtitle, style: Theme.of(c).textTheme.labelMedium),
            const SizedBox(height: 12),
            Text(l.aboutText, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            GradientPill(label: l.viewOnSite, icon: Icons.public_rounded, onTap: () => openInApp(AppConfig.aboutUrl)),
          ]),
        ),
      ),
    );
  }
}

class _BigTile extends StatelessWidget {
  const _BigTile({required this.icon, required this.label, required this.gradient, required this.onTap});

  final IconData icon;
  final String label;
  final Gradient gradient;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: label,
        excludeSemantics: true,
        child: Material(
          color: Colors.transparent,
          child: Ink(
            height: 96,
            decoration: BoxDecoration(gradient: gradient, borderRadius: BorderRadius.circular(Brand.radius)),
            child: InkWell(
              borderRadius: BorderRadius.circular(Brand.radius),
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(icon, color: Colors.white, size: 28),
                  const SizedBox(height: 6),
                  Text(label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
                ]),
              ),
            ),
          ),
        ),
      );
}

class _Group extends StatelessWidget {
  const _Group({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeader(title: title),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: AppCard(child: Column(children: children)),
          ),
        ],
      );
}

class _TopicsGroup extends StatelessWidget {
  const _TopicsGroup();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final app = context.app;
    final available = app.push?.available ?? false;
    final topics = app.settings.topics;
    final classes = app.config.classes;

    Future<void> set(String topic, bool on) async {
      final next = {...topics};
      on ? next.add(topic) : next.remove(topic);
      await app.settings.setTopics(next);
      await app.push?.syncTopics();
    }

    SwitchListTile tile(String topic, String label, IconData icon) => SwitchListTile(
          secondary: Icon(icon),
          title: Text(label),
          value: topics.contains(topic),
          onChanged: available ? (v) => set(topic, v) : null,
        );

    return _Group(title: l.notificationTopics, children: [
      if (!available)
        ListTile(
          leading: const Icon(Icons.notifications_off_outlined),
          title: Text(l.notificationsUnavailable, style: Theme.of(context).textTheme.bodySmall),
        ),
      tile(Topics.all, l.topicAll, Icons.campaign_rounded),
      tile(Topics.lba, l.topicLba, Icons.quiz_rounded),
      tile(Topics.info, l.topicInfo, Icons.gavel_rounded),
      tile(Topics.study, l.topicStudy, Icons.menu_book_rounded),
      tile(Topics.quiz, l.topicQuiz, Icons.emoji_events_rounded),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
        child: Wrap(spacing: 6, runSpacing: 6, children: [
          for (final c in classes)
            FilterChip(
              label: Text(c.label(Localizations.localeOf(context))),
              selected: topics.contains(Topics.forClass(int.parse(c.key))),
              onSelected: available ? (v) => set(Topics.forClass(int.parse(c.key)), v) : null,
            ),
        ]),
      ),
    ]);
  }
}

class _StorageGroup extends StatefulWidget {
  const _StorageGroup();

  @override
  State<_StorageGroup> createState() => _StorageGroupState();
}

class _StorageGroupState extends State<_StorageGroup> {
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final app = context.app;
    return _Group(title: l.storage, children: [
      ListTile(
        leading: const Icon(Icons.download_done_rounded),
        title: Text(l.myDownloads),
        subtitle: Text(l.storageUsed(formatBytes(app.downloads.totalBytes))),
      ),
      ListTile(
        leading: const Icon(Icons.cleaning_services_rounded),
        title: Text(l.clearCache),
        subtitle: Text(formatBytes(app.repo.cacheBytes())),
        onTap: () async {
          final messenger = ScaffoldMessenger.of(context);
          await app.repo.clearCache();
          try {
            await DefaultCacheManager().emptyCache();
          } catch (_) {/* image cache unavailable */}
          if (!mounted) return;
          setState(() {});
          messenger.showSnackBar(SnackBar(content: Text(l.cacheCleared)));
        },
      ),
    ]);
  }
}
