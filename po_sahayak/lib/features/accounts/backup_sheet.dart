import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../app/format.dart';
import '../../app/scope.dart';
import '../../app/theme.dart';
import '../../widgets/common.dart';

/// Bottom sheet to save saved accounts to a file or restore them.
Future<void> showBackupSheet(BuildContext context) {
  final s = context.s;
  final messenger = ScaffoldMessenger.of(context);
  void say(String text) =>
      messenger.showSnackBar(SnackBar(content: Text(text)));
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheet) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
            child: Text(
              s.backup,
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(s.backupSub),
          ),
          const SizedBox(height: 8),
          ListTile(
            leading: const IconBadge(Icons.upload_rounded, Brand.red, size: 36),
            title: Text(s.exportBackup),
            subtitle: Text(s.exportBackupSub),
            onTap: () async {
              Navigator.pop(sheet);
              final repo = context.accounts;
              if (repo.accounts.isEmpty) return say(s.noAccountsToBackup);
              try {
                final dir = await Directory.systemTemp.createTemp('backup');
                final name = 'po_calculator_backup_${dmy(DateTime.now())}.json';
                final f = File('${dir.path}/$name');
                await f.writeAsString(repo.exportJson(), flush: true);
                await SharePlus.instance.share(
                  ShareParams(
                    files: [XFile(f.path, mimeType: 'application/json')],
                    subject: name,
                  ),
                );
              } catch (e) {
                debugPrint('Backup failed: $e');
                say(s.shareFailed);
              }
            },
          ),
          ListTile(
            leading: const IconBadge(
              Icons.download_rounded,
              Brand.red,
              size: 36,
            ),
            title: Text(s.importBackup),
            subtitle: Text(s.importBackupSub),
            onTap: () async {
              Navigator.pop(sheet);
              final repo = context.accounts;
              try {
                final file = await FilePicker.pickFile();
                if (file == null) return;
                final added = await repo.importJson(
                  utf8.decode(await file.readAsBytes()),
                );
                say(added == 0 ? s.nothingNew : s.restored(added));
              } on FormatException {
                say(s.badBackup);
              } catch (e) {
                debugPrint('Restore failed: $e');
                say(s.badBackup);
              }
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}
