import '../core/article_number.dart';
import '../core/fuzzy.dart';
import '../core/geo.dart';

int _now() => DateTime.now().millisecondsSinceEpoch;

class Beat {
  Beat({this.id, required this.name, this.office = '', this.notes = '', int? createdAt})
    : createdAt = createdAt ?? _now();
  final int? id;
  final String name;
  final String office;
  final String notes;
  final int createdAt;

  Map<String, Object?> toMap() => {'id': id, 'name': name, 'office': office, 'notes': notes, 'created_at': createdAt};

  factory Beat.fromMap(Map<String, Object?> m) => Beat(
    id: m['id'] as int?,
    name: m['name'] as String? ?? '',
    office: m['office'] as String? ?? '',
    notes: m['notes'] as String? ?? '',
    createdAt: m['created_at'] as int? ?? 0,
  );

  Beat copyWith({String? name, String? office, String? notes}) => Beat(
    id: id,
    name: name ?? this.name,
    office: office ?? this.office,
    notes: notes ?? this.notes,
    createdAt: createdAt,
  );
}

class Street {
  Street({
    this.id,
    required this.beatId,
    required this.name,
    this.area = '',
    this.crossMainNote = '',
    this.orderIndex = 0,
  });
  final int? id;
  final int beatId;
  final String name;
  final String area;
  final String crossMainNote;
  final int orderIndex;

  Map<String, Object?> toMap() => {
    'id': id,
    'beat_id': beatId,
    'name': name,
    'name_norm': normalizeCompact(name),
    'area': area,
    'cross_main_note': crossMainNote,
    'order_index': orderIndex,
  };

  factory Street.fromMap(Map<String, Object?> m) => Street(
    id: m['id'] as int?,
    beatId: m['beat_id'] as int,
    name: m['name'] as String? ?? '',
    area: m['area'] as String? ?? '',
    crossMainNote: m['cross_main_note'] as String? ?? '',
    orderIndex: m['order_index'] as int? ?? 0,
  );

  Street copyWith({String? name, String? area, String? crossMainNote, int? orderIndex}) => Street(
    id: id,
    beatId: beatId,
    name: name ?? this.name,
    area: area ?? this.area,
    crossMainNote: crossMainNote ?? this.crossMainNote,
    orderIndex: orderIndex ?? this.orderIndex,
  );
}

enum PlaceType { house, shop, office, apartment, other }

PlaceType placeTypeFromCode(String? c) =>
    PlaceType.values.firstWhere((t) => t.name == c, orElse: () => PlaceType.house);

class Place {
  Place({
    this.id,
    required this.beatId,
    this.streetId,
    this.doorNo = '',
    this.building = '',
    this.floorFlat = '',
    this.area = '',
    this.pin = '',
    this.landmark = '',
    this.lat,
    this.lng,
    this.gpsAccuracyM,
    this.type = PlaceType.house,
    this.notes = '',
    this.deliveryPref = '',
    this.walkOrder,
    int? createdAt,
    int? updatedAt,
  }) : createdAt = createdAt ?? _now(),
       updatedAt = updatedAt ?? _now();

  final int? id;
  final int beatId;
  final int? streetId;
  final String doorNo;
  final String building;
  final String floorFlat;
  final String area;
  final String pin;
  final String landmark;
  final double? lat;
  final double? lng;
  final double? gpsAccuracyM;
  final PlaceType type;
  final String notes;
  final String deliveryPref;

  /// Remembered manual order inside its street (route planning).
  final int? walkOrder;
  final int createdAt;
  final int updatedAt;

  GeoPoint? get point => (lat != null && lng != null) ? GeoPoint(lat!, lng!) : null;

  Map<String, Object?> toMap() => {
    'id': id,
    'beat_id': beatId,
    'street_id': streetId,
    'door_no': doorNo,
    'door_no_norm': normalizeDoorNo(doorNo),
    'building': building,
    'floor_flat': floorFlat,
    'area': area,
    'pin': pin,
    'landmark': landmark,
    'lat': lat,
    'lng': lng,
    'gps_accuracy_m': gpsAccuracyM,
    'type': type.name,
    'notes': notes,
    'delivery_pref': deliveryPref,
    'walk_order': walkOrder,
    'created_at': createdAt,
    'updated_at': updatedAt,
  };

