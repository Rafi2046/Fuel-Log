import '../../views/screens/setup_widgets/vehicle_identity_step.dart';

/// Shared energy-type options used across setup / logging UI.
abstract final class FuelOptions {
  static const String electric = 'Electric (EV)';

  static const List<String> forCar = [
    'Petrol',
    'Diesel',
    'Octane',
    'CNG',
    electric,
  ];

  static const List<String> forBike = [
    'Petrol',
    'Octane',
    'CNG',
    electric,
  ];

  static List<String> forVehicleType(VehicleType type) =>
      type == VehicleType.car ? forCar : forBike;

  static bool isElectric(String fuelType) => fuelType == electric;
}
