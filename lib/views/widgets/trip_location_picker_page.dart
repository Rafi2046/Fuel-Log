import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_map_tiles.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/services/reverse_geocoding_service.dart';
import '../../models/mock_gas_station.dart';
import 'app_app_bar.dart';

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

  bool get _canMoveMap {
    if (!mounted) return false;
    try {
      final camera = _mapController.camera;
      final size = camera.nonRotatedSize;
      if (!size.isFinite || size.width <= 0 || size.height <= 0) return false;
      return camera.zoom.isFinite &&
          camera.center.latitude.isFinite &&
          camera.center.longitude.isFinite;
    } catch (_) {
      return false;
    }
  }

  void _safeMoveMap(LatLng center, double zoom) {
    if (!center.latitude.isFinite ||
        !center.longitude.isFinite ||
        !zoom.isFinite) {
      return;
    }
    final clampedZoom = zoom.clamp(AppMapTiles.minZoom, AppMapTiles.maxZoom);
    _center = center;
    _zoom = clampedZoom;
    if (!_canMoveMap) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_canMoveMap) {
          try {
            _mapController.move(center, clampedZoom);
          } catch (_) {}
        }
      });
      return;
    }
    try {
      _mapController.move(center, clampedZoom);
    } catch (_) {}
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
      final pos = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.medium,
              timeLimit: Duration(seconds: 3),
            ),
          );
      final point = LatLng(pos.latitude, pos.longitude);
      if (!mounted) return;
      setState(() => _center = point);
      if (moveMap) {
        _safeMoveMap(point, 16);
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
    _safeMoveMap(place.point, 15.4);
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
      appBar: AppAppBar(
        leading: const AppBackButton(),
        titleWidget: _searching
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
              initialZoom: _zoom.clamp(AppMapTiles.minZoom, AppMapTiles.maxZoom),
              minZoom: AppMapTiles.minZoom,
              maxZoom: AppMapTiles.maxZoom,
              backgroundColor: AppMapTiles.backgroundColor,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.drag |
                    InteractiveFlag.flingAnimation |
                    InteractiveFlag.pinchMove |
                    InteractiveFlag.pinchZoom |
                    InteractiveFlag.rotate |
                    InteractiveFlag.doubleTapZoom,
              ),
              onPositionChanged: (camera, _) {
                _zoom = camera.zoom;
                _center = camera.center;
              },
            ),
            children: [
              ...AppMapTiles.stackedLayers(context: context),
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
                    if (!_canMoveMap) return;
                    final cam = _mapController.camera;
                    _safeMoveMap(cam.center, cam.zoom + 1);
                  },
                ),
                _MapRoundButton(
                  icon: Icons.remove,
                  onTap: () {
                    if (!_canMoveMap) return;
                    final cam = _mapController.camera;
                    _safeMoveMap(cam.center, cam.zoom - 1);
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
