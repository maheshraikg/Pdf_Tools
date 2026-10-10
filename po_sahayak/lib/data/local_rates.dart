/// Interest rates typed in on the phone for a new quarter, before an app
/// update brings them. Kept in shared_preferences.
library;

import 'dart:convert';

import 'package:decimal/decimal.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/models/scheme.dart';
import '../domain/rates/rate_repository.dart';

class LocalRates extends ChangeNotifier {
  LocalRates._(this._prefs, this.bundled, this._from, this._rates);

  static const _key = 'local_rates_v1';

  static Future<LocalRates> load(RateRepository bundled) async {
    final p = await SharedPreferences.getInstance();
    DateTime? from;
    final rates = <Scheme, Decimal>{};
    final raw = p.getString(_key);
    if (raw != null) {
      try {
        final j = jsonDecode(raw) as Map<String, dynamic>;
        from = DateTime.parse(j['from'] as String);
        for (final e in (j['rates'] as Map<String, dynamic>).entries) {
          final s = Scheme.fromCode(e.key);
          if (s != null) rates[s] = Decimal.parse(e.value.toString());
        }
      } catch (e) {
        debugPrint('Ignoring bad local rates: $e');
      }
    }
    return LocalRates._(p, bundled, from, rates);
  }

  final SharedPreferences _prefs;

  /// The table shipped with the app.
  final RateRepository bundled;
  DateTime? _from;
  Map<Scheme, Decimal> _rates;

  /// The table every screen uses.
  RateRepository get repo =>
      _from == null ? bundled : bundled.withLocal(_from!, _rates);

  /// Saved typed rates, even when an app update has made them unused.
  DateTime? get from => _from;

  Future<void> save(DateTime from, Map<Scheme, Decimal> rates) async {
    _from = from;
    _rates = Map.of(rates);
    await _prefs.setString(
      _key,
      jsonEncode({
        'from': from.toIso8601String().substring(0, 10),
        'rates': {
          for (final e in rates.entries) e.key.code: e.value.toString(),
        },
      }),
    );
    notifyListeners();
  }

  Future<void> clear() async {
    _from = null;
    _rates = {};
    await _prefs.remove(_key);
    notifyListeners();
  }
}
