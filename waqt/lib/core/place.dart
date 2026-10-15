/// Places: a preset list (Kerala first) plus GPS / manual entries.
library;

import 'prayer_calc.dart';

class Place {
  const Place({
    required this.id,
    required this.name,
    this.nameMl,
    required this.latitude,
    required this.longitude,
    this.elevation = 0,
    this.utcOffsetMinutes,
    this.region = '',
    this.methodId = 'kerala',
    this.asr = AsrMethod.shafii,
  });

  final String id;
  final String name;
  final String? nameMl;
  final double latitude;
  final double longitude;
  final double elevation;

  /// Fixed UTC offset of the place, or null to use the phone's time zone
  /// (GPS and manual places).
  final int? utcOffsetMinutes;
  final String region;

  /// Suggested method and Asr school, applied when the place is picked.
  final String methodId;
  final AsrMethod asr;

  String label(bool malayalam) => malayalam && nameMl != null ? nameMl! : name;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    if (nameMl != null) 'nameMl': nameMl,
    'lat': latitude,
    'lng': longitude,
    'elev': elevation,
    if (utcOffsetMinutes != null) 'utc': utcOffsetMinutes,
    'region': region,
    'method': methodId,
    'asr': asr.name,
  };

  factory Place.fromJson(Map<String, dynamic> j) => Place(
    id: j['id'] as String,
    name: j['name'] as String,
    nameMl: j['nameMl'] as String?,
    latitude: (j['lat'] as num).toDouble(),
    longitude: (j['lng'] as num).toDouble(),
    elevation: (j['elev'] as num?)?.toDouble() ?? 0,
    utcOffsetMinutes: j['utc'] as int?,
    region: j['region'] as String? ?? '',
    methodId: j['method'] as String? ?? 'kerala',
    asr: AsrMethod.values.asNameMap()[j['asr']] ?? AsrMethod.shafii,
  );

  @override
  bool operator ==(Object other) =>
      other is Place &&
      other.id == id &&
      other.latitude == latitude &&
      other.longitude == longitude &&
      other.elevation == elevation &&
      other.utcOffsetMinutes == utcOffsetMinutes;

  @override
  int get hashCode =>
      Object.hash(id, latitude, longitude, elevation, utcOffsetMinutes);
}

const _ist = 330;

Place _k(String id, String name, String ml, double lat, double lng) => Place(
  id: id,
  name: name,
  nameMl: ml,
  latitude: lat,
  longitude: lng,
  utcOffsetMinutes: _ist,
  region: 'Kerala',
);

Place _p(
  String id,
  String name,
  double lat,
  double lng,
  int utc,
  String region, {
  String method = 'karachi',
  AsrMethod asr = AsrMethod.shafii,
  String? ml,
}) => Place(
  id: id,
  name: name,
  nameMl: ml,
  latitude: lat,
  longitude: lng,
  utcOffsetMinutes: utc,
  region: region,
  methodId: method,
  asr: asr,
);

