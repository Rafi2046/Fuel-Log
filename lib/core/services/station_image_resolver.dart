import 'package:latlong2/latlong.dart';

/// Picks the best available thumbnail for a fuel station.
abstract final class StationImageResolver {
  static const _assets = [
    'assets/images/station_city_express.jpg',
    'assets/images/station_trust.jpg',
    'assets/images/station_navana.jpg',
    'assets/images/station_meghna.jpg',
    'assets/images/station_padma.jpg',
    'assets/images/station_clean_fuel.jpg',
  ];

  /// Returns a local asset path or remote image URL.
  static String resolve({
    required String name,
    required String fuelTypes,
    Map<String, dynamic>? osmTags,
    LatLng? location,
  }) {
    if (osmTags != null) {
      final fromOsm = _fromOsmTags(osmTags);
      if (fromOsm != null) return fromOsm;
    }

    final fromBrand = _fromBrandKeywords(name, fuelTypes);
    if (fromBrand != null) return fromBrand;

    return _hashAsset('$name|${location?.latitude}|${location?.longitude}');
  }

  static String? _fromOsmTags(Map<String, dynamic> tags) {
    for (final key in ['image', 'image:url', 'photo', 'logo', 'image:0']) {
      final value = tags[key]?.toString().trim() ?? '';
      if (value.startsWith('http')) return value;
    }

    final wiki = tags['wikimedia_commons'] ?? tags['brand:wikimedia'];
    if (wiki != null && wiki.toString().trim().isNotEmpty) {
      final file = wiki
          .toString()
          .trim()
          .replaceFirst(RegExp(r'^File:', caseSensitive: false), '');
      return 'https://commons.wikimedia.org/wiki/Special:FilePath/'
          '${Uri.encodeComponent(file)}?width=320';
    }

    return null;
  }

  static String? _fromBrandKeywords(String name, String fuelTypes) {
    final lower = name.toLowerCase();
    final fuels = fuelTypes.toLowerCase();

    if (lower.contains('trust') || lower.contains('csd')) {
      return 'assets/images/station_trust.jpg';
    }
    if (lower.contains('navana') ||
        lower.contains('skamco') ||
        lower.contains('minerva') ||
        lower.contains('sam associates')) {
      return 'assets/images/station_navana.jpg';
    }
    if (lower.contains('meghna') ||
        lower.contains('chittagong') ||
        lower.contains('sumatra') ||
        lower.contains('sumita') ||
        lower.contains('sobahan')) {
      return 'assets/images/station_meghna.jpg';
    }
    if (lower.contains('padma') ||
        lower.contains('purbachal') ||
        lower.contains('diganta') ||
        lower.contains('shatabdi') ||
        lower.contains('shahjalal')) {
      return 'assets/images/station_padma.jpg';
    }
    if (lower.contains('clean') ||
        lower.contains('green') ||
        lower.contains('omera') ||
        lower.contains('comfort') ||
        lower.contains('denso') ||
        lower.contains('intraco') ||
        fuels.contains('ev')) {
      return 'assets/images/station_clean_fuel.jpg';
    }
    if (lower.contains('chairmanbari') ||
        lower.contains('gulshan service') ||
        lower.contains('arunima') ||
        lower.contains('eureka')) {
      return 'assets/images/station_city_express.jpg';
    }

    if (fuels.contains('cng') && !fuels.contains('octane')) {
      return 'assets/images/station_clean_fuel.jpg';
    }
    if (fuels.contains('lpg')) {
      return 'assets/images/station_meghna.jpg';
    }

    return null;
  }

  static String _hashAsset(String seed) {
    final index = seed.hashCode.abs() % _assets.length;
    return _assets[index];
  }
}
