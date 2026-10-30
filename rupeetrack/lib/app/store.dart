import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../ledger/ledger.dart';
import '../models/models.dart';

/// Where the quick-add form takes money from: an account or a card.
class Source {
  const Source.account(int id) : accountId = id, cardId = null;
  const Source.card(int id) : cardId = id, accountId = null;

  final int? accountId;
  final int? cardId;

  String get key => accountId != null ? 'a$accountId' : 'c$cardId';

  static Source? parse(String? key) {
    if (key == null || key.length < 2) return null;
    final id = int.tryParse(key.substring(1));
    if (id == null) return null;
    return switch (key[0]) {
      'a' => Source.account(id),
      'c' => Source.card(id),
      _ => null,
    };
  }

  @override
  bool operator ==(Object other) =>
      other is Source && other.accountId == accountId && other.cardId == cardId;

  @override
  int get hashCode => Object.hash(accountId, cardId);
}

/// All of the user's data, persisted as JSON in shared_preferences. Every
/// change rebuilds [ledger], from which all balances and reports are derived.
class FinanceStore extends ChangeNotifier {
  FinanceStore._(this._prefs);

  final SharedPreferences? _prefs;

  /// In-memory store (tests, previews).
  FinanceStore.memory() : _prefs = null;

  static const _dataKey = 'rupeetrack.data.v1';

  static Future<FinanceStore> load() async {
    final prefs = await SharedPreferences.getInstance();
    return FinanceStore._(prefs).._read();
  }

  final List<Account> _accounts = [];
  final List<CreditCard> _cards = [];
  final List<Investment> _investments = [];
  final List<Txn> _txns = [];
  int _nextId = 1;

  ThemeMode themeMode = ThemeMode.system;

  /// Remembered so that the next quick entry is one tap shorter.
  String lastCategory = expenseCategories.first;
  Source? lastSource;

  Ledger _ledger = Ledger();
  Ledger get ledger => _ledger;

  bool get isEmpty => _accounts.isEmpty && _cards.isEmpty;

  void _read() {
    final raw = _prefs!.getString(_dataKey);
    if (raw == null) return;
    try {
      final j = jsonDecode(raw) as Map<String, dynamic>;
      List<T> list<T>(String key, T Function(Map<String, dynamic>) f) =>
          ((j[key] as List?) ?? const [])
              .map((e) => f(e as Map<String, dynamic>))
              .toList();
      _accounts.addAll(list('accounts', Account.fromJson));
      _cards.addAll(list('cards', CreditCard.fromJson));
      _investments.addAll(list('investments', Investment.fromJson));
      _txns.addAll(list('txns', Txn.fromJson));
      _nextId = (j['nextId'] as int?) ?? 1;
      themeMode = ThemeMode.values.asNameMap()[j['theme']] ?? ThemeMode.system;
      lastCategory = (j['lastCategory'] as String?) ?? lastCategory;
      lastSource = Source.parse(j['lastSource'] as String?);
    } catch (e) {
      debugPrint('RupeeTrack: could not read saved data: $e');
    }
    _rebuild();
  }

  Map<String, Object?> toJson() => {
    'accounts': _accounts.map((e) => e.toJson()).toList(),
    'cards': _cards.map((e) => e.toJson()).toList(),
    'investments': _investments.map((e) => e.toJson()).toList(),
    'txns': _txns.map((e) => e.toJson()).toList(),
    'nextId': _nextId,
    'theme': themeMode.name,
    'lastCategory': lastCategory,
    'lastSource': lastSource?.key,
  };

  void _rebuild() {
    _ledger = Ledger(
      accounts: List.unmodifiable(_accounts),
      cards: List.unmodifiable(_cards),
      investments: List.unmodifiable(_investments),
      txns: _txns,
    );
  }

  Future<void> _save() async {
    _rebuild();
    notifyListeners();
    await _prefs?.setString(_dataKey, jsonEncode(toJson()));
  }

  int _newId() => _nextId++;

  static void _upsert<T>(List<T> items, T item, int Function(T) idOf) {
    final i = items.indexWhere((e) => idOf(e) == idOf(item));
    if (i >= 0) {
      items[i] = item;
    } else {
      items.add(item);
    }
  }

  // ---- Accounts, cards, investments --------------------------------------

  Future<void> addAccount(String name, AccountKind kind, int openingBalance) {
    _accounts.add(
      Account(
        id: _newId(),
        name: name,
        kind: kind,
        openingBalance: openingBalance,
      ),
    );
    return _save();
  }

  Future<void> addCard({
    required String name,
    required String lastFour,
    required int creditLimit,
    required int statementDay,
    required int dueDay,
    int openingOutstanding = 0,
  }) {
    _cards.add(
      CreditCard(
        id: _newId(),
        name: name,
        lastFour: lastFour,
        creditLimit: creditLimit,
        statementDay: statementDay,
        dueDay: dueDay,
        openingOutstanding: openingOutstanding,
      ),
    );
    return _save();
  }

  Future<Investment> addInvestment(String name, InvestmentType type) async {
    final inv = Investment(id: _newId(), name: name, type: type);
    _investments.add(inv);
    await _save();
    return inv;
  }

  Future<void> updateInvestmentValue(Investment inv, int value, DateTime on) {
    _upsert(_investments, inv.withValue(value, on), (e) => e.id);
    return _save();
  }

  bool isInUse({int? accountId, int? cardId, int? investmentId}) => _txns.any(
    (t) =>
        (accountId != null &&
            (t.fromAccountId == accountId || t.toAccountId == accountId)) ||
        (cardId != null && (t.fromCardId == cardId || t.toCardId == cardId)) ||
        (investmentId != null && t.investmentId == investmentId),
  );

  /// Deletes an account, card or investment that has no transactions.
  Future<bool> deleteHolding({int? accountId, int? cardId, int? investmentId}) {
    if (isInUse(
      accountId: accountId,
      cardId: cardId,
      investmentId: investmentId,
    )) {
      return Future.value(false);
    }
    _accounts.removeWhere((a) => a.id == accountId);
    _cards.removeWhere((c) => c.id == cardId);
    _investments.removeWhere((i) => i.id == investmentId);
    if (lastSource == Source.account(accountId ?? -1) ||
        lastSource == Source.card(cardId ?? -1)) {
      lastSource = null;
    }
    return _save().then((_) => true);
  }

  // ---- Transactions -------------------------------------------------------

  /// Saves [t] (a new one when its id is 0). Returns validation errors, or an
  /// empty list on success.
  Future<List<String>> saveTxn(Txn t) async {
    final errors = validate(t);
    if (errors.isNotEmpty) return errors;
    final saved = t.id == 0 ? t.withId(_newId()) : t;
    _upsert(_txns, saved, (e) => e.id);
    if (t.type == TxnType.expense) {
      lastCategory = t.category ?? lastCategory;
      lastSource = t.fromAccountId != null
          ? Source.account(t.fromAccountId!)
          : Source.card(t.fromCardId!);
    }
    await _save();
    return const [];
  }

  Future<void> deleteTxn(int id) {
    _txns.removeWhere((t) => t.id == id);
    return _save();
  }

  /// Adds [t] back after an undo.
  Future<void> restoreTxn(Txn t) {
    _upsert(_txns, t, (e) => e.id);
    return _save();
  }

  Future<void> setThemeMode(ThemeMode mode) {
    themeMode = mode;
    return _save();
  }
}
