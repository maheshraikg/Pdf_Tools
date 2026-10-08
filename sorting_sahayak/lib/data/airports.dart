/// Public reference table of Indian airport IATA codes — NOT sorting rules.
/// Used by the Air code finder (by code, name, or nearest to a PIN's post
/// office) and to warn about unknown codes when importing an office's air
/// code sheet. An office's own air code sheet always wins over this table.
library;

import 'dart:math' as math;

class Airport {
  const Airport(this.iata, this.city, this.airport, this.state, this.lat, this.lng);

  final String iata;
  final String city;
  final String airport;
  final String state;

  /// Approximate location, for "nearest airport" only.
  final double lat;
  final double lng;
}

const List<Airport> kAirports = [
  Airport('BLR', 'Bengaluru', 'Kempegowda International Airport', 'Karnataka', 13.199, 77.706),
  Airport('IXE', 'Mangaluru', 'Mangaluru International Airport', 'Karnataka', 12.961, 74.890),
  Airport('MYQ', 'Mysuru', 'Mysuru Airport', 'Karnataka', 12.230, 76.656),
  Airport('HBX', 'Hubballi', 'Hubballi Airport', 'Karnataka', 15.362, 75.085),
  Airport('IXG', 'Belagavi', 'Belagavi Airport', 'Karnataka', 15.859, 74.618),
  Airport('GBI', 'Kalaburagi', 'Kalaburagi Airport', 'Karnataka', 17.307, 76.958),
  Airport('MAA', 'Chennai', 'Chennai International Airport', 'Tamil Nadu', 12.994, 80.171),
  Airport('CJB', 'Coimbatore', 'Coimbatore International Airport', 'Tamil Nadu', 11.030, 77.043),
  Airport('IXM', 'Madurai', 'Madurai Airport', 'Tamil Nadu', 9.834, 78.093),
  Airport('TRZ', 'Tiruchirappalli', 'Tiruchirappalli International Airport', 'Tamil Nadu', 10.765, 78.710),
  Airport('COK', 'Kochi', 'Cochin International Airport', 'Kerala', 10.152, 76.402),
  Airport('CCJ', 'Kozhikode', 'Calicut International Airport', 'Kerala', 11.137, 75.955),
  Airport('CNN', 'Kannur', 'Kannur International Airport', 'Kerala', 11.918, 75.547),
  Airport('TRV', 'Thiruvananthapuram', 'Thiruvananthapuram International Airport', 'Kerala', 8.482, 76.920),
  Airport('HYD', 'Hyderabad', 'Rajiv Gandhi International Airport', 'Telangana', 17.240, 78.429),
  Airport('VTZ', 'Visakhapatnam', 'Visakhapatnam Airport', 'Andhra Pradesh', 17.721, 83.225),
  Airport('VGA', 'Vijayawada', 'Vijayawada International Airport', 'Andhra Pradesh', 16.530, 80.797),
  Airport('TIR', 'Tirupati', 'Tirupati Airport', 'Andhra Pradesh', 13.632, 79.543),
  Airport('BOM', 'Mumbai', 'Chhatrapati Shivaji Maharaj International Airport', 'Maharashtra', 19.089, 72.868),
  Airport('PNQ', 'Pune', 'Pune Airport', 'Maharashtra', 18.582, 73.920),
  Airport('NAG', 'Nagpur', 'Dr. Babasaheb Ambedkar International Airport', 'Maharashtra', 21.092, 79.047),
  Airport('GOI', 'Goa (Dabolim)', 'Dabolim Airport', 'Goa', 15.381, 73.831),
  Airport('GOX', 'Goa (Mopa)', 'Manohar International Airport', 'Goa', 15.744, 73.861),
  Airport('DEL', 'Delhi', 'Indira Gandhi International Airport', 'Delhi', 28.556, 77.100),
  Airport('CCU', 'Kolkata', 'Netaji Subhas Chandra Bose International Airport', 'West Bengal', 22.655, 88.447),
  Airport('IXB', 'Bagdogra', 'Bagdogra Airport', 'West Bengal', 26.681, 88.329),
  Airport('AMD', 'Ahmedabad', 'Sardar Vallabhbhai Patel International Airport', 'Gujarat', 23.077, 72.635),
  Airport('STV', 'Surat', 'Surat Airport', 'Gujarat', 21.114, 72.742),
  Airport('BDQ', 'Vadodara', 'Vadodara Airport', 'Gujarat', 22.336, 73.226),
  Airport('JAI', 'Jaipur', 'Jaipur International Airport', 'Rajasthan', 26.824, 75.812),
  Airport('UDR', 'Udaipur', 'Maharana Pratap Airport', 'Rajasthan', 24.618, 73.896),
  Airport('LKO', 'Lucknow', 'Chaudhary Charan Singh International Airport', 'Uttar Pradesh', 26.761, 80.889),
  Airport('VNS', 'Varanasi', 'Lal Bahadur Shastri International Airport', 'Uttar Pradesh', 25.452, 82.859),
  Airport('PAT', 'Patna', 'Jay Prakash Narayan International Airport', 'Bihar', 25.591, 85.088),
  Airport('IXR', 'Ranchi', 'Birsa Munda Airport', 'Jharkhand', 23.314, 85.322),
  Airport('GAU', 'Guwahati', 'Lokpriya Gopinath Bordoloi International Airport', 'Assam', 26.106, 91.586),
  Airport('IMF', 'Imphal', 'Imphal International Airport', 'Manipur', 24.760, 93.897),
  Airport('IXA', 'Agartala', 'Maharaja Bir Bikram Airport', 'Tripura', 23.887, 91.240),
  Airport('BBI', 'Bhubaneswar', 'Biju Patnaik International Airport', 'Odisha', 20.244, 85.818),
  Airport('IXC', 'Chandigarh', 'Chandigarh International Airport', 'Chandigarh', 30.673, 76.788),
  Airport('ATQ', 'Amritsar', 'Sri Guru Ram Dass Jee International Airport', 'Punjab', 31.710, 74.797),
  Airport('SXR', 'Srinagar', 'Sheikh ul-Alam International Airport', 'Jammu & Kashmir', 33.987, 74.774),
  Airport('IXJ', 'Jammu', 'Jammu Airport', 'Jammu & Kashmir', 32.689, 74.838),
  Airport('IXL', 'Leh', 'Kushok Bakula Rimpochee Airport', 'Ladakh', 34.136, 77.546),
  Airport('DED', 'Dehradun', 'Jolly Grant Airport', 'Uttarakhand', 30.190, 78.180),
  Airport('IDR', 'Indore', 'Devi Ahilya Bai Holkar Airport', 'Madhya Pradesh', 22.722, 75.801),
  Airport('BHO', 'Bhopal', 'Raja Bhoj Airport', 'Madhya Pradesh', 23.288, 77.337),
  Airport('RPR', 'Raipur', 'Swami Vivekananda Airport', 'Chhattisgarh', 21.180, 81.739),
  Airport('IXZ', 'Port Blair', 'Veer Savarkar International Airport', 'Andaman & Nicobar', 11.641, 92.730),
];

