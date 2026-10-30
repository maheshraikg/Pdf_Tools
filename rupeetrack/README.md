# RupeeTrack

A personal finance tracker in Indian rupees for Android, built with Flutter.
It tracks savings accounts, credit cards and investments, and recording an
expense takes only a few seconds. All data stays on the phone. There is no
sign-up and no bank login.

## Features

- **Home**: net worth (accounts + investments − card dues), this month's
  spending, income and amount invested, credit card alerts, top spending
  categories and recent transactions.
- **Quick add**: enter the amount, tap a category, tap the account or card,
  then Save. The last category and payment source are remembered. Also
  records income, transfers, card bill payments, refunds and investments.
- **Transactions**: grouped by day, with search ("petrol", "250", "SBI") and
  filters. Tap to edit, swipe to delete (with undo).
- **Credit cards**: limit, outstanding, available credit, utilisation bar,
  spend in the current cycle, statement bill, amount still due and due date.
  Alerts appear 7 days before the due date, on the due date, when the bill is
  overdue, and when usage crosses 30%, 50% or 75% of the limit.
- **Investments**: mutual funds / SIPs, stocks, PPF, NSC, FDs, RDs, Post
  Office schemes, NPS, gold and others, kept separate from spending. Shows
  amount invested, current value (entered by you, with its date), gain,
  return % and yearly return (XIRR).
- **Accounts**: bank accounts, cash in hand and UPI wallets with their
  balances, the combined balance and this month's savings rate.

## Accounting rules

Balances are never stored. They are always recalculated from opening
balances and transactions, so editing or deleting an entry fixes every total.

| Entry | Account | Card owed | Spending | Investments |
|---|---|---|---|---|
| Expense from account | − | | + | |
| Expense on card | | + | + | |
| Income | + | | | |
| Transfer between own accounts | − / + | | | |
| Card bill payment | − | − | (not a second expense) | |
| Refund | + (or card −) | | − | |
| Invest (from account or card) | − | (+) | | + |
| Withdraw from investment | + | | | − |
| Dividend / interest | + if paid out | | | reinvested: already in value |

Amounts are stored as whole paise, so totals never pick up rounding errors.

## Code layout

- `lib/models/`: data types, validation, rupee formatting/parsing
- `lib/ledger/`: balances, card billing cycle, alerts, returns and XIRR
  (plain Dart, fully unit-tested)
- `lib/app/`: `FinanceStore` (shared_preferences JSON) and `AppScope`
- `lib/screens/`, `lib/widgets/`: UI

## Build

```sh
flutter pub get
flutter analyze
flutter test
flutter build apk --release
```

Release signing reads `android/key.properties` (`storeFile`,
`storePassword`, `keyAlias`, `keyPassword`) when it exists. Without it, the
debug key is used so that the release APK is still installable.

## Not yet included

Local notifications for due dates, CSV import/export and backup, monthly
category budgets, recurring entries, receipt photos, and live market prices.
