import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';

import '../../app/format.dart';
import '../../app/scope.dart';
import '../../data/saved_account_repository.dart';
import '../../reminders/notification_service.dart';
import '../../widgets/common.dart';
import '../result/result_screen.dart';

class AccountsScreen extends StatelessWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.s, repo = context.accounts;
    return Scaffold(
      appBar: AppBar(
        title: Text(s.myAccounts),
        actions: const [LanguageToggle()],
      ),
      body: ListenableBuilder(
        listenable: repo,
        builder: (context, _) {
          final list = repo.accounts;
          if (list.isEmpty) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Text(
                  s.noAccounts,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            );
          }
          final today = DateUtils.dateOnly(DateTime.now());
          final deposited = list.fold(
            Decimal.zero,
            (a, e) => a + e.result.totalDeposit,
          );
          final atMaturity = list.fold(
            Decimal.zero,
            (a, e) => a + e.result.maturityValue,
          );
          final upcoming = list
              .where((a) => !a.result.maturityDate.isBefore(today))
              .take(3)
              .toList();
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      ValueTile(s.portfolio, rupee(deposited)),
                      ValueTile(
                        s.portfolioAtMaturity,
                        rupee(atMaturity),
                        emphasis: true,
                      ),
                    ],
                  ),
                ),
              ),
              if (upcoming.isNotEmpty) ...[
                SectionTitle(s.upcoming),
                for (final a in upcoming)
                  Note(
                    '${a.name}: ${dmy(a.result.maturityDate)} '
                    '(${s.inDays(a.result.maturityDate.difference(today).inDays)})',
                    icon: Icons.event,
                  ),
              ],
              SectionTitle(s.myAccounts),
              for (final a in list) _AccountCard(account: a, today: today),
              const SizedBox(height: 8),
              Note(s.estimateOnly),
            ],
          );
        },
      ),
    );
  }
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({required this.account, required this.today});
  final SavedAccount account;
  final DateTime today;

  Future<void> _toggle(BuildContext context, bool on) async {
    final s = context.s, repo = context.accounts;
    final messenger = ScaffoldMessenger.of(context);
    if (on && !await NotificationService.requestPermission()) {
      messenger.showSnackBar(SnackBar(content: Text(s.permissionDenied)));
      return;
    }
    await repo.setRemind(account.id, on);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s, r = account.result;
    final matured = r.maturityDate.isBefore(today);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => ResultScreen(result: r, saved: true),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      account.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  IconButton(
                    tooltip: s.delete,
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => context.accounts.remove(account.id),
                  ),
                ],
              ),
              Text('${s.schemeName(r.scheme)} · ${pct(r.input.rate)}%'),
              ValueTile(s.maturityValue, rupee(r.maturityValue)),
              ValueTile(
                s.maturityDate,
                matured
                    ? '${dmy(r.maturityDate)} · ${s.matured}'
                    : dmy(r.maturityDate),
              ),
              if (!matured)
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(s.reminder),
                  subtitle: Text(s.reminderHelp),
                  value: account.remind,
                  onChanged: (v) => _toggle(context, v),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
