import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'features/research/data/datasources/openalex_service.dart';
import 'features/research/data/repositories/publication_repository_impl.dart';
import 'features/research/domain/usecases/get_year_counts.dart';
import 'features/research/domain/usecases/search_publications.dart';
import 'features/research/presentation/providers/research_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');

  runApp(
    ChangeNotifierProvider(
      create: (_) {
        final repository =
            PublicationRepositoryImpl(service: OpenAlexService());
        return ResearchProvider(
          searchPublications: SearchPublications(repository),
          getYearCounts: GetYearCounts(repository),
        );
      },
      child: const JournexaApp(),
    ),
  );
}
