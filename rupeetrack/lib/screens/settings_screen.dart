import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app/files.dart';
import '../app/notifications.dart';
import '../app/scope.dart';
import '../data/csv.dart';
import '../data/reports.dart';
import '../models/models.dart';
import '../widgets/design.dart';
import 'auto_detect_screen.dart';
import 'budgets_screen.dart';
import 'import_screen.dart';
import 'investments_screen.dart' show refreshFundPrices;
import 'recurring_screen.dart';
import '../l10n/strings.dart';

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
        SnackBar(content: Text(tr('Something went wrong: {0}', [e]))),
      );
    }
  }

  Future<void> _restore(BuildContext context) async {
    final store = context.store;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr('Restore from backup?')),
        content: Text(
          tr(
            'Everything currently in the app will be replaced by the backup. Make a backup first if you are not sure.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(tr('Cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(tr('Choose backup file')),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    await _run(context, () async {
      final text = await pickTextFile();
      if (text == null) return;
      await store.restoreBackup(text);
    }, done: tr('Backup restored'));
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
              color: Theme.of(context).colorScheme.onSurfaceVariant,
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
      appBar: AppBar(title: Text(tr('Settings'))),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          group(tr('Language'), [
            tile(
              Icons.translate,
              currentLanguageName(),
              tr('Change the app language'),
              () => showLanguagePicker(context),
            ),
          ]),
          group(tr('Automatic'), [
            tile(
              Icons.auto_awesome,
              tr('Auto-detect from SMS, statements & Gmail'),
              store.smsSync
                  ? tr('Bank SMS on{0}', [
                      store.detected.isEmpty
                          ? ''
                          : ' · ${store.detected.length} new found',
                    ])
                  : tr('Fill cards and accounts from bank messages'),
              () => push(const AutoDetectScreen()),
            ),
          ]),
          group(tr('Planning'), [
            tile(
              Icons.pie_chart_outline,
              tr('Budgets'),
              l.budgets.isEmpty
                  ? tr('Monthly limits per category')
                  : tr('{0} categories', [l.budgets.length]),
              () => push(const BudgetsScreen()),
            ),
            tile(
              Icons.event_repeat,
              tr('Recurring entries'),
              l.recurring.isEmpty
                  ? tr('Rent, SIPs, subscriptions, salary')
                  : tr('{0} active', [
                      l.recurring.where((r) => r.active).length,
                    ]),
              () => push(const RecurringScreen()),
            ),
          ]),
          group(tr('Reminders'), [
            SwitchListTile(
              secondary: const IconBadge(
                Icons.notifications_active_outlined,
                size: 36,
              ),
              title: Text(tr('Bill and payment reminders')),
              subtitle: Text(
                tr(
                  'Card dues 7 and 3 days before and on the day; recurring entries on their date (9 AM)',
                ),
              ),
              value: store.notifications,
              onChanged: (on) async {
                if (on) await Reminders.requestPermission();
                await store.setNotifications(on);
              },
            ),
          ]),
          group(tr('Appearance'), [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SegmentedButton<ThemeMode>(
                segments: [
                  ButtonSegment(
                    value: ThemeMode.system,
                    icon: Icon(Icons.brightness_auto),
                    label: Text(tr('Auto')),
                  ),
                  ButtonSegment(
                    value: ThemeMode.light,
                    icon: Icon(Icons.light_mode),
                    label: Text(tr('Light')),
                  ),
                  ButtonSegment(
                    value: ThemeMode.dark,
                    icon: Icon(Icons.dark_mode),
                    label: Text(tr('Dark')),
                  ),
                ],
                selected: {store.themeMode},
                onSelectionChanged: (s) => store.setThemeMode(s.first),
              ),
            ),
          ]),
          group(tr('Investments'), [
            tile(
              Icons.sync,
              tr('Update mutual fund prices'),
              tr('Latest NAV from AMFI for linked funds (needs internet)'),
              l.investments.any((i) => i.isLinked)
                  ? () => refreshFundPrices(context)
                  : null,
            ),
          ]),
          group(tr('Your data'), [
            tile(
              Icons.table_view_outlined,
              tr('Export transactions (CSV)'),
              tr('Open in Excel or Google Sheets'),
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
              tr('Monthly summary (CSV)'),
              tr('This month by category, with budgets'),
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
              tr('Import bank statement'),
              tr('CSV from net banking; duplicates are skipped'),
              l.accounts.isEmpty && l.cards.isEmpty
                  ? null
                  : () => push(const ImportScreen()),
            ),
            tile(
              Icons.grid_on_outlined,
              tr('Excel report (.xlsx)'),
              tr('Transactions, accounts, cards, investments and budgets'),
              () => _run(
                context,
                () => shareBytesFile(
                  'rupeetrack-report-$stamp.xlsx',
                  buildExcelReport(l, today()),
                  mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
                ),
              ),
            ),
            tile(
              Icons.picture_as_pdf_outlined,
              tr('PDF report'),
              tr('A printable summary with every transaction'),
              () => _run(context, () async {
                final regular = await rootBundle.load(
                  'assets/fonts/Carlito-Regular.ttf',
                );
                final bold = await rootBundle.load(
                  'assets/fonts/Carlito-Bold.ttf',
                );
                await shareBytesFile(
                  'rupeetrack-report-$stamp.pdf',
                  await buildPdfReport(
                    l,
                    today(),
                    regular: regular,
                    bold: bold,
                  ),
                  mimeType: 'application/pdf',
                );
              }),
            ),
            tile(
              Icons.cloud_upload_outlined,
              tr('Back up'),
              tr('Everything, to restore later (Drive, email or a file)'),
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
              tr('Restore from backup'),
              tr('Replace the data in this app'),
              () => _restore(context),
            ),
          ]),
          group(tr('About'), [
            tile(
              Icons.lock_outline,
              tr('Private by design'),
              tr(
                'Your data stays on this phone. Nothing is sent anywhere unless you share or back it up yourself. Receipt photos are not included in backups.',
              ),
              null,
              info: true,
            ),
          ]),
        ],
      ),
    );
  }
}

String currentLanguageName() => appLanguages
    .firstWhere(
      (l) => l.code == currentLanguage,
      orElse: () => appLanguages.first,
    )
    .nativeName;

/// Bottom sheet listing every language in its own script.
Future<void> showLanguagePicker(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.only(bottom: 16),
          children: [
            for (final l in availableLanguages)
              ListTile(
                title: Text(l.nativeName),
                subtitle: l.code == 'en' ? null : Text(l.englishName),
                trailing: l.code == currentLanguage
                    ? Icon(
                        Icons.check_rounded,
                        color: Theme.of(sheetContext).colorScheme.primary,
                      )
                    : null,
                onTap: () {
                  Navigator.pop(sheetContext);
                  context.store.setLanguage(l.code);
                },
              ),
          ],
        ),
      ),
    );
