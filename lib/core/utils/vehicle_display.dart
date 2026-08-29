import 'package:flutter/material.dart';

import '../database/app_database.dart';

/// Shared vehicle icon / type helpers for garage, home bar, etc.
abstract final class VehicleDisplay {
  static bool isBike(Vehicle vehicle) {
    final type = vehicle.type.toLowerCase().trim();
    if (type == 'bike' ||
        type.contains('bike') ||
        type.contains('motorcycle') ||
        type.contains('scooter')) {
      return true;
    }
    final name = vehicle.name.toLowerCase();
    return name.contains('bike') ||
        name.contains('r15') ||
        name.contains('scooter') ||
        name.contains('motorcycle');
  }

  static IconData iconFor(Vehicle vehicle) {
    return isBike(vehicle)
        ? Icons.two_wheeler_rounded
        : Icons.directions_car_filled_rounded;
  }
}
