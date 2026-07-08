import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import 'helpers.dart';

void main() {
  // Test Case 8 — Profile Navigation: user profile info is displayed.
  patrolTest('shows the user profile information', ($) async {
    await $.pumpWidgetAndSettle(await buildApp());
    await ensureAuthenticated($);

    await $('Profile').tap();
    await $.pumpAndSettle();

    expect($(const Key('profileDisplayName')).exists, isTrue);
    expect($('Notification Center').exists, isTrue);
    expect($(const Key('signOutButton')).exists, isTrue);
  });
}
