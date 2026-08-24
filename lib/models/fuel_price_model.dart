import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

/// Supported fuel types and octane ratings in Bangladesh and global standards.
enum FuelTypeGrade {
  octane95(
    code: '95',
    label: 'Octane (95)',
    shortCode: 'Octane',
    category: 'E',
    badgeColor: Color(0xFF262632),
    defaultBpcPrice: 125.00,
    unit: '৳/L',
  ),
  octane98(
    code: '98',
    label: 'Octane (98)',
    shortCode: 'Octane',
    category: 'E',
    badgeColor: Color(0xFF262632),
    defaultBpcPrice: 130.00,
    unit: '৳/L',
  ),
  petrol91(
    code: '91',
    label: 'Petrol (91)',
    shortCode: 'Petrol',
    category: 'G',
    badgeColor: Color(0xFF262632),
    defaultBpcPrice: 121.00,
    unit: '৳/L',
  ),
  petrol89(
    code: '89',
    label: 'Petrol (89)',
    shortCode: 'Petrol',
    category: 'G',
    badgeColor: Color(0xFF262632),
    defaultBpcPrice: 121.00,
    unit: '৳/L',
  ),
  petrol87(
    code: '87',
    label: 'Petrol (87)',
    shortCode: 'Petrol',
    category: 'G',
    badgeColor: Color(0xFF262632),
    defaultBpcPrice: 121.00,
    unit: '৳/L',
  ),
  diesel(
    code: 'D',
    label: 'Diesel',
    shortCode: 'Diesel',
    category: 'D',
    badgeColor: Color(0xFF262632),
    defaultBpcPrice: 105.00,
    unit: '৳/L',
  ),
  cng(
    code: 'CNG',
    label: 'CNG',
    shortCode: 'CNG',
    category: 'CNG',
    badgeColor: Color(0xFF262632),
    defaultBpcPrice: 43.00,
    unit: '৳/m³',
  ),
  lpg(
    code: 'LPG',
    label: 'LPG AutoGas',
    shortCode: 'LPG',
    category: 'LPG',
    badgeColor: Color(0xFF262632),
    defaultBpcPrice: 68.50,
    unit: '৳/L',
  ),
  ev(
    code: 'EV',
    label: 'EV Fast Charging',
    shortCode: 'EV',
    category: 'EV',
    badgeColor: Color(0xFF262632),
    defaultBpcPrice: 18.50,
    unit: '৳/kWh',
  ),
  e85(
    code: 'E85',
    label: 'Ethanol E85',
    shortCode: 'E85',
    category: 'E',
    badgeColor: Color(0xFF262632),
    defaultBpcPrice: 124.90,
    unit: '৳/L',
  );

  const FuelTypeGrade({
    required this.code,
    required this.label,
    required this.shortCode,
    required this.category,
    required this.badgeColor,
    required this.defaultBpcPrice,
    required this.unit,
  });

  final String code;
  final String label;
  final String shortCode;
  final String category;
  final Color badgeColor;
  final double defaultBpcPrice;
  final String unit;

  static FuelTypeGrade fromCode(String code) {
    return FuelTypeGrade.values.firstWhere(
      (e) => e.code.toLowerCase() == code.toLowerCase() || e.shortCode.toLowerCase() == code.toLowerCase(),
      orElse: () => FuelTypeGrade.octane95,
    );
  }
}

/// Fuel price entry at a specific gas station
class StationPriceItem {
  final String fuelGradeCode;
  final double price;
  final DateTime lastUpdated;
  final String? updatedBy;
  final bool isCrowdSourced;

  const StationPriceItem({
    required this.fuelGradeCode,
    required this.price,
    required this.lastUpdated,
    this.updatedBy,
    this.isCrowdSourced = false,
  });

  FuelTypeGrade get grade => FuelTypeGrade.fromCode(fuelGradeCode);

  StationPriceItem copyWith({
    String? fuelGradeCode,
    double? price,
    DateTime? lastUpdated,
    String? updatedBy,
    bool? isCrowdSourced,
  }) {
    return StationPriceItem(
      fuelGradeCode: fuelGradeCode ?? this.fuelGradeCode,
      price: price ?? this.price,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      updatedBy: updatedBy ?? this.updatedBy,
      isCrowdSourced: isCrowdSourced ?? this.isCrowdSourced,
    );
  }

