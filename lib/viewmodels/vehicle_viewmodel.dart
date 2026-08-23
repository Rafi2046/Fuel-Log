import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/database/app_database.dart';

/// App-wide Drift database instance.
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

/// Handles vehicle create / load operations.
class VehicleViewModel extends StateNotifier<AsyncValue<void>> {
  VehicleViewModel(this._db) : super(const AsyncData(null));

  final AppDatabase _db;

  Future<bool> addVehicle({
    required String type,
    required String name,
    String? model,
    required double startOdo,
    required double capacity,
    required String fuelType,
    required bool isElectric,
  }) async {
    state = const AsyncLoading();
    try {
      await _db.insertVehicle(
        VehiclesCompanion.insert(
          type: type,
          name: name,
          model: model == null || model.isEmpty
              ? const Value.absent()
              : Value(model),
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
}

final vehicleProvider =
    StateNotifierProvider<VehicleViewModel, AsyncValue<void>>((ref) {
  return VehicleViewModel(ref.watch(databaseProvider));
});
