import 'package:flutter_test/flutter_test.dart';
import 'package:waqt/app/city_data.dart';
import 'package:waqt/app/location.dart';
import 'package:waqt/app/settings.dart';
import 'package:waqt/app/strings.dart';
import 'package:waqt/core/place.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('distance', () {
    // Kozhikode – Kochi is about 160 km.
    expect(distanceKm(11.2588, 75.7804, 9.9816, 76.2999), closeTo(152, 10));
    expect(distanceKm(1, 1, 1, 1), 0);
  });

  test('GPS place takes the nearest town and its time zone', () async {
    debugResetCities();
    final s = AppSettings.memory();
    final london = await gpsPlace(s, S(s.lang), 51.51, -0.12);
    expect(london.id, 'gps');
    expect(london.timeZone, 'Europe/London');
    expect(london.name, contains('London'));
    expect(london.offsetMinutesAt(DateTime.utc(2026, 7, 1)), 60);
    final apia = await gpsPlace(s, S(s.lang), -13.83, -171.77);
    expect(apia.timeZone, 'Pacific/Apia');
    // Mid-ocean: no town nearby, the phone's zone is used.
    final ocean = await gpsPlace(s, S(s.lang), 0, -140);
    expect(ocean.timeZone, isNull);
  });

  test('picking GPS turns automatic location on, a fixed place off', () async {
    final s = AppSettings.memory();
    await s.choosePlace(
      const Place(id: 'gps', name: 'x', latitude: 1, longitude: 1),
      applySuggestions: false,
    );
    expect(s.autoLocation, isTrue);
    await s.choosePlace(presetPlaces.first);
    expect(s.autoLocation, isFalse);
  });
}
