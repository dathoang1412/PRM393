import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import 'helpers.dart';

void main() {
  // Test Case 10 — Remote Config: values are retrieved and displayed.
  patrolTest('retrieves and displays Remote Config values', ($) async {
    await $.pumpWidgetAndSettle(await buildApp());
    await ensureAuthenticated($);

    await $('Profile').tap();
    await $.pumpAndSettle();

    await $(const Key('remoteConfigRefreshButton')).scrollTo().tap();
    await $.pumpAndSettle(timeout: const Duration(seconds: 20));

    expect($(const Key('remoteConfigMaxJournals')).exists, isTrue);
    expect($(const Key('remoteConfigMaxKeywords')).exists, isTrue);
    expect($('max_journals').exists, isTrue);
    expect($('max_keywords').exists, isTrue);
  });
}
