import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/database/app_database.dart';
import 'vehicle_viewmodel.dart';

/// Stream provider watching all trip logs for the currently active vehicle (ordered by started_at descending).
final vehicleTripsProvider = StreamProvider<List<TripLog>>((ref) {
  final vehicle = ref.watch(activeVehicleProvider).valueOrNull;
  if (vehicle == null) {
    return Stream.value(const []);
  }
  final db = ref.watch(databaseProvider);
  return db.watchTripLogsForVehicle(vehicle.id);
});

/// ViewModel managing trip log persistence and operations.
class TripLogViewModel extends StateNotifier<AsyncValue<void>> {
  TripLogViewModel(this._db) : super(const AsyncData(null));

  final AppDatabase _db;

  Future<void> addTrip(TripLogsCompanion trip) async {
    state = const AsyncLoading();
    try {
      await _db.insertTripLog(trip);
      state = const AsyncData(null);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }

  Future<void> deleteTrip(int id) async {
    state = const AsyncLoading();
    try {
      await _db.deleteTripLog(id);
      state = const AsyncData(null);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }
}

final tripLogProvider =
    StateNotifierProvider<TripLogViewModel, AsyncValue<void>>((ref) {
  return TripLogViewModel(ref.watch(databaseProvider));
});
