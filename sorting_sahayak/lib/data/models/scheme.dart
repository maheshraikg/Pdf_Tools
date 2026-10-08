/// Sorting scheme data model: bag rules, bags, air codes and DMSL hub rules.
library;

enum RuleType {
  exact('pin'),
  range('range'),
  prefix('prefix'),
  office('office'),
  district('district'),
  state('state'),
  fallback('default');

  const RuleType(this.db);

  /// Stored value in the database / export files.
  final String db;

  static RuleType fromDb(String? s) => RuleType.values.firstWhere((t) => t.db == s, orElse: () => RuleType.fallback);
}

/// The "which articles does this rule match" part shared by every rule kind.
class MatchSpec {
  const MatchSpec({
    required this.type,
    this.pin,
    this.pinFrom,
    this.pinTo,
    this.prefix,
    this.officeNorm,
    this.districtNorm,
    this.stateNorm,
  });

  const MatchSpec.exact(int this.pin)
    : type = RuleType.exact,
      pinFrom = null,
      pinTo = null,
      prefix = null,
      officeNorm = null,
      districtNorm = null,
      stateNorm = null;

  const MatchSpec.range(int this.pinFrom, int this.pinTo)
    : type = RuleType.range,
      pin = null,
      prefix = null,
      officeNorm = null,
      districtNorm = null,
      stateNorm = null;

  const MatchSpec.prefix(String this.prefix)
    : type = RuleType.prefix,
      pin = null,
      pinFrom = null,
      pinTo = null,
      officeNorm = null,
      districtNorm = null,
      stateNorm = null;

  const MatchSpec.fallback()
    : type = RuleType.fallback,
      pin = null,
      pinFrom = null,
      pinTo = null,
      prefix = null,
      officeNorm = null,
      districtNorm = null,
      stateNorm = null;

  final RuleType type;
  final int? pin;
  final int? pinFrom;
  final int? pinTo;
  final String? prefix;
  final String? officeNorm;
  final String? districtNorm;
  final String? stateNorm;

  /// Identity of what is matched (for duplicate detection).
  String get key => switch (type) {
    RuleType.exact => 'pin:$pin',
    RuleType.range => 'range:$pinFrom-$pinTo',
    RuleType.prefix => 'prefix:$prefix',
    RuleType.office => 'office:$officeNorm',
    RuleType.district => 'district:$districtNorm',
    RuleType.state => 'state:$stateNorm',
    RuleType.fallback => 'default',
  };

  /// Human-readable description, e.g. "574201–574299" or "575xxx".
  String describe({String? officeName, String? district, String? state}) => switch (type) {
    RuleType.exact => '$pin',
    RuleType.range => '$pinFrom–$pinTo',
    RuleType.prefix => '$prefix${'x' * (6 - (prefix?.length ?? 0))}',
    RuleType.office => officeName ?? officeNorm ?? '',
    RuleType.district => district ?? districtNorm ?? '',
    RuleType.state => state ?? stateNorm ?? '',
    RuleType.fallback => '*',
  };

  bool matchesPin(int p) => switch (type) {
    RuleType.exact => pin == p,
    RuleType.range => pinFrom! <= p && p <= pinTo!,
    RuleType.prefix => '$p'.startsWith(prefix!),
    _ => false,
  };

  Map<String, Object?> toRow() => {
    'pin': pin,
    'pin_from': pinFrom,
    'pin_to': pinTo,
    'prefix': prefix,
    'office_name_norm': officeNorm,
    'district_norm': districtNorm,
    'state_norm': stateNorm,
  };

  static MatchSpec fromRow(Map<String, Object?> r, String typeColumn) => MatchSpec(
    type: RuleType.fromDb(r[typeColumn] as String?),
    pin: r['pin'] as int?,
    pinFrom: r['pin_from'] as int?,
    pinTo: r['pin_to'] as int?,
    prefix: r['prefix'] as String?,
    officeNorm: r['office_name_norm'] as String?,
    districtNorm: r['district_norm'] as String?,
    stateNorm: r['state_norm'] as String?,
  );
}

/// Anything the priority resolver can pick.
abstract class Matchable {
  MatchSpec get match;

