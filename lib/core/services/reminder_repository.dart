import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/reminder_model.dart';

/// Repository for vehicle maintenance reminders & service logs
class ReminderRepository {
  ReminderRepository._();
  static final ReminderRepository instance = ReminderRepository._();

  static const String _keyReminders = 'vehicle_maintenance_reminders_v1';

  /// Loads reminders for a specific vehicle. If empty, generates baseline defaults.
  Future<List<ServiceReminder>> getReminders({
    required int vehicleId,
    required bool isBike,
    required double currentOdo,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyReminders);
    List<ServiceReminder> all = [];

    if (raw != null) {
      try {
        final list = jsonDecode(raw) as List<dynamic>;
        all = list
            .map((e) => ServiceReminder.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (_) {
        all = [];
      }
    }

    final vehicleReminders = all.where((r) => r.vehicleId == vehicleId).toList();
    return vehicleReminders;
  }

  /// Adds a new maintenance reminder
  Future<void> addReminder(ServiceReminder reminder) async {
    final prefs = await SharedPreferences.getInstance();
    final all = await _getAll(prefs);
    all.add(reminder);
    await _save(prefs, all);
  }

  /// Updates an existing reminder
  Future<void> updateReminder(ServiceReminder reminder) async {
    final prefs = await SharedPreferences.getInstance();
    final all = await _getAll(prefs);
    final index = all.indexWhere((r) => r.id == reminder.id);
    if (index != -1) {
      all[index] = reminder;
      await _save(prefs, all);
    }
  }

  /// Deletes a reminder
  Future<void> deleteReminder(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final all = await _getAll(prefs);
    all.removeWhere((r) => r.id == id);
    await _save(prefs, all);
  }

  /// Marks a maintenance service as completed / replaced and resets the cycle
  Future<ServiceReminder?> markAsCompleted({
    required String id,
    required double currentOdometer,
    double? cost,
    String? notes,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final all = await _getAll(prefs);
    final index = all.indexWhere((r) => r.id == id);
    if (index == -1) return null;

    final existing = all[index];
    final now = DateTime.now();

    if (existing.isRecurring) {
      // Advance to next cycle
      final updated = existing.copyWith(
        lastServiceOdo: currentOdometer,
        lastServiceDate: now,
        lastCost: cost ?? existing.lastCost,
        notes: notes ?? existing.notes,
        isCompleted: false,
      );
      all[index] = updated;
      await _save(prefs, all);
      return updated;
    } else {
      final updated = existing.copyWith(
        isCompleted: true,
        lastCost: cost,
        notes: notes,
      );
      all[index] = updated;
      await _save(prefs, all);
      return updated;
    }
  }

  /// Generates initial smart baseline reminders for Cars vs Bikes
  List<ServiceReminder> generateDefaultPresets({
    required int vehicleId,
    required bool isBike,
    required double currentOdo,
  }) {
    final now = DateTime.now();
    final baselineOdo = (currentOdo > 0) ? currentOdo : 0.0;

    if (isBike) {
      return [
        ServiceReminder(
          id: '${vehicleId}_oil_${now.millisecondsSinceEpoch}',
          vehicleId: vehicleId,
          title: 'Engine Oil Change',
          serviceType: ServiceType.engineOil,
          lastServiceOdo: baselineOdo,
          lastServiceDate: now.subtract(const Duration(days: 15)),
          intervalKm: 2000,
          intervalDays: 60,
          notes: 'Semi-Synthetic 10W-40 or 20W-50',
          isRecurring: true,
        ),
        ServiceReminder(
          id: '${vehicleId}_service_${now.millisecondsSinceEpoch + 1}',
          vehicleId: vehicleId,
          title: 'Periodic General Servicing',
          serviceType: ServiceType.generalService,
          lastServiceOdo: baselineOdo,
          lastServiceDate: now.subtract(const Duration(days: 30)),
          intervalKm: 4000,
          intervalDays: 120,
          notes: 'Carburetor / FI tuning, chain lube, brake check',
          isRecurring: true,
        ),
      ];
    } else {
      return [
        ServiceReminder(
          id: '${vehicleId}_oil_${now.millisecondsSinceEpoch}',
          vehicleId: vehicleId,
          title: 'Engine Oil & Filter Change',
          serviceType: ServiceType.engineOil,
          lastServiceOdo: baselineOdo,
          lastServiceDate: now.subtract(const Duration(days: 45)),
          intervalKm: 5000,
          intervalDays: 180,
          notes: 'Synthetic 5W-30 or 10W-40 with OEM oil filter',
          isRecurring: true,
        ),
        ServiceReminder(
          id: '${vehicleId}_service_${now.millisecondsSinceEpoch + 1}',
          vehicleId: vehicleId,
          title: 'Periodic Vehicle Servicing',
          serviceType: ServiceType.generalService,
          lastServiceOdo: baselineOdo,
          lastServiceDate: now.subtract(const Duration(days: 60)),
          intervalKm: 10000,
          intervalDays: 365,
          notes: 'Brake pads, fluid top-up, AC filter, suspension check',
          isRecurring: true,
        ),
      ];
    }
  }

  Future<List<ServiceReminder>> _getAll(SharedPreferences prefs) async {
    final raw = prefs.getString(_keyReminders);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => ServiceReminder.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _save(SharedPreferences prefs, List<ServiceReminder> list) async {
    final jsonList = list.map((e) => e.toJson()).toList();
    await prefs.setString(_keyReminders, jsonEncode(jsonList));
  }
}
