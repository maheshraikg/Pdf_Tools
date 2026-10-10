import 'dart:io';

import 'package:decimal/decimal.dart';
import 'package:po_sahayak/domain/engine/calculators.dart';
import 'package:po_sahayak/domain/models/result.dart';
import 'package:po_sahayak/domain/models/scheme.dart';
import 'package:po_sahayak/domain/rates/rate_repository.dart';

Decimal d(Object v) => Decimal.parse('$v');

CalcResult calc(Scheme s, int amount, String rate, {DateTime? opening}) =>
    calculate(
      CalcInput(
        scheme: s,
        amount: Decimal.fromInt(amount),
        opening: opening ?? DateTime(2026, 10, 10),
        rate: d(rate),
      ),
    );

RateRepository loadRates() =>
    RateRepository.fromJson(File('assets/rates.json').readAsStringSync());
