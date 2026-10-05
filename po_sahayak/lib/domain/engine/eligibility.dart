/// Who can open which account, and amount limits. Shared by the calculator's
/// validation and Staff mode's eligibility checker.
library;

import 'package:decimal/decimal.dart';

import '../models/scheme.dart';

enum Holding { single, joint, minor }

enum Issue {
  belowMin,
  aboveMax,
  notMultiple,
  msscClosed,
  scssAge,
  scssEarlyRetiree, // 55–60 civilian / 50–60 defence retirees: conditions
  ssyGirlAge,
  noJoint,
  noMinor,
}

class EligibilityInput {
  const EligibilityInput({
    required this.scheme,
    required this.amount,
    this.age,
    this.holding = Holding.single,
    this.opening,
  });

  final Scheme scheme;
  final Decimal amount;

  /// Depositor's age (SSY: the girl's age).
  final int? age;
  final Holding holding;
  final DateTime? opening;
}

Decimal maxFor(Scheme s, Holding h) => s == Scheme.mis && h == Holding.joint
    ? Decimal.fromInt(Scheme.misJointMax)
    : Decimal.fromInt(s.maxAmount!);

/// Problems with the amount alone.
List<Issue> amountIssues(
  Scheme s,
  Decimal amount, {
  Holding h = Holding.single,
}) {
  return [
    if (amount < s.min) Issue.belowMin,
    if (s.maxAmount != null && amount > maxFor(s, h)) Issue.aboveMax,
    if (amount >= s.min &&
        amount % Decimal.fromInt(s.multipleOf) != Decimal.zero)
      Issue.notMultiple,
  ];
}

List<Issue> checkEligibility(EligibilityInput e) {
  final s = e.scheme, age = e.age;
  return [
    ...amountIssues(s, e.amount, h: e.holding),
    if (s == Scheme.mssc &&
        (e.opening == null || e.opening!.isAfter(Scheme.msscLastOpening)))
      Issue.msscClosed,
    if (s == Scheme.scss && age != null && age < 50) Issue.scssAge,
    if (s == Scheme.scss && age != null && age >= 50 && age < 60)
      Issue.scssEarlyRetiree,
    if (s == Scheme.ssy && age != null && age >= 10) Issue.ssyGirlAge,
    if ((s == Scheme.ppf || s == Scheme.ssy || s == Scheme.mssc) &&
        e.holding == Holding.joint)
      Issue.noJoint,
    if (s == Scheme.scss && e.holding == Holding.minor) Issue.noMinor,
  ];
}

/// Documents to bring, as string keys (see S.doc).
enum Doc {
  form, // account opening form
  kyc, // KYC form
  aadhaar,
  pan,
  photo,
  payInSlip,
  addressProof,
  guardianKyc,
  birthCert, // child's birth certificate
  ageProof,
  retirementProof, // SCSS below 60: retirement benefit papers
  jointKyc, // KYC of each joint holder
  nomination,
}

List<Doc> documentsFor(Scheme s, {Holding h = Holding.single}) => [
  Doc.form,
  Doc.kyc,
  Doc.aadhaar,
  Doc.pan,
  Doc.photo,
  Doc.addressProof,
  Doc.payInSlip,
  if (s == Scheme.ssy || h == Holding.minor) ...[
    Doc.birthCert,
    Doc.guardianKyc,
  ],
  if (s == Scheme.scss) ...[Doc.ageProof, Doc.retirementProof],
  if (h == Holding.joint) Doc.jointKyc,
  Doc.nomination,
];
