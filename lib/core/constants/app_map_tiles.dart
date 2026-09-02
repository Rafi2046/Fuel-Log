import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

/// OpenStreetMap tiles — same source as [openstreetmap.org](https://www.openstreetmap.org).
abstract final class AppMapTiles {
  static const userAgentPackageName = 'com.example.fuel_log';

  /// Standard OSM raster tiles (XYZ).
  static const urlTemplate =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

  static const probeHosts = <String>[
    'tile.openstreetmap.org',
  ];

  /// Light neutral fill while tiles load (matches OSM, avoids black gaps).
  static const backgroundColor = Color(0xFFE8E4DA);
  static const minZoom = 9.0;
  static const maxZoom = 19.0;

  static TileLayer layer({
    int keepBuffer = 4,
    int panBuffer = 2,
    BuildContext? context,
    Key? key,
  }) {
    // headers MUST be mutable — TileLayer calls putIfAbsent('User-Agent').
    return TileLayer(
      key: key,
      urlTemplate: urlTemplate,
      userAgentPackageName: userAgentPackageName,
      maxNativeZoom: 19,
      maxZoom: maxZoom,
      // Retina simulation quadruples tile count; OSM allows only 2 parallel
      // connections — causes black gaps and choppy zoom on phones.
      retinaMode: false,
      keepBuffer: keepBuffer,
      panBuffer: panBuffer,
      tileDisplay: const TileDisplay.instantaneous(),
      tileProvider: NetworkTileProvider(
        headers: <String, String>{},
        silenceExceptions: true,
      ),
    );
  }

  static List<Widget> stackedLayers({
    int keepBuffer = 4,
    int panBuffer = 2,
    BuildContext? context,
    Key? key,
  }) {
    return [
      layer(
        keepBuffer: keepBuffer,
        panBuffer: panBuffer,
        context: context,
        key: key,
      ),
    ];
  }
}
