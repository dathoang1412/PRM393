import 'package:flutter_test/flutter_test.dart';
import 'package:journexa/features/research/presentation/widgets/rank_row.dart';
import 'package:patrol/patrol.dart';

import 'helpers.dart';

void main() {
  // Test Case 6 — Keywords Navigation: statistics and list are displayed.
  patrolTest('shows keyword statistics and ranking list', ($) async {
    await $.pumpWidgetAndSettle(await buildApp());
    await ensureAuthenticated($);
    await searchTopic($, 'Machine Learning');

    await $('Keywords').tap();
    await $.pumpAndSettle();

    expect($('Unique concepts').exists, isTrue);
    expect($('Keyword Frequency').exists, isTrue);
    expect($('Keyword Ranking').exists, isTrue);
  });

  // Test Case 7 — Keyword Details: analysis information is displayed.
  patrolTest('opens a keyword and shows its analysis', ($) async {
    await $.pumpWidgetAndSettle(await buildApp());
    await ensureAuthenticated($);
    await searchTopic($, 'Machine Learning');

    await $('Keywords').tap();
    await $.pumpAndSettle();
    await $.tester.tap(find.byType(RankRow).first);
    await $.pumpAndSettle();

    expect($('Keyword Analysis').exists, isTrue);
    expect($('Top Contributing Authors').exists, isTrue);
    expect($('Related Journals').exists, isTrue);
  });
}
