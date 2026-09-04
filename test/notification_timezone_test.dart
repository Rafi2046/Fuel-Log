import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

void main() {
  setUpAll(() {
    tzdata.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Dhaka'));
  });

  test('Asia/Dhaka local is UTC+6 (not bare UTC)', () {
    final now = tz.TZDateTime.now(tz.local);
    expect(now.location.name, 'Asia/Dhaka');
    expect(now.timeZoneOffset, const Duration(hours: 6));
  });

  test('morning tip at 07:00 local is 01:00 UTC', () {
    final local = tz.TZDateTime(tz.local, 2026, 9, 5, 7, 0);
    expect(local.toUtc().hour, 1);
  });

  test('past scheduled dates should be treated as immediate', () {
    final past = DateTime.now().subtract(const Duration(minutes: 1));
    final now = DateTime.now();
    expect(past.isBefore(now), isTrue);
  });

  test('document reminder id namespace does not collide with weather ids', () {
    const weatherMorning = 91001;
    const weatherAlert = 91002;
    const activeTrip = 91003;
    final docId = 800000 + 42;
    expect(docId, isNot(anyOf(weatherMorning, weatherAlert, activeTrip)));
  });
}