  Map<String, dynamic> toJson() => {
        'fuelGradeCode': fuelGradeCode,
        'price': price,
        'lastUpdated': lastUpdated.toIso8601String(),
        'updatedBy': updatedBy,
        'isCrowdSourced': isCrowdSourced,
      };

  factory StationPriceItem.fromJson(Map<String, dynamic> json) => StationPriceItem(
        fuelGradeCode: json['fuelGradeCode'] as String? ?? '95',
        price: (json['price'] as num?)?.toDouble() ?? 125.0,
        lastUpdated: json['lastUpdated'] != null
            ? DateTime.tryParse(json['lastUpdated'] as String) ?? DateTime.now()
            : DateTime.now(),
        updatedBy: json['updatedBy'] as String?,
        isCrowdSourced: json['isCrowdSourced'] as bool? ?? false,
      );
}

/// Rich Gas Station Model supporting Bangladesh & international filling stations
class StationInfo {
  final String id;
  final String name;
  final String? banglaName;
  final String address;
  final LatLng location;
  final double distanceMeters;
  final int upvotes;
  final bool isFavorite;
  final bool isUserUpvoted;
  final List<String> availableCategories; // ['G', 'D', 'E', 'LPG', 'CNG']
  final List<StationPriceItem> prices;
  final String? brand;
  final bool isOpen;

  const StationInfo({
    required this.id,
    required this.name,
    this.banglaName,
    required this.address,
    required this.location,
    this.distanceMeters = 1000,
    this.upvotes = 5,
    this.isFavorite = false,
    this.isUserUpvoted = false,
    required this.availableCategories,
    required this.prices,
    this.brand,
    this.isOpen = true,
  });

  /// Formatted display name prioritizing local/Bangla name if available
  String get displayName => banglaName ?? name;

  /// Primary representative fuel price (usually Octane 95 or Petrol 91)
  double get primaryPrice {
    final octane = prices.where((p) => p.fuelGradeCode == '95' || p.fuelGradeCode == '98');
    if (octane.isNotEmpty) return octane.first.price;
    if (prices.isNotEmpty) return prices.first.price;
    return 125.00;
  }

  /// Relative formatted distance (e.g. "1154m" or "2.4 km")
  String get formattedDistance {
    if (distanceMeters < 1000) {
      return '${distanceMeters.toInt()}m';
    }
    return '${(distanceMeters / 1000).toStringAsFixed(1)} km';
  }

  /// Most recent update relative string (e.g. "5 days ago", "Today")
  String get latestUpdateRelative {
    if (prices.isEmpty) return 'Recent';
    final newest = prices.reduce((curr, next) => curr.lastUpdated.isAfter(next.lastUpdated) ? curr : next);
    final diff = DateTime.now().difference(newest.lastUpdated);
    if (diff.inDays == 0) {
      if (diff.inHours == 0) return 'Just now';
      return '${diff.inHours}h ago';
    }
    if (diff.inDays == 1) return 'Yesterday';
    return '${diff.inDays} days ago';
  }

  StationInfo copyWith({
    String? id,
    String? name,
    String? banglaName,
    String? address,
    LatLng? location,
    double? distanceMeters,
    int? upvotes,
    bool? isFavorite,
    bool? isUserUpvoted,
    List<String>? availableCategories,
    List<StationPriceItem>? prices,
    String? brand,
    bool? isOpen,
  }) {
    return StationInfo(
      id: id ?? this.id,
      name: name ?? this.name,
      banglaName: banglaName ?? this.banglaName,
      address: address ?? this.address,
      location: location ?? this.location,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      upvotes: upvotes ?? this.upvotes,
      isFavorite: isFavorite ?? this.isFavorite,
      isUserUpvoted: isUserUpvoted ?? this.isUserUpvoted,
      availableCategories: availableCategories ?? this.availableCategories,
      prices: prices ?? this.prices,
      brand: brand ?? this.brand,
      isOpen: isOpen ?? this.isOpen,
    );
  }
}
