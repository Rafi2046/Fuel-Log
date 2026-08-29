import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/database/app_database.dart';
import '../core/utils/notification_service.dart';
import '../models/reminder_model.dart';
import 'fuel_log_viewmodel.dart';
import 'service_log_viewmodel.dart';
import 'vehicle_viewmodel.dart';

/// State for vehicle maintenance reminders
class RemindersState {
  final bool isLoading;
  final List<ServiceReminder> reminders;
  final double currentOdometer;
  final String? error;

  const RemindersState({
    this.isLoading = false,
    this.reminders = const [],
    this.currentOdometer = 0.0,
    this.error,
  });

  List<ServiceReminder> get activeReminders =>
      reminders.where((r) => !r.isCompleted).toList();

  List<ServiceReminder> get completedReminders =>
      reminders.where((r) => r.isCompleted).toList();

  int get overdueCount => activeReminders
      .where((r) => r.status(currentOdometer) == ReminderStatus.overdue)
      .length;

  int get dueSoonCount => activeReminders
      .where((r) => r.status(currentOdometer) == ReminderStatus.dueSoon)
      .length;

  ServiceReminder? get engineOilReminder {
    try {
      return activeReminders
          .firstWhere((r) => r.serviceType == ServiceType.engineOil);
    } catch (_) {
      return null;
    }
  }

  /// Finds the most urgent service needing attention
  ServiceReminder? get mostUrgentReminder {
    if (activeReminders.isEmpty) return null;
    final sorted = List<ServiceReminder>.from(activeReminders)
      ..sort((a, b) {
        final aProg = a.healthProgress(currentOdometer);
        final bProg = b.healthProgress(currentOdometer);
        return aProg.compareTo(bProg);
      });
    return sorted.first;
  }

  /// Overall vehicle maintenance score (0.0 to 1.0)
  double get overallHealthScore {
    if (activeReminders.isEmpty) return 1.0;
    double total = 0.0;
    for (final r in activeReminders) {
      total += r.healthProgress(currentOdometer);
    }
    return (total / activeReminders.length).clamp(0.0, 1.0);
  }

  RemindersState copyWith({
    bool? isLoading,
    List<ServiceReminder>? reminders,
    double? currentOdometer,
    String? error,
  }) {
    return RemindersState(
      isLoading: isLoading ?? this.isLoading,
      reminders: reminders ?? this.reminders,
      currentOdometer: currentOdometer ?? this.currentOdometer,
      error: error,
    );
  }
}

/// StateNotifier managing vehicle reminders backed by Drift AppDatabase
class RemindersNotifier extends StateNotifier<RemindersState> {
  RemindersNotifier(this.ref) : super(const RemindersState()) {
    loadReminders();
  }

  final Ref ref;

  ServiceType _mapServiceType(String title) {
    final lower = title.toLowerCase();
    if (lower.contains('oil')) return ServiceType.engineOil;
    if (lower.contains('tire') || lower.contains('tyre')) {
      return ServiceType.tireRotation;
    }
    if (lower.contains('air') || lower.contains('filter')) {
      return ServiceType.airFilter;
    }
    if (lower.contains('brake')) return ServiceType.brakeFluid;
    if (lower.contains('spark') || lower.contains('plug')) {
      return ServiceType.sparkPlug;
    }
    if (lower.contains('coolant') || lower.contains('radiator')) {
      return ServiceType.coolant;
    }
    if (lower.contains('battery')) return ServiceType.battery;
    if (lower.contains('tax') || lower.contains('token')) {
      return ServiceType.taxToken;
    }
    if (lower.contains('insurance')) return ServiceType.insurance;
    if (lower.contains('service')) return ServiceType.generalService;
    return ServiceType.custom;
  }

  ServiceReminder _mapDriftToModel(Reminder r, double currentOdo) {
    final serviceType = _mapServiceType(r.title);

    final lastServiceOdo = r.intervalKm != null && r.targetOdometer != null
        ? r.targetOdometer! - r.intervalKm!
        : currentOdo;

    final lastServiceDate = r.targetDate != null
        ? r.targetDate!.subtract(const Duration(days: 90))
        : DateTime.now();

    return ServiceReminder(
      id: r.id.toString(),
      vehicleId: r.vehicleId,
      title: r.title,
      serviceType: serviceType,
      lastServiceOdo: lastServiceOdo,
      lastServiceDate: lastServiceDate,
      intervalKm: r.intervalKm,
      targetOdo: r.targetOdometer,
      targetDate: r.targetDate,
      isCompleted: r.isCompleted,
    );
  }

