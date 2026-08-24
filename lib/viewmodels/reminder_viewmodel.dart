import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/services/reminder_repository.dart';
import '../models/reminder_model.dart';
import 'fuel_log_viewmodel.dart';
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

/// StateNotifier managing vehicle reminders
class RemindersNotifier extends StateNotifier<RemindersState> {
  RemindersNotifier(this.ref) : super(const RemindersState()) {
    loadReminders();
  }

  final Ref ref;
  final _repo = ReminderRepository.instance;

  Future<void> loadReminders() async {
    final vehicle = ref.read(activeVehicleProvider).valueOrNull;
    if (vehicle == null) {
      state = state.copyWith(isLoading: false, reminders: const []);
      return;
    }

    final logs = ref.read(vehicleLogsProvider).valueOrNull ?? const [];
    final currentOdo = logs.isNotEmpty ? logs.first.odometer : vehicle.startOdo;

    final type = vehicle.type.toLowerCase();
    final isBike = type == 'bike' ||
        type.contains('bike') ||
        type.contains('motorcycle') ||
        type.contains('scooter') ||
        vehicle.name.toLowerCase().contains('bike') ||
        vehicle.name.toLowerCase().contains('r15');

    state = state.copyWith(isLoading: true, currentOdometer: currentOdo, error: null);

    try {
      final list = await _repo.getReminders(
        vehicleId: vehicle.id,
        isBike: isBike,
        currentOdo: currentOdo,
      );
      state = state.copyWith(
        isLoading: false,
        reminders: list,
        currentOdometer: currentOdo,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> addReminder(ServiceReminder reminder) async {
    await _repo.addReminder(reminder);
    await loadReminders();
  }

  Future<void> updateReminder(ServiceReminder reminder) async {
    await _repo.updateReminder(reminder);
    await loadReminders();
  }

  Future<void> deleteReminder(String id) async {
    await _repo.deleteReminder(id);
    await loadReminders();
  }

  Future<void> markAsDone(String id, {double? cost, String? notes}) async {
    await _repo.markAsCompleted(
      id: id,
      currentOdometer: state.currentOdometer,
      cost: cost,
      notes: notes,
    );
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
