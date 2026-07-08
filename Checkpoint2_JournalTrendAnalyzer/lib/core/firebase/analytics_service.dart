import 'package:firebase_analytics/firebase_analytics.dart';

import 'firebase_bootstrap.dart';

/// Typed wrapper around the Firebase Analytics events required by Lab 03.
/// Every method is a safe no-op while Firebase is unconfigured, so calling
/// code never needs to guard.
class AnalyticsService {
  const AnalyticsService._();

  static const instance = AnalyticsService._();

  FirebaseAnalytics? get _analytics =>
      FirebaseBootstrap.isAvailable ? FirebaseAnalytics.instance : null;

  Future<void> logLogin() async =>
      _analytics?.logLogin(loginMethod: 'google');

  Future<void> logLogout() async => _analytics?.logEvent(name: 'logout');

  Future<void> logSearchTopic(String keyword) async => _analytics
      ?.logEvent(name: 'search_topic', parameters: {'keyword': keyword});

  Future<void> logViewPublication(String title, int? year) async =>
      _analytics?.logEvent(name: 'view_publication', parameters: {
        // Analytics caps string params at 100 chars.
        'publication_title':
            title.length > 100 ? title.substring(0, 100) : title,
        if (year != null) 'publication_year': year,
      });

  Future<void> logViewJournal(String journalName) async =>
      _analytics?.logEvent(name: 'view_journal', parameters: {
        'journal_name': journalName.length > 100
            ? journalName.substring(0, 100)
            : journalName,
      });

  Future<void> logViewKeyword(String keyword) async => _analytics
      ?.logEvent(name: 'view_keyword', parameters: {'keyword': keyword});

  Future<void> logExportPdf(String topic) async =>
      _analytics?.logEvent(name: 'export_pdf', parameters: {'topic': topic});
}