final Map<String, Airport> _byCode = {for (final a in kAirports) a.iata: a};

Airport? airportByCode(String code) => _byCode[code.trim().toUpperCase()];

bool isKnownAirportCode(String code) => _byCode.containsKey(code.trim().toUpperCase());

List<Airport> searchAirports(String q) {
  final s = q.trim().toLowerCase();
  if (s.isEmpty) return kAirports;
  final code = kAirports.where((a) => a.iata.toLowerCase().startsWith(s));
  final rest = kAirports.where(
    (a) =>
        !a.iata.toLowerCase().startsWith(s) &&
        (a.city.toLowerCase().contains(s) || a.airport.toLowerCase().contains(s) || a.state.toLowerCase().contains(s)),
  );
  return [...code, ...rest];
}

/// Great-circle distance in km.
double distanceKm(double lat1, double lng1, double lat2, double lng2) {
  const r = 6371.0;
  double rad(double d) => d * math.pi / 180;
  final dLat = rad(lat2 - lat1);
  final dLng = rad(lng2 - lng1);
  final a = math.sin(dLat / 2) * math.sin(dLat / 2) + math.cos(rad(lat1)) * math.cos(rad(lat2)) * math.sin(dLng / 2) * math.sin(dLng / 2);
  return 2 * r * math.asin(math.min(1, math.sqrt(a)));
}

/// Airports closest to a point, nearest first.
List<(Airport, double)> nearestAirports(double lat, double lng, {int count = 3}) {
  final list = [for (final a in kAirports) (a, distanceKm(lat, lng, a.lat, a.lng))]..sort((x, y) => x.$2.compareTo(y.$2));
  return list.take(count).toList();
}

/// Airports in the given states (case-insensitive).
List<Airport> airportsInStates(Iterable<String> states) {
  String n(String x) => x.toLowerCase().replaceAll('&', 'and').replaceAll(RegExp(r'[^a-z]'), '');
  final s = {for (final x in states) n(x)};
  return kAirports.where((a) => s.contains(n(a.state))).toList();
}
