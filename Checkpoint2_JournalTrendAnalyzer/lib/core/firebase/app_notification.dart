import 'package:firebase_messaging/firebase_messaging.dart';

/// A push notification received via FCM, shown in the Profile tab's
/// Notification Center.
class AppNotification {
  const AppNotification({
    required this.title,
    required this.body,
    required this.receivedAt,
  });

  factory AppNotification.fromMessage(RemoteMessage message) {
    return AppNotification(
      title: message.notification?.title ?? 'Journexa update',
      body: message.notification?.body ?? message.data.toString(),
      receivedAt: DateTime.now(),
    );
  }

  final String title;
  final String body;
  final DateTime receivedAt;
}
