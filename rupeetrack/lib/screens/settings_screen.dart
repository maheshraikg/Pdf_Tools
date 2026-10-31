import 'package:flutter/material.dart';

import '../app/files.dart';
import '../app/notifications.dart';
import '../app/scope.dart';
import '../data/csv.dart';
import '../models/models.dart';
import '../widgets/design.dart';
import 'budgets_screen.dart';
import 'import_screen.dart';
import 'investments_screen.dart' show refreshFundPrices;
import 'recurring_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _run(
    BuildContext context,
    Future<void> Function() action, {
    String? done,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await action();
      if (done != null) messenger.showSnackBar(SnackBar(content: Text(done)));
    } on FormatException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Something went wrong: $e')),
      );
    }
  }

  Future<void> _restore(BuildContext context) async {
    final store = context.store;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restore from backup?'),
        content: const Text(
          'Everything currently in the app will be replaced by the backup. '
          'Make a backup first if you are not sure.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Choose backup file'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    await _run(context, () async {
      final text = await pickTextFile();
      if (text == null) return;
      await store.restoreBackup(text);
    }, done: 'Backup restored');
  }

  @override
  Widget build(BuildContext context) {
    final store = context.store;
    final l = store.ledger;
    final stamp = isoDate(today());

    Widget tile(
      IconData icon,
      String title,
      String? subtitle,
      VoidCallback? onTap, {
      Widget? trailing,
      bool info = false,
    }) => ListTile(
      // Actions that are not available yet are greyed out; info rows are not.
      enabled: info || onTap != null,
      leading: IconBadge(icon, size: 36),
      title: Text(title),
      subtitle: subtitle == null ? null : Text(subtitle),
      trailing:
          trailing ?? (onTap == null ? null : const Icon(Icons.chevron_right)),
      onTap: onTap,
    );

    Widget group(String title, List<Widget> children) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 16, 16, 8),
          child: Text(
            title.toUpperCase(),
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              letterSpacing: 1,
            ),
          ),
        ),
        Panel(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(children: children),
        ),
      ],
    );

    void push(Widget screen) => Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => screen),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          group('Planning', [
            tile(
              Icons.pie_chart_outline,
              'Budgets',
              l.budgets.isEmpty
                  ? 'Monthly limits per category'
                  : '${l.budgets.length} categories',
              () => push(const BudgetsScreen()),
            ),
            tile(
              Icons.event_repeat,
              'Recurring entries',
              l.recurring.isEmpty
                  ? 'Rent, SIPs, subscriptions, salary'
                  : '${l.recurring.where((r) => r.active).length} active',
              () => push(const RecurringScreen()),
            ),
          ]),
          group('Reminders', [
            SwitchListTile(
              secondary: const IconBadge(
                Icons.notifications_active_outlined,
                size: 36,
              ),
              title: const Text('Bill and payment reminders'),
              subtitle: const Text(
                'Card dues 7 and 3 days before and on the day; recurring '
                'entries on their date (9 AM)',
              ),
              value: store.notifications,
              onChanged: (on) async {
                if (on) await Reminders.requestPermission();
                await store.setNotifications(on);
              },
            ),
          ]),
          group('Appearance', [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SegmentedButton<ThemeMode>(
                segments: const [
                  ButtonSegment(
                    value: ThemeMode.system,
                    icon: Icon(Icons.brightness_auto),
                    label: Text('Auto'),
                  ),
                  ButtonSegment(
                    value: ThemeMode.light,
                    icon: Icon(Icons.light_mode),
                    label: Text('Light'),
                  ),
                  ButtonSegment(
                    value: ThemeMode.dark,
                    icon: Icon(Icons.dark_mode),
                    label: Text('Dark'),
                  ),
                ],
                selected: {store.themeMode},
                onSelectionChanged: (s) => store.setThemeMode(s.first),
              ),
            ),
          ]),
          group('Investments', [
            tile(
              Icons.sync,
              'Update mutual fund prices',
              'Latest NAV from AMFI for linked funds (needs internet)',
              l.investments.any((i) => i.isLinked)
                  ? () => refreshFundPrices(context)
                  : null,
            ),
          ]),
          group('Your data', [
            tile(
              Icons.table_view_outlined,
              'Export transactions (CSV)',
              'Open in Excel or Google Sheets',
              l.txns.isEmpty
                  ? null
                  : () => _run(
                      context,
                      () => shareTextFile(
                        'rupeetrack-transactions-$stamp.csv',
                        exportTransactionsCsv(l),
                        mimeType: 'text/csv',
                      ),
                    ),
            ),
            tile(
              Icons.summarize_outlined,
              'Monthly summary (CSV)',
              'This month by category, with budgets',
              l.txns.isEmpty
                  ? null
                  : () => _run(
                      context,
                      () => shareTextFile(
                        'rupeetrack-summary-$stamp.csv',
                        exportMonthSummaryCsv(l, today()),
                        mimeType: 'text/csv',
                      ),
                    ),
            ),
            tile(
              Icons.upload_file_outlined,
              'Import bank statement',
              'CSV from net banking; duplicates are skipped',
              l.accounts.isEmpty && l.cards.isEmpty
                  ? null
                  : () => push(const ImportScreen()),
            ),
            tile(
              Icons.cloud_upload_outlined,
              'Back up',
              'Save everything to Drive, email or a file',
              () => _run(
                context,
                () => shareTextFile(
                  'rupeetrack-backup-$stamp.json',
                  store.backupJson(),
                  mimeType: 'application/json',
                ),
              ),
            ),
            tile(
              Icons.settings_backup_restore,
              'Restore from backup',
              'Replace the data in this app',
              () => _restore(context),
            ),
          ]),
          group('About', [
            tile(
              Icons.lock_outline,
              'Private by design',
              'Your data stays on this phone. Nothing is sent anywhere '
                  'unless you share or back it up yourself. Receipt photos '
                  'are not included in backups.',
              null,
              info: true,
            ),
          ]),
        ],
      ),
    );
  }
}
