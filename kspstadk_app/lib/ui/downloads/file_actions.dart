import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';

import '../../config.dart';
import '../../content/post_content.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../downloads/download_manager.dart';
import '../../l10n/app_localizations.dart';
import '../../state/app_state.dart';
import '../routes.dart';
import '../screens/pdf_viewer_screen.dart';

/// Library metadata for a file found in [from].
DownloadMeta metaFor(BuildContext context, FileLink f, {Post? from, String? lessonTitle}) {
  final cfg = context.app.config;
  final locale = Localizations.localeOf(context);
  final parts = [
    if (lessonTitle != null && lessonTitle.isNotEmpty) lessonTitle,
    if (f.label.isNotEmpty) f.label,
  ];
  final title = parts.isEmpty ? (from?.title ?? f.link.fileId ?? 'file') : parts.join(' · ');
  return DownloadMeta(
    title: title,
    postId: from?.id,
    postTitle: from?.title,
    group: from == null ? null : cfg.classOf(from)?.label(locale),
    subgroup: from == null ? null : cfg.subjectOf(from)?.label(locale),
  );
}

/// Opens a saved file: PDFs in the in-app viewer, others with the system.
Future<void> openRecord(BuildContext context, DownloadRecord r) async {
  if (r.isPdf) {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => PdfViewerScreen(path: r.path, title: r.title)));
  } else {
    await OpenFilex.open(r.path);
  }
}

/// Downloads (if needed) and opens [f].
Future<void> openFile(BuildContext context, FileLink f, DownloadMeta meta) async {
  final rec = await downloadFile(context, f, meta);
  if (rec != null && context.mounted) await openRecord(context, rec);
}

/// Downloads [f], showing a snackbar on failure. Returns null on error.
Future<DownloadRecord?> downloadFile(BuildContext context, FileLink f, DownloadMeta meta) async {
  final app = context.app;
  final l = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.maybeOf(context);
  final already = app.downloads.record(f.link.key);
  if (already != null) return already;
  try {
    final rec = await app.downloads.download(f.link, meta);
    final n = await app.settings.incrementDownloads();
    if (AppConfig.inAppReviewEnabled && n >= AppConfig.reviewAfterDownloads && !app.settings.reviewAsked) {
      await app.settings.markReviewAsked();
      final review = InAppReview.instance;
      if (await review.isAvailable()) await review.requestReview();
    }
    return rec;
  } on DownloadException catch (e) {
    messenger?.showSnackBar(SnackBar(
      content: Text(e.error == DownloadError.notPublic
          ? l.downloadNotPublic
          : (e.error == DownloadError.network ? l.errorOffline : l.downloadFailed)),
      action: SnackBarAction(label: l.openInBrowser, onPressed: () => openInApp(f.link.url)),
    ));
    return null;
  }
}

Future<void> shareFile(BuildContext context, FileLink f, DownloadMeta meta) async {
  final rec = context.app.downloads.record(f.link.key);
  if (rec != null) {
    await SharePlus.instance.share(ShareParams(files: [XFile(rec.path)], text: meta.title));
  } else {
    await SharePlus.instance.share(ShareParams(text: '${meta.title}\n${f.link.url}'));
  }
}

/// Bottom sheet with Open / Download / Share for a single file link.
Future<void> showFileActions(BuildContext context, FileLink f, {Post? from}) {
  final meta = metaFor(context, f, from: from);
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheet) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  _FileIcon(ext: f.link.extension),
                  const SizedBox(width: 12),
                  Expanded(child: Text(meta.title, style: Theme.of(sheet).textTheme.titleMedium, maxLines: 3)),
                ],
              ),
              const SizedBox(height: 16),
              FileActionsRow(file: f, meta: meta, expanded: true),
            ],
          ),
        ),
      );
    },
  );
}

/// Open · Download/Saved · Share buttons with live progress.
class FileActionsRow extends StatelessWidget {
  const FileActionsRow({super.key, required this.file, required this.meta, this.expanded = false, this.compact = false});

  final FileLink file;
  final DownloadMeta meta;
  final bool expanded;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final dm = context.app.downloads;
    return ValueListenableBuilder<DownloadState>(
      valueListenable: dm.state(file.link.key),
      builder: (context, s, _) {
        final running = s.status == DownloadStatus.running;
        final done = s.status == DownloadStatus.done;
        final scheme = Theme.of(context).colorScheme;
        final open = FilledButton.icon(
          onPressed: running ? null : () => openFile(context, file, meta),
          icon: const Icon(Icons.menu_book_rounded, size: 18),
          label: Text(l.open),
        );
        final download = OutlinedButton.icon(
          onPressed: done || running ? null : () => downloadFile(context, file, meta),
          icon: running
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2.4, value: s.progress),
                )
              : Icon(done ? Icons.offline_pin_rounded : Icons.download_rounded, size: 18, color: done ? Brand.green : null),
          label: Text(running
              ? (s.progress == null ? l.downloading : '${(s.progress! * 100).round()}%')
              : (done ? l.savedOffline : l.download)),
        );
        final share = IconButton.filledTonal(
          tooltip: l.share,
          onPressed: running ? null : () => shareFile(context, file, meta),
          icon: Icon(Icons.share_rounded, size: 18, color: scheme.primary),
        );
        if (expanded) {
          return Row(children: [Expanded(child: open), const SizedBox(width: 8), Expanded(child: download), const SizedBox(width: 8), share]);
        }
        return Wrap(spacing: 8, runSpacing: 6, crossAxisAlignment: WrapCrossAlignment.center, children: [open, download, share]);
      },
    );
  }
}

class _FileIcon extends StatelessWidget {
  const _FileIcon({this.ext});

  final String? ext;

  @override
  Widget build(BuildContext context) {
    final isZip = ext == 'zip' || ext == 'rar';
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        gradient: isZip ? Brand.rainbowAt(4) : Brand.rainbowAt(0),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(isZip ? Icons.folder_zip_rounded : Icons.picture_as_pdf_rounded, color: Colors.white),
    );
  }
}

/// Status dot for compact rows: saved tick or progress ring.
class DownloadStatusIcon extends StatelessWidget {
  const DownloadStatusIcon({super.key, required this.fileKey});

  final String fileKey;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return ValueListenableBuilder<DownloadState>(
      valueListenable: context.app.downloads.state(fileKey),
      builder: (context, s, _) => switch (s.status) {
        DownloadStatus.running => SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2.4, value: s.progress, semanticsLabel: l.downloading),
          ),
        DownloadStatus.done => Icon(Icons.offline_pin_rounded, color: Brand.green, size: 22, semanticLabel: l.savedOffline),
        DownloadStatus.failed => Icon(Icons.error_outline_rounded, color: Theme.of(context).colorScheme.error, size: 22),
        DownloadStatus.idle => Icon(Icons.download_rounded, size: 22, color: Theme.of(context).colorScheme.onSurfaceVariant),
      },
    );
  }
}
