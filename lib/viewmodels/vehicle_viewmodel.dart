import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/database/app_database.dart';

/// App-wide Drift database instance.
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

/// Live list of all saved vehicles.
final vehiclesProvider = StreamProvider<List<Vehicle>>((ref) {
  return ref.watch(databaseProvider).watchAllVehicles();
});

/// Currently selected vehicle ID (optional, defaults to first vehicle in DB).
final selectedVehicleIdProvider = StateProvider<int?>((ref) => null);

/// Currently selected active vehicle — dynamically uses selectedVehicleIdProvider, fallback to first row.
final activeVehicleProvider = Provider<AsyncValue<Vehicle?>>((ref) {
  final selectedId = ref.watch(selectedVehicleIdProvider);
  return ref.watch(vehiclesProvider).whenData((vehicles) {
    if (vehicles.isEmpty) return null;
    if (selectedId != null) {
      final found = vehicles.where((v) => v.id == selectedId).firstOrNull;
      if (found != null) return found;
    }
    return vehicles.first;
  });
});

/// Handles vehicle create / load operations.
class VehicleViewModel extends StateNotifier<AsyncValue<void>> {
  VehicleViewModel(this._db) : super(const AsyncData(null));

  final AppDatabase _db;

  static const int maxVehicles = 3;

  Future<bool> addVehicle({
    required String type,
    required String name,
    String? model,
    String? brand,
    required double startOdo,
    required double capacity,
    required String fuelType,
    required bool isElectric,
  }) async {
    state = const AsyncLoading();
    try {
      final existing = await _db.vehicleCount();
      if (existing >= maxVehicles) {
        state = const AsyncData(null);
        return false;
      }
      await _db.insertVehicle(
        VehiclesCompanion.insert(
          type: type,
          name: name,
          model: model == null || model.isEmpty
              ? const Value.absent()
              : Value(model),
          brand: brand == null || brand.isEmpty
              ? const Value.absent()
              : Value(brand),
          startOdo: startOdo,
          capacity: capacity,
          fuelType: fuelType,
          isElectric: Value(isElectric),
        ),
      );
      state = const AsyncData(null);
      return true;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      return false;
    }
  }

  Future<bool> deleteVehicle(int id) async {
    state = const AsyncLoading();
    try {
      await _db.deleteVehicle(id);
      state = const AsyncData(null);
      return true;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      return false;
    }
  }
}

final vehicleProvider =
    StateNotifierProvider<VehicleViewModel, AsyncValue<void>>((ref) {
  return VehicleViewModel(ref.watch(databaseProvider));
});
