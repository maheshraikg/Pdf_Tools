/// Column auto-detection, row parsing and validation for sorting schemes,
/// air code sheets and DMSL (Due Mail Sorting List) files.
library;

import '../../core/fuzzy.dart';
import '../../core/pin_utils.dart';
import '../../core/theme.dart' show parseColour;
import '../airports.dart';
import '../models/scheme.dart';

enum ImportKind { bagRules, airCodes, dmsl }

enum ImportField {
  type,
  pin,
  pinFrom,
  pinTo,
  prefix,
  office,
  district,
  state,
  bagCode,
  bagName,
  section,
  remarks,
  category,
  connectivity,
  colour,
  airCode,
  station,
  via,
  l2Hub,
  l1Hub,
  direct,
}

/// Fields offered on the mapping screen for each kind.
const Map<ImportKind, List<ImportField>> kImportFields = {
  ImportKind.bagRules: [
    ImportField.type, ImportField.pin, ImportField.pinFrom, ImportField.pinTo, ImportField.prefix, //
    ImportField.office, ImportField.district, ImportField.state, ImportField.bagCode, ImportField.bagName, //
    ImportField.section, ImportField.remarks, ImportField.category, ImportField.connectivity, ImportField.colour,
  ],
  ImportKind.airCodes: [
    ImportField.type, ImportField.pin, ImportField.pinFrom, ImportField.pinTo, ImportField.prefix, //
    ImportField.district, ImportField.state, ImportField.airCode, ImportField.station, ImportField.via, //
    ImportField.remarks,
  ],
  ImportKind.dmsl: [
    ImportField.type, ImportField.pin, ImportField.pinFrom, ImportField.pinTo, ImportField.prefix, //
    ImportField.office, ImportField.district, ImportField.state, ImportField.l2Hub, ImportField.l1Hub, //
    ImportField.direct, ImportField.connectivity, ImportField.remarks,
  ],
};

/// Header synonyms in English, Kannada and Hindi (compared after lower-casing
/// and removing spaces, dots, underscores, hyphens and brackets).
const Map<ImportField, List<String>> kHeaderSynonyms = {
  ImportField.type: ['type', 'ruletype', 'matchtype', 'ವಿಧ', 'ಪ್ರಕಾರ', 'प्रकार'],
  ImportField.pin: ['pin', 'pincode', 'pinno', 'postalcode', 'ಪಿನ್', 'ಪಿನ್ಕೋಡ್', 'पिन', 'पिनकोड'],
  ImportField.pinFrom: ['pinfrom', 'pincodefrom', 'frompincode', 'rangefrom', 'fromrange', 'from', 'frompin', 'start', 'startpin', 'pinstart', 'ಇಂದ', 'ಪಿನ್ಇಂದ', 'से', 'पिनसे'],
  ImportField.pinTo: ['pinto', 'pincodeto', 'topincode', 'rangeto', 'torange', 'upto', 'to', 'topin', 'end', 'endpin', 'pinend', 'ವರೆಗೆ', 'ಪಿನ್ವರೆಗೆ', 'तक', 'पिनतक'],
  ImportField.prefix: ['prefix', 'pinprefix', 'series', 'pinseries', 'first3digits', 'ಪೂರ್ವಪ್ರತ್ಯಯ', 'ಸರಣಿ', 'उपसर्ग', 'श्रृंखला'],
  ImportField.office: ['office', 'officename', 'postoffice', 'po', 'place', 'destination', 'ಕಚೇರಿ', 'ಅಂಚೆಕಚೇರಿ', 'ಸ್ಥಳ', 'कार्यालय', 'डाकघर', 'स्थान'],
  ImportField.district: ['district', 'districtname', 'dist', 'ಜಿಲ್ಲೆ', 'जिला'],
  ImportField.state: ['state', 'statename', 'ರಾಜ್ಯ', 'राज्य'],
  ImportField.bagCode: ['bag', 'bagno', 'bagnumber', 'bagcode', 'bagnum', 'bagid', 'line', 'linename', 'route', 'beat', 'sortingline', 'ಚೀಲ', 'ಚೀಲಸಂಖ್ಯೆ', 'ಬ್ಯಾಗ್', 'बैग', 'थैला', 'थैलासंख्या', 'बैगनं'],
  ImportField.bagName: ['bagname', 'bagdescription', 'bagtitle', 'closedto', 'ಚೀಲಹೆಸರು', 'ಬ್ಯಾಗ್ಹೆಸರು', 'बैगकानाम', 'थैलेकानाम'],
  ImportField.section: ['section', 'sectionno', 'set', 'ವಿಭಾಗ', 'सेक्शन', 'अनुभाग'],
  ImportField.remarks: ['remarks', 'remark', 'notes', 'note', 'comments', 'ಷರಾ', 'ಟಿಪ್ಪಣಿ', 'टिप्पणी', 'अभ्युक्ति'],
  ImportField.category: ['category', 'mailcategory', 'mailtype', 'ವರ್ಗ', 'श्रेणी'],
  ImportField.connectivity: ['connectivity', 'airsurface', 'mode', 'transmission', 'ಸಂಪರ್ಕ', 'कनेक्टिविटी'],
  ImportField.colour: ['colour', 'color', 'bagcolour', 'bagcolor', 'ಬಣ್ಣ', 'रंग'],
  ImportField.airCode: ['aircode', 'airstationcode', 'code', 'iata', 'airportcode', 'labelcode', 'ವಾಯುಕೋಡ್', 'एयरकोड'],
  ImportField.station: ['station', 'airstation', 'stationname', 'airstationname', 'airport', 'ನಿಲ್ದಾಣ', 'स्टेशन'],
  ImportField.via: ['via', 'viahub', 'hub', 'ಮೂಲಕ', 'होकर', 'मार्ग'],
  ImportField.l2Hub: ['l2hub', 'l2', 'l2nsh', 'level2hub', 'l2parcelhub', 'ಎಲ್2ಹಬ್', 'एल2हब'],
  ImportField.l1Hub: ['l1hub', 'l1', 'l1nsh', 'level1hub', 'l1parcelhub', 'ಎಲ್1ಹಬ್', 'एल1हब'],
  ImportField.direct: ['direct', 'directclosure', 'directtol1', 'direct(y/n)', 'directclosureyn', 'ನೇರ', 'सीधा'],
};

