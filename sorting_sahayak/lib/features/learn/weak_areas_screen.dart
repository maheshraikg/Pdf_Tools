import 'package:flutter/material.dart';

import '../../core/app_scope.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/widgets.dart';
import '../../data/user_repo.dart';

/// Bags and PIN prefixes answered wrongly most often.
class WeakAreasScreen extends StatefulWidget {
  const WeakAreasScreen({super.key});

  @override
  State<WeakAreasScreen> createState() => _WeakAreasScreenState();
}

class _WeakAreasScreenState extends State<WeakAreasScreen> {
  List<WeakArea>? _areas;
  List<QuizRecord> _history = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_areas == null) _load();
  }

  Future<void> _load() async {
    final s = context.services;
    final a = await s.user.weakAreas(s.active?.scheme.id);
    final h = await s.user.quizHistory(schemeId: s.active?.scheme.id);
    if (mounted) {
      setState(() {
        _areas = a;
        _history = h;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final a = _areas;
    final bags = a?.where((x) => x.kind == 'bag').toList() ?? [];
    final prefixes = a?.where((x) => x.kind == 'prefix').toList() ?? [];
    final scheme = context.services.active;
    return Scaffold(
      appBar: AppBar(
        title: Text(l.weakAreas),
        actions: [
          IconButton(
            tooltip: l.resetProgress,
            icon: const Icon(Icons.restart_alt),
            onPressed: () async {
              if (!await confirm(context, l.resetProgressConfirm)) return;
              if (!context.mounted) return;
              await context.services.user.clearLearning(scheme?.scheme.id);
              await _load();
            },
          ),
        ],
      ),
      body: a == null
          ? const Center(child: CircularProgressIndicator())
          : a.isEmpty
          ? EmptyState(icon: Icons.emoji_events_outlined, text: l.noWeakAreas)
          : ListView(
              padding: const EdgeInsets.all(12),
              children: [
                if (_history.isNotEmpty)
                  Card(
                    child: ListTile(
                      title: Text(l.quizzesTaken(_history.length)),
                      subtitle: Text(l.averageScore((_history.map((r) => r.percent).reduce((x, y) => x + y) / _history.length).round())),
                    ),
                  ),
                if (bags.isNotEmpty) Text(l.weakBags, style: Theme.of(context).textTheme.titleMedium),
                for (final b in bags)
                  ListTile(
                    leading: CircleAvatar(backgroundColor: bagColour(context, scheme?.bags[b.label]), child: Text('${b.wrong}')),
                    title: Text(scheme?.bags[b.label]?.label ?? b.label, style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text(l.wrongTimes(b.wrong)),
                  ),
                const SizedBox(height: 12),
                if (prefixes.isNotEmpty) Text(l.weakPrefixes, style: Theme.of(context).textTheme.titleMedium),
                for (final p in prefixes)
                  ListTile(
                    leading: CircleAvatar(child: Text('${p.wrong}')),
                    title: Text('${p.label}xxx', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
                    subtitle: Text(l.wrongTimes(p.wrong)),
                  ),
              ],
            ),
    );
  }
}
