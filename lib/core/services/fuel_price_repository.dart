import 'dart:convert';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/fuel_price_model.dart';

class FuelPriceRepository {
  FuelPriceRepository._();
  static final FuelPriceRepository instance = FuelPriceRepository._();

  static const String _keyPriceOverrides = 'fuel_price_overrides_v1';
  static const String _keyFavorites = 'fuel_station_favorites_v1';
  static const String _keyUpvotes = 'fuel_station_upvotes_v1';

  static const Distance _distanceCalculator = Distance();

  /// Default baseline Bangladesh stations mirroring real-world stations & the user's UI mockups
  static final List<StationInfo> _seedStations = [
    StationInfo(
      id: 'bd_sumatra',
      name: 'Sumatra Filling Station',
      banglaName: 'সুমাত্রা ফিলিং ষ্টেশন',
      address: 'Bijoy Sarani, Tejgaon, Dhaka',
      location: const LatLng(23.7663, 90.3876),
      distanceMeters: 1154,
      upvotes: 16,
      availableCategories: ['G', 'D', 'E', 'LPG'],
      prices: [
        StationPriceItem(
          fuelGradeCode: '85',
          price: 145.00,
          lastUpdated: DateTime.now().subtract(const Duration(days: 30)),
        ),
        StationPriceItem(
          fuelGradeCode: '87',
          price: 145.00,
          lastUpdated: DateTime.now().subtract(const Duration(days: 6)),
        ),
        StationPriceItem(
          fuelGradeCode: '89',
          price: 145.00,
          lastUpdated: DateTime.now().subtract(const Duration(days: 18)),
        ),
        StationPriceItem(
          fuelGradeCode: '91',
          price: 145.00,
          lastUpdated: DateTime.now().subtract(const Duration(days: 19)),
        ),
        StationPriceItem(
          fuelGradeCode: '93',
          price: 145.00,
          lastUpdated: DateTime.now().subtract(const Duration(days: 19)),
        ),
        StationPriceItem(
          fuelGradeCode: '95',
          price: 145.00,
          lastUpdated: DateTime.now().subtract(const Duration(days: 9)),
        ),
        StationPriceItem(
          fuelGradeCode: '98',
          price: 145.00,
          lastUpdated: DateTime.now().subtract(const Duration(days: 5)),
        ),
        StationPriceItem(
          fuelGradeCode: 'E85',
          price: 144.92,
          lastUpdated: DateTime.now().subtract(const Duration(days: 28)),
        ),
        StationPriceItem(
          fuelGradeCode: 'LPG',
          price: 72.50,
          lastUpdated: DateTime.now().subtract(const Duration(days: 4)),
        ),
        StationPriceItem(
          fuelGradeCode: 'D',
          price: 105.00,
          lastUpdated: DateTime.now().subtract(const Duration(days: 2)),
        ),
      ],
    ),
    StationInfo(
      id: 'bd_diganta',
      name: 'Diganta Filling Station',
      banglaName: 'দিগন্ত ফিলিং স্টেশন',
      address: 'Mohakhali C/A, Dhaka',
      location: const LatLng(23.7781, 90.4002),
      distanceMeters: 1250,
      upvotes: 2,
      availableCategories: ['G', 'D', 'E'],
      prices: [
        StationPriceItem(
          fuelGradeCode: '95',
          price: 145.00,
          lastUpdated: DateTime.now().subtract(const Duration(days: 9)),
        ),
        StationPriceItem(
          fuelGradeCode: '91',
          price: 145.00,
          lastUpdated: DateTime.now().subtract(const Duration(days: 9)),
        ),
        StationPriceItem(
          fuelGradeCode: 'D',
          price: 105.00,
          lastUpdated: DateTime.now().subtract(const Duration(days: 12)),
        ),
      ],
    ),
    StationInfo(
      id: 'bd_sp',
      name: 'SP Filling Station',
      banglaName: 'এসপি ফিলিং স্টেশন',
      address: 'Gulshan Link Road, Dhaka',
      location: const LatLng(23.7745, 90.4120),
      distanceMeters: 1283,
      upvotes: 8,
      availableCategories: ['G', 'D', 'E', 'CNG'],
      prices: [
        StationPriceItem(
          fuelGradeCode: '95',
          price: 140.00,
          lastUpdated: DateTime.now().subtract(const Duration(days: 81)),
        ),
        StationPriceItem(
          fuelGradeCode: '91',
          price: 136.00,
          lastUpdated: DateTime.now().subtract(const Duration(days: 81)),
        ),
        StationPriceItem(
          fuelGradeCode: 'CNG',
          price: 43.00,
          lastUpdated: DateTime.now().subtract(const Duration(days: 15)),
        ),
      ],
    ),
    StationInfo(
      id: 'bd_trust',
      name: 'Trust Filling Station',
      banglaName: 'ট্রাস্ট ফিলিং স্টেশন',
      address: 'Army Golf Club, Airport Road, Dhaka',
      location: const LatLng(23.8055, 90.4072),
      distanceMeters: 1306,
      upvotes: 24,
      availableCategories: ['G', 'D', 'E', 'LPG', 'CNG'],
      prices: [
        StationPriceItem(
          fuelGradeCode: '95',
          price: 145.00,
          lastUpdated: DateTime.now().subtract(const Duration(days: 49)),
        ),
        StationPriceItem(
          fuelGradeCode: '98',
          price: 148.00,
          lastUpdated: DateTime.now().subtract(const Duration(days: 10)),
        ),
        StationPriceItem(
          fuelGradeCode: 'D',
          price: 105.00,
          lastUpdated: DateTime.now().subtract(const Duration(days: 5)),
        ),
      ],
    ),
    StationInfo(
      id: 'bd_arunima',
      name: 'Arunima Filling Station',
      banglaName: 'অরুনিমা ফিলিং স্টেশন',
      address: 'Mirpur Road, Kalyanpur, Dhaka',
      location: const LatLng(23.7798, 90.3582),
      distanceMeters: 1362,
      upvotes: 4,
      availableCategories: ['G', 'D', 'E'],
      prices: [
        StationPriceItem(
          fuelGradeCode: '95',
          price: 145.00,
          lastUpdated: DateTime.now().subtract(const Duration(days: 10)),
        ),
        StationPriceItem(
          fuelGradeCode: 'D',
          price: 105.00,
          lastUpdated: DateTime.now().subtract(const Duration(days: 10)),
        ),
      ],
    ),
    StationInfo(
      id: 'bd_csd_arunima',
      name: 'CSD Arunima Filling Station',
      banglaName: 'সিএসডি অরুনিমা ফিলিং',
      address: 'Dhaka Cantonment, Dhaka',
      location: const LatLng(23.8185, 90.3920),
      distanceMeters: 1362,
      upvotes: 5,
      availableCategories: ['G', 'D', 'E', 'CNG'],
      prices: [
        StationPriceItem(
          fuelGradeCode: '95',
          price: 145.00,
          lastUpdated: DateTime.now().subtract(const Duration(days: 5)),
        ),
        StationPriceItem(
          fuelGradeCode: '91',
          price: 141.00,
          lastUpdated: DateTime.now().subtract(const Duration(days: 5)),
        ),
      ],
    ),
    StationInfo(
      id: 'bd_shatak',
      name: 'Shatak Fuel Station',
      banglaName: 'শতক ফুয়েল স্টেশন',
      address: 'Progoti Sarani, Kuril, Dhaka',
      location: const LatLng(23.8152, 90.4248),
      distanceMeters: 1421,
      upvotes: 11,
      availableCategories: ['G', 'D', 'E', 'LPG'],
      prices: [
        StationPriceItem(
          fuelGradeCode: '95',
          price: 140.00,
          lastUpdated: DateTime.now().subtract(const Duration(days: 14)),
        ),
        StationPriceItem(
          fuelGradeCode: 'LPG',
          price: 70.00,
          lastUpdated: DateTime.now().subtract(const Duration(days: 3)),
        ),
      ],
    ),
    StationInfo(
      id: 'bd_clean_fuel',
      name: 'Clean Fuel CNG & Petrol Pump',
      banglaName: 'ক্লিন ফুয়েল সিএনজি ও পেট্রোল পাম্প',
      address: 'Kawran Bazar, Dhaka',
      location: const LatLng(23.7511, 90.3934),
      distanceMeters: 1850,
      upvotes: 32,
      availableCategories: ['G', 'D', 'E', 'CNG'],
      prices: [
        StationPriceItem(
          fuelGradeCode: '95',
          price: 125.00,
          lastUpdated: DateTime.now().subtract(const Duration(days: 1)),
        ),
        StationPriceItem(
          fuelGradeCode: 'CNG',
          price: 43.00,
          lastUpdated: DateTime.now().subtract(const Duration(days: 1)),
        ),
      ],
    ),
  ];

