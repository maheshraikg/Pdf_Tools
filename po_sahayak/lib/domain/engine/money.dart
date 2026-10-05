/// Exact money maths on [Decimal]. Doubles are never used for amounts; the
/// only double in this file is the starting guess for [nthRoot], which Newton
/// iteration then refines in Decimal.
library;

import 'dart:math' as math;

import 'package:decimal/decimal.dart';

/// Working scale (digits after the point) for intermediate results.
const int kScale = 24;

final Decimal kHundred = Decimal.fromInt(100);
final Decimal k400 = Decimal.fromInt(400);
final Decimal k1200 = Decimal.fromInt(1200);

Decimal dec(Object v) => switch (v) {
  Decimal d => d,
  int i => Decimal.fromInt(i),
  _ => Decimal.parse(v.toString()),
};

Decimal _trim(Decimal x) => x.round(scale: kScale);

/// `a / b` at [kScale] digits.
Decimal div(Decimal a, Decimal b) =>
    (a / b).toDecimal(scaleOnInfinitePrecision: kScale);

/// `base ^ n` for a whole n ≥ 0, by squaring, kept at [kScale] digits.
Decimal pw(Decimal base, int n) {
  assert(n >= 0);
  var result = Decimal.one;
  var b = base;
  var e = n;
  while (e > 0) {
    if (e & 1 == 1) result = _trim(result * b);
    b = _trim(b * b);
    e >>= 1;
  }
  return result;
}

/// The positive n-th root of [x] (x > 0) by Newton's method.
Decimal nthRoot(Decimal x, int n) {
  assert(x > Decimal.zero && n >= 1);
  if (n == 1) return x;
  var y = dec(math.pow(x.toDouble(), 1 / n).toStringAsFixed(12));
  final nd = Decimal.fromInt(n);
  for (var i = 0; i < 50; i++) {
    final next = _trim(y - div(pw(y, n) - x, nd * pw(y, n - 1)));
    if ((next - y).abs() < Decimal.parse('1e-22')) return next;
    y = next;
  }
  return y;
}

/// Rounds to whole rupees, half up (the post office rounding).
Decimal rupees(Decimal x) => x.round();

/// Rounds to whole rupees, down (used for withdrawal limits).
Decimal rupeesDown(Decimal x) => x.floor();

/// `p × pct / 100`.
Decimal percentOf(Decimal p, Decimal pct) => div(p * pct, kHundred);
