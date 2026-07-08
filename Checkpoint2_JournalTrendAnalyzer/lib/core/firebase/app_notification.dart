import 'package:firebase_messaging/firebase_messaging.dart';

/// A push notification received via FCM, shown in the Profile tab's
/// Notification Center.
class AppNotification {
  const AppNotification({
    required this.title,
    required this.body,
    required this.receivedAt,
    this.imageUrl,
  });

  factory AppNotification.fromMessage(RemoteMessage message) {
    return AppNotification(
      title: message.notification?.title ?? 'Journexa update',
      body: message.notification?.body ?? message.data.toString(),
      receivedAt: DateTime.now(),
      // Android's "big picture" image, if the push included one. Falls back
      // to the data payload so a data-only test message (e.g. {"image":
      // "https://..."}) still renders a thumbnail.
      imageUrl: message.notification?.android?.imageUrl ??
          message.data['image'],
    );
  }

  final String title;
  final String body;
  final DateTime receivedAt;
  final String? imageUrl;
}
