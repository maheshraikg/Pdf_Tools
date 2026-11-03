import 'package:flutter/material.dart';

import '../widgets/design.dart';
import 'accounts_screen.dart';
import 'auto_detect_screen.dart';
import 'budgets_screen.dart';
import 'goals_screen.dart';
import 'home_screen.dart';
import 'import_screen.dart';
import 'insights_screen.dart';
import 'investments_screen.dart';
import 'loans_screen.dart';
import 'recurring_screen.dart';
import 'settings_screen.dart';

/// Every other part of the app, in three short groups.
class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Widget item(IconData icon, String label, Widget screen) => ListTile(
      leading: IconBadge(icon, size: 38),
      title: Text(label),
      trailing: Icon(Icons.chevron_right, color: scheme.outline),
      onTap: () => push(context, screen),
    );
    Widget group(String title, List<Widget> items) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 16, 16, 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.labelLarge
                ?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ),
        Panel(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(children: items),
        ),
      ],
    );
    return Scaffold(
      appBar: AppBar(title: const Text('More')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 120),
        children: [
          group('Money', [
            item(
              Icons.account_balance_outlined,
              'Accounts',
              const AccountsScreen(),
            ),
            item(
              Icons.trending_up_rounded,
              'Investments',
              const InvestmentsScreen(),
            ),
            item(
              Icons.event_repeat_outlined,
              'Loans & EMIs',
              const LoansScreen(),
            ),
            item(Icons.savings_outlined, 'Savings goals', const GoalsScreen()),
          ]),
          group('Plan', [
            item(Icons.donut_large_outlined, 'Budgets', const BudgetsScreen()),
            item(Icons.repeat_rounded, 'Recurring', const RecurringScreen()),
            item(Icons.insights_outlined, 'Insights', const InsightsScreen()),
          ]),
          group('Data', [
            item(
              Icons.auto_awesome_outlined,
              'Automatic (SMS, Gmail)',
              const AutoDetectScreen(),
            ),
            item(
              Icons.upload_file_outlined,
              'Import statement',
              const ImportScreen(),
            ),
            item(Icons.settings_outlined, 'Settings', const SettingsScreen()),
          ]),
        ],
      ),
    );
  }
}
