import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import 'package:journexa/core/firebase/analytics_service.dart';
import 'package:journexa/core/firebase/auth_service.dart';
import 'package:journexa/core/firebase/firebase_bootstrap.dart';

enum AuthStatus { signedOut, signingIn, signedIn }

/// Authentication state for the whole app. Gate logic:
/// - Firebase configured → Google Sign-In required (Lab 03 spec).
/// - Firebase NOT configured → a guest-mode escape hatch keeps the app
///   usable for development before `flutterfire configure` has been run.
class AuthViewModel extends ChangeNotifier {
  AuthViewModel({AuthService? authService})
      : _authService = authService ?? AuthService() {
    if (FirebaseBootstrap.isAvailable) {
      _subscription = _authService.userChanges.listen((user) {
        _user = user;
        _status =
            user == null ? AuthStatus.signedOut : AuthStatus.signedIn;
        notifyListeners();
      });
    }
  }

  final AuthService _authService;
  StreamSubscription<User?>? _subscription;

  AuthStatus _status = AuthStatus.signedOut;
  User? _user;
  bool _guestMode = false;
  String? _errorMessage;

  AuthStatus get status => _status;
  User? get user => _user;
  bool get isGuest => _guestMode;
  String? get errorMessage => _errorMessage;
  bool get firebaseAvailable => FirebaseBootstrap.isAvailable;

  /// Signed in with Google, or continuing as a guest — either way the main
  /// shell should be shown.
  bool get isAuthenticated => _status == AuthStatus.signedIn || _guestMode;

  String get displayName => _user?.displayName ?? 'Guest Researcher';
  String get email => _user?.email ?? 'Not signed in';
  String? get photoUrl => _user?.photoURL;

  Future<void> signInWithGoogle() async {
    if (!FirebaseBootstrap.isAvailable) {
      _errorMessage =
          'Firebase is not configured yet — run `flutterfire configure` '
          '(see FIREBASE_SETUP.md) or continue as guest.';
      notifyListeners();
      return;
    }

    _status = AuthStatus.signingIn;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await _authService.signInWithGoogle();
      if (user == null) {
        // User dismissed the account picker.
        _status = AuthStatus.signedOut;
      } else {
        _user = user;
        _status = AuthStatus.signedIn;
        await AnalyticsService.instance.logLogin();
      }
    } catch (e) {
      _status = AuthStatus.signedOut;
      _errorMessage = 'Sign-in failed: $e';
    }
    notifyListeners();
  }

  void continueAsGuest() {
    _guestMode = true;
    notifyListeners();
  }

  Future<void> signOut() async {
    await AnalyticsService.instance.logLogout();
    _guestMode = false;
    if (FirebaseBootstrap.isAvailable) {
      await _authService.signOut();
    }
    _user = null;
    _status = AuthStatus.signedOut;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
