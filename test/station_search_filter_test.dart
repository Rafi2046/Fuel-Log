import 'package:flutter_test/flutter_test.dart';
import 'package:fuel_log/core/utils/station_search_filter.dart';
import 'package:fuel_log/models/mock_gas_station.dart';
import 'package:fuel_log/models/station_search_filter.dart';
import 'package:latlong2/latlong.dart';

void main() {
  const loc = LatLng(23.82, 90.39);

  MockGasStation station({
    required String name,
    required String fuels,
    required double meters,
    double rating = 4.0,
  }) {
    return MockGasStation(
      id: name,
      name: name,
      distance: '$meters',
      fuelTypes: fuels,
      rating: rating,
      location: loc,
      straightLineMeters: meters,
      drivingDistanceMeters: meters,
    );
  }

  final stations = [
    station(name: 'CSD Filling Station', fuels: 'Octane • Diesel', meters: 5000, rating: 4.8),
    station(name: 'Ariya CNG', fuels: 'CNG • Octane', meters: 1700, rating: 4.2),
    station(name: 'Padma Hub', fuels: 'Diesel', meters: 12000, rating: 4.9),
  ];

  test('filters by radius, fuel, and query', () {
    final filtered = applyStationSearchFilter(
      stations,
      const StationSearchFilter(
        query: 'csd',
        radiusKm: 10,
        fuel: StationFuelFilter.diesel,
      ),
    );

    expect(filtered.map((s) => s.name), ['CSD Filling Station']);
  });

  test('sorts nearest first after apply', () {
    final filtered = applyStationSearchFilter(
      stations,
      const StationSearchFilter(radiusKm: 15),
    );

    expect(filtered.first.name, 'Ariya CNG');
    expect(filtered.last.name, 'Padma Hub');
  });

  test('hides stations outside radius', () {
    final filtered = applyStationSearchFilter(
      stations,
      const StationSearchFilter(radiusKm: 5),
    );

    expect(filtered.any((s) => s.name == 'Padma Hub'), isFalse);
    expect(filtered.length, 2);
  });
}
