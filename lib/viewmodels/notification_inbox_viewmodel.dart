import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/utils/notification_service.dart';
import '../models/reminder_model.dart';
import '../models/weather_models.dart';
import 'reminder_viewmodel.dart';
import 'weather_viewmodel.dart';

const _dismissedPrefsKey = 'notification_dismissed_ids_v1';

/// Persisted "read" inbox IDs so the bell badge clears after dismiss / clear-all.
class NotificationInboxNotifier extends StateNotifier<Set<String>> {
  NotificationInboxNotifier() : super(const {}) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_dismissedPrefsKey) ?? const [];
    if (!mounted) return;
    state = raw.toSet();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_dismissedPrefsKey, state.toList()..sort());
  }

  Future<void> dismiss(String id) async {
    if (state.contains(id)) return;
    state = {...state, id};
    await _persist();
    await _cancelSystemFor(id);
  }

  Future<void> dismissAll(Iterable<String> ids) async {
    final next = {...state, ...ids};
    if (next.length == state.length) return;
    state = next;
    await _persist();
    for (final id in ids) {
      await _cancelSystemFor(id);
    }
  }

  Future<void> _cancelSystemFor(String id) async {
    final service = NotificationService();
    if (id.startsWith('overdue_') || id.startsWith('due_soon_')) {
      final raw = id.split('_').last;
      final numId = int.tryParse(raw);
      if (numId != null) await service.cancelNotification(numId);
      return;
    }
    if (id == 'weather_daily_alert') {
      await service.cancelNotification(NotificationService.weatherAlertId);
    }
  }
}

final notificationInboxProvider =
    StateNotifierProvider<NotificationInboxNotifier, Set<String>>(
  (ref) => NotificationInboxNotifier(),
);

/// Bell badge count: unread overdue / due-soon / caution-weather only.
final notificationBadgeCountProvider = Provider<int>((ref) {
  final dismissed = ref.watch(notificationInboxProvider);
  final reminders = ref.watch(remindersProvider);
  final weather = ref.watch(weatherAdviceProvider).valueOrNull;

  var count = 0;
  for (final r in reminders.activeReminders) {
    final status = r.status(reminders.currentOdometer);
    if (status == ReminderStatus.overdue) {
      if (!dismissed.contains('overdue_${r.id}')) count++;
    } else if (status == ReminderStatus.dueSoon) {
      if (!dismissed.contains('due_soon_${r.id}')) count++;
    }
  }

  if (weather != null &&
      (weather.level == DriveAdviceLevel.caution ||
          weather.level == DriveAdviceLevel.avoid) &&
      !dismissed.contains('weather_daily_alert')) {
    count++;
  }

  return count;
});
