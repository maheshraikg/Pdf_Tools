import '../models/models.dart';
import '../models/money.dart';
import '../models/planning.dart';
import 'billing_cycle.dart';
import 'returns.dart';

/// Where a credit card stands on a given day.
class CardStatus {
  const CardStatus({
    required this.card,
    required this.outstanding,
    required this.cycleSpend,
    required this.lastStatementDate,
    required this.statementBalance,
    required this.amountDue,
    required this.dueDate,
    required this.overdue,
    this.minDue,
    this.fromBank = false,
  });

  final CreditCard card;

  /// Minimum amount due still unpaid, when the bank reported one.
  final Paise? minDue;

  /// True when the bill figures come from the bank (SMS, email or PDF)
  /// rather than being worked out from the entries in the app.
  final bool fromBank;

  /// Everything currently owed, including purchases after the statement.
  final Paise outstanding;

  /// Purchases since the last statement (they go on the next bill).
  final Paise cycleSpend;
  final DateTime lastStatementDate;

  /// What the last statement said was owed.
  final Paise statementBalance;

  /// Unpaid part of the bill that [dueDate] applies to.
  final Paise amountDue;
  final DateTime dueDate;
  final bool overdue;

  Paise get availableCredit {
    final available = card.creditLimit - outstanding;
    return available < 0 ? 0 : available;
  }

  double get utilisationPercent => card.creditLimit <= 0
      ? 0
      : (outstanding < 0 ? 0 : outstanding) * 100 / card.creditLimit;
}

class NetWorth {
  const NetWorth({
    required this.cash,
    required this.investments,
    required this.liabilities,
    required this.hasUnvaluedInvestments,
  });

  /// Money in accounts, cash and wallets.
  final Paise cash;

  /// Current value of investments (amount invested where no value has been
  /// entered yet; see [hasUnvaluedInvestments]).
  final Paise investments;

  /// Credit card outstanding.
  final Paise liabilities;
  final bool hasUnvaluedInvestments;

  Paise get total => cash + investments - liabilities;
}

enum AlertKind { overdue, dueSoon, overBudget, highUtilisation, nearBudget }

class FinanceAlert {
  const FinanceAlert(this.kind, this.message, {this.card, this.category});
  final AlertKind kind;
  final String message;

  /// The card a due-date or utilisation alert is about.
  final CreditCard? card;

  /// The category a budget alert is about.
  final String? category;
}

/// How a category is doing against its monthly [Budget].
class BudgetStatus {
  const BudgetStatus(this.budget, this.spent);
  final Budget budget;
  final Paise spent;

  Paise get remaining => budget.monthlyLimit - spent;
  double get percent =>
      budget.monthlyLimit <= 0 ? 0 : spent * 100 / budget.monthlyLimit;
}

/// Read-only view over all accounts, cards, investments and transactions that
/// derives every balance and report. Nothing here is stored, so editing or
/// deleting a transaction automatically fixes every number.
class Ledger {
  Ledger({
    this.accounts = const [],
    this.cards = const [],
    this.investments = const [],
    this.budgets = const [],
    this.recurring = const [],
    List<Txn> txns = const [],
  }) : txns = List.unmodifiable(
         [...txns]..sort((a, b) {
           final byDate = b.date.compareTo(a.date);
           return byDate != 0 ? byDate : b.id.compareTo(a.id);
         }),
       );

  final List<Account> accounts;
  final List<CreditCard> cards;
  final List<Investment> investments;
  final List<Budget> budgets;
  final List<Recurring> recurring;

  /// Newest first.
  final List<Txn> txns;

  Account? account(int? id) => _find(accounts, id, (a) => a.id);
  CreditCard? card(int? id) => _find(cards, id, (c) => c.id);
  Investment? investment(int? id) => _find(investments, id, (i) => i.id);

  static T? _find<T>(List<T> items, int? id, int Function(T) idOf) {
    if (id == null) return null;
    for (final item in items) {
      if (idOf(item) == id) return item;
    }
    return null;
  }

  Iterable<Txn> _upTo(DateTime? asOf) =>
      asOf == null ? txns : txns.where((t) => !t.date.isAfter(dateOnly(asOf)));