  factory Place.fromMap(Map<String, Object?> m) => Place(
    id: m['id'] as int?,
    beatId: m['beat_id'] as int,
    streetId: m['street_id'] as int?,
    doorNo: m['door_no'] as String? ?? '',
    building: m['building'] as String? ?? '',
    floorFlat: m['floor_flat'] as String? ?? '',
    area: m['area'] as String? ?? '',
    pin: m['pin'] as String? ?? '',
    landmark: m['landmark'] as String? ?? '',
    lat: (m['lat'] as num?)?.toDouble(),
    lng: (m['lng'] as num?)?.toDouble(),
    gpsAccuracyM: (m['gps_accuracy_m'] as num?)?.toDouble(),
    type: placeTypeFromCode(m['type'] as String?),
    notes: m['notes'] as String? ?? '',
    deliveryPref: m['delivery_pref'] as String? ?? '',
    walkOrder: m['walk_order'] as int?,
    createdAt: m['created_at'] as int? ?? 0,
    updatedAt: m['updated_at'] as int? ?? 0,
  );

  Place copyWith({
    int? streetId,
    bool clearStreet = false,
    String? doorNo,
    String? building,
    String? floorFlat,
    String? area,
    String? pin,
    String? landmark,
    double? lat,
    double? lng,
    double? gpsAccuracyM,
    PlaceType? type,
    String? notes,
    String? deliveryPref,
    int? walkOrder,
  }) => Place(
    id: id,
    beatId: beatId,
    streetId: clearStreet ? null : (streetId ?? this.streetId),
    doorNo: doorNo ?? this.doorNo,
    building: building ?? this.building,
    floorFlat: floorFlat ?? this.floorFlat,
    area: area ?? this.area,
    pin: pin ?? this.pin,
    landmark: landmark ?? this.landmark,
    lat: lat ?? this.lat,
    lng: lng ?? this.lng,
    gpsAccuracyM: gpsAccuracyM ?? this.gpsAccuracyM,
    type: type ?? this.type,
    notes: notes ?? this.notes,
    deliveryPref: deliveryPref ?? this.deliveryPref,
    walkOrder: walkOrder ?? this.walkOrder,
    createdAt: createdAt,
    updatedAt: _now(),
  );
}

class PlacePhoto {
  PlacePhoto({this.id, required this.placeId, required this.filePath, int? createdAt})
    : createdAt = createdAt ?? _now();
  final int? id;
  final int placeId;

  /// File name inside the app-private encrypted photo folder.
  final String filePath;
  final int createdAt;

  Map<String, Object?> toMap() => {'id': id, 'place_id': placeId, 'file_path': filePath, 'created_at': createdAt};

  factory PlacePhoto.fromMap(Map<String, Object?> m) => PlacePhoto(
    id: m['id'] as int?,
    placeId: m['place_id'] as int,
    filePath: m['file_path'] as String,
    createdAt: m['created_at'] as int? ?? 0,
  );
}

class Addressee {
  Addressee({this.id, required this.placeId, required this.name, this.aliases = '', this.phone = '', this.note = ''});
  final int? id;
  final int placeId;
  final String name;

  /// Comma separated other spellings / names.
  final String aliases;
  final String phone;
  final String note;

  Map<String, Object?> toMap() => {
    'id': id,
    'place_id': placeId,
    'name': name,
    'name_norm': '${normalizeText(name)} ${normalizeText(aliases)}'.trim(),
    'aliases': aliases,
    'phone_optional': phone,
    'note': note,
  };

  factory Addressee.fromMap(Map<String, Object?> m) => Addressee(
    id: m['id'] as int?,
    placeId: m['place_id'] as int,
    name: m['name'] as String? ?? '',
    aliases: m['aliases'] as String? ?? '',
    phone: m['phone_optional'] as String? ?? '',
    note: m['note'] as String? ?? '',
  );

  Addressee copyWith({int? placeId, String? name, String? aliases, String? phone, String? note}) => Addressee(
    id: id,
    placeId: placeId ?? this.placeId,
    name: name ?? this.name,
    aliases: aliases ?? this.aliases,
    phone: phone ?? this.phone,
    note: note ?? this.note,
  );
}

enum ArticleStatus { pending, delivered, notDelivered }

ArticleStatus articleStatusFromCode(String? c) => switch (c) {
  'delivered' => ArticleStatus.delivered,
  'not_delivered' => ArticleStatus.notDelivered,
  _ => ArticleStatus.pending,
};

String articleStatusCode(ArticleStatus s) => switch (s) {
  ArticleStatus.delivered => 'delivered',
  ArticleStatus.notDelivered => 'not_delivered',
  ArticleStatus.pending => 'pending',
};

/// Reasons for "not delivered" (codes are stored; labels are localised).
enum NotDeliveredReason { doorLocked, addresseeAbsent, leftShifted, refused, wrongAddress, unclaimed, other }

