import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Live Bangladesh fuel rates (govt / BPC administered — same at every pump).
class BdFuelRates {
  const BdFuelRates({
    required this.octane,
    required this.petrol,
    required this.diesel,
    required this.kerosene,
    required this.updatedAt,
    this.fromNetwork = false,
    this.sourceLabel = 'BPC fallback',
  });

  /// Safe offline defaults (Aug 2026 BPC baseline).
  factory BdFuelRates.fallback() => BdFuelRates(
        octane: 145,
        petrol: 140,
        diesel: 115,
        kerosene: 135,
        updatedAt: DateTime.now(),
        fromNetwork: false,
        sourceLabel: 'BPC fallback',
      );

  final double octane;
  final double petrol;
  final double diesel;
  final double kerosene;
  final DateTime updatedAt;
  final bool fromNetwork;
  final String sourceLabel;

  Map<String, dynamic> toJson() => {
        'octane': octane,
        'petrol': petrol,
        'diesel': diesel,
        'kerosene': kerosene,
        'updatedAt': updatedAt.toIso8601String(),
        'sourceLabel': sourceLabel,
      };

  factory BdFuelRates.fromJson(Map<String, dynamic> json) {
    return BdFuelRates(
      octane: (json['octane'] as num?)?.toDouble() ?? 145,
      petrol: (json['petrol'] as num?)?.toDouble() ?? 140,
      diesel: (json['diesel'] as num?)?.toDouble() ?? 115,
      kerosene: (json['kerosene'] as num?)?.toDouble() ?? 135,
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.now(),
      fromNetwork: false,
      sourceLabel: json['sourceLabel'] as String? ?? 'cached',
    );
  }
}

/// Fetches BD retail fuel prices (OpenVan free API, BPC-sourced) and caches them.
class BdFuelRateService {
  BdFuelRateService._();
  static final BdFuelRateService instance = BdFuelRateService._();

  static const _cacheKey = 'bd_fuel_rates_v1';
  static const _url =
      'https://openvan.camp/api/fuel/prices?source=fuel_log_app';

  BdFuelRates _current = BdFuelRates.fallback();
  bool _loaded = false;

  BdFuelRates get current => _current;
  double get octane => _current.octane;
  double get petrol => _current.petrol;
  double get diesel => _current.diesel;

  /// Load cache once, then refresh from network when needed.
  Future<BdFuelRates> ensureLoaded({bool forceRefresh = false}) async {
    if (!_loaded) {
      await _loadCache();
      _loaded = true;
    }
    if (forceRefresh || _isStale) {
      await refresh();
    }
    return _current;
  }

  bool get _isStale {
    final age = DateTime.now().difference(_current.updatedAt);
    return age.inHours >= 12;
  }

  Future<void> _loadCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_cacheKey);
      if (raw == null) return;
      _current = BdFuelRates.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } catch (_) {}
  }

  Future<void> _saveCache(BdFuelRates rates) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKey, jsonEncode(rates.toJson()));
    } catch (_) {}
  }

  /// Pull latest BD rates from OpenVan (no API key). Falls back to cache/defaults.
  Future<BdFuelRates> refresh() async {
    try {
      final res = await http
          .get(Uri.parse(_url))
          .timeout(const Duration(seconds: 12));
      if (res.statusCode != 200) return _current;

      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>?;
      final bd = data?['BD'] as Map<String, dynamic>?;
      if (bd == null) return _current;

      final prices = bd['prices'] as Map<String, dynamic>? ?? {};
      final sources = (bd['sources'] as List?)?.cast<String>() ?? const [];

      // OpenVan maps: gasoline=Petrol, gasoline_premium/premium=Octane
      final octane = (prices['gasoline_premium'] as num?)?.toDouble() ??
          (prices['premium'] as num?)?.toDouble() ??
          _current.octane;
      final petrol =
          (prices['gasoline'] as num?)?.toDouble() ?? _current.petrol;
      final diesel = (prices['diesel'] as num?)?.toDouble() ?? _current.diesel;
      final kerosene =
          (prices['kerosene'] as num?)?.toDouble() ?? _current.kerosene;

      final fetchedAt = DateTime.tryParse(bd['fetched_at'] as String? ?? '') ??
          DateTime.now();

      _current = BdFuelRates(
        octane: octane,
        petrol: petrol,
        diesel: diesel,
        kerosene: kerosene,
        updatedAt: fetchedAt,
        fromNetwork: true,
        sourceLabel: sources.isNotEmpty ? sources.first : 'OpenVan.camp',
      );
      await _saveCache(_current);
    } catch (_) {
      // Keep cache / fallback — offline OK.
    }
    return _current;
  }
}
