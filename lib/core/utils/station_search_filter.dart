import '../../models/mock_gas_station.dart';
import '../../models/station_search_filter.dart';

List<MockGasStation> applyStationSearchFilter(
  List<MockGasStation> stations,
  StationSearchFilter filter,
) {
  var list = stations.where((station) {
    final radiusMeters = filter.radiusKm * 1000;
    final distance = station.sortDistanceMeters > 0
        ? station.sortDistanceMeters
        : station.straightLineMeters;
    if (distance <= 0 || distance > radiusMeters) return false;

    final query = filter.query.trim().toLowerCase();
    if (query.isNotEmpty) {
      final haystack = [
        station.name,
        station.addressHint,
        station.fuelTypes,
        station.distance,
      ].join(' ').toLowerCase();
      if (!haystack.contains(query)) return false;
    }

    if (filter.fuel != StationFuelFilter.all) {
      final fuels = station.fuelTypes.toLowerCase();
      if (!fuels.contains(filter.fuel.matchToken)) return false;
    }

    return true;
  }).toList();

  list.sort((a, b) {
    final aDist =
        a.sortDistanceMeters > 0 ? a.sortDistanceMeters : a.straightLineMeters;
    final bDist =
        b.sortDistanceMeters > 0 ? b.sortDistanceMeters : b.straightLineMeters;
    return aDist.compareTo(bDist);
  });

  return list;
}