/// Preset places. Coordinates are city centres; a few kilometres change
/// times by well under a minute.
final List<Place> presetPlaces = [
  _k('tvm', 'Thiruvananthapuram', 'തിരുവനന്തപുരം', 8.5241, 76.9366),
  _k('kollam', 'Kollam', 'കൊല്ലം', 8.8932, 76.6141),
  _k('pathanamthitta', 'Pathanamthitta', 'പത്തനംതിട്ട', 9.2648, 76.7870),
  _k('alappuzha', 'Alappuzha', 'ആലപ്പുഴ', 9.4981, 76.3388),
  _k('kottayam', 'Kottayam', 'കോട്ടയം', 9.5916, 76.5222),
  _k('thodupuzha', 'Thodupuzha (Idukki)', 'തൊടുപുഴ (ഇടുക്കി)', 9.8959, 76.7184),
  _k('kochi', 'Kochi (Ernakulam)', 'കൊച്ചി (എറണാകുളം)', 9.9816, 76.2999),
  _k('aluva', 'Aluva', 'ആലുവ', 10.1076, 76.3516),
  _k('thrissur', 'Thrissur', 'തൃശൂർ', 10.5276, 76.2144),
  _k('palakkad', 'Palakkad', 'പാലക്കാട്', 10.7867, 76.6548),
  _k('ponnani', 'Ponnani', 'പൊന്നാനി', 10.7677, 75.9259),
  _k('tirur', 'Tirur', 'തിരൂർ', 10.9144, 75.9221),
  _k('perinthalmanna', 'Perinthalmanna', 'പെരിന്തൽമണ്ണ', 10.9764, 76.2254),
  _k('malappuram', 'Malappuram', 'മലപ്പുറം', 11.0510, 76.0711),
  _k('manjeri', 'Manjeri', 'മഞ്ചേരി', 11.1203, 76.1199),
  _k('kozhikode', 'Kozhikode', 'കോഴിക്കോട്', 11.2588, 75.7804),
  _k('vadakara', 'Vadakara', 'വടകര', 11.6085, 75.5917),
  _k('kalpetta', 'Kalpetta (Wayanad)', 'കൽപ്പറ്റ (വയനാട്)', 11.6103, 76.0828),
  _k('thalassery', 'Thalassery', 'തലശ്ശേരി', 11.7491, 75.4890),
  _k('kannur', 'Kannur', 'കണ്ണൂർ', 11.8745, 75.3704),
  _k('kanhangad', 'Kanhangad', 'കാഞ്ഞങ്ങാട്', 12.3130, 75.0870),
  _k('kasaragod', 'Kasaragod', 'കാസർകോട്', 12.4996, 74.9869),
  _p(
    'kavaratti',
    'Kavaratti (Lakshadweep)',
    10.5669,
    72.6420,
    _ist,
    'Lakshadweep',
    method: 'kerala',
    ml: 'കവരത്തി (ലക്ഷദ്വീപ്)',
  ),
  _p(
    'mangaluru',
    'Mangaluru',
    12.9141,
    74.8560,
    _ist,
    'Karnataka',
    method: 'kerala',
    ml: 'മംഗളൂരു',
  ),
  _p(
    'bhatkal',
    'Bhatkal',
    13.9850,
    74.5560,
    _ist,
    'Karnataka',
    method: 'kerala',
  ),
  _p(
    'bengaluru',
    'Bengaluru',
    12.9716,
    77.5946,
    _ist,
    'Karnataka',
    ml: 'ബെംഗളൂരു',
  ),
  _p(
    'coimbatore',
    'Coimbatore',
    11.0168,
    76.9558,
    _ist,
    'Tamil Nadu',
    ml: 'കോയമ്പത്തൂർ',
  ),
  _p('chennai', 'Chennai', 13.0827, 80.2707, _ist, 'Tamil Nadu', ml: 'ചെന്നൈ'),
  _p(
    'hyderabad',
    'Hyderabad',
    17.3850,
    78.4867,
    _ist,
    'India',
    asr: AsrMethod.hanafi,
  ),
  _p(
    'mumbai',
    'Mumbai',
    19.0760,
    72.8777,
    _ist,
    'India',
    asr: AsrMethod.hanafi,
    ml: 'മുംബൈ',
  ),
  _p(
    'delhi',
    'Delhi',
    28.6139,
    77.2090,
    _ist,
    'India',
    asr: AsrMethod.hanafi,
    ml: 'ഡൽഹി',
  ),
  _p('male', 'Malé', 4.1755, 73.5093, 300, 'Maldives', method: 'mwl'),
  _p(
    'dubai',
    'Dubai',
    25.2048,
    55.2708,
    240,
    'UAE',
    method: 'dubai',
    ml: 'ദുബൈ',
  ),
  _p(
    'sharjah',
    'Sharjah',
    25.3463,
    55.4209,
    240,
    'UAE',
    method: 'dubai',
    ml: 'ഷാർജ',
  ),
  _p(
    'abudhabi',
    'Abu Dhabi',
    24.4539,
    54.3773,
    240,
    'UAE',
    method: 'dubai',
    ml: 'അബുദാബി',
  ),
  _p('alain', 'Al Ain', 24.2075, 55.7447, 240, 'UAE', method: 'dubai'),
  _p(
    'muscat',
    'Muscat',
    23.5880,
    58.3829,
    240,
    'Oman',
    method: 'mwl',
    ml: 'മസ്കത്ത്',
  ),
  _p(
    'doha',
    'Doha',
    25.2854,
    51.5310,
    180,
    'Qatar',
    method: 'qatar',
    ml: 'ദോഹ',
  ),
  _p('manama', 'Manama', 26.2285, 50.5860, 180, 'Bahrain', method: 'mwl'),
  _p(
    'kuwait',
    'Kuwait City',
    29.3759,
    47.9774,
    180,
    'Kuwait',
    method: 'kuwait',
    ml: 'കുവൈത്ത്',
  ),
  _p(
    'riyadh',
    'Riyadh',
    24.7136,
    46.6753,
    180,
    'Saudi Arabia',
    method: 'umm_al_qura',
    ml: 'റിയാദ്',
  ),
  _p(
    'dammam',
    'Dammam',
    26.4207,
    50.0888,
    180,
    'Saudi Arabia',
    method: 'umm_al_qura',
    ml: 'ദമ്മാം',
  ),
  _p(
    'jeddah',
    'Jeddah',
    21.4858,
    39.1925,
    180,
    'Saudi Arabia',
    method: 'umm_al_qura',
    ml: 'ജിദ്ദ',
  ),
  _p(
    'makkah',
    'Makkah',
    21.4225,
    39.8262,
    180,
    'Saudi Arabia',
    method: 'umm_al_qura',
    ml: 'മക്ക',
  ),
  _p(
    'madinah',
    'Madinah',
    24.5247,
    39.5692,
    180,
    'Saudi Arabia',
    method: 'umm_al_qura',
    ml: 'മദീന',
  ),
];

/// Place of the Kaaba (for the Qibla).
const double kaabaLatitude = 21.422487;
const double kaabaLongitude = 39.826206;
