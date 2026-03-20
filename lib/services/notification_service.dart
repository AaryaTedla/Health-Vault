
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(
          android: androidSettings, iOS: iosSettings),
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    await _requestPermissions();
  }

  static Future<void> _requestPermissions() async {
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  static void _onNotificationTap(NotificationResponse response) {
    // Handle notification tap — navigate to medicine screen
  }

  // ─── Schedule a daily medicine reminder ─────────────────────────────────
  static Future<void> scheduleMedicineReminder({
    required int id,
    required String medicineName,
    required String dosage,
    required String time, // "08:00"
  }) async {
    final parts = time.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1].split(' ')[0]);
    final isPm = time.contains('PM');
    final h24 = isPm && hour != 12 ? hour + 12 : (!isPm && hour == 12 ? 0 : hour);

    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
        tz.local, now.year, now.month, now.day, h24, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    const androidDetails = AndroidNotificationDetails(
      'medicine_reminders',
      'Medicine Reminders',
      channelDescription: 'Daily medicine reminder notifications',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: Color(0xFF1B6CA8),
      playSound: true,
      enableVibration: true,
      styleInformation: BigTextStyleInformation(''),
    );

    await _plugin.zonedSchedule(
      id,
      '💊 Medicine Reminder',
      'Time to take $medicineName ($dosage)',
      scheduled,
      const NotificationDetails(android: androidDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  // ─── Emergency alert notification ────────────────────────────────────────
  static Future<void> showEmergencyNotification({
    required String contactName,
    required String patientName,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'emergency_alerts',
      'Emergency Alerts',
      channelDescription: 'Emergency alert notifications',
      importance: Importance.max,
      priority: Priority.max,
      color: Color(0xFFE74C3C),
      fullScreenIntent: true,
      playSound: true,
      enableVibration: true,
    );

    await _plugin.show(
      9999,
      '🚨 Emergency Alert Sent',
      '$patientName has sent an emergency alert to $contactName',
      const NotificationDetails(android: androidDetails),
    );
  }

  // ─── Guardian update notification ─────────────────────────────────────
  static Future<void> showGuardianUpdate({
    required String patientName,
    required String update,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'guardian_updates',
      'Guardian Updates',
      channelDescription: 'Health updates from your patient',
      importance: Importance.high,
      priority: Priority.high,
      color: Color(0xFF1B6CA8),
    );

    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      '🏥 Health Update — $patientName',
      update,
      const NotificationDetails(android: androidDetails),
    );
  }

  // ─── Cancel all reminders for a medicine ─────────────────────────────
  static Future<void> cancelMedicineReminders(List<int> ids) async {
    for (final id in ids) {
      await _plugin.cancel(id);
    }
  }

  static Future<void> cancelAll() async => _plugin.cancelAll();
}
