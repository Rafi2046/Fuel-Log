import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/services/reverse_geocoding_service.dart';
import '../../models/mock_gas_station.dart';

class PickedTripLocation {
  const PickedTripLocation({required this.point, required this.label});

  final LatLng point;
  final String label;
}

Future<PickedTripLocation?> showTripLocationPicker(
  BuildContext context, {
  required String title,
  LatLng? initial,
}) {
  return Navigator.of(context).push<PickedTripLocation>(
    MaterialPageRoute(
      builder: (_) => TripLocationPickerPage(title: title, initial: initial),
    ),
  );
}

class TripLocationPickerPage extends StatefulWidget {
  const TripLocationPickerPage({
    super.key,
    required this.title,
    this.initial,
  });

  final String title;
  final LatLng? initial;

  @override
  State<TripLocationPickerPage> createState() => _TripLocationPickerPageState();
}

class _TripLocationPickerPageState extends State<TripLocationPickerPage> {
  final _mapController = MapController();
  final _searchCtrl = TextEditingController();
  late LatLng _center;
  var _zoom = 15.0;
  var _searching = false;
  var _confirming = false;
  List<GeocodedPlace> _results = const [];

  @override
  void initState() {
    super.initState();
    _center = widget.initial ?? kDefaultUserLocation;
    if (widget.initial == null) {
      _goToGps(moveMap: false);
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _goToGps({bool moveMap = true}) async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }
      final last = await Geolocator.getLastKnownPosition();
      final pos = last ??
          await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.medium,
              timeLimit: Duration(seconds: 3),
            ),
          );
      final point = LatLng(pos.latitude, pos.longitude);
      if (!mounted) return;
      setState(() => _center = point);
      if (moveMap) {
        try {
          _mapController.move(point, 16);
        } catch (_) {}
      }
    } catch (_) {}
  }

  Future<void> _runSearch(String query) async {
    final q = query.trim();
    if (q.length < 2) return;
    setState(() => _confirming = true);
    try {
      final results = await ReverseGeocodingService.search(q);
      if (!mounted) return;
      if (results.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('locationNotFound'.tr()),
            behavior: SnackBarBehavior.floating,
          ),
        );
        setState(() => _results = const []);
        return;
      }
      setState(() => _results = results);
      await _goToPlace(results.first);
    } finally {
      if (mounted) setState(() => _confirming = false);
    }
  }

  Future<void> _goToPlace(GeocodedPlace place) async {
    setState(() => _center = place.point);
    try {
      _mapController.move(place.point, 15.4);
    } catch (_) {}
  }

  Future<void> _onCheckPressed() async {
    if (_searching && _searchCtrl.text.trim().length >= 2) {
      await _runSearch(_searchCtrl.text);
      if (!mounted) return;
      setState(() {
        _searching = false;
        _results = const [];
      });
    }
    await _confirm();
  }

  Future<void> _confirm() async {
    if (_confirming) return;
    setState(() => _confirming = true);
    try {
      final point = _center;
      final label = await ReverseGeocodingService.resolveLabel(point);
      if (!mounted) return;
      Navigator.of(context).pop(
        PickedTripLocation(
          point: point,
          label: (label != null && label.isNotEmpty)
              ? label
              : '${point.latitude.toStringAsFixed(5)}, ${point.longitude.toStringAsFixed(5)}',
        ),
      );
    } finally {
      if (mounted) setState(() => _confirming = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F12),
      appBar: AppBar(
        backgroundColor: const Color(0xFF14141B),
        foregroundColor: AppColors.textPrimary,
        title: _searching
            ? TextField(
                controller: _searchCtrl,
                autofocus: true,
                style: AppTextStyles.body,
                cursorColor: AppColors.primary,
                decoration: InputDecoration(
                  hintText: 'searchLocation'.tr(),
                  hintStyle: AppTextStyles.bodySecondary,
                  border: InputBorder.none,
                ),
                textInputAction: TextInputAction.search,
                onSubmitted: _runSearch,
                onChanged: (_) {},
              )
            : Text(widget.title),
        actions: [
          IconButton(
            icon: Icon(_searching ? Icons.close_rounded : Icons.search_rounded),
            onPressed: () {
              setState(() {
                _searching = !_searching;
                if (!_searching) {
                  _results = const [];
                  _searchCtrl.clear();
                }
              });
            },
          ),
          IconButton(
            onPressed: _confirming ? null : _onCheckPressed,
            icon: _confirming
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check_rounded, color: AppColors.primary),
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _center,
              initialZoom: _zoom,
              minZoom: 8.5,
              maxZoom: 18,
              backgroundColor: const Color(0xFF0F0F12),
              onPositionChanged: (camera, _) {
                _zoom = camera.zoom;
                _center = camera.center;
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.fuel_log',
                retinaMode: false,
                tileBuilder: (context, tileWidget, tile) {
                  return ColorFiltered(
                    colorFilter: const ColorFilter.matrix(<double>[
                      -0.2126, -0.7152, -0.0722, 0, 255,
                      -0.2126, -0.7152, -0.0722, 0, 255,
                      -0.2126, -0.7152, -0.0722, 0, 255,
                      0, 0, 0, 1, 0,
                    ]),
                    child: tileWidget,
                  );
                },
              ),
            ],
          ),
          const IgnorePointer(
            child: Center(
              child: Padding(
                padding: EdgeInsets.only(bottom: 36),
                child: Icon(
                  Icons.location_on_rounded,
                  size: 44,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          Positioned(
            right: 14,
            top: 14,
            child: Column(
              children: [
                _MapRoundButton(
                  icon: Icons.my_location_rounded,
                  onTap: () => _goToGps(),
                ),
                const SizedBox(height: 8),
                _MapRoundButton(
                  icon: Icons.add,
                  onTap: () {
                    try {
                      _mapController.move(
                        _mapController.camera.center,
                        (_mapController.camera.zoom + 1).clamp(8.5, 18),
                      );
                    } catch (_) {}
                  },
                ),
                _MapRoundButton(
                  icon: Icons.remove,
                  onTap: () {
                    try {
                      _mapController.move(
                        _mapController.camera.center,
                        (_mapController.camera.zoom - 1).clamp(8.5, 18),
                      );
                    } catch (_) {}
                  },
                ),
              ],
            ),
          ),
          if (_results.isNotEmpty)
            Positioned(
              left: 12,
              right: 12,
              top: 8,
              child: Material(
                color: const Color(0xFF1A1A22),
                borderRadius: BorderRadius.circular(12),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _results.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final place = _results[i];
                    return ListTile(
                      dense: true,
                      title: Text(
                        place.label,
                        style: AppTextStyles.body.copyWith(fontSize: 13),
                      ),
                      onTap: () {
                        _goToPlace(place);
                        setState(() {
                          _results = const [];
                          _searching = false;
                          _searchCtrl.clear();
                        });
                      },
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MapRoundButton extends StatelessWidget {
  const _MapRoundButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF18181F).withValues(alpha: 0.94),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, size: 18, color: AppColors.textPrimary),
        ),
      ),
    );
  }
}