String _norm(String h) => h.toLowerCase().replaceAll(RegExp(r'[\s._\-()/\\:#]'), '');

/// Auto-detects which column holds which field. Exact synonym matches win;
/// then "starts with" matches. Each column is used at most once.
Map<ImportField, int> autoDetectColumns(List<String> header, ImportKind kind) {
  final fields = kImportFields[kind]!;
  final norms = header.map(_norm).toList();
  final out = <ImportField, int>{};
  final used = <int>{};
  // Pass 1: exact matches. Longer synonyms first so "bagname" beats "bag".
  for (final f in fields) {
    for (final s in kHeaderSynonyms[f]!.map(_norm)) {
      final i = norms.indexOf(s);
      if (i >= 0 && !used.contains(i)) {
        out[f] = i;
        used.add(i);
        break;
      }
    }
  }
  // Pass 2: for each unused column, the unmapped field with the longest
  // synonym the header starts with ("Pincode From" → PIN From, "Bag No." → Bag).
  for (var i = 0; i < norms.length; i++) {
    if (used.contains(i) || norms[i].isEmpty) continue;
    ImportField? best;
    var bestLen = 0;
    for (final f in fields) {
      if (out.containsKey(f)) continue;
      for (final s in kHeaderSynonyms[f]!.map(_norm)) {
        final hit = s.length >= 2 && (norms[i].startsWith(s) || (s.length >= 4 && norms[i].contains(s)));
        if (hit && s.length > bestLen) {
          best = f;
          bestLen = s.length;
        }
      }
    }
    if (best != null) {
      out[best] = i;
      used.add(i);
    }
  }
  return out;
}

/// Finds the header row: the first of the first 15 rows with at least two
/// recognised headers.
int detectHeaderRow(List<List<String>> rows, ImportKind kind) {
  var best = 0, bestCount = 0;
  for (var r = 0; r < rows.length && r < 15; r++) {
    final n = autoDetectColumns(rows[r], kind).length;
    if (n > bestCount) {
      best = r;
      bestCount = n;
    }
    if (n >= 2) return r;
  }
  return best;
}

enum IssueKind {
  badPin,
  noBag,
  noMatchKey,
  duplicate,
  conflict,
  overlap,
  nested,
  unknownAirCode,
  noConnectivity,
  treatedAsDefault,
  badColour,
}