  /// Loads all stations, merges OSM nearby stations, and applies user overrides from SharedPreferences.
  Future<List<StationInfo>> getStations({LatLng? userLocation}) async {
    final prefs = await SharedPreferences.getInstance();

    // 1. Load user custom price overrides
    final rawOverrides = prefs.getString(_keyPriceOverrides);
    final Map<String, dynamic> priceOverrides = rawOverrides != null ? jsonDecode(rawOverrides) as Map<String, dynamic> : {};

    // 2. Load favorites and upvotes
    final List<String> favorites = prefs.getStringList(_keyFavorites) ?? [];
    final List<String> upvoted = prefs.getStringList(_keyUpvotes) ?? [];

    final center = userLocation ?? const LatLng(23.7925, 90.4078);

    // 3. Clone and enrich seed stations
    final list = _seedStations.map((station) {
      final distanceM = _distanceCalculator.as(
        LengthUnit.Meter,
        center,
        station.location,
      );

      // Check if price override exists for this station
      var stationPrices = List<StationPriceItem>.from(station.prices);
      if (priceOverrides.containsKey(station.id)) {
        final List<dynamic> overrideList = priceOverrides[station.id] as List<dynamic>;
        final overrides = overrideList.map((e) => StationPriceItem.fromJson(e as Map<String, dynamic>)).toList();
        
        // Merge or replace
        for (final ov in overrides) {
          final idx = stationPrices.indexWhere((p) => p.fuelGradeCode == ov.fuelGradeCode);
          if (idx != -1) {
            stationPrices[idx] = ov;
          } else {
            stationPrices.add(ov);
          }
        }
      }

      final isFav = favorites.contains(station.id);
      final isUp = upvoted.contains(station.id);
      final upvoteCount = station.upvotes + (isUp ? 1 : 0);

      return station.copyWith(
        distanceMeters: distanceM,
        prices: stationPrices,
        isFavorite: isFav,
        isUserUpvoted: isUp,
        upvotes: upvoteCount,
      );
    }).toList();

    // Sort initially by distance
    list.sort((a, b) => a.distanceMeters.compareTo(b.distanceMeters));
    return list;
  }

