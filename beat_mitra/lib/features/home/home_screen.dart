import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app_state.dart';
import '../../core/settings.dart';
import '../../data/models.dart';
import '../backup/backup_screen.dart';
import '../beat/beat_detail_screen.dart';
import '../beat/beats_screen.dart';
import '../common/widgets.dart';
import '../learn/learn_screen.dart';
import '../places/nearby_screen.dart';
import '../places/place_edit_screen.dart';
import '../run/route_screen.dart';
import '../search/search_screen.dart';
import '../settings/help_screen.dart';
import '../settings/map_screen.dart';
import '../settings/settings_screen.dart';
import '../summary/summary_screen.dart';
import '../today/today_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final app = context.watch<AppState>();
    final settings = context.watch<AppSettings>();
    final beat = app.activeBeat;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.appName),
            if (beat != null) Text(beat.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
          ],
        ),
        actions: [
          if (app.beats.length > 1)
            PopupMenuButton<Beat>(
              tooltip: l.switchBeat,
              icon: const Icon(Icons.swap_horiz),
              onSelected: app.setActiveBeat,
              itemBuilder: (_) => [
                for (final b in app.beats)
                  CheckedPopupMenuItem(value: b, checked: b.id == beat?.id, child: Text(b.name)),
              ],
            ),
          IconButton(
            tooltip: l.settings,
            icon: const Icon(Icons.settings),
            onPressed: () => _push(context, const SettingsScreen()),
          ),
        ],
      ),
      body: !app.ready
          ? const Center(child: CircularProgressIndicator())
          : beat == null
          ? EmptyState(
              icon: Icons.map_outlined,
              text: l.noBeatYet,
              action: FilledButton.icon(
                icon: const Icon(Icons.add),
                label: Text(l.createBeat),
                onPressed: () => _push(context, const BeatsScreen()),
              ),
            )
          : _body(context, app, settings, beat),
      floatingActionButton: beat == null
          ? null
          : FloatingActionButton.extended(
              heroTag: 'addHere',
              onPressed: () => _push(context, PlaceEditScreen(beatId: beat.id!, addHere: true)),
              icon: const Icon(Icons.add_location_alt, size: 30),
              label: Text(l.addHere),
            ),
    );
  }

  Widget _body(BuildContext context, AppState app, AppSettings settings, Beat beat) {
    final l = context.l;
    final scheme = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
      children: [
        if (settings.backupReminderDue && app.index.length > 0)
          Card(
            color: scheme.secondaryContainer,
            child: ListTile(
              leading: const Icon(Icons.warning_amber_rounded, size: 32),
              title: Text(l.backupReminder),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _push(context, const BackupScreen()),
            ),
          ),
        // Big search bar.
        Semantics(
          button: true,
          label: l.searchHint,
          child: Material(
            color: scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(28),
            child: InkWell(
              borderRadius: BorderRadius.circular(28),
              onTap: () => _push(context, const SearchScreen()),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                child: Row(
                  children: [
                    const Icon(Icons.search, size: 30),
                    const SizedBox(width: 12),
                    Expanded(child: Text(l.searchHint, style: const TextStyle(fontSize: 18))),
                    IconButton(
                      tooltip: l.voiceInput,
                      icon: const Icon(Icons.mic, size: 30),
                      onPressed: () => _push(context, const SearchScreen(startWithVoice: true)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        _TodayTile(version: app.version),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.35,
          children: [
            BigTile(
              icon: Icons.alt_route,
              label: l.routeAndRun,
              color: scheme.primary,
              onTap: () => _push(context, const RouteScreen()),
            ),
            BigTile(icon: Icons.near_me, label: l.nearby, onTap: () => _push(context, const NearbyScreen())),
            BigTile(
              icon: Icons.summarize_outlined,
              label: l.daySummary,
              onTap: () => _push(context, const SummaryScreen()),
            ),
            BigTile(
              icon: Icons.signpost_outlined,
              label: l.beatAndStreets,
              onTap: () => _push(context, BeatDetailScreen(beatId: beat.id!)),
            ),
            BigTile(icon: Icons.school_outlined, label: l.learnBeat, onTap: () => _push(context, const LearnScreen())),
            BigTile(icon: Icons.ios_share, label: l.handoverBackup, onTap: () => _push(context, const BackupScreen())),
            if (settings.onlineMap && mapAvailableInBuild)
              BigTile(icon: Icons.map, label: l.map, onTap: () => _push(context, const MapScreen())),
            BigTile(icon: Icons.help_outline, label: l.help, onTap: () => _push(context, const HelpScreen())),
          ],
        ),
      ],
    );
  }
}

/// Big "Today's articles" tile with pending / delivered counts.
class _TodayTile extends StatelessWidget {
  const _TodayTile({required this.version});
  final int version;

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final scheme = Theme.of(context).colorScheme;
    return FutureBuilder<List<Article>>(
      key: ValueKey(version),
      future: context.services.articles.forDate(dayKey(DateTime.now())),
      builder: (context, snap) {
        final list = snap.data ?? const <Article>[];
        final pending = list.where((a) => a.status == ArticleStatus.pending).length;
        final done = list.length - pending;
        return Material(
          color: scheme.secondary,
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => _push(context, const TodayScreen()),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  Icon(Icons.mark_email_unread_outlined, size: 44, color: scheme.onSecondary),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l.todaysArticles,
                          style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800, color: scheme.onSecondary),
                        ),
                        Text(
                          l.pendingDoneCount(pending, done),
                          style: TextStyle(fontSize: 17, color: scheme.onSecondary),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, size: 32, color: scheme.onSecondary),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

Future<T?> _push<T>(BuildContext context, Widget page) =>
    Navigator.of(context).push<T>(MaterialPageRoute(builder: (_) => page));