class ImportIssue {
  const ImportIssue(this.kind, this.row, this.message, {this.otherRow});

  final IssueKind kind;

  /// 1-based row number in the file (as the user sees it in Excel).
  final int row;
  final int? otherRow;
  final String message;

  /// Errors skip the row; warnings are informational.
  bool get isError => kind == IssueKind.badPin || kind == IssueKind.noBag || kind == IssueKind.noMatchKey;
}

class ParsedRow<T extends Matchable> {
  const ParsedRow(this.row, this.rule);

  final int row;
  final T rule;
}

class ImportResult<T extends Matchable> {
  ImportResult(this.rows, this.issues, {this.bags = const []});

  final List<ParsedRow<T>> rows;
  final List<ImportIssue> issues;

  /// Bags derived from bag rules (code, name, colour).
  final List<Bag> bags;

  List<T> get rules => rows.map((r) => r.rule).toList();
  List<ImportIssue> get errors => issues.where((i) => i.isError).toList();
  List<ImportIssue> get warnings => issues.where((i) => !i.isError).toList();
  int count(IssueKind k) => issues.where((i) => i.kind == k).length;
}

/// Match part parsed from a row.
class _MatchCells {
  _MatchCells(this.spec, this.error, {this.officeName, this.district, this.state, this.implicitDefault = false});

  final MatchSpec? spec;
  final String? error;
  final String? officeName;
  final String? district;
  final String? state;
  final bool implicitDefault;
}

final RegExp _pinRange = RegExp(r'^([1-9]\d{5})\s*(?:-|–|—|to|TO|To|ರಿಂದ|से)\s*([1-9]\d{5})$');
final RegExp _prefixLike = RegExp(r'^([1-9]\d{0,5})\s*(?:[xX*?]+|\.\.\.)?$');
const Set<String> _defaultWords = {'default', 'allother', 'allothers', 'others', 'other', 'rest', '*', 'any', 'ಇತರೆ', 'ಉಳಿದ', 'अन्य', 'बाकी'};

RuleType? _parseType(String s) {
  final v = _norm(s);
  if (v.isEmpty) return null;
  if (v == 'pin' || v == 'exact' || v == 'exactpin' || v == 'ಪಿನ್' || v == 'पिन') return RuleType.exact;
  if (v.startsWith('range') || v == 'ಶ್ರೇಣಿ' || v == 'रेंज') return RuleType.range;
  if (v.startsWith('prefix') || v.startsWith('series')) return RuleType.prefix;
  if (v.startsWith('office') || v.startsWith('place')) return RuleType.office;
  if (v.startsWith('district') || v == 'ಜಿಲ್ಲೆ' || v == 'जिला') return RuleType.district;
  if (v.startsWith('state') || v == 'ರಾಜ್ಯ' || v == 'राज्य') return RuleType.state;
  if (_defaultWords.contains(v) || v.startsWith('default') || v.startsWith('allother')) return RuleType.fallback;
  return null;
}

