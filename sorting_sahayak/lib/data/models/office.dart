/// One post office row from the PIN directory.
class Office {
  const Office({
    this.id,
    required this.pincode,
    required this.officeName,
    this.officeType = '',
    this.delivery = true,
    this.division = '',
    this.region = '',
    this.circle = '',
    this.district = '',
    this.state = '',
    this.taluk = '',
    this.latitude,
    this.longitude,
  });

  final int? id;
  final int pincode;
  final String officeName;

  /// HO, SO, BO, PO (or '' when unknown).
  final String officeType;
  final bool delivery;
  final String division;
  final String region;
  final String circle;
  final String district;
  final String state;
  final String taluk;
  final double? latitude;
  final double? longitude;

  String get pin => pincode.toString();

  factory Office.fromRow(Map<String, Object?> r) => Office(
    id: r['id'] as int?,
    pincode: r['pincode'] as int,
    officeName: r['office_name'] as String? ?? '',
    officeType: r['office_type'] as String? ?? '',
    delivery: (r['delivery'] as String? ?? 'Delivery') == 'Delivery',
    division: r['division'] as String? ?? '',
    region: r['region'] as String? ?? '',
    circle: r['circle'] as String? ?? '',
    district: r['district'] as String? ?? '',
    state: r['state'] as String? ?? '',
    taluk: r['taluk'] as String? ?? '',
    latitude: (r['latitude'] as num?)?.toDouble(),
    longitude: (r['longitude'] as num?)?.toDouble(),
  );

  @override
  String toString() => '$officeName $officeType $pincode ($district, $state)';
}

class DirectoryMeta {
  const DirectoryMeta(this.values);

  final Map<String, String> values;

  String get source => values['source'] ?? '';
  String get fileDate => values['file_date'] ?? '';
  int get rowCount => int.tryParse(values['row_count'] ?? '') ?? 0;
  String get builtAt => values['built_at'] ?? '';
  String get stateFilter => values['state_filter'] ?? '';
  bool get hasFts => values['fts'] == '1';
}