  /// Updates or adds a price for a specific fuel grade at a station.
  Future<void> updateStationPrice({
    required String stationId,
    required String fuelGradeCode,
    required double newPrice,
    String? updatedBy,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final rawOverrides = prefs.getString(_keyPriceOverrides);
    final Map<String, dynamic> priceOverrides = rawOverrides != null ? jsonDecode(rawOverrides) as Map<String, dynamic> : {};

    final List<dynamic> stationOverrideList = (priceOverrides[stationId] as List<dynamic>?) ?? [];
    final List<StationPriceItem> items = stationOverrideList
        .map((e) => StationPriceItem.fromJson(e as Map<String, dynamic>))
        .toList();

    final newEntry = StationPriceItem(
      fuelGradeCode: fuelGradeCode,
      price: newPrice,
      lastUpdated: DateTime.now(),
      updatedBy: updatedBy ?? 'User',
      isCrowdSourced: true,
    );

    final idx = items.indexWhere((p) => p.fuelGradeCode == fuelGradeCode);
    if (idx != -1) {
      items[idx] = newEntry;
    } else {
      items.add(newEntry);
    }

    priceOverrides[stationId] = items.map((e) => e.toJson()).toList();
    await prefs.setString(_keyPriceOverrides, jsonEncode(priceOverrides));
  }

  /// Toggles favorite status for a station.
  Future<bool> toggleFavorite(String stationId) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> favorites = prefs.getStringList(_keyFavorites) ?? [];
    final bool willBeFavorite;
    if (favorites.contains(stationId)) {
      favorites.remove(stationId);
      willBeFavorite = false;
    } else {
      favorites.add(stationId);
      willBeFavorite = true;
    }
    await prefs.setStringList(_keyFavorites, favorites);
    return willBeFavorite;
  }

  /// Toggles upvote/like for a station.
  Future<bool> toggleUpvote(String stationId) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> upvotes = prefs.getStringList(_keyUpvotes) ?? [];
    final bool willBeUpvoted;
    if (upvotes.contains(stationId)) {
      upvotes.remove(stationId);
      willBeUpvoted = false;
    } else {
      upvotes.add(stationId);
      willBeUpvoted = true;
    }
    await prefs.setStringList(_keyUpvotes, upvotes);
    return willBeUpvoted;
  }
}
