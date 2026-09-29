/// Public reference table of Indian airport IATA codes — NOT sorting rules.
/// Used only for the "Airport codes" lookup and to warn about unknown codes
/// when importing an office's air code sheet. Air codes are never assigned
/// from this table.
library;

class Airport {
  const Airport(this.iata, this.city, this.airport, this.state);

  final String iata;
  final String city;
  final String airport;
  final String state;
}

const List<Airport> kAirports = [
  Airport('BLR', 'Bengaluru', 'Kempegowda International Airport', 'Karnataka'),
  Airport('IXE', 'Mangaluru', 'Mangaluru International Airport', 'Karnataka'),
  Airport('MYQ', 'Mysuru', 'Mysuru Airport', 'Karnataka'),
  Airport('HBX', 'Hubballi', 'Hubballi Airport', 'Karnataka'),
  Airport('IXG', 'Belagavi', 'Belagavi Airport', 'Karnataka'),
  Airport('GBI', 'Kalaburagi', 'Kalaburagi Airport', 'Karnataka'),
  Airport('MAA', 'Chennai', 'Chennai International Airport', 'Tamil Nadu'),
  Airport('CJB', 'Coimbatore', 'Coimbatore International Airport', 'Tamil Nadu'),
  Airport('IXM', 'Madurai', 'Madurai Airport', 'Tamil Nadu'),
  Airport('TRZ', 'Tiruchirappalli', 'Tiruchirappalli International Airport', 'Tamil Nadu'),
  Airport('COK', 'Kochi', 'Cochin International Airport', 'Kerala'),
  Airport('CCJ', 'Kozhikode', 'Calicut International Airport', 'Kerala'),
  Airport('CNN', 'Kannur', 'Kannur International Airport', 'Kerala'),
  Airport('TRV', 'Thiruvananthapuram', 'Thiruvananthapuram International Airport', 'Kerala'),
  Airport('HYD', 'Hyderabad', 'Rajiv Gandhi International Airport', 'Telangana'),
  Airport('VTZ', 'Visakhapatnam', 'Visakhapatnam Airport', 'Andhra Pradesh'),
  Airport('VGA', 'Vijayawada', 'Vijayawada International Airport', 'Andhra Pradesh'),
  Airport('TIR', 'Tirupati', 'Tirupati Airport', 'Andhra Pradesh'),
  Airport('BOM', 'Mumbai', 'Chhatrapati Shivaji Maharaj International Airport', 'Maharashtra'),
  Airport('PNQ', 'Pune', 'Pune Airport', 'Maharashtra'),
  Airport('NAG', 'Nagpur', 'Dr. Babasaheb Ambedkar International Airport', 'Maharashtra'),
  Airport('GOI', 'Goa (Dabolim)', 'Dabolim Airport', 'Goa'),
  Airport('GOX', 'Goa (Mopa)', 'Manohar International Airport', 'Goa'),
  Airport('DEL', 'Delhi', 'Indira Gandhi International Airport', 'Delhi'),
  Airport('CCU', 'Kolkata', 'Netaji Subhas Chandra Bose International Airport', 'West Bengal'),
  Airport('IXB', 'Bagdogra', 'Bagdogra Airport', 'West Bengal'),
  Airport('AMD', 'Ahmedabad', 'Sardar Vallabhbhai Patel International Airport', 'Gujarat'),
  Airport('STV', 'Surat', 'Surat Airport', 'Gujarat'),
  Airport('BDQ', 'Vadodara', 'Vadodara Airport', 'Gujarat'),
  Airport('JAI', 'Jaipur', 'Jaipur International Airport', 'Rajasthan'),
  Airport('UDR', 'Udaipur', 'Maharana Pratap Airport', 'Rajasthan'),
  Airport('LKO', 'Lucknow', 'Chaudhary Charan Singh International Airport', 'Uttar Pradesh'),
  Airport('VNS', 'Varanasi', 'Lal Bahadur Shastri International Airport', 'Uttar Pradesh'),
  Airport('PAT', 'Patna', 'Jay Prakash Narayan International Airport', 'Bihar'),
  Airport('IXR', 'Ranchi', 'Birsa Munda Airport', 'Jharkhand'),
  Airport('GAU', 'Guwahati', 'Lokpriya Gopinath Bordoloi International Airport', 'Assam'),
  Airport('IMF', 'Imphal', 'Imphal International Airport', 'Manipur'),
  Airport('IXA', 'Agartala', 'Maharaja Bir Bikram Airport', 'Tripura'),
  Airport('BBI', 'Bhubaneswar', 'Biju Patnaik International Airport', 'Odisha'),
  Airport('IXC', 'Chandigarh', 'Chandigarh International Airport', 'Chandigarh'),
  Airport('ATQ', 'Amritsar', 'Sri Guru Ram Dass Jee International Airport', 'Punjab'),
  Airport('SXR', 'Srinagar', 'Sheikh ul-Alam International Airport', 'Jammu & Kashmir'),
  Airport('IXJ', 'Jammu', 'Jammu Airport', 'Jammu & Kashmir'),
  Airport('IXL', 'Leh', 'Kushok Bakula Rimpochee Airport', 'Ladakh'),
  Airport('DED', 'Dehradun', 'Jolly Grant Airport', 'Uttarakhand'),
  Airport('IDR', 'Indore', 'Devi Ahilya Bai Holkar Airport', 'Madhya Pradesh'),
  Airport('BHO', 'Bhopal', 'Raja Bhoj Airport', 'Madhya Pradesh'),
  Airport('RPR', 'Raipur', 'Swami Vivekananda Airport', 'Chhattisgarh'),
  Airport('IXZ', 'Port Blair', 'Veer Savarkar International Airport', 'Andaman & Nicobar'),
];

final Map<String, Airport> _byCode = {for (final a in kAirports) a.iata: a};

Airport? airportByCode(String code) => _byCode[code.trim().toUpperCase()];

bool isKnownAirportCode(String code) => _byCode.containsKey(code.trim().toUpperCase());

List<Airport> searchAirports(String q) {
  final s = q.trim().toLowerCase();
  if (s.isEmpty) return kAirports;
  return kAirports
      .where((a) =>
          a.iata.toLowerCase().contains(s) ||
          a.city.toLowerCase().contains(s) ||
          a.airport.toLowerCase().contains(s) ||
          a.state.toLowerCase().contains(s))
      .toList();
}
