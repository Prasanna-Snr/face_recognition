import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'main.dart'; // yo le global flutterLocalNotificationsPlugin import garxa

class NotificationHelper {
  static Future<void> show({
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'face_verify_channel',
      'Face Verification',
      channelDescription: 'Face verify result',
      importance: Importance.max,
      priority: Priority.high,
    );

    const details = NotificationDetails(android: androidDetails);

    await flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000, // unique id
      title,
      body,
      details,
    );
  }
}
