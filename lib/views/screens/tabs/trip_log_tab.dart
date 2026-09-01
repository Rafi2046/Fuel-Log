import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/services/gas_station_service.dart';
import '../../../core/services/navigation_routing_service.dart';
import '../../../core/services/reverse_geocoding_service.dart';
import '../../../core/utils/notification_service.dart';
import '../../../models/mock_gas_station.dart';
import '../../widgets/station_list_modal_sheet.dart';
import '../../widgets/trip_manual_entry_sheet.dart';
import '../../widgets/weather_drive_card.dart';
import 'dashboard_bottom_bar.dart';
import 'trip/widgets/active_navigation_bottom_bar.dart';
import 'trip/widgets/nearby_stations_carousel.dart';
import 'trip/widgets/navigation_top_hud.dart';
import 'trip/widgets/trip_default_fabs.dart';
import 'trip/widgets/trip_history_sheet.dart';
import 'trip/widgets/trip_map_action_chips.dart';
import 'trip/widgets/trip_map_markers.dart';
import 'trip/widgets/trip_map_zoom_controls.dart';
import 'trip/widgets/trip_stats_pill.dart';

export '../../../models/mock_gas_station.dart';

part 'trip/trip_log_map_layers.dart';
part 'trip/trip_log_map_view.dart';
part 'trip/trip_log_tab_controller.dart';

/// Map-centric trip logging — free OpenStreetMap tiles (no API key / card).
class TripLogTab extends StatefulWidget {
  const TripLogTab({super.key, this.isActive = true});

  final bool isActive;

  @override
  TripLogTabState createState() => TripLogTabState();
}

class TripLogTabState extends State<TripLogTab>
    with
        WidgetsBindingObserver,
        TickerProviderStateMixin,
        TripLogTabController,
        TripLogMapLayersMixin,
        TripLogMapViewMixin {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _mapController = MapController();
    _carouselController = PageController(viewportFraction: 0.86);

    if (widget.isActive) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _fetchLiveLocation();
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tripTimer?.cancel();
    _gpsPollingTimer?.cancel();
    _gpsStream?.cancel();
    NotificationService().cancelActiveTripNotification();
    _mapAnimController?.stop();
    _mapAnimController?.dispose();
    _mapAnimController = null;
    _mapController.dispose();
    _carouselController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    onTripAppLifecycle(state);
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isActive) {
      return const ColoredBox(color: Color(0xFF0F0F12));
    }
    return buildTripMapScaffold(context);
  }
}
