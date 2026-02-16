import 'package:flutter_local_notifications/flutter_local_notifications.dart';

abstract class INotificationService {
  Future<void> initializeNotifications();
  Future<void> requestPermissionsLocalNotifications();
  Future<void> showNotification(String title, String body, String payload);
  Future<dynamic> selectNotification(NotificationResponse details);
}
