import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rupeetrack/app/scope.dart';
import 'package:rupeetrack/app/store.dart';
import 'package:rupeetrack/main.dart';
import 'package:rupeetrack/models/models.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => clock = () => DateTime(2026, 10, 30));

  testWidgets('welcome screen when there is no data', (tester) async {
    await tester.pumpWidget(
      RupeeTrackApp(store: FinanceStore.memory(), background: false),
    );
    expect(find.text('All your money,\none simple view.'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsNothing);
  });

  testWidgets('quick add: amount, category, source, save', (tester) async {
    final store = FinanceStore.memory();
    await store.addAccount('SBI Savings', AccountKind.savings, 1000000);
    await tester.pumpWidget(RupeeTrackApp(store: store, background: false));
    expect(find.text('₹10,000'), findsOneWidget); // net worth

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '250');
    await tester.tap(find.widgetWithText(ChoiceChip, 'Food'));
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(store.ledger.txns, hasLength(1));
    final t = store.ledger.txns.single;
    expect(t.type, TxnType.expense);
    expect(t.amount, 25000);
    expect(t.category, 'Food');
    expect(t.fromAccountId, store.ledger.accounts.single.id);
    expect(store.ledger.accountBalance(t.fromAccountId!), 975000);
    expect(find.text('₹9,750'), findsNWidgets(2)); // net worth + in accounts
    expect(store.lastCategory, 'Food');
  });

  testWidgets('quick add rejects an empty amount', (tester) async {
    final store = FinanceStore.memory();
    await store.addAccount('Cash', AccountKind.cash, 0);
    await tester.pumpWidget(RupeeTrackApp(store: store, background: false));
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pump();
    expect(find.textContaining('Enter a valid amount'), findsOneWidget);
    expect(store.ledger.txns, isEmpty);
  });

  testWidgets('all tabs render with data', (tester) async {
    final store = FinanceStore.memory();
    await store.addAccount('SBI', AccountKind.savings, 1000000);
    await store.addCard(
      name: 'HDFC',
      lastFour: '1234',
      creditLimit: 10000000,
      statementDay: 15,
      dueDay: 5,
      openingOutstanding: 500000,
    );
    final inv = await store.addInvestment(
      'Index fund',
      InvestmentType.mutualFund,
    );
    await store.saveTxn(
      Txn(
        id: 0,
        type: TxnType.invest,
        amount: 200000,
        date: DateTime.utc(2026, 10, 5),
        fromAccountId: store.ledger.accounts.single.id,
        investmentId: inv.id,
      ),
    );
    await tester.pumpWidget(RupeeTrackApp(store: store, background: false));
    for (final tab in ['Activity', 'Cards', 'Invest', 'Accounts', 'Home']) {
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text(tab),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Cards'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('HDFC'), findsOneWidget);
    expect(find.text('•••• 1234'), findsOneWidget);
    expect(find.text('Pay bill'), findsOneWidget);
  });

  test('data survives a reload', () async {
    SharedPreferences.setMockInitialValues({});
    final store = await FinanceStore.load();
    await store.addAccount('SBI', AccountKind.savings, 1000000);
    await store.saveTxn(
      Txn(
        id: 0,
        type: TxnType.expense,
        amount: 25000,
        date: DateTime.utc(2026, 10, 30),
        category: 'Food',
        fromAccountId: store.ledger.accounts.single.id,
      ),
    );
    final reloaded = await FinanceStore.load();
    expect(reloaded.ledger.totalCash, 975000);
    expect(reloaded.lastCategory, 'Food');
    expect(jsonEncode(reloaded.toJson()), jsonEncode(store.toJson()));
  });
}
