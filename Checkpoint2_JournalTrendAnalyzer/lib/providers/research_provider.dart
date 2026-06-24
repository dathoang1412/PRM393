import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import '../models/author_impact.dart';
import '../models/author_stat.dart';
import '../models/country_stat.dart';
import '../models/dashboard_summary.dart';
import '../models/institution_stat.dart';
import '../models/journal_stat.dart';
import '../models/keyword_stat.dart';
import '../models/publication.dart';
import '../models/trend_point.dart';
import '../repositories/publication_repository.dart';
import '../services/openalex_service.dart';
import '../utils/analytics_calculator.dart';

enum ResearchStatus { idle, loading, success, empty, error }

class ResearchProvider extends ChangeNotifier {
  ResearchProvider({required PublicationRepository repository})
      : _repository = repository;

  final PublicationRepository _repository;

  ResearchStatus _status = ResearchStatus.idle;
  String _keyword = '';
  String? _errorMessage;
  List<Publication> _publications = const [];
  int? _yearFrom;
  int? _yearTo;
  int _page = 1;
  int _totalCount = 0;
  bool _isLoadingMore = false;

  ResearchStatus get status => _status;
  String get keyword => _keyword;
  String? get errorMessage => _errorMessage;
  List<Publication> get publications => _publications;
  int? get yearFrom => _yearFrom;
  int? get yearTo => _yearTo;
  bool get hasYearFilter => _yearFrom != null || _yearTo != null;
  int get totalCount => _totalCount;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _publications.length < _totalCount;

  /// "`N` publications" once everything matching is loaded, or
  /// "`N` of `M` publications" while more pages remain to be fetched via
  /// [loadMore]. Shared by every screen that surfaces a result count so the
  /// wording (and number formatting) can't drift between them.
  String resultsSummary({String suffix = ''}) {
    final fmt = NumberFormat.decimalPattern();
    final loaded = fmt.format(_publications.length);
    final noun = suffix.isEmpty ? 'publications' : 'publications$suffix';
    return hasMore ? '$loaded of ${fmt.format(_totalCount)} $noun' : '$loaded $noun';
  }

  List<Publication> get filteredPublications {
    if (!hasYearFilter) return _publications;
    return _publications.where((p) {
      final y = p.publicationYear;
      if (y == null) return false;
      if (_yearFrom != null && y < _yearFrom!) return false;
      if (_yearTo != null && y > _yearTo!) return false;
      return true;
    }).toList();
  }

  void setYearRange(int? from, int? to) {
    _yearFrom = from;
    _yearTo = to;
    notifyListeners();
  }

  // ── Computed analytics (all respect year filter) ────────────────────────────
  List<TrendPoint> get trends =>
      AnalyticsCalculator.publicationTrends(filteredPublications);
  List<JournalStat> get journals =>
      AnalyticsCalculator.topJournals(filteredPublications);
  List<AuthorStat> get authors =>
      AnalyticsCalculator.topAuthors(filteredPublications);
  List<Publication> get influentialPapers =>
      AnalyticsCalculator.influentialPapers(filteredPublications);
  DashboardSummary get summary =>
      AnalyticsCalculator.summary(filteredPublications);
  List<TrendPoint> get citationTrends =>
      AnalyticsCalculator.citationTrends(filteredPublications);
  List<KeywordStat> get topKeywords =>
      AnalyticsCalculator.topKeywords(filteredPublications);
  List<InstitutionStat> get topInstitutions =>
      AnalyticsCalculator.topInstitutions(filteredPublications);
  List<CountryStat> get topCountries =>
      AnalyticsCalculator.topCountries(filteredPublications);
  List<AuthorImpact> get authorImpacts =>
      AnalyticsCalculator.authorImpact(filteredPublications);
  List<MapEntry<String, int>> get workTypes =>
      AnalyticsCalculator.workTypeDistribution(filteredPublications);

  // ── Search ──────────────────────────────────────────────────────────────────
  Future<void> search(String rawKeyword) async {
    final nextKeyword = rawKeyword.trim();
    if (nextKeyword.isEmpty) {
      _status = ResearchStatus.error;
      _errorMessage = 'Enter a research topic or keyword.';
      notifyListeners();
      return;
    }

    _keyword = nextKeyword;
    _status = ResearchStatus.loading;
    _errorMessage = null;
    _yearFrom = null;
    _yearTo = null;
    _page = 1;
    _totalCount = 0;
    notifyListeners();

    try {
      final result = await _repository.search(nextKeyword, page: 1);
      _publications = result.publications;
      _totalCount = result.totalCount;
      _status = result.publications.isEmpty
          ? ResearchStatus.empty
          : ResearchStatus.success;
    } catch (error) {
      _status = ResearchStatus.error;
      _errorMessage = _messageFor(error);
    }
    notifyListeners();
  }

  /// Fetches the next page of results for the current keyword and appends
  /// it to [publications]. No-ops if already loading, on a non-success
  /// search, or once every match has been fetched.
  Future<void> loadMore() async {
    if (_isLoadingMore || !hasMore || _status != ResearchStatus.success) {
      return;
    }

    final keywordAtRequest = _keyword;
    final nextPage = _page + 1;
    _isLoadingMore = true;
    notifyListeners();

    try {
      final result = await _repository.search(keywordAtRequest, page: nextPage);
      if (keywordAtRequest == _keyword) {
        // Mutate in place instead of spreading into a new list — appending
        // one page at a time would otherwise re-copy every previously
        // loaded publication on each call to loadMore().
        _publications.addAll(result.publications);
        _totalCount = result.totalCount;
        _page = nextPage;
      }
    } catch (_) {
      // Keep existing results visible; the user can retry via the button.
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  String _messageFor(Object error) {
    if (error is OpenAlexException) return error.message;
    return 'Unable to fetch publications. Try again.';
  }
}