_MatchCells _parseMatch(String Function(ImportField) cell, {required bool allowOffice}) {
  final type = _parseType(cell(ImportField.type));
  final pinRaw = PinUtils.normalizeDigits(cell(ImportField.pin)).trim();
  final fromRaw = PinUtils.digitsOnly(cell(ImportField.pinFrom));
  final toRaw = PinUtils.digitsOnly(cell(ImportField.pinTo));
  final prefixRaw = PinUtils.normalizeDigits(cell(ImportField.prefix)).trim();
  final office = allowOffice ? cell(ImportField.office) : '';
  final district = cell(ImportField.district);
  final state = cell(ImportField.state);

  MatchSpec? range(String a, String b) {
    if (!PinUtils.isValid(a) || !PinUtils.isValid(b)) return null;
    final x = int.parse(a), y = int.parse(b);
    return x <= y ? MatchSpec.range(x, y) : null;
  }

  MatchSpec? prefix(String raw) {
    final m = _prefixLike.firstMatch(raw.replaceAll(' ', ''));
    if (m == null) return null;
    final p = m[1]!;
    return p.length == 6 ? MatchSpec.exact(int.parse(p)) : MatchSpec.prefix(p);
  }

  bool isDefaultWord(String s) => _defaultWords.contains(_norm(s));

  // Explicit type column wins.
  if (type != null) {
    switch (type) {
      case RuleType.exact:
        final d = PinUtils.digitsOnly(pinRaw);
        return PinUtils.isValid(d)
            ? _MatchCells(MatchSpec.exact(int.parse(d)), null)
            : _MatchCells(null, 'Invalid PIN "$pinRaw"');
      case RuleType.range:
        final a = fromRaw.isNotEmpty ? fromRaw : _pinRange.firstMatch(pinRaw)?[1] ?? '';
        final b = toRaw.isNotEmpty ? toRaw : _pinRange.firstMatch(pinRaw)?[2] ?? '';
        final r = range(a, b);
        return r != null ? _MatchCells(r, null) : _MatchCells(null, 'Invalid PIN range "$a" – "$b"');
      case RuleType.prefix:
        final p = prefix(prefixRaw.isNotEmpty ? prefixRaw : pinRaw);
        return p != null ? _MatchCells(p, null) : _MatchCells(null, 'Invalid prefix "$prefixRaw$pinRaw"');
      case RuleType.office:
        return office.isNotEmpty
            ? _MatchCells(MatchSpec(type: RuleType.office, officeNorm: normalizePlace(office)), null, officeName: office)
            : _MatchCells(null, 'Office rule without office name');
      case RuleType.district:
        return district.isNotEmpty
            ? _MatchCells(MatchSpec(type: RuleType.district, districtNorm: normalizePlace(district)), null, district: district)
            : _MatchCells(null, 'District rule without district');
      case RuleType.state:
        return state.isNotEmpty
            ? _MatchCells(MatchSpec(type: RuleType.state, stateNorm: normalizePlace(state)), null, state: state)
            : _MatchCells(null, 'State rule without state');
      case RuleType.fallback:
        return _MatchCells(const MatchSpec.fallback(), null);
    }
  }

  // Inferred from which cells are filled.
  if (fromRaw.isNotEmpty || toRaw.isNotEmpty) {
    final r = range(fromRaw, toRaw);
    return r != null ? _MatchCells(r, null) : _MatchCells(null, 'Invalid PIN range "$fromRaw" – "$toRaw"');
  }
  // Office names typed into the PIN column ("Sampaje" under "Pincode").
  if (pinRaw.isNotEmpty && !isDefaultWord(pinRaw) && RegExp(r'[A-Za-z\u0C80-\u0CFF\u0900-\u097F]{3}').hasMatch(pinRaw) &&
      allowOffice && !RegExp(r'\d{3}').hasMatch(pinRaw)) {
    return _MatchCells(MatchSpec(type: RuleType.office, officeNorm: normalizePlace(pinRaw)), null, officeName: pinRaw);
  }
  if (pinRaw.isNotEmpty && !isDefaultWord(pinRaw)) {
    final rm = _pinRange.firstMatch(pinRaw);
    if (rm != null) {
      final r = range(rm[1]!, rm[2]!);
      return r != null ? _MatchCells(r, null) : _MatchCells(null, 'Invalid PIN range "$pinRaw"');
    }
    final compact = pinRaw.replaceAll(RegExp(r'[\s\-]'), '');
    if (PinUtils.isValid(compact)) return _MatchCells(MatchSpec.exact(int.parse(compact)), null);
    final p = prefix(compact);
    if (p != null) return _MatchCells(p, null);
    return _MatchCells(null, 'Invalid PIN "$pinRaw"');
  }
  if (prefixRaw.isNotEmpty && !isDefaultWord(prefixRaw)) {
    final p = prefix(prefixRaw);
    return p != null ? _MatchCells(p, null) : _MatchCells(null, 'Invalid prefix "$prefixRaw"');
  }
  if (office.isNotEmpty && !isDefaultWord(office)) {
    return _MatchCells(MatchSpec(type: RuleType.office, officeNorm: normalizePlace(office)), null, officeName: office);
  }
  if (district.isNotEmpty && !isDefaultWord(district)) {
    return _MatchCells(MatchSpec(type: RuleType.district, districtNorm: normalizePlace(district)), null, district: district);
  }
  if (state.isNotEmpty && !isDefaultWord(state)) {
    return _MatchCells(MatchSpec(type: RuleType.state, stateNorm: normalizePlace(state)), null, state: state);
  }
  final explicitDefault = [pinRaw, prefixRaw, office, district, state].any(isDefaultWord);
  return _MatchCells(const MatchSpec.fallback(), null, implicitDefault: !explicitDefault);
}

