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
import 'package:journexa/features/research/presentation/viewmodels/notifications_viewmodel.dart';
import 'package:journexa/features/research/presentation/viewmodels/research_viewmodel.dart';
import 'package:provider/provider.dart';

ResearchViewModel _idleViewModel() {
  final repository = PublicationRepositoryImpl(
    service: OpenAlexService(
      client: MockClient((_) async =>
          http.Response(jsonEncode({'results': [], 'meta': {'count': 0}}), 200)),
    ),
  );
  return ResearchViewModel(
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

  testWidgets('Home renders search field and idle dashboard state '
      'without layout errors', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => _idleViewModel()),
          ChangeNotifierProvider(create: (_) => NotificationsViewModel()),
        ],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('topicSearchField')), findsOneWidget);
    expect(find.byKey(const Key('searchButton')), findsOneWidget);
    expect(find.text('Start with a topic'), findsOneWidget);
    // Quick topic chips render.
    expect(find.text('Machine Learning'), findsOneWidget);
  });
}