  Future<void> loadReminders() async {
    final vehicle = ref.read(activeVehicleProvider).valueOrNull;
    if (vehicle == null) {
      state = state.copyWith(isLoading: false, reminders: const []);
      return;
    }

    final logs = ref.read(vehicleLogsProvider).valueOrNull ?? const [];
    final currentOdo =
        logs.isNotEmpty ? logs.first.odometer : vehicle.startOdo;

    state = state.copyWith(
        isLoading: true, currentOdometer: currentOdo, error: null);

    try {
      final db = ref.read(databaseProvider);
      final driftList = await db.getRemindersForVehicle(vehicle.id);
      final mappedList =
          driftList.map((r) => _mapDriftToModel(r, currentOdo)).toList();
      state = state.copyWith(
        isLoading: false,
        reminders: mappedList,
        currentOdometer: currentOdo,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> deleteReminder(String id) async {
    final numId = int.tryParse(id);
    if (numId != null) {
      final db = ref.read(databaseProvider);
      await db.deleteReminder(numId);
    }
    await loadReminders();
  }

  Future<void> markAsDone(String id, {double? cost, String? notes}) async {
    final numId = int.tryParse(id);
    if (numId == null) return;

    final vehicle = ref.read(activeVehicleProvider).valueOrNull;
    if (vehicle == null) return;

    final db = ref.read(databaseProvider);
    final existing = await db.getReminderById(numId);
    if (existing == null) return;

    final currentOdo = state.currentOdometer;
    final now = DateTime.now();

    await db.markReminderCompleted(numId);
    await NotificationService().cancelNotification(numId);

    if (cost != null && cost > 0) {
      await ref.read(serviceLogServiceProvider).addServiceLog(
            vehicleId: vehicle.id,
            date: now,
            category: 'Maintenance',
            title: existing.title,
            cost: cost,
            odometer: currentOdo,
            note: notes,
          );
    }

    double? newTargetOdo;
    if (existing.intervalKm != null) {
      newTargetOdo = currentOdo + existing.intervalKm!;
    } else if (existing.targetOdometer != null) {
      final priorSpan = existing.targetOdometer! - currentOdo;
      newTargetOdo = currentOdo + (priorSpan > 0 ? priorSpan : 5000);
    }

    DateTime? newTargetDate;
    if (existing.targetDate != null) {
      var next = DateTime(
        existing.targetDate!.year + 1,
        existing.targetDate!.month,
        existing.targetDate!.day,
      );
      while (!next.isAfter(now)) {
        next = DateTime(next.year + 1, next.month, next.day);
      }
      newTargetDate = next;
    }

    final newId = await db.insertReminder(
      RemindersCompanion.insert(
        vehicleId: existing.vehicleId,
        title: existing.title,
        targetDate: newTargetDate != null
            ? Value(newTargetDate)
            : const Value.absent(),
        targetOdometer: newTargetOdo != null
            ? Value(newTargetOdo)
            : const Value.absent(),
        oilType: existing.oilType != null
            ? Value(existing.oilType!)
            : const Value.absent(),
        intervalKm: existing.intervalKm != null
            ? Value(existing.intervalKm!)
            : const Value.absent(),
      ),
    );

    if (newTargetDate != null) {
      await NotificationService().scheduleNotification(
        id: newId,
        title: existing.title,
        scheduledDate: newTargetDate,
        body: 'Maintenance Due Today: ${existing.title}',
      );
    }

    await loadReminders();
  }
}

/// Provider for RemindersNotifier
final remindersProvider =
    StateNotifierProvider<RemindersNotifier, RemindersState>((ref) {
  final notifier = RemindersNotifier(ref);
  // Auto-reload when active vehicle or fuel logs change
  ref.listen(activeVehicleProvider, (_, _) => notifier.loadReminders());
  ref.listen(vehicleLogsProvider, (_, _) => notifier.loadReminders());
  return notifier;
});
