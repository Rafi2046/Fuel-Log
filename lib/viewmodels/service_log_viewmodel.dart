import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/database/app_database.dart';
import 'vehicle_viewmodel.dart';

/// Stream provider watching all non-fuel service logs for the active vehicle
final serviceLogsProvider = StreamProvider<List<ServiceLog>>((ref) {
  final vehicle = ref.watch(activeVehicleProvider).valueOrNull;
  if (vehicle == null) {
    return Stream.value([]);
  }
  final db = ref.watch(databaseProvider);
  return db.watchServiceLogsForVehicle(vehicle.id);
});

/// Helper class for adding/deleting service logs
class ServiceLogService {
  ServiceLogService(this.ref);
  final Ref ref;

  Future<int> addServiceLog({
    required int vehicleId,
    required DateTime date,
    required String category,
    required String title,
    required double cost,
    double? odometer,
    String? note,
  }) async {
    final db = ref.read(databaseProvider);
    return db.insertServiceLog(
      ServiceLogsCompanion.insert(
        vehicleId: vehicleId,
        date: date,
        category: category,
        title: title,
        cost: cost,
        odometer: Value(odometer),
        note: Value(note),
      ),
    );
  }

  Future<int> deleteServiceLog(int id) async {
    final db = ref.read(databaseProvider);
    return db.deleteServiceLog(id);
  }
}

final serviceLogServiceProvider = Provider<ServiceLogService>((ref) {
  return ServiceLogService(ref);
});
