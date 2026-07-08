import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:journexa/app.dart';
import 'package:journexa/core/firebase/firebase_bootstrap.dart';
import 'package:journexa/core/firebase/remote_config_service.dart';
import 'package:journexa/features/research/data/datasources/openalex_service.dart';
import 'package:journexa/features/research/data/repositories/publication_repository_impl.dart';
import 'package:journexa/features/research/domain/usecases/get_year_counts.dart';
import 'package:journexa/features/research/domain/usecases/search_publications.dart';
import 'package:journexa/features/research/presentation/viewmodels/auth_viewmodel.dart';
import 'package:journexa/features/research/presentation/viewmodels/notifications_viewmodel.dart';
import 'package:journexa/features/research/presentation/viewmodels/research_viewmodel.dart';
import 'package:patrol/patrol.dart';
import 'package:provider/provider.dart' hide Selector;

/// Boots the real app (mirrors `main()`), suitable for E2E tests.
Future<Widget> buildApp() async {
  await dotenv.load(fileName: '.env');
  await FirebaseBootstrap.tryInit();

  final remoteConfig = RemoteConfigService();
  await remoteConfig.init();

  final repository = PublicationRepositoryImpl(service: OpenAlexService());
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => AuthViewModel()),
      ChangeNotifierProvider(create: (_) => NotificationsViewModel()),
      ChangeNotifierProvider.value(value: remoteConfig),
      ChangeNotifierProvider(
        create: (_) => ResearchViewModel(
          searchPublications: SearchPublications(repository),
          getYearCounts: GetYearCounts(repository),
        ),
      ),
    ],
    child: const JournexaApp(),
  );
}

/// Gets past the login screen via guest mode. Used by every test that isn't
/// specifically exercising the sign-in flow itself (journals, keywords,
/// profile, export, remote config, …) — guest mode is fast and reliable
/// regardless of whether Google Sign-In is fully configured on the test
/// device. See [signInWithGoogle] for Test Case 1, which drives the real
/// Google flow.
Future<void> ensureAuthenticated(PatrolIntegrationTester $) async {
  if ($(const Key('continueAsGuestButton')).exists) {
    await $(const Key('continueAsGuestButton')).tap();
    await $.pumpAndSettle();
  }
}

/// Drives the real Google Sign-In flow (native account picker). Requires
/// the Google provider to be enabled in Firebase and a Google account
/// configured on the test device/emulator.
Future<void> signInWithGoogle(PatrolIntegrationTester $) async {
  await $(const Key('googleSignInButton')).tap();
  try {
    await $.native.tap(Selector(textContains: '@gmail.com'));
  } catch (_) {
    // Picker may be skipped when a default account is configured.
  }
  await $.pumpAndSettle(timeout: const Duration(seconds: 20));
}

/// Runs a topic search from the Home tab and waits for results.
Future<void> searchTopic(PatrolIntegrationTester $, String topic) async {
  await $(const Key('topicSearchField')).enterText(topic);
  await $(const Key('searchButton')).tap();
  // Live OpenAlex request — allow generous time.
  await $.pumpAndSettle(timeout: const Duration(seconds: 30));
}
