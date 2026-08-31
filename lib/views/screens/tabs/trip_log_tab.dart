import 'dart:async';
import 'dart:convert';

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
import 'trip/widgets/trip_list_view.dart';
import 'trip/widgets/trip_map_action_chips.dart';
import 'trip/widgets/trip_map_markers.dart';
import 'trip/widgets/trip_map_zoom_controls.dart';
import 'trip/widgets/trip_stats_pill.dart';
import 'trip/widgets/trip_summary_card.dart';

export '../../../models/mock_gas_station.dart';

part 'trip/trip_log_tab_controller.dart';
part 'trip/trip_log_map_layers.dart';
part 'trip/trip_log_map_view.dart';

/// Map-centric trip logging — free OpenStreetMap tiles (no API key / card).
class TripLogTab extends StatefulWidget {
  const TripLogTab({super.key, this.isActive = true});

  final bool isActive;

  @override
  TripLogTabState createState() => TripLogTabState();
}

class TripLogTabState extends State<TripLogTab>
    with
        TickerProviderStateMixin,
        TripLogTabController,
        TripLogMapLayersMixin,
        TripLogMapViewMixin {
  @override
  Widget build(BuildContext context) {
    if (!widget.isActive) {
      return const ColoredBox(color: Color(0xFF0F0F12));
    }
    return buildTripMapScaffold(context);
  }
}
