import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher'); // your app icon

    const InitializationSettings initSettings =
        InitializationSettings(android: androidSettings);

    await _notificationsPlugin.initialize(initSettings);
  }

  static Future<void> showPoopReminder() async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'poop_channel',
      'Poop Reminders',
      channelDescription: 'Reminds you to log a poop check-in',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
    );

    const NotificationDetails details =
        NotificationDetails(android: androidDetails);

    await _notificationsPlugin.show(
      0,
      '💩 Don’t forget!',
      'It’s been over 3 days since your last poop check-in.',
      details,
    );
  }
}