NotDeliveredReason? reasonFromCode(String? c) {
  for (final r in NotDeliveredReason.values) {
    if (r.name == c) return r;
  }
  return null;
}

class Article {
  Article({
    this.id,
    required this.date,
    this.articleNo = '',
    this.type = ArticleType.letter,
    this.rawAddress = '',
    this.placeId,
    this.status = ArticleStatus.pending,
    this.reason,
    this.attempts = 0,
    this.deliveredAt,
    this.lat,
    this.lng,
    this.note = '',
    this.carriedFrom,
  });

  final int? id;

  /// Day key "yyyy-MM-dd".
  final String date;
  final String articleNo;
  final ArticleType type;
  final String rawAddress;
  final int? placeId;
  final ArticleStatus status;
  final String? reason;
  final int attempts;

  /// Time of the last delivery action (delivered / not delivered).
  final int? deliveredAt;
  final double? lat;
  final double? lng;
  final String note;

  /// Original date when this is a re-attempt carried forward.
  final String? carriedFrom;

  Map<String, Object?> toMap() => {
    'id': id,
    'date': date,
    'article_no': articleNo,
    'type': type.name,
    'raw_address': rawAddress,
    'place_id': placeId,
    'status': articleStatusCode(status),
    'reason': reason,
    'attempts': attempts,
    'delivered_at': deliveredAt,
    'lat': lat,
    'lng': lng,
    'note': note,
    'carried_from': carriedFrom,
  };

  factory Article.fromMap(Map<String, Object?> m) => Article(
    id: m['id'] as int?,
    date: m['date'] as String,
    articleNo: m['article_no'] as String? ?? '',
    type: ArticleTypeX.fromCode(m['type'] as String?),
    rawAddress: m['raw_address'] as String? ?? '',
    placeId: m['place_id'] as int?,
    status: articleStatusFromCode(m['status'] as String?),
    reason: m['reason'] as String?,
    attempts: m['attempts'] as int? ?? 0,
    deliveredAt: m['delivered_at'] as int?,
    lat: (m['lat'] as num?)?.toDouble(),
    lng: (m['lng'] as num?)?.toDouble(),
    note: m['note'] as String? ?? '',
    carriedFrom: m['carried_from'] as String?,
  );

  Article copyWith({
    String? date,
    String? articleNo,
    ArticleType? type,
    String? rawAddress,
    int? placeId,
    bool clearPlace = false,
    ArticleStatus? status,
    String? reason,
    bool clearReason = false,
    int? attempts,
    int? deliveredAt,
    double? lat,
    double? lng,
    String? note,
  }) => Article(
    id: id,
    date: date ?? this.date,
    articleNo: articleNo ?? this.articleNo,
    type: type ?? this.type,
    rawAddress: rawAddress ?? this.rawAddress,
    placeId: clearPlace ? null : (placeId ?? this.placeId),
    status: status ?? this.status,
    reason: clearReason ? null : (reason ?? this.reason),
    attempts: attempts ?? this.attempts,
    deliveredAt: deliveredAt ?? this.deliveredAt,
    lat: lat ?? this.lat,
    lng: lng ?? this.lng,
    note: note ?? this.note,
    carriedFrom: carriedFrom,
  );
}

class AreaNote {
  AreaNote({this.id, required this.beatId, required this.title, this.text = ''});
  final int? id;
  final int beatId;
  final String title;
  final String text;

  Map<String, Object?> toMap() => {'id': id, 'beat_id': beatId, 'title': title, 'text': text};

  factory AreaNote.fromMap(Map<String, Object?> m) => AreaNote(
    id: m['id'] as int?,
    beatId: m['beat_id'] as int,
    title: m['title'] as String? ?? '',
    text: m['text'] as String? ?? '',
  );
}

/// A place with everything a card needs.
class PlaceDetails {
  PlaceDetails({required this.place, this.street, this.addressees = const [], this.photos = const []});
  final Place place;
  final Street? street;
  final List<Addressee> addressees;
  final List<PlacePhoto> photos;

  String get streetName => street?.name ?? '';

  /// "12/3, 4th Cross" style title.
  String get title {
    final parts = <String>[
      if (place.doorNo.isNotEmpty) place.doorNo,
      if (place.building.isNotEmpty) place.building,
      if (streetName.isNotEmpty) streetName,
    ];
    return parts.isEmpty ? '#${place.id}' : parts.join(', ');
  }
}

/// Day key "yyyy-MM-dd" for [d] (local time).
String dayKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
