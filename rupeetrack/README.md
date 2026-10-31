# RupeeTrack

A personal finance tracker in Indian rupees for Android, built with Flutter.
It tracks savings accounts, credit cards and investments, and recording an
expense takes only a few seconds. All data stays on the phone. There is no
sign-up and no bank login.

## Features

- **Home**: net worth card (accounts + investments − card dues), quick
  actions, alerts, this month's spending, income and amount invested with a
  six-month chart, a "where it went" category donut, budgets, and recent
  activity.
- **Quick add**: enter the amount, tap a category, tap the account or card,
  then Save. The last category and source are remembered. Also covers income,
  transfers, card bills, refunds and investments. Optional receipt photo
  (camera or gallery) and a **Repeat** option (weekly, monthly, yearly).
- **Activity**: grouped by day with daily totals, search ("petrol", "250",
  "SBI") and filters. Tap to edit, swipe to delete (with undo).
- **Credit cards**: each card is drawn as a card face, with usage, available
  credit, the bill, spend this cycle, the due date and a Pay bill button.
- **Investments**: mutual funds / SIPs, stocks, PPF, NSC, FDs, RDs, Post
  Office schemes, NPS, gold and others, kept separate from spending. Shows
  portfolio value, allocation, gain, return % and yearly return (XIRR). Mutual
  funds can be **linked to the daily NAV from AMFI** (units × NAV); other
  holdings use a value you enter, with its date.
- **Accounts**: bank accounts, cash and UPI wallets, with the total balance
  and savings rate.
- **Budgets**: monthly limit per category, with a warning at 80% and once
  it is exceeded.
- **Recurring entries**: rent, SIPs, subscriptions and salary are recorded
  automatically on each due date.
- **Reminders** (local notifications at 9 AM): card bills 7 days before, 3
  days before and on the due date; recurring entries on their date.
- **Your data**: export transactions or a monthly summary as CSV; back up
  everything as a JSON file and restore it later; **import bank or card
  statements** (CSV), with column detection, category guessing and
  duplicate skipping.
- Light and dark themes and a custom launcher icon. Works fully offline; the
  internet is used only when you choose to update fund NAVs.

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

- `lib/models/`: data types, budgets, recurring rules, validation, rupee
  formatting and parsing
- `lib/ledger/`: balances, card billing cycle, alerts, budgets, returns and
  XIRR (plain Dart, unit-tested)
- `lib/data/`: CSV export, statement import and the AMFI NAV parser
- `lib/app/`: `FinanceStore` (shared_preferences JSON), `AppScope`,
  reminders, file sharing and receipts
- `lib/screens/`, `lib/widgets/`: UI (`widgets/design.dart` holds the theme
  and shared components)

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

## Notes

- Receipt photos stay in the app's private folder and are not part of the
  JSON backup.
- Live prices cover mutual funds only (AMFI publishes them free). Stocks,
  PPF, FDs and others use the value you enter.
