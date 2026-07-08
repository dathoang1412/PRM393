import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import 'helpers.dart';

void main() {
  // Test Case 9 — PDF Export: generate, upload to Storage, verify URL.
  // Requires Firebase to be configured (Storage upload).
  patrolTest('exports a PDF report and shows the uploaded URL', ($) async {
    await $.pumpWidgetAndSettle(await buildApp());
    await ensureAuthenticated($);

    // A topic must be loaded before a report can be generated.
    await searchTopic($, 'Machine Learning');

    await $('Profile').tap();
    await $.pumpAndSettle();

    await $(const Key('exportPdfButton')).scrollTo().tap();
    // PDF build + Storage upload over the network.
    await $.pumpAndSettle(timeout: const Duration(seconds: 60));

    expect($(const Key('uploadedUrlBox')).exists, isTrue);
    expect($('https://').exists, isTrue);
  });
}
