import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/services/mileage_calculation_service.dart';
import '../models/mileage_entry_model.dart';
import 'fuel_log_viewmodel.dart';

/// Currently selected fuel efficiency unit in the Mileage UI.
final selectedEfficiencyUnitProvider = StateProvider<EfficiencyUnit>((ref) {
  return EfficiencyUnit.kmPerLitre;
});

/// Processed list of mileage entry models watching raw vehicle logs.
final processedMileageEntriesProvider = Provider<List<MileageEntryModel>>((ref) {
  final logsAsync = ref.watch(vehicleLogsProvider);
  final logs = logsAsync.valueOrNull ?? [];
  return MileageCalculationService.instance.computeMileageEntries(logs);
});

/// Calculated summary stats for the active vehicle.
final mileageSummaryProvider = Provider<MileageVehicleSummary>((ref) {
  final entries = ref.watch(processedMileageEntriesProvider);
  return MileageCalculationService.instance.computeSummary(entries);
});
