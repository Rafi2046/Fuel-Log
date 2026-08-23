import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/database/app_database.dart';
import 'vehicle_viewmodel.dart';

/// Fuel / charge logs for the active vehicle (newest first).
final vehicleLogsProvider = StreamProvider<List<FuelLog>>((ref) {
  final vehicle = ref.watch(activeVehicleProvider).valueOrNull;
  if (vehicle == null) {
    return Stream<List<FuelLog>>.value(const []);
  }
  return ref.watch(databaseProvider).watchLogsForVehicle(vehicle.id);
});

/// Handles fuel / charge log inserts.
class FuelLogViewModel extends StateNotifier<AsyncValue<void>> {
  FuelLogViewModel(this._db) : super(const AsyncData(null));

  final AppDatabase _db;

  Future<bool> addFuelLog({
    required int vehicleId,
    required DateTime date,
    required double odometer,
    required double amount,
    required double cost,
    required bool isFullTank,
    String? note,
  }) async {
    state = const AsyncLoading();
    try {
      await _db.insertFuelLog(
        FuelLogsCompanion.insert(
          vehicleId: vehicleId,
          date: date,
          odometer: odometer,
          amount: amount,
          cost: cost,
          isFullTank: Value(isFullTank),
          note: note == null || note.isEmpty
              ? const Value.absent()
              : Value(note),
        ),
      );
      state = const AsyncData(null);
      return true;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      return false;
    }
  }

  Future<void> deleteFuelLog(int id) async {
    await _db.deleteFuelLog(id);
  }
}

final fuelLogProvider =
    StateNotifierProvider<FuelLogViewModel, AsyncValue<void>>((ref) {
  return FuelLogViewModel(ref.watch(databaseProvider));
});
