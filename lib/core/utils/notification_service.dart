import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Service for managing local push notifications for maintenance reminders
/// and weather / drive tips.
class NotificationService {
  NotificationService._internal();
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;

  static const weatherMorningId = 91001;
  static const weatherAlertId = 91002;

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  /// Initializes timezone data and Flutter Local Notifications plugin.
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      tz.initializeTimeZones();

      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _flutterLocalNotificationsPlugin.initialize(initSettings);

      final androidImplementation =
          _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidImplementation != null) {
        await androidImplementation.requestNotificationsPermission();
        await androidImplementation.requestExactAlarmsPermission();
      }

      _isInitialized = true;
    } catch (_) {
      // Platform channel not registered in headless test runners
    }
  }

  Future<bool> _ensureIosPermissions() async {
    final ios = _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
    if (ios == null) return true;

    final granted = await ios.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
    return granted ?? false;
  }

  /// Schedules a local notification at a specific [scheduledDate].
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required DateTime scheduledDate,
    String? body,
  }) async {
    await init();
    if (Platform.isIOS) {
      await _ensureIosPermissions();
    }

    final now = DateTime.now();
    if (scheduledDate.isBefore(now)) {
      await showNotification(
        id: id,
        title: title,
        body: body ?? 'Maintenance Due Today: $title',
      );
      return;
    }

    final tzScheduledDate = tz.TZDateTime.from(scheduledDate, tz.local);

    const androidDetails = AndroidNotificationDetails(
      'maintenance_reminders',
      'Maintenance Reminders',
      channelDescription:
          'Notifications for scheduled vehicle maintenance and service due dates',
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    try {
      await _flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        title,
        body ?? 'Scheduled Maintenance Due: $title',
        tzScheduledDate,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (_) {
      await _flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        title,
        body ?? 'Scheduled Maintenance Due: $title',
        tzScheduledDate,
        details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }

  /// Shows an immediate local notification (e.g. for odometer triggers).
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    await init();
    if (Platform.isIOS) {
      await _ensureIosPermissions();
    }

    const androidDetails = AndroidNotificationDetails(
      'maintenance_reminders',
      'Maintenance Reminders',
      channelDescription:
          'Notifications for scheduled vehicle maintenance and service due dates',
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      details,
    );
  }

  /// Schedules a local push notification for document expiry.
  Future<void> scheduleDocumentReminder({
    required int id,
    required String title,
    required DateTime scheduledDate,
    required String body,
  }) async {
    await init();
    if (Platform.isIOS) {
      await _ensureIosPermissions();
    }

    final now = DateTime.now();
    if (scheduledDate.isBefore(now)) {
      await showDocumentNotification(
        id: id,
        title: title,
        body: body,
      );
      return;
    }

    final tzScheduledDate = tz.TZDateTime.from(scheduledDate, tz.local);

    const androidDetails = AndroidNotificationDetails(
      'document_reminders',
      'Document Expiry Reminders',
      channelDescription:
          'Notifications for expiring vehicle and personal documents',
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    try {
      await _flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        tzScheduledDate,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (_) {
      await _flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        tzScheduledDate,
        details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }

  /// Shows an immediate document expiry notification.
  Future<void> showDocumentNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    await init();
    if (Platform.isIOS) {
      await _ensureIosPermissions();
    }

    const androidDetails = AndroidNotificationDetails(
      'document_reminders',
      'Document Expiry Reminders',
      channelDescription:
          'Notifications for expiring vehicle and personal documents',
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      details,
    );
  }

  NotificationDetails get _weatherDetails {
    const androidDetails = AndroidNotificationDetails(
      'weather_drive_tips',
      'Weather & Drive Tips',
      channelDescription:
          'Morning drive tips and alerts when weather may affect driving',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );
    const iosDetails = DarwinNotificationDetails();
    return const NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
  }

  /// Immediate weather / drive advice notification (translated strings).
  Future<void> showWeatherNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    await init();
    if (Platform.isIOS) {
      await _ensureIosPermissions();
    }
    await _flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      _weatherDetails,
    );
  }

  /// Daily morning tip at 07:00 local — opens reminder to check drive weather.
  Future<void> scheduleMorningWeatherTip({
    String title = 'Drive weather tip',
    String body = 'Check today’s conditions before you take the car out.',
  }) async {
    await init();
    if (Platform.isIOS) {
      await _ensureIosPermissions();
    }

    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      7,
    );
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    try {
      await _flutterLocalNotificationsPlugin.zonedSchedule(
        weatherMorningId,
        title,
        body,
        scheduled,
        _weatherDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (_) {
      // Scheduling can fail on restricted devices — ignore quietly.
    }
  }

  static const activeTripNotificationId = 91003;

  NotificationDetails get _activeTripDetails {
    const androidDetails = AndroidNotificationDetails(
      'active_trip_tracking',
      'Active Trip Tracking',
      channelDescription:
          'Live distance and time updates during active trips and navigation',
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      autoCancel: false,
      onlyAlertOnce: true,
      showWhen: false,
      visibility: NotificationVisibility.public,
    );
    const iosDetails = DarwinNotificationDetails();
    return const NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
  }

  /// Updates or shows an ongoing notification for live trip tracking (visible on lock screen).
  Future<void> updateActiveTripNotification({
    required double distanceKm,
    required Duration duration,
    String? destination,
  }) async {
    await init();
    if (Platform.isIOS) {
      await _ensureIosPermissions();
    }

    final m = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    final h = duration.inHours;
    final timeStr = h > 0 ? '${h.toString().padLeft(2, '0')}:$m:$s' : '$m:$s';
    final distStr = '${distanceKm.toStringAsFixed(2)} km';

    final title = (destination != null && destination.isNotEmpty)
        ? 'Navigating to $destination'
        : '🚗 Active Trip in Progress';
    final body = '$distStr • $timeStr elapsed';

    try {
      await _flutterLocalNotificationsPlugin.show(
        activeTripNotificationId,
        title,
        body,
        _activeTripDetails,
      );
    } catch (_) {}
  }

  /// Cancels the live trip ongoing notification.
  Future<void> cancelActiveTripNotification() async {
    await init();
    try {
      await _flutterLocalNotificationsPlugin.cancel(activeTripNotificationId);
    } catch (_) {}
  }

  Future<void> cancelWeatherNotifications() async {
    await init();
    await _flutterLocalNotificationsPlugin.cancel(weatherMorningId);
    await _flutterLocalNotificationsPlugin.cancel(weatherAlertId);
  }

  /// Cancels a scheduled maintenance reminder notification.
  Future<void> cancelNotification(int id) async {
    try {
      await init();
      await _flutterLocalNotificationsPlugin.cancel(id);
    } catch (_) {}
  }
}
