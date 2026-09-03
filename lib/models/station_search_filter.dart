enum StationFuelFilter {
  all,
  octane,
  petrol,
  diesel,
  cng,
  lpg,
}

enum StationListSort {
  nearest,
  topRated,
  bestPrice,
}

class StationSearchFilter {
  const StationSearchFilter({
    this.query = '',
    this.radiusKm = 10,
    this.fuel = StationFuelFilter.all,
    this.sort = StationListSort.nearest,
  });

  final String query;
  final double radiusKm;
  final StationFuelFilter fuel;
  final StationListSort sort;

  static const radiusOptions = [2.0, 5.0, 10.0, 15.0];

  StationSearchFilter copyWith({
    String? query,
    double? radiusKm,
    StationFuelFilter? fuel,
    StationListSort? sort,
  }) {
    return StationSearchFilter(
      query: query ?? this.query,
      radiusKm: radiusKm ?? this.radiusKm,
      fuel: fuel ?? this.fuel,
      sort: sort ?? this.sort,
    );
  }

  bool get hasActiveConstraints =>
      query.trim().isNotEmpty ||
      radiusKm != 10 ||
      fuel != StationFuelFilter.all ||
      sort != StationListSort.nearest;

  @override
  bool operator ==(Object other) {
    return other is StationSearchFilter &&
        other.query == query &&
        other.radiusKm == radiusKm &&
        other.fuel == fuel &&
        other.sort == sort;
  }

  @override
  int get hashCode => Object.hash(query, radiusKm, fuel, sort);
}

extension StationFuelFilterX on StationFuelFilter {
  String get label => switch (this) {
        StationFuelFilter.all => 'All fuels',
        StationFuelFilter.octane => 'Octane',
        StationFuelFilter.petrol => 'Petrol',
        StationFuelFilter.diesel => 'Diesel',
        StationFuelFilter.cng => 'CNG',
        StationFuelFilter.lpg => 'LPG',
      };

  String get matchToken => switch (this) {
        StationFuelFilter.all => '',
        StationFuelFilter.octane => 'octane',
        StationFuelFilter.petrol => 'petrol',
        StationFuelFilter.diesel => 'diesel',
        StationFuelFilter.cng => 'cng',
        StationFuelFilter.lpg => 'lpg',
      };
}

extension StationListSortX on StationListSort {
  String get label => switch (this) {
        StationListSort.nearest => 'Nearest',
        StationListSort.topRated => 'Top rated',
        StationListSort.bestPrice => 'Best price',
      };
}
