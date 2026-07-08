import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'core/firebase/firebase_bootstrap.dart';
import 'core/firebase/messaging_service.dart';
import 'core/firebase/remote_config_service.dart';
import 'features/research/data/datasources/openalex_service.dart';
import 'features/research/data/repositories/publication_repository_impl.dart';
import 'features/research/domain/usecases/get_year_counts.dart';
import 'features/research/domain/usecases/search_publications.dart';
import 'features/research/presentation/viewmodels/auth_viewmodel.dart';
import 'features/research/presentation/viewmodels/notifications_viewmodel.dart';
import 'features/research/presentation/viewmodels/research_viewmodel.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');

  // Initializes Firebase when configured; otherwise the app runs in guest
  // mode (see FIREBASE_SETUP.md).
  await FirebaseBootstrap.tryInit();

  final remoteConfig = RemoteConfigService();
  final notifications = NotificationsViewModel();
  // Fire-and-forget: neither should delay first frame.
  remoteConfig.init();
  const MessagingService().init(notifications.add);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
        ChangeNotifierProvider.value(value: notifications),
        ChangeNotifierProvider.value(value: remoteConfig),
        ChangeNotifierProvider(
          create: (_) {
            final repository =
                PublicationRepositoryImpl(service: OpenAlexService());
            return ResearchViewModel(
              searchPublications: SearchPublications(repository),
              getYearCounts: GetYearCounts(repository),
            );
          },
        ),
      ],
      child: const JournexaApp(),
    ),
  );
}
