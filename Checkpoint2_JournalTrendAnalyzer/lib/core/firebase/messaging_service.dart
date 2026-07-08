import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'app_notification.dart';
import 'firebase_bootstrap.dart';

/// Background messages must be handled by a top-level entry point.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Data-only background messages need no work here; notification messages
  // are displayed by the system tray automatically.
  debugPrint('FCM background message: ${message.messageId}');
}

/// Firebase Cloud Messaging: permission, token, and foreground routing into
/// the in-app Notification Center.
class MessagingService {
  const MessagingService();

  Future<void> init(ValueChanged<AppNotification> onNotification) async {
    if (!FirebaseBootstrap.isAvailable) return;

    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission();
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Log the device token so a test push can be sent from the Firebase
    // console (Messaging → New campaign → Send test message).
    final token = await messaging.getToken();
    debugPrint('FCM registration token: $token');

    FirebaseMessaging.onMessage
        .listen((m) => onNotification(AppNotification.fromMessage(m)));
    FirebaseMessaging.onMessageOpenedApp
        .listen((m) => onNotification(AppNotification.fromMessage(m)));

    final initial = await messaging.getInitialMessage();
    if (initial != null) onNotification(AppNotification.fromMessage(initial));
  }
}
