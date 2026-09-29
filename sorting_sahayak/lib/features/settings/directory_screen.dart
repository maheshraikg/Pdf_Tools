/// PIN directory info and "Update PIN directory" from a newer CSV.
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import '../../core/app_scope.dart';
import '../../core/files.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/widgets.dart';
import '../../data/db.dart';
import '../../data/directory_update.dart';
import '../../data/models/office.dart';

class DirectoryScreen extends StatefulWidget {
  const DirectoryScreen({super.key});

  @override
  State<DirectoryScreen> createState() => _DirectoryScreenState();
}

class _DirectoryScreenState extends State<DirectoryScreen> {
  DirectoryMeta? _meta;
  DirectoryUpdateProgress? _progress;
  final _state = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_meta == null) _load();
  }

  Future<void> _load() async {
    final m = await context.services.directory.meta();
    if (mounted) setState(() => _meta = m);
  }

  Future<void> _update() async {
    final l = AppLocalizations.of(context);
    final services = context.services;
    final path = await pickCsvPath();
    if (path == null) return;
    final target = '${await AppDatabases.directoryPath()}.new';
    await for (final p in buildDirectoryFromCsv(
      csvPath: path,
      targetPath: target,
      openDb: (x) => openDatabase(x),
      stateFilter: _state.text.trim().isEmpty ? null : _state.text.trim(),
    )) {
      if (!mounted) return;
      setState(() => _progress = p);
      if (p.stage == 'error') return;
    }
    // Swap the new file in: switch to it, then move it over the old file.
    final live = await AppDatabases.directoryPath();
    await services.replaceDirectory(await openDatabase(target));
    final liveFile = File(live);
    if (liveFile.existsSync()) await liveFile.delete();
    await File(target).rename(live);
    await services.replaceDirectory(await openDatabase(live));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dirCustom', true);
    if (!mounted) return;
    toast(context, l.directoryUpdated(_progress?.rows ?? 0));
    setState(() => _meta = null);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final m = _meta;
    final p = _progress;
    final busy = p != null && p.stage != 'done' && p.stage != 'error';
    return Scaffold(
      appBar: AppBar(title: Text(l.pinDirectory)),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          if (m != null)
            Card(
              child: Column(
                children: [
                  ListTile(title: Text(l.dirSource), subtitle: Text(m.source)),
                  ListTile(title: Text(l.dirRows), subtitle: Text('${m.rowCount}')),
                  ListTile(title: Text(l.dirFileDate), subtitle: Text(m.fileDate)),
                  ListTile(title: Text(l.dirBuilt), subtitle: Text(m.builtAt)),
                  if (m.stateFilter.isNotEmpty) ListTile(title: Text(l.dirStateFilter), subtitle: Text(m.stateFilter)),
                  ListTile(title: Text(l.dirSearchIndex), subtitle: Text(m.hasFts ? 'FTS5' : 'LIKE')),
                ],
              ),
            ),
          if (m != null && m.rowCount < 1000) ...[
            const SizedBox(height: 8),
            WarningBanner(text: l.dirPlaceholderWarning),
          ],
          const SizedBox(height: 16),
          Text(l.dirUpdateHelp),
          const SizedBox(height: 8),
          TextField(controller: _state, decoration: InputDecoration(labelText: l.dirStateOnly, hintText: 'Karnataka')),
          const SizedBox(height: 8),
          FilledButton.icon(onPressed: busy ? null : _update, icon: const Icon(Icons.upload_file), label: Text(l.updateDirectory)),
          if (p != null) ...[
            const SizedBox(height: 12),
            LinearProgressIndicator(value: p.progress),
            const SizedBox(height: 4),
            Text(switch (p.stage) {
              'parse' => l.dirParsing,
              'write' => l.dirWriting,
              'done' => l.directoryUpdated(p.rows ?? 0),
              _ => l.error(p.error ?? ''),
            }),
          ],
          const SizedBox(height: 16),
          Text(l.dataCredit, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