  Iterable<Txn> _between(DateTime from, DateTime to) {
    final f = dateOnly(from);
    final l = dateOnly(to);
    return txns.where((t) => !t.date.isBefore(f) && !t.date.isAfter(l));
  }

  // ---- Accounts -----------------------------------------------------------

  Paise accountBalance(int accountId, {DateTime? asOf}) {
    final a = account(accountId);
    var balance = a?.openingBalance ?? 0;
    final since = a?.since;
    for (final t in _upTo(asOf)) {
      if (_isHistory(t, since)) continue;
      if (t.fromAccountId == accountId) balance -= t.amount;
      if (t.toAccountId == accountId) balance += t.amount;
    }
    return balance;
  }

  /// Imported entries dated before an account's or card's opening balance
  /// are already part of that balance: shown in history, not counted again.
  /// Entries typed in by hand always count.
  static bool _isHistory(Txn t, DateTime? since) =>
      since != null && t.sourceKey != null && t.date.isBefore(since);

  Paise get totalCash =>
      accounts.fold(0, (sum, a) => sum + accountBalance(a.id));

  /// Balance of an account ([accountId]) or amount owed on a card
  /// ([cardId]) right after each of its entries, keyed by transaction id,
  /// like the balance column of a bank statement. History entries (see
  /// [Account.since]) have no balance.
  Map<int, Paise> runningBalances({int? accountId, int? cardId}) {
    final a = account(accountId);
    final c = card(cardId);
    var balance = a?.openingBalance ?? c?.openingOutstanding ?? 0;
    final since = a?.since ?? c?.since;
    final result = <int, Paise>{};
    for (final t in txns.reversed) {
      if (_isHistory(t, since)) continue;
      var delta = 0;
      if (accountId != null) {
        if (t.fromAccountId == accountId) delta -= t.amount;
        if (t.toAccountId == accountId) delta += t.amount;
      } else {
        if (t.fromCardId == cardId) delta += t.amount;
        if (t.toCardId == cardId) delta -= t.amount;
      }
      if (delta == 0) continue;
      balance += delta;
      result[t.id] = balance;
    }
    return result;
  }

  /// Transactions touching [accountId], newest first.
  List<Txn> accountTxns(int accountId) => txns
      .where((t) => t.fromAccountId == accountId || t.toAccountId == accountId)
      .toList();

  // ---- Credit cards -------------------------------------------------------

  Paise cardOutstanding(int cardId, {DateTime? asOf}) {
    final c = card(cardId);
    var owed = c?.openingOutstanding ?? 0;
    final since = c?.since;
    for (final t in _upTo(asOf)) {
      if (_isHistory(t, since)) continue;
      // A card purchase (expense or investment) adds to what is owed; a bill
      // payment or a refund to the card reduces it.
      if (t.fromCardId == cardId) owed += t.amount;
      if (t.toCardId == cardId) owed -= t.amount;
    }
    return owed;
  }

  Paise get totalCardOutstanding => cards.fold(0, (sum, c) {
    final owed = cardOutstanding(c.id);
    return sum + (owed > 0 ? owed : 0);
  });

  List<Txn> cardTxns(int cardId) => txns
      .where((t) => t.fromCardId == cardId || t.toCardId == cardId)
      .toList();

  CardStatus cardStatus(CreditCard c, DateTime today) {
    final t = dateOnly(today);
    final statement = BillingCycle.lastStatementDate(c, t);
    final owedAtStatement = cardOutstanding(c.id, asOf: statement);
    final statementBalance = owedAtStatement > 0 ? owedAtStatement : 0;

    var creditsSince = 0;
    var cycleSpend = 0;
    for (final x in txns) {
      if (!x.date.isAfter(statement) || x.date.isAfter(t)) continue;
      if (x.toCardId == c.id) creditsSince += x.amount;
      if (x.fromCardId == c.id) cycleSpend += x.amount;
    }
    final remaining = statementBalance - creditsSince;
    final amountDue = remaining > 0 ? remaining : 0;

    final statementDue = BillingCycle.dueDateFor(c, statement);
    final DateTime dueDate;
    final bool overdue;
    if (!statementDue.isBefore(t)) {
      dueDate = statementDue;
      overdue = false;
    } else if (amountDue > 0) {
      dueDate = statementDue;
      overdue = true;
    } else {
      // Last bill is settled; the next one has not been generated yet.
      dueDate = BillingCycle.dueDateFor(
        c,
        BillingCycle.nextStatementDate(c, statement),
      );
      overdue = false;
    }

    final fromBank = _bankBillStatus(c, t, cycleSpend);
    if (fromBank != null) return fromBank;

    return CardStatus(
      card: c,
      outstanding: cardOutstanding(c.id),
      cycleSpend: cycleSpend,
      lastStatementDate: statement,
      statementBalance: statementBalance,
      amountDue: amountDue,
      dueDate: dueDate,
      overdue: overdue,
    );
  }

