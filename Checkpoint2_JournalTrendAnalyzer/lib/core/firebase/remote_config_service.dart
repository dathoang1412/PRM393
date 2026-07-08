import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

import 'firebase_bootstrap.dart';

/// Firebase Remote Config: caps how many journals/keywords the ranking
/// screens display. Falls back to the defaults below until Firebase is
/// configured (or when fetch fails).
class RemoteConfigService extends ChangeNotifier {
  static const defaultMaxJournals = 10;
  static const defaultMaxKeywords = 15;

  int _maxJournals = defaultMaxJournals;
  int _maxKeywords = defaultMaxKeywords;
  bool _fetched = false;

  int get maxJournals => _maxJournals;
  int get maxKeywords => _maxKeywords;

  /// True once values actually came from Remote Config (vs the defaults).
  bool get fetched => _fetched;

  Future<void> init() async {
    if (!FirebaseBootstrap.isAvailable) return;
    try {
      final rc = FirebaseRemoteConfig.instance;
      await rc.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        // Zero for the lab demo so console changes show up on every refresh;
        // production apps should use hours.
        minimumFetchInterval: Duration.zero,
      ));
      await rc.setDefaults(const {
        'max_journals': defaultMaxJournals,
        'max_keywords': defaultMaxKeywords,
      });
      await rc.fetchAndActivate();
      _maxJournals = rc.getInt('max_journals');
      _maxKeywords = rc.getInt('max_keywords');
      _fetched = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Remote Config fetch failed: $e');
    }
  }

  Future<void> refresh() => init();
}