  /// Mail category this rule is limited to; null/empty = all categories.
  String? get category;
}

enum Connectivity {
  air('Air'),
  surface('Surface');

  const Connectivity(this.label);

  final String label;

  static Connectivity? parse(String? s) {
    final v = (s ?? '').trim().toLowerCase();
    if (v.isEmpty) return null;
    if (v.startsWith('a') || v.contains('ವಾಯು') || v.contains('हवाई')) return Connectivity.air;
    if (v.startsWith('s') || v.startsWith('r') || v.contains('ಭೂ') || v.contains('सतह')) return Connectivity.surface;
    return null;
  }
}

class Scheme {
  const Scheme({
    this.id,
    required this.name,
    this.office = '',
    this.notes = '',
    this.importedAt,
    this.active = false,
    this.isSample = false,
  });

  final int? id;
  final String name;
  final String office;
  final String notes;
  final DateTime? importedAt;
  final bool active;
  final bool isSample;

  factory Scheme.fromRow(Map<String, Object?> r) => Scheme(
    id: r['id'] as int,
    name: r['name'] as String,
    office: r['office'] as String? ?? '',
    notes: r['notes'] as String? ?? '',
    importedAt: DateTime.tryParse(r['imported_at'] as String? ?? ''),
    active: (r['active'] as int? ?? 0) == 1,
    isSample: (r['is_sample'] as int? ?? 0) == 1,
  );

  Map<String, Object?> toRow() => {
    'name': name,
    'office': office,
    'notes': notes,
    'imported_at': (importedAt ?? DateTime.now()).toIso8601String(),
    'active': active ? 1 : 0,
    'is_sample': isSample ? 1 : 0,
  };
}

class Bag {
  const Bag({required this.code, this.name = '', this.colour, this.order = 0});

  final String code;
  final String name;

  /// "#RRGGBB" or null.
  final String? colour;
  final int order;

  String get label => name.isEmpty || name == code ? code : '$code – $name';

  Bag copyWith({String? name, String? colour, int? order}) =>
      Bag(code: code, name: name ?? this.name, colour: colour ?? this.colour, order: order ?? this.order);

  factory Bag.fromRow(Map<String, Object?> r) => Bag(
    code: r['bag_code'] as String,
    name: r['bag_name'] as String? ?? '',
    colour: r['colour'] as String?,
    order: r['sort_order'] as int? ?? 0,
  );
}

class BagRule implements Matchable {
  const BagRule({
    this.id,
    required this.match,
    this.officeName,
    this.district,
    this.state,
    required this.bagCode,
    this.bagName = '',
    this.section = '',
    this.remarks = '',
    this.category,
    this.connectivity,
  });

  final int? id;
  @override
  final MatchSpec match;
  final String? officeName;
  final String? district;
  final String? state;
  final String bagCode;
  final String bagName;
  final String section;
  final String remarks;
  @override
  final String? category;
  final Connectivity? connectivity;

  String get describe => match.describe(officeName: officeName, district: district, state: state);

  Map<String, Object?> toRow(int schemeId) => {
    'scheme_id': schemeId,
    'type': match.type.db,
    ...match.toRow(),
    'office_name': officeName,
    'district': district,
    'state': state,
    'bag_code': bagCode,
    'bag_name': bagName,
    'section': section,
    'remarks': remarks,
    'category': category,
    'connectivity': connectivity?.label,
  };

  factory BagRule.fromRow(Map<String, Object?> r) => BagRule(
    id: r['id'] as int?,
    match: MatchSpec.fromRow(r, 'type'),
    officeName: r['office_name'] as String?,
    district: r['district'] as String?,
    state: r['state'] as String?,
    bagCode: r['bag_code'] as String? ?? '',
    bagName: r['bag_name'] as String? ?? '',
    section: r['section'] as String? ?? '',
    remarks: r['remarks'] as String? ?? '',
    category: _blankToNull(r['category'] as String?),
    connectivity: Connectivity.parse(r['connectivity'] as String?),
  );
}