bool _parseYes(String s) {
  final v = _norm(s);
  return v == 'y' || v == 'yes' || v == 'true' || v == '1' || v == 'direct' || v == 'ಹೌದು' || v == 'हाँ' || v == 'हां';
}

/// Parses the data rows below [headerRow] using [mapping].
ImportResult<T> parseRows<T extends Matchable>({
  required List<List<String>> rows,
  required int headerRow,
  required Map<ImportField, int> mapping,
  required ImportKind kind,
}) {
  final parsed = <ParsedRow<Matchable>>[];
  final issues = <ImportIssue>[];
  final bags = <String, Bag>{};

  for (var r = headerRow + 1; r < rows.length; r++) {
    final row = rows[r];
    final rowNo = r + 1;
    if (row.every((c) => c.trim().isEmpty)) continue;
    String cell(ImportField f) {
      final i = mapping[f];
      return i == null || i >= row.length ? '' : row[i].trim();
    }

    final m = _parseMatch(cell, allowOffice: kind != ImportKind.airCodes);
    if (m.spec == null) {
      issues.add(ImportIssue(IssueKind.badPin, rowNo, m.error!));
      continue;
    }
    final spec = m.spec!;
    switch (kind) {
      case ImportKind.bagRules:
        var code = cell(ImportField.bagCode);
        final name = cell(ImportField.bagName);
        if (code.isEmpty && name.isEmpty) {
          issues.add(ImportIssue(IssueKind.noBag, rowNo, 'Row has no bag'));
          continue;
        }
        if (code.isEmpty) code = name;
        final conn = Connectivity.parse(cell(ImportField.connectivity));
        final category = cell(ImportField.category);
        final colourRaw = cell(ImportField.colour);
        final colour = parseColour(colourRaw);
        if (colourRaw.isNotEmpty && colour == null) {
          issues.add(ImportIssue(IssueKind.badColour, rowNo, 'Unknown colour "$colourRaw"'));
        }
        final existing = bags[code];
        bags[code] = Bag(
          code: code,
          name: existing?.name.isNotEmpty == true ? existing!.name : (name == code ? '' : name),
          colour: existing?.colour ?? (colour == null ? null : '#${(colour.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}'),
          order: existing?.order ?? bags.length,
        );
        if (m.implicitDefault) {
          issues.add(ImportIssue(IssueKind.treatedAsDefault, rowNo, 'No PIN/office/district: treated as "All other"'));
        }
        parsed.add(ParsedRow(
          rowNo,
          BagRule(
            match: spec,
            officeName: m.officeName,
            district: m.district,
            state: m.state,
            bagCode: code,
            bagName: name == code ? '' : name,
            section: cell(ImportField.section),
            remarks: cell(ImportField.remarks),
            category: category.isEmpty ? null : category,
            connectivity: conn,
          ),
        ));
      case ImportKind.airCodes:
        final code = cell(ImportField.airCode).toUpperCase();
        if (code.isEmpty) {
          issues.add(ImportIssue(IssueKind.noBag, rowNo, 'Row has no air code'));
          continue;
        }
        if (!isKnownAirportCode(code)) {
          issues.add(ImportIssue(IssueKind.unknownAirCode, rowNo, 'Air code "$code" is not in the airport code list (kept)'));
        }
        if (m.implicitDefault) {
          issues.add(ImportIssue(IssueKind.treatedAsDefault, rowNo, 'No PIN/district/state: treated as "All other"'));
        }
        parsed.add(ParsedRow(
          rowNo,
          AirCodeRule(
            match: spec,
            district: m.district,
            state: m.state,
            airCode: code,
            stationName: cell(ImportField.station),
            viaHub: cell(ImportField.via),
            remarks: cell(ImportField.remarks),
          ),
        ));
      case ImportKind.dmsl:
        final l2 = cell(ImportField.l2Hub);
        final l1 = cell(ImportField.l1Hub);
        if (l2.isEmpty && l1.isEmpty) {
          issues.add(ImportIssue(IssueKind.noBag, rowNo, 'Row has no L2 / L1 hub'));
          continue;
        }
        final conn = Connectivity.parse(cell(ImportField.connectivity));
        if (conn == null) {
          issues.add(ImportIssue(IssueKind.noConnectivity, rowNo, 'Connectivity blank: treated as Surface'));
        }
        final direct = _parseYes(cell(ImportField.direct)) || (l2.isEmpty && l1.isNotEmpty);
        parsed.add(ParsedRow(
          rowNo,
          HubRule(
            match: spec,
            officeName: m.officeName,
            district: m.district,
            state: m.state,
            l2Hub: l2,
            l1Hub: l1,
            directClosure: direct,
            connectivity: conn,
            remarks: cell(ImportField.remarks),
          ),
        ));
    }
  }
  issues.addAll(validateRules(parsed));
  issues.sort((a, b) => a.row.compareTo(b.row));
  return ImportResult<T>(
    parsed.map((p) => ParsedRow<T>(p.row, p.rule as T)).toList(),
    issues,
    bags: bags.values.toList(),
  );
}

