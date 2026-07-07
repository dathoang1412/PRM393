import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:journexa/features/research/data/datasources/openalex_service.dart';
import 'package:journexa/features/research/data/repositories/publication_repository_impl.dart';
import 'package:journexa/features/research/domain/usecases/get_year_counts.dart';
import 'package:journexa/features/research/domain/usecases/search_publications.dart';
import 'package:journexa/features/research/presentation/pages/home_screen.dart';
import 'package:journexa/features/research/presentation/providers/research_provider.dart';
import 'package:provider/provider.dart';

ResearchProvider _idleProvider() {
  final repository = PublicationRepositoryImpl(
    service: OpenAlexService(
      client: MockClient((_) async =>
          http.Response(jsonEncode({'results': [], 'meta': {'count': 0}}), 200)),
    ),
  );
  return ResearchProvider(
    searchPublications: SearchPublications(repository),
    getYearCounts: GetYearCounts(repository),
  );
}

void main() {
  setUpAll(() {
    // Tests have no network; render with fallback fonts instead of fetching.
    GoogleFonts.config.allowRuntimeFetching = false;
    dotenv.testLoad();
  });

  testWidgets('renders hero, feature cards, and trending topics '
      'without layout errors', (tester) async {
    // Phone-sized surface — layout bugs (unbounded heights, overflows) only
    // manifest when actually laid out at device dimensions.
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    var searched = '';
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => _idleProvider(),
        child: MaterialApp(
          home: HomeScreen(
            onOpenResearch: () {},
            onOpenTrends: () {},
            onOpenRankings: (_) {},
            onSearchTopic: (t) => searched = t,
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('JOURNEXA'), findsOneWidget);
    expect(find.text('Journal Research'), findsOneWidget);
    expect(find.text('Trend Analysis'), findsOneWidget);
    expect(find.text('Leading Journals'), findsOneWidget);
    expect(find.text('Top Authors'), findsOneWidget);

    // Tapping a trending topic forwards the query.
    await tester.tap(find.text('Large Language Models'));
    expect(searched, 'Large Language Models');
  });
}
