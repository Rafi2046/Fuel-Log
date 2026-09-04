import 'package:flutter/material.dart';

import 'package:fuel_log/core/utils/notification_service.dart';

/// Device smoke target:
///   flutter run -d <device> -t tool/notification_smoke.dart
///
/// Fires immediate service / document / weather notifications so the shade
/// can be verified without waiting for scheduled alarms.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final notifications = NotificationService();
  await notifications.init();

  await notifications.showNotification(
    id: 990001,
    title: 'QA · Service reminder',
    body: 'Maintenance due smoke test (Engine Oil Change)',
  );
  await notifications.showDocumentNotification(
    id: 990002,
    title: 'QA · Document vault',
    body: 'Registration expires in 7 days — vault smoke test',
  );
  await notifications.showWeatherNotification(
    id: 990003,
    title: 'QA · Weather tip',
    body: 'Drive-weather notification smoke test',
  );

  // Reschedule morning tip with corrected local timezone.
  await notifications.cancelWeatherNotifications();
  await notifications.scheduleMorningWeatherTip(
    title: 'QA morning tip',
    body: 'Should fire at 07:00 local after timezone fix',
  );

  runApp(
    const MaterialApp(
      home: Scaffold(
        backgroundColor: Color(0xFF121212),
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              '3 notifications fired.\nPull down the shade to verify.\nThen reopen the main app.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 16, height: 1.4),
            ),
          ),
        ),
      ),
    ),
  );
}
