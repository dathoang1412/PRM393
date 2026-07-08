import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

import 'package:journexa/firebase_options.dart';

/// Initializes Firebase once at startup and remembers whether it succeeded.
///
/// Every Firebase-touching service checks [isAvailable] first, so the app
/// degrades to an offline/guest experience instead of crashing when the
/// project hasn't been configured yet (placeholder firebase_options.dart).
class FirebaseBootstrap {
  const FirebaseBootstrap._();

  static bool _available = false;
  static bool get isAvailable => _available;

  static Future<bool> tryInit() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      _available = true;

      // Crashlytics: capture uncaught Flutter and platform errors.
      FlutterError.onError =
          FirebaseCrashlytics.instance.recordFlutterFatalError;
      PlatformDispatcher.instance.onError = (error, stack) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        return true;
      };
    } catch (error) {
      _available = false;
      debugPrint('Firebase not configured — running in guest mode: $error');
    }
    return _available;
  }
}
