import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import 'helpers.dart';

void main() {
  // Test Case 1 — Google Sign-In: launch, sign in, land on Home.
  // Requires the Google provider enabled in Firebase + SHA-1 registered +
  // a Google account on the test device (see FIREBASE_SETUP.md §2).
  patrolTest('signs in with Google and reaches the Home screen', ($) async {
    await $.pumpWidgetAndSettle(await buildApp());

    await signInWithGoogle($);

    // Home is identified by its topic search field.
    expect($(const Key('topicSearchField')).exists, isTrue);
  });

  // Test Case 11 — Logout: sign out redirects to the Login screen.
  patrolTest('signs out and returns to the Login screen', ($) async {
    await $.pumpWidgetAndSettle(await buildApp());
    await ensureAuthenticated($);

    await $('Profile').tap();
    await $(const Key('signOutButton')).scrollTo().tap();
    await $.pumpAndSettle();

    expect($(const Key('googleSignInButton')).exists, isTrue);
  });
}
