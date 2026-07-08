import 'package:flutter_test/flutter_test.dart';
import 'package:journexa/features/research/presentation/widgets/publication_card.dart';
import 'package:patrol/patrol.dart';

import 'helpers.dart';

void main() {
  // Test Case 2 — Topic Search: results are displayed.
  patrolTest('searches a topic and shows publication results', ($) async {
    await $.pumpWidgetAndSettle(await buildApp());
    await ensureAuthenticated($);

    await searchTopic($, 'Machine Learning');

    expect($('Total publications').exists, isTrue);
    expect($.tester.any(find.byType(PublicationCard)), isTrue);
  });

  // Test Case 3 — Publication Details: correct info is displayed.
  patrolTest('opens a publication and shows its details', ($) async {
    await $.pumpWidgetAndSettle(await buildApp());
    await ensureAuthenticated($);
    await searchTopic($, 'Machine Learning');

    await $.tester.tap(find.byType(PublicationCard).first);
    await $.pumpAndSettle();

    expect($('Publication Details').exists, isTrue);
    expect($('Abstract').exists, isTrue);
    expect($('View original publication').exists, isTrue);
  });
}
