/// Localised labels for enums and built-in values.
library;

import '../data/import/scheme_import.dart';
import '../data/models/scheme.dart';
import 'constants.dart';
import 'l10n/app_localizations.dart';

String ruleTypeLabel(AppLocalizations l, RuleType t) => switch (t) {
  RuleType.exact => l.ruleExact,
  RuleType.range => l.ruleRange,
  RuleType.prefix => l.rulePrefix,
  RuleType.office => l.ruleOffice,
  RuleType.district => l.ruleDistrict,
  RuleType.state => l.ruleState,
  RuleType.fallback => l.ruleDefault,
};

String categoryLabel(AppLocalizations l, String c) => switch (c) {
  kCatLetters => l.catLetters,
  kCatParcel => l.catParcel,
  kCatAirParcel => l.catAirParcel,
  kCatSpeedPost => l.catSpeedPost,
  _ => c,
};

String connectivityLabel(AppLocalizations l, Connectivity c) => c == Connectivity.air ? l.connAir : l.connSurface;

String fieldLabel(AppLocalizations l, ImportField f) => switch (f) {
  ImportField.type => l.fType,
  ImportField.pin => l.fPin,
  ImportField.pinFrom => l.fPinFrom,
  ImportField.pinTo => l.fPinTo,
  ImportField.prefix => l.fPrefix,
  ImportField.office => l.fOffice,
  ImportField.district => l.fDistrict,
  ImportField.state => l.fState,
  ImportField.bagCode => l.fBagCode,
  ImportField.bagName => l.fBagName,
  ImportField.section => l.fSection,
  ImportField.remarks => l.fRemarks,
  ImportField.category => l.fCategory,
  ImportField.connectivity => l.fConnectivity,
  ImportField.colour => l.fColour,
  ImportField.airCode => l.fAirCode,
  ImportField.station => l.fStation,
  ImportField.via => l.fVia,
  ImportField.l2Hub => l.fL2Hub,
  ImportField.l1Hub => l.fL1Hub,
  ImportField.direct => l.fDirect,
};

String issueLabel(AppLocalizations l, IssueKind k) => switch (k) {
  IssueKind.badPin => l.issueBadPin,
  IssueKind.noBag => l.issueNoBag,
  IssueKind.noMatchKey => l.issueNoMatch,
  IssueKind.duplicate => l.issueDuplicate,
  IssueKind.conflict => l.issueConflict,
  IssueKind.overlap => l.issueOverlap,
  IssueKind.nested => l.issueNested,
  IssueKind.unknownAirCode => l.issueUnknownAir,
  IssueKind.noConnectivity => l.issueNoConnectivity,
  IssueKind.treatedAsDefault => l.issueDefault,
  IssueKind.badColour => l.issueBadColour,
};

String officeTypeLabel(AppLocalizations l, String t) => switch (t) {
  'HO' => l.typeHO,
  'SO' => l.typeSO,
  'BO' => l.typeBO,
  _ => t.isEmpty ? l.typePO : t,
};
