import 'package:flutter_test/flutter_test.dart';
import 'package:fuel_log/models/mock_gas_station.dart';
import 'package:latlong2/latlong.dart';

void main() {
  group('MockGasStation distance labels', () {
    const testLoc = LatLng(23.82, 90.386);

    test('shows straight-line as away when no driving route', () {
      const station = MockGasStation(
        id: '1',
        name: 'Sumatra Filling',
        distance: 'Matikata • 1.1 km away',
        fuelTypes: 'Octane',
        rating: 4.5,
        location: testLoc,
        straightLineMeters: 1100,
      );

      expect(station.formattedDistanceBadge, '1.1 km away');
      expect(station.formattedEta, isNull);
      expect(station.sortDistanceMeters, 1100);
    });

    test('shows driving distance and ETA when OSRM data present', () {
      const station = MockGasStation(
        id: '1',
        name: 'Sumatra Filling',
        distance: 'Matikata • 17 min • 4.1 km drive',
        fuelTypes: 'Octane',
        rating: 4.5,
        location: testLoc,
        straightLineMeters: 1100,
        drivingDistanceMeters: 4100,
        drivingDurationSeconds: 1020,
      );

      expect(station.formattedDistanceBadge, '4.1 km drive');
      expect(station.formattedEta, '17 min');
      expect(station.sortDistanceMeters, 4100);
    });
  });
}