class AirCodeRule implements Matchable {
  const AirCodeRule({
    this.id,
    required this.match,
    this.district,
    this.state,
    required this.airCode,
    this.stationName = '',
    this.viaHub = '',
    this.remarks = '',
  });

  final int? id;
  @override
  final MatchSpec match;
  final String? district;
  final String? state;
  final String airCode;
  final String stationName;
  final String viaHub;
  final String remarks;

  @override
  String? get category => null;

  String get describe => match.describe(district: district, state: state);

  Map<String, Object?> toRow(int schemeId) {
    final m = match.toRow()..remove('office_name_norm');
    return {
      'scheme_id': schemeId,
      'rule_type': match.type.db,
      ...m,
      'district': district,
      'state': state,
      'air_code': airCode,
      'air_station_name': stationName,
      'via_hub': viaHub,
      'remarks': remarks,
    };
  }

  factory AirCodeRule.fromRow(Map<String, Object?> r) => AirCodeRule(
    id: r['id'] as int?,
    match: MatchSpec.fromRow(r, 'rule_type'),
    district: r['district'] as String?,
    state: r['state'] as String?,
    airCode: r['air_code'] as String? ?? '',
    stationName: r['air_station_name'] as String? ?? '',
    viaHub: r['via_hub'] as String? ?? '',
    remarks: r['remarks'] as String? ?? '',
  );
}

class HubRule implements Matchable {
  const HubRule({
    this.id,
    required this.match,
    this.officeName,
    this.district,
    this.state,
    this.l2Hub = '',
    this.l1Hub = '',
    this.directClosure = false,
    this.connectivity,
    this.remarks = '',
  });

  final int? id;
  @override
  final MatchSpec match;
  final String? officeName;
  final String? district;
  final String? state;
  final String l2Hub;
  final String l1Hub;

  /// Y = bag closed directly to the L1 hub (skips L2).
  final bool directClosure;
  final Connectivity? connectivity;
  final String remarks;

  @override
  String? get category => null;

  String get describe => match.describe(officeName: officeName, district: district, state: state);

  /// Comparable route string for diffs.
  String get route => directClosure ? '→ $l1Hub (direct)' : '$l2Hub → $l1Hub';

  String get routeKey => '${directClosure ? 'D' : ''}|$l2Hub|$l1Hub|${connectivity?.label ?? ''}';

  Map<String, Object?> toRow(int versionId) => {
    'version_id': versionId,
    'rule_type': match.type.db,
    ...match.toRow(),
    'office_name': officeName,
    'district': district,
    'state': state,
    'l2_hub': l2Hub,
    'l1_hub': l1Hub,
    'direct_closure': directClosure ? 1 : 0,
    'connectivity': connectivity?.label,
    'remarks': remarks,
  };

  factory HubRule.fromRow(Map<String, Object?> r) => HubRule(
    id: r['id'] as int?,
    match: MatchSpec.fromRow(r, 'rule_type'),
    officeName: r['office_name'] as String?,
    district: r['district'] as String?,
    state: r['state'] as String?,
    l2Hub: r['l2_hub'] as String? ?? '',
    l1Hub: r['l1_hub'] as String? ?? '',
    directClosure: (r['direct_closure'] as int? ?? 0) == 1,
    connectivity: Connectivity.parse(r['connectivity'] as String?),
    remarks: r['remarks'] as String? ?? '',
  );
}

class DmslVersion {
  const DmslVersion({
    this.id,
    required this.schemeId,
    required this.versionName,
    this.validFrom,
    this.importedAt,
    this.active = false,
  });

  final int? id;
  final int schemeId;
  final String versionName;
  final DateTime? validFrom;
  final DateTime? importedAt;
  final bool active;

  factory DmslVersion.fromRow(Map<String, Object?> r) => DmslVersion(
    id: r['id'] as int,
    schemeId: r['scheme_id'] as int,
    versionName: r['version_name'] as String,
    validFrom: DateTime.tryParse(r['valid_from'] as String? ?? ''),
    importedAt: DateTime.tryParse(r['imported_at'] as String? ?? ''),
    active: (r['active'] as int? ?? 0) == 1,
  );
}

String? _blankToNull(String? s) => s == null || s.trim().isEmpty ? null : s.trim();