  /// The bank's own bill for [c], while it is current: not yet due, or due
  /// within the last 60 days and still unpaid.
  CardStatus? _bankBillStatus(CreditCard c, DateTime t, Paise cycleSpend) {
    final bill = c.bill;
    if (bill == null) return null;
    final from =
        bill.statementDate ?? bill.dueDate.subtract(const Duration(days: 20));
    var paid = 0;
    for (final x in txns) {
      if (x.toCardId == c.id && x.date.isAfter(from) && !x.date.isAfter(t)) {
        paid += x.amount;
      }
    }
    final remaining = bill.totalDue - paid;
    final amountDue = remaining > 0 ? remaining : 0;
    final pastDue = bill.dueDate.isBefore(t);
    if (pastDue && (amountDue == 0 || t.difference(bill.dueDate).inDays > 60)) {
      return null;
    }
    final minLeft = bill.minDue == null ? null : bill.minDue! - paid;
    return CardStatus(
      card: c,
      outstanding: cardOutstanding(c.id),
      cycleSpend: cycleSpend,
      lastStatementDate: bill.statementDate ?? from,
      statementBalance: bill.totalDue,
      amountDue: amountDue,
      dueDate: bill.dueDate,
      overdue: pastDue && amountDue > 0,
      minDue: minLeft == null || minLeft <= 0 ? null : minLeft,
      fromBank: true,
    );
  }

  /// Due-date reminders ([reminderDays] before the due date), utilisation
  /// warnings (highest of [utilisationThresholds] crossed) and budgets that
  /// are over or past [nearBudgetPercent] this month. Most urgent first.
  List<FinanceAlert> alerts(
    DateTime today, {
    int reminderDays = 7,
    List<int> utilisationThresholds = const [30, 50, 75],
    double nearBudgetPercent = 80,
  }) {
    final t = dateOnly(today);
    final result = <FinanceAlert>[];
    for (final c in cards) {
      final s = cardStatus(c, t);
      final daysLeft = s.dueDate.difference(t).inDays;
      if (s.overdue) {
        result.add(
          FinanceAlert(
            AlertKind.overdue,
            card: c,
            '${c.displayName}: ${formatRupees(s.amountDue)} was due '
            '${_daysText(-daysLeft)} ago',
          ),
        );
      } else if (s.amountDue > 0 && daysLeft <= reminderDays) {
        result.add(
          FinanceAlert(
            AlertKind.dueSoon,
            card: c,
            daysLeft == 0
                ? '${c.displayName}: ${formatRupees(s.amountDue)} is due today'
                : '${c.displayName}: ${formatRupees(s.amountDue)} due in '
                      '${_daysText(daysLeft)}',
          ),
        );
      }
      final crossed = [...utilisationThresholds]..sort();
      final hit = crossed.lastWhere(
        (p) => s.utilisationPercent >= p,
        orElse: () => -1,
      );
      if (hit >= 0) {
        result.add(
          FinanceAlert(
            AlertKind.highUtilisation,
            card: c,
            '${c.displayName}: ${s.utilisationPercent.toStringAsFixed(0)}% of '
            'the limit used (over $hit%)',
          ),
        );
      }
    }
    for (final b in budgetStatuses(t)) {
      if (b.percent >= 100) {
        result.add(
          FinanceAlert(
            AlertKind.overBudget,
            category: b.budget.category,
            '${b.budget.category}: ${formatRupees(-b.remaining)} over the '
            '${formatRupees(b.budget.monthlyLimit)} budget',
          ),
        );
      } else if (b.percent >= nearBudgetPercent) {
        result.add(
          FinanceAlert(
            AlertKind.nearBudget,
            category: b.budget.category,
            '${b.budget.category}: ${b.percent.toStringAsFixed(0)}% of the '
            'budget used, ${formatRupees(b.remaining)} left',
          ),
        );
      }
    }
    final order = AlertKind.values;
    result.sort(
      (a, b) => order.indexOf(a.kind).compareTo(order.indexOf(b.kind)),
    );
    return result;
  }

