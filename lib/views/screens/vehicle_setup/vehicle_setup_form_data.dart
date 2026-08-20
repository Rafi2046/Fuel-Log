enum VehicleType { car, bike }

/// Local UI state for the vehicle setup form (ViewModel comes later).
class VehicleSetupFormData {
  VehicleType type = VehicleType.car;
  bool isDefault = true;
}
