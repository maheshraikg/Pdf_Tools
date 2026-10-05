import 'package:decimal/decimal.dart';
import 'package:intl/intl.dart';

final NumberFormat _inr = NumberFormat.decimalPattern('en_IN');

/// ₹7,13,659 (Indian grouping, whole rupees, Western digits).
String rupee(Decimal v) => '₹${_inr.format(v.round().toBigInt().toInt())}';

/// Plain number for input fields: 713659.
String plain(Decimal v) => v.toString();

/// 7.5 (no trailing zeros).
String pct(Decimal v) => v.toString();

/// 05-10-2026.
String dmy(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}-${d.month.toString().padLeft(2, '0')}-${d.year}';
