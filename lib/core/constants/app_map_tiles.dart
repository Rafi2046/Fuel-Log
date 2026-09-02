import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

/// OpenStreetMap tiles — same source as [openstreetmap.org](https://www.openstreetmap.org).
abstract final class AppMapTiles {
  static const userAgentPackageName = 'com.example.fuel_log';

  static const urlTemplate =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

  static const probeHosts = <String>[
    'tile.openstreetmap.org',
  ];

  /// Shown only while tiles load (not the final map colour).
  static const backgroundColor = Color(0xFF1A1D24);

  static const minZoom = 9.0;
  static const maxZoom = 19.0;

  /// Soft darken so OSM stays readable but fits the dark app chrome.
  static Widget osmSoftDarkTileBuilder(
    BuildContext context,
    Widget tileWidget,
    TileImage tile,
  ) {
    return ColorFiltered(
      colorFilter: const ColorFilter.mode(
        Color(0xFF2A3040),
        BlendMode.darken,
      ),
      child: tileWidget,
    );
  }

  static TileLayer layer({
    int keepBuffer = 4,
    int panBuffer = 2,
    BuildContext? context,
    Key? key,
    bool softDark = false,
  }) {
    return TileLayer(
      key: key,
      urlTemplate: urlTemplate,
      userAgentPackageName: userAgentPackageName,
      minZoom: minZoom,
      maxZoom: maxZoom,
      minNativeZoom: 0,
      maxNativeZoom: 19,
      retinaMode: false,
      keepBuffer: keepBuffer,
      panBuffer: panBuffer,
      tileDisplay: const TileDisplay.instantaneous(),
      tileBuilder: softDark ? osmSoftDarkTileBuilder : null,
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
    bool softDark = false,
  }) {
    return [
      layer(
        keepBuffer: keepBuffer,
        panBuffer: panBuffer,
        context: context,
        key: key,
        softDark: softDark,
      ),
    ];
  }
}