  static String _daysText(int days) => days == 1 ? '1 day' : '$days days';

  // ---- Spending & income --------------------------------------------------

  /// Expenses minus refunds between [from] and [to] (inclusive). Transfers,
  /// card bill payments and investments are never counted.
  Paise spending(DateTime from, DateTime to) =>
      spendingByCategory(from, to).values.fold(0, (a, b) => a + b);

  /// Spending per category, largest first.
  Map<String, Paise> spendingByCategory(DateTime from, DateTime to) {
    final totals = <String, Paise>{};
    for (final t in _between(from, to)) {
      final category = t.category ?? 'Other';
      if (t.type == TxnType.expense) {
        totals[category] = (totals[category] ?? 0) + t.amount;
      } else if (t.type == TxnType.refund) {
        totals[category] = (totals[category] ?? 0) - t.amount;
      }
    }
    final entries = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Map.fromEntries(entries);
  }

  Paise income(DateTime from, DateTime to) => _between(
    from,
    to,
  ).where((t) => t.type == TxnType.income).fold(0, (sum, t) => sum + t.amount);

  /// New money put into investments between [from] and [to].
  Paise invested(DateTime from, DateTime to) => _between(
    from,
    to,
  ).where((t) => t.type == TxnType.invest).fold(0, (sum, t) => sum + t.amount);

  /// Share of income not spent, as a percentage; null without income.
  double? savingsRate(DateTime from, DateTime to) {
    final earned = income(from, to);
    if (earned <= 0) return null;
    return (earned - spending(from, to)) * 100 / earned;
  }

  /// Spending against each budget in the month containing [day].
  List<BudgetStatus> budgetStatuses(DateTime day) {
    if (budgets.isEmpty) return const [];
    final spent = spendingByCategory(monthStart(day), monthEnd(day));
    return [for (final b in budgets) BudgetStatus(b, spent[b.category] ?? 0)];
  }

  // ---- Investments --------------------------------------------------------

  InvestmentSummary investmentSummary(Investment inv, DateTime today) {
    var contributed = 0;
    var withdrawn = 0;
    var paidOut = 0;
    final flows = <CashFlow>[];
    for (final t in txns.where((t) => t.investmentId == inv.id)) {
      switch (t.type) {
        case TxnType.invest:
          contributed += t.amount;
          flows.add(CashFlow(t.date, -t.amount));
        case TxnType.investWithdrawal:
          withdrawn += t.amount;
          flows.add(CashFlow(t.date, t.amount));
        case TxnType.investIncome when t.toAccountId != null:
          paidOut += t.amount;
          flows.add(CashFlow(t.date, t.amount));
        default:
          break;
      }
    }
    final value = inv.currentValue;
    if (value != null) {
      flows.add(CashFlow(inv.valueUpdatedOn ?? dateOnly(today), value));
    }
    return InvestmentSummary(
      investment: inv,
      contributed: contributed,
      withdrawn: withdrawn,
      incomePaidOut: paidOut,
      xirr: value == null ? null : xirr(flows),
    );
  }

  List<Txn> investmentTxns(int investmentId) =>
      txns.where((t) => t.investmentId == investmentId).toList();

  // ---- Net worth ----------------------------------------------------------

  NetWorth netWorth(DateTime today) {
    var investmentsValue = 0;
    var unvalued = false;
    for (final inv in investments) {
      final s = investmentSummary(inv, today);
      if (s.currentValue != null) {
        investmentsValue += s.currentValue!;
      } else {
        unvalued = unvalued || s.netInvested > 0;
        investmentsValue += s.netInvested > 0 ? s.netInvested : 0;
      }
    }
    return NetWorth(
      cash: totalCash,
      investments: investmentsValue,
      liabilities: totalCardOutstanding,
      hasUnvaluedInvestments: unvalued,
    );
  }
}

DateTime monthStart(DateTime d) => DateTime.utc(d.year, d.month);
DateTime monthEnd(DateTime d) => DateTime.utc(d.year, d.month + 1, 0);