/// Target of a rule, for duplicate/conflict/overlap detection.
String _target(Matchable r) => switch (r) {
  BagRule b => b.bagCode,
  AirCodeRule a => a.airCode,
  HubRule h => h.routeKey,
  _ => '',
};

/// Duplicate / conflicting rules and overlapping ranges.
List<ImportIssue> validateRules(List<ParsedRow<Matchable>> rows) {
  final issues = <ImportIssue>[];
  final byKey = <String, ParsedRow<Matchable>>{};
  for (final p in rows) {
    final k = '${p.rule.match.key}|${p.rule.category ?? ''}';
    final prev = byKey[k];
    if (prev == null) {
      byKey[k] = p;
    } else if (_target(prev.rule) == _target(p.rule)) {
      issues.add(ImportIssue(IssueKind.duplicate, p.row, 'Duplicate of row ${prev.row}', otherRow: prev.row));
    } else {
      issues.add(ImportIssue(
        IssueKind.conflict,
        p.row,
        'Same ${p.rule.match.describe()} as row ${prev.row} but a different result (row ${prev.row} wins)',
        otherRow: prev.row,
      ));
    }
  }
  final ranges = rows.where((p) => p.rule.match.type == RuleType.range).toList()
    ..sort((a, b) => a.rule.match.pinFrom!.compareTo(b.rule.match.pinFrom!));
  for (var i = 0; i < ranges.length; i++) {
    final a = ranges[i].rule.match;
    for (var j = i + 1; j < ranges.length; j++) {
      final b = ranges[j].rule.match;
      if (b.pinFrom! > a.pinTo!) break;
      if ((ranges[i].rule.category ?? '') != (ranges[j].rule.category ?? '')) continue;
      if (a.pinFrom == b.pinFrom && a.pinTo == b.pinTo) continue; // reported as duplicate/conflict
      if (_target(ranges[i].rule) == _target(ranges[j].rule)) continue;
      final nested = (b.pinFrom! >= a.pinFrom! && b.pinTo! <= a.pinTo!) || (a.pinFrom! >= b.pinFrom! && a.pinTo! <= b.pinTo!);
      final later = ranges[i].row > ranges[j].row ? ranges[i] : ranges[j];
      final earlier = identical(later, ranges[i]) ? ranges[j] : ranges[i];
      issues.add(ImportIssue(
        nested ? IssueKind.nested : IssueKind.overlap,
        later.row,
        nested
            ? 'Range ${later.rule.match.describe()} is inside row ${earlier.row} (${earlier.rule.match.describe()}); the smaller range wins'
            : 'Range ${later.rule.match.describe()} overlaps row ${earlier.row} (${earlier.rule.match.describe()})',
        otherRow: earlier.row,
      ));
    }
  }
  return issues;
}

/// Bags referenced by [rules] that are missing from [bags] are added with
/// palette colours.
List<Bag> completeBags(List<BagRule> rules, List<Bag> bags, List<String> palette) {
  final out = {for (final b in bags) b.code: b};
  for (final r in rules) {
    out.putIfAbsent(r.bagCode, () => Bag(code: r.bagCode, name: r.bagName, order: out.length));
  }
  var i = 0;
  return out.values.map((b) => b.colour != null ? b : b.copyWith(colour: palette[i++ % palette.length])).toList()
    ..sort((a, b) => a.order.compareTo(b.order));
}
