import 'package:flutter/material.dart';

import '../../core/text_utils.dart';
import '../../core/theme.dart';
import '../../downloads/download_manager.dart';
import '../../l10n/app_localizations.dart';
import '../../state/app_state.dart';
import '../downloads/file_actions.dart';
import '../routes.dart';
import '../widgets/common.dart';

/// Offline library: every saved file grouped by class → subject, with
/// search, delete and storage used. Works with no internet at all.
class DownloadsScreen extends StatefulWidget {
  const DownloadsScreen({super.key});

  @override
  State<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends State<DownloadsScreen> {
  final _search = TextEditingController();
  String _q = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _delete(DownloadRecord r) async {
    final l = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(l.deleteConfirm(r.title)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: Text(l.cancel)),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(c).colorScheme.error),
            onPressed: () => Navigator.pop(c, true),
            child: Text(l.delete),
          ),
        ],
      ),
    );
    if (ok == true && mounted) await context.app.downloads.delete(r.key);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = Theme.of(context);
    final dm = context.app.downloads;
    return Scaffold(
      appBar: AppBar(title: Text(l.myDownloads)),
      body: ListenableBuilder(
        listenable: dm,
        builder: (context, _) {
          final all = dm.all;
          if (all.isEmpty) {
            return EmptyState(icon: Icons.download_for_offline_rounded, title: l.noDownloads, subtitle: l.noDownloadsHint);
          }
          final q = _q.toLowerCase();
          final items = q.isEmpty
              ? all
              : all
                  .where((r) => [r.title, r.postTitle, r.group, r.subgroup].any((s) => s != null && s.toLowerCase().contains(q)))
                  .toList();
          // group → subgroup → records
          final groups = <String, Map<String, List<DownloadRecord>>>{};
          for (final r in items) {
            groups
                .putIfAbsent(r.group ?? l.other, () => {})
                .putIfAbsent(r.subgroup ?? r.postTitle ?? l.other, () => [])
                .add(r);
          }
          final keys = groups.keys.toList()..sort(_classOrder);
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(gradient: Brand.headerGradient, borderRadius: BorderRadius.circular(Brand.radius)),
                    child: Row(children: [
                      const Icon(Icons.sd_storage_rounded, color: Colors.white, size: 30),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(l.filesCount(all.length), style: t.textTheme.titleMedium?.copyWith(color: Colors.white)),
                          Text(l.storageUsed(formatBytes(dm.totalBytes)), style: t.textTheme.bodySmall?.copyWith(color: Colors.white70)),
                        ]),
                      ),
                      const Icon(Icons.offline_pin_rounded, color: Colors.white),
                    ]),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                  child: TextField(
                    controller: _search,
                    onChanged: (v) => setState(() => _q = v.trim()),
                    decoration: InputDecoration(
                      hintText: l.searchDownloads,
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _q.isEmpty
                          ? null
                          : IconButton(
                              tooltip: l.clear,
                              icon: const Icon(Icons.close_rounded),
                              onPressed: () => setState(() {
                                _search.clear();
                                _q = '';
                              }),
                            ),
                    ),
                  ),
                ),
              ),
              if (items.isEmpty) SliverFillRemaining(hasScrollBody: false, child: EmptyState(icon: Icons.search_off_rounded, title: l.noResults)),
              for (final (gi, g) in keys.indexed) ...[
                SliverToBoxAdapter(child: SectionHeader(title: g, icon: Icons.school_rounded, padding: const EdgeInsets.fromLTRB(16, 16, 16, 6))),
                for (final sub in groups[g]!.keys)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
                      child: AppCard(
                        padding: const EdgeInsets.fromLTRB(14, 10, 4, 6),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(color: Brand.rainbow[gi % Brand.rainbow.length][0], shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 8),
                            Expanded(child: Text(sub, style: t.textTheme.titleSmall, maxLines: 2, overflow: TextOverflow.ellipsis)),
                          ]),
                          for (final r in groups[g]![sub]!) _RecordRow(record: r, onDelete: () => _delete(r)),
                        ]),
                      ),
                    ),
                  ),
              ],
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          );
        },
      ),
    );
  }

  /// "1 ನೇ ತರಗತಿ" < "2 …" < "10 …" < everything else.
  static int _classOrder(String a, String b) {
    int? n(String s) => int.tryParse(RegExp(r'^\D*(\d+)').firstMatch(s)?.group(1) ?? '');
    final na = n(a), nb = n(b);
    if (na != null && nb != null) return na.compareTo(nb);
    if (na != null) return -1;
    if (nb != null) return 1;
    return a.compareTo(b);
  }
}

class _RecordRow extends StatelessWidget {
  const _RecordRow({required this.record, required this.onDelete});

  final DownloadRecord record;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final l = AppLocalizations.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => openRecord(context, record),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(gradient: Brand.rainbowAt(record.isPdf ? 0 : 4), borderRadius: BorderRadius.circular(10)),
            child: Icon(record.isPdf ? Icons.picture_as_pdf_rounded : Icons.insert_drive_file_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(record.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: t.textTheme.labelLarge),
              Text('${record.extension.toUpperCase()} · ${formatBytes(record.bytes)} · ${friendlyDate(context, record.savedAt)}',
                  style: t.textTheme.labelSmall?.copyWith(color: t.colorScheme.onSurfaceVariant)),
            ]),
          ),
          PopupMenuButton<String>(
            tooltip: l.navMore,
            onSelected: (v) {
              switch (v) {
                case 'open':
                  openRecord(context, record);
                case 'post':
                  if (record.postId != null) openPost(context, record.postId!);
                case 'delete':
                  onDelete();
              }
            },
            itemBuilder: (c) => [
              PopupMenuItem(value: 'open', child: ListTile(leading: const Icon(Icons.menu_book_rounded), title: Text(l.open))),
              if (record.postId != null)
                PopupMenuItem(value: 'post', child: ListTile(leading: const Icon(Icons.article_rounded), title: Text(record.postTitle ?? ''))),
              PopupMenuItem(
                value: 'delete',
                child: ListTile(leading: Icon(Icons.delete_outline_rounded, color: t.colorScheme.error), title: Text(l.delete)),
              ),
            ],
          ),
        ]),
      ),
    );
  }
}
