import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'firebase_bootstrap.dart';

/// Firebase Authentication with Google Sign-In.
class AuthService {
  AuthService();

  // Constructed lazily, only when a sign-in is actually attempted. This app
  // targets Android — Google Sign-In needs a clientId meta tag on web and
  // has no official Windows desktop support, so eagerly constructing
  // GoogleSignIn() at app-startup (regardless of whether it's ever used)
  // would hard-crash the whole widget tree on those platforms instead of
  // the graceful guest-mode fallback the rest of the app relies on.
  GoogleSignIn? _googleSignIn;
  GoogleSignIn get _signIn => _googleSignIn ??= GoogleSignIn();

  Stream<User?> get userChanges => FirebaseBootstrap.isAvailable
      ? FirebaseAuth.instance.userChanges()
      : const Stream.empty();

  User? get currentUser =>
      FirebaseBootstrap.isAvailable ? FirebaseAuth.instance.currentUser : null;

  /// Runs the Google Sign-In flow. Returns null when the user cancels the
  /// account picker.
  Future<User?> signInWithGoogle() async {
    final googleUser = await _signIn.signIn();
    if (googleUser == null) return null;

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    final result =
        await FirebaseAuth.instance.signInWithCredential(credential);
    return result.user;
  }

  Future<void> signOut() async {
    await _googleSignIn?.signOut();
    await FirebaseAuth.instance.signOut();
  }
}
