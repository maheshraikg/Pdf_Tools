/// Saved accounts, kept on the device as JSON in shared_preferences.
library;

import 'dart:convert';

import 'package:decimal/decimal.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/engine/calculators.dart';
import '../domain/models/result.dart';
import '../domain/models/scheme.dart';

class SavedAccount {
  SavedAccount({
    required this.id,
    required this.name,
    required this.input,
    this.remind = false,
  }) : result = calculate(input);

  factory SavedAccount.fromJson(Map<String, dynamic> j) => SavedAccount(
    id: j['id'] as String,
    name: j['name'] as String,
    remind: j['remind'] as bool? ?? false,
    input: CalcInput(
      scheme: Scheme.fromCode(j['scheme'] as String)!,
      amount: Decimal.parse(j['amount'] as String),
      opening: DateTime.parse(j['opening'] as String),
      rate: Decimal.parse(j['rate'] as String),
      rateFrom: j['rateFrom'] == null
          ? null
          : DateTime.parse(j['rateFrom'] as String),
    ),
  );

  final String id;
  final String name;
  final CalcInput input;
  final bool remind;

  /// Recomputed from [input] on load.
  final CalcResult result;

  SavedAccount copyWith({bool? remind}) => SavedAccount(
    id: id,
    name: name,
    input: input,
    remind: remind ?? this.remind,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'remind': remind,
    'scheme': input.scheme.code,
    'amount': input.amount.toString(),
    'opening': input.opening.toIso8601String().substring(0, 10),
    'rate': input.rate.toString(),
    if (input.rateFrom != null)
      'rateFrom': input.rateFrom!.toIso8601String().substring(0, 10),
  };
}

class SavedAccountRepository extends ChangeNotifier {
  SavedAccountRepository._(this._prefs, this._accounts);

  static const _key = 'accounts_v1';

  static Future<SavedAccountRepository> load() async {
    final p = await SharedPreferences.getInstance();
    final list = <SavedAccount>[];
    final raw = p.getString(_key);
    if (raw != null) {
      for (final j in jsonDecode(raw) as List) {
        try {
          list.add(SavedAccount.fromJson(j as Map<String, dynamic>));
        } catch (e) {
          debugPrint('Skipping bad saved account: $e');
        }
      }
    }
    return SavedAccountRepository._(p, list);
  }

  final SharedPreferences _prefs;
  final List<SavedAccount> _accounts;

  /// Sorted by maturity date.
  List<SavedAccount> get accounts => [..._accounts]
    ..sort((a, b) => a.result.maturityDate.compareTo(b.result.maturityDate));

  Future<void> _persist() async {
    await _prefs.setString(
      _key,
      jsonEncode([for (final a in _accounts) a.toJson()]),
    );
    notifyListeners();
  }

  Future<void> add(String name, CalcInput input) {
    _accounts.add(
      SavedAccount(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        name: name,
        input: input,
      ),
    );
    return _persist();
  }

  Future<void> setRemind(String id, bool remind) {
    final i = _accounts.indexWhere((a) => a.id == id);
    if (i >= 0) _accounts[i] = _accounts[i].copyWith(remind: remind);
    return _persist();
  }

  Future<void> remove(String id) {
    _accounts.removeWhere((a) => a.id == id);
    return _persist();
  }
}
