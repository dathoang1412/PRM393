import 'package:flutter_test/flutter_test.dart';
import 'package:journexa/features/research/presentation/widgets/rank_row.dart';
import 'package:patrol/patrol.dart';

import 'helpers.dart';

void main() {
  // Test Case 4 — Journals Navigation: statistics and list are displayed.
  patrolTest('shows journal statistics and ranking list', ($) async {
    await $.pumpWidgetAndSettle(await buildApp());
    await ensureAuthenticated($);
    await searchTopic($, 'Machine Learning');

    await $('Journals').tap();
    await $.pumpAndSettle();

    expect($('Unique venues').exists, isTrue);
    expect($('Journal Contribution').exists, isTrue);
    expect($('Citation Statistics by Journal').exists, isTrue);
    expect($.tester.any(find.byType(RankRow)), isTrue);
  });

  // Test Case 5 — Journal Details: details are displayed correctly.
  patrolTest('opens a journal and shows its details', ($) async {
    await $.pumpWidgetAndSettle(await buildApp());
    await ensureAuthenticated($);
    await searchTopic($, 'Machine Learning');

    await $('Journals').tap();
    await $.pumpAndSettle();
    await $.tester.tap(find.byType(RankRow).first);
    await $.pumpAndSettle();

    expect($('Journal Details').exists, isTrue);
    expect($('Total citations').exists, isTrue);
    expect($('Avg citations').exists, isTrue);
  });
}
