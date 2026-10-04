import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../app_state.dart';
import '../../core/crypto.dart';
import '../../core/settings.dart';
import '../../data/backup_codec.dart';
import '../../data/models.dart';
import '../common/widgets.dart';

/// Handover export / import and full encrypted backup / restore.
class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _cleanExports();
  }

  /// Shared handover files are temporary; remove old ones.
  Future<void> _cleanExports() async {
    try {
      final d = Directory(p.join((await getTemporaryDirectory()).path, 'exports'));
      if (d.existsSync()) d.deleteSync(recursive: true);
    } catch (_) {}
  }

  BackupCodec get _codec => BackupCodec(context.services.database.db, context.services.photos);

  Future<T?> _run<T>(Future<T> Function() job) async {
    setState(() => _busy = true);
    try {
      return await job();
    } on WrongPasswordException {
      if (mounted) context.toast(context.l.wrongPassword);
    } on NotABeatMitraFileException {
      if (mounted) context.toast(context.l.notBeatMitraFile);
    } on BadBackupException {
      if (mounted) context.toast(context.l.notBeatMitraFile);
    } catch (e) {
      if (mounted) context.toast('${context.l.somethingWrong}: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    return null;
  }

  // ---------- Handover ----------

  Future<void> _handover() async {
    final l = context.l;
    final app = context.app;
    final chosen = <int>{if (app.activeBeat != null) app.activeBeat!.id!};
    var includePhones = false;
    final pw1 = TextEditingController();
    final pw2 = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (c, setD) => AlertDialog(
          title: Text(l.handoverExport),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.chooseBeats, style: Theme.of(c).textTheme.titleSmall),
                for (final b in app.beats)
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: chosen.contains(b.id),
                    title: Text(b.name),
                    onChanged: (v) => setD(() => v == true ? chosen.add(b.id!) : chosen.remove(b.id)),
                  ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: includePhones,
                  title: Text(l.includePhones),
                  onChanged: (v) => setD(() => includePhones = v),
                ),
                _pwFields(pw1, pw2),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c, false), child: Text(l.cancel)),
            FilledButton(onPressed: () => Navigator.pop(c, true), child: Text(l.createAndShare)),
          ],
        ),
      ),
    );
    if (ok != true || !mounted) return;
    if (!_checkPw(pw1.text, pw2.text) || chosen.isEmpty) return;
    final codec = _codec;
    final bytes = await _run(
      () => codec.export(
        password: pw1.text,
        kind: ExportKind.handover,
        beatIds: chosen.toList(),
        includePhones: includePhones,
      ),
    );
    if (bytes == null || !mounted) return;
    final names = app.beats.where((b) => chosen.contains(b.id)).map((b) => b.name).join('_');
    final safe = names.replaceAll(RegExp(r'[^A-Za-z0-9ऀ-ॿಀ-೿_-]+'), '_');
    final dir = Directory(p.join((await getTemporaryDirectory()).path, 'exports'))..createSync(recursive: true);
    final f = File(p.join(dir.path, 'beat_${safe}_${dayKey(DateTime.now())}.beatmitra'));
    await f.writeAsBytes(bytes, flush: true);
    if (!mounted) return;
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(f.path, mimeType: 'application/octet-stream')],
        text: l.handoverShareText,
      ),
    );
  }

  Widget _pwFields(TextEditingController a, TextEditingController b) {
    final l = context.l;
    return Column(
      children: [
        const SizedBox(height: 8),
        TextField(
          controller: a,
          obscureText: true,
          decoration: InputDecoration(labelText: l.password, helperText: l.passwordHelp),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: b,
          obscureText: true,
          decoration: InputDecoration(labelText: l.passwordAgain),
        ),
      ],
    );
  }

  bool _checkPw(String a, String b) {
    final l = context.l;
    if (a.length < 6) {
      context.toast(l.passwordTooShort);
      return false;
    }
    if (a != b) {
      context.toast(l.passwordMismatch);
      return false;
    }
    return true;
  }

  // ---------- Import / restore ----------

  Future<void> _import({required bool fullRestore}) async {
    final l = context.l;
    final files = await FilePicker.pickFiles(type: FileType.any);
    if (files.isEmpty || !mounted) return;
    final Uint8List data = await files.first.xFile.readAsBytes();
    if (!isBeatMitraFile(data)) {
      if (mounted) context.toast(l.notBeatMitraFile);
      return;
    }
    if (!mounted) return;
    final pw = await askText(context, l.enterFilePassword, label: l.password, obscure: true);
    if (pw == null || pw.isEmpty || !mounted) return;
    final opened = await _run(() => BackupCodec.open(data, pw));
    if (opened == null || !mounted) return;
    final (kind, archive) = opened;
    var replace = false;
    if (kind == ExportKind.fullBackup) {
      replace = await confirm(context, l.restoreBackup, l.restoreConfirm, danger: true, ok: l.restore);
      if (!replace) return;
    } else if (fullRestore) {
      context.toast(l.thisIsHandover);
    }
    if (!mounted) return;
    final codec = _codec;
    final app = context.app;
    final r = await _run(() => codec.import(archive, replaceAll: replace));
    if (r == null) return;
    await app.reloadBeats();
    await app.rebuildIndex();
    if (mounted) context.toast(l.importDone(r.beats, r.places, r.photos));
  }

  // ---------- Full backup ----------

  Future<void> _fullBackup() async {
    final l = context.l;
    final pw1 = TextEditingController();
    final pw2 = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(l.fullBackup),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [Text(l.fullBackupHelp), _pwFields(pw1, pw2)]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: Text(l.cancel)),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: Text(l.chooseLocation)),
        ],
      ),
    );
    if (ok != true || !mounted || !_checkPw(pw1.text, pw2.text)) return;
    final codec = _codec;
    final settings = context.read<AppSettings>();
    final bytes = await _run(() => codec.export(password: pw1.text, kind: ExportKind.fullBackup));
    if (bytes == null || !mounted) return;
    final uri = await _run(
      () => FilePicker.saveFile(
        fileName: 'beat_mitra_backup_${dayKey(DateTime.now())}.beatmitra',
        bytes: bytes,
        dialogTitle: l.fullBackup,
      ),
    );
    if (uri == null || !mounted) return;
    settings.lastBackupAt = DateTime.now().millisecondsSinceEpoch;
    context.toast(l.backupSaved);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final t = Theme.of(context).textTheme;
    final settings = context.watch<AppSettings>();
    context.watch<AppState>();
    final last = settings.lastBackupAt;
    return Scaffold(
      appBar: AppBar(title: Text(l.handoverBackup)),
      body: AbsorbPointer(
        absorbing: _busy,
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            if (_busy) const LinearProgressIndicator(minHeight: 6),
            Text(l.handover, style: t.titleLarge),
            Text(l.handoverHelp, style: t.bodyMedium),
            const SizedBox(height: 8),
            FilledButton.icon(onPressed: _handover, icon: const Icon(Icons.ios_share), label: Text(l.handoverExport)),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => _import(fullRestore: false),
              icon: const Icon(Icons.file_open),
              label: Text(l.importBeat),
            ),
            const Divider(height: 40),
            Text(l.fullBackup, style: t.titleLarge),
            Text(l.backupAdvice, style: t.bodyMedium),
            const SizedBox(height: 4),
            Text(
              last == null
                  ? l.neverBackedUp
                  : l.lastBackup(DateTime.fromMillisecondsSinceEpoch(last).toString().substring(0, 16)),
              style: t.titleSmall?.copyWith(
                color: settings.backupReminderDue ? Theme.of(context).colorScheme.error : null,
              ),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(onPressed: _fullBackup, icon: const Icon(Icons.save_alt), label: Text(l.backupNow)),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => _import(fullRestore: true),
              icon: const Icon(Icons.settings_backup_restore),
              label: Text(l.restoreBackup),
            ),
          ],
        ),
      ),
    );
  }
}
