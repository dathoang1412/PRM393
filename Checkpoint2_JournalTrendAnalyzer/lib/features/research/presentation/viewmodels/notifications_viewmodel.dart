import 'package:flutter/foundation.dart';

import 'package:journexa/core/firebase/app_notification.dart';

/// In-app Notification Center backing store: push messages received via FCM
/// while the app runs, newest first.
class NotificationsViewModel extends ChangeNotifier {
  final List<AppNotification> _items = [];

  List<AppNotification> get items => List.unmodifiable(_items);
  bool get isEmpty => _items.isEmpty;

  void add(AppNotification notification) {
    _items.insert(0, notification);
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
}
