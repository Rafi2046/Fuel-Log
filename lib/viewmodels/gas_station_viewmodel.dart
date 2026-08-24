import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

import '../core/services/fuel_price_repository.dart';
import '../models/fuel_price_model.dart';

enum StationSortOption {
  distance,
  price,
  upvotes,
  name,
}

class GasStationsState {
  final List<StationInfo> allStations;
  final bool isLoading;
  final String? error;
  final String searchQuery;
  final String selectedFuelFilter; // 'ALL', '95', '98', '91', 'D', 'CNG', 'LPG'
  final StationSortOption sortOption;
  final int activeNavigationIndex; // 0: Map, 1: List, 2: Favorites
  final LatLng? userLocation;
  final StationInfo? selectedStation;

  const GasStationsState({
    this.allStations = const [],
    this.isLoading = true,
    this.error,
    this.searchQuery = '',
    this.selectedFuelFilter = 'ALL',
    this.sortOption = StationSortOption.distance,
    this.activeNavigationIndex = 1, // Default to List view matching user screenshot
    this.userLocation,
    this.selectedStation,
  });

  List<StationInfo> get filteredStations {
    var list = List<StationInfo>.from(allStations);

    // Filter by Tab (Favorites only)
    if (activeNavigationIndex == 2) {
      list = list.where((s) => s.isFavorite).toList();
    }

    // Filter by Search Query
    if (searchQuery.trim().isNotEmpty) {
      final q = searchQuery.toLowerCase().trim();
      list = list.where((s) {
        return s.name.toLowerCase().contains(q) ||
            (s.banglaName?.toLowerCase().contains(q) ?? false) ||
            s.address.toLowerCase().contains(q);
      }).toList();
    }

    // Filter by Fuel Type
    if (selectedFuelFilter != 'ALL') {
      list = list.where((s) {
        return s.prices.any((p) => p.fuelGradeCode.toUpperCase() == selectedFuelFilter.toUpperCase()) ||
            s.availableCategories.contains(selectedFuelFilter);
      }).toList();
    }

    // Apply Sorting
    switch (sortOption) {
      case StationSortOption.distance:
        list.sort((a, b) => a.distanceMeters.compareTo(b.distanceMeters));
        break;
      case StationSortOption.price:
        list.sort((a, b) => a.primaryPrice.compareTo(b.primaryPrice));
        break;
      case StationSortOption.upvotes:
        list.sort((a, b) => b.upvotes.compareTo(a.upvotes));
        break;
      case StationSortOption.name:
        list.sort((a, b) => a.displayName.compareTo(b.displayName));
        break;
    }

    return list;
  }

  GasStationsState copyWith({
    List<StationInfo>? allStations,
    bool? isLoading,
    String? error,
    String? searchQuery,
    String? selectedFuelFilter,
    StationSortOption? sortOption,
    int? activeNavigationIndex,
    LatLng? userLocation,
    StationInfo? selectedStation,
  }) {
    return GasStationsState(
      allStations: allStations ?? this.allStations,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedFuelFilter: selectedFuelFilter ?? this.selectedFuelFilter,
      sortOption: sortOption ?? this.sortOption,
      activeNavigationIndex: activeNavigationIndex ?? this.activeNavigationIndex,
      userLocation: userLocation ?? this.userLocation,
      selectedStation: selectedStation ?? this.selectedStation,
    );
  }
}

class GasStationsNotifier extends StateNotifier<GasStationsState> {
  GasStationsNotifier() : super(const GasStationsState()) {
    loadStations();
  }

  final _repo = FuelPriceRepository.instance;

  Future<void> loadStations() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      LatLng? location;
      try {
        final permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
          final pos = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.medium,
              timeLimit: Duration(seconds: 4),
            ),
          );
          location = LatLng(pos.latitude, pos.longitude);
        }
      } catch (_) {
        // Fallback gracefully
      }

      location ??= const LatLng(23.7925, 90.4078); // Dhaka Default

      final stations = await _repo.getStations(userLocation: location);
      state = state.copyWith(
        allStations: stations,
        isLoading: false,
        userLocation: location,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void setFuelFilter(String fuelFilter) {
    state = state.copyWith(selectedFuelFilter: fuelFilter);
  }

  void setSortOption(StationSortOption option) {
    state = state.copyWith(sortOption: option);
  }

  void setActiveNavigationIndex(int index) {
    state = state.copyWith(activeNavigationIndex: index);
  }

  void selectStation(StationInfo? station) {
    state = state.copyWith(selectedStation: station);
  }

  Future<void> toggleFavorite(String stationId, {StationInfo? fallbackStation}) async {
    final willBeFav = await _repo.toggleFavorite(stationId);
    bool found = false;
    final updated = state.allStations.map((s) {
      if (s.id == stationId) {
        found = true;
        return s.copyWith(isFavorite: willBeFav);
      }
      return s;
    }).toList();

    if (!found && fallbackStation != null) {
      updated.add(fallbackStation.copyWith(isFavorite: willBeFav));
    }

    state = state.copyWith(allStations: updated);
  }

  Future<void> toggleUpvote(String stationId, {StationInfo? fallbackStation}) async {
    final willBeUpvoted = await _repo.toggleUpvote(stationId);
    bool found = false;
    final updated = state.allStations.map((s) {
      if (s.id == stationId) {
        found = true;
        final delta = willBeUpvoted ? 1 : -1;
        return s.copyWith(
          isUserUpvoted: willBeUpvoted,
          upvotes: (s.upvotes + delta).clamp(0, 9999),
        );
      }
      return s;
    }).toList();

    if (!found && fallbackStation != null) {
      final delta = willBeUpvoted ? 1 : 0;
      updated.add(
        fallbackStation.copyWith(
          isUserUpvoted: willBeUpvoted,
          upvotes: (fallbackStation.upvotes + delta).clamp(0, 9999),
        ),
      );
    }

    state = state.copyWith(allStations: updated);
  }

  Future<void> updatePrice({
    required String stationId,
    required String fuelGradeCode,
    required double newPrice,
    String? updatedBy,
  }) async {
    await _repo.updateStationPrice(
      stationId: stationId,
      fuelGradeCode: fuelGradeCode,
      newPrice: newPrice,
      updatedBy: updatedBy,
    );
    // Reload stations to refresh all views
    await loadStations();
  }
}

final gasStationsProvider = StateNotifierProvider<GasStationsNotifier, GasStationsState>((ref) {
  return GasStationsNotifier();
});
