import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import 'package:journexa/features/research/data/models/author_impact.dart';
import 'package:journexa/features/research/data/models/author_stat.dart';
import 'package:journexa/features/research/data/models/country_stat.dart';
import 'package:journexa/features/research/data/models/dashboard_summary.dart';
import 'package:journexa/features/research/data/models/institution_stat.dart';
import 'package:journexa/features/research/data/models/journal_stat.dart';
import 'package:journexa/features/research/data/models/keyword_stat.dart';
import 'package:journexa/features/research/data/models/publication.dart';
import 'package:journexa/features/research/data/models/trend_point.dart';
import 'package:journexa/core/error/openalex_exception.dart';
import 'package:journexa/features/research/domain/usecases/analytics_calculator.dart';
import 'package:journexa/features/research/domain/usecases/get_year_counts.dart';
import 'package:journexa/features/research/domain/usecases/search_publications.dart';

enum ResearchStatus { idle, loading, success, empty, error }

class ResearchProvider extends ChangeNotifier {
  ResearchProvider({
    required SearchPublications searchPublications,
    required GetYearCounts getYearCounts,
  })  : _searchPublications = searchPublications,
        _getYearCounts = getYearCounts;

  final SearchPublications _searchPublications;
  final GetYearCounts _getYearCounts;

  ResearchStatus _status = ResearchStatus.idle;
  String _keyword = '';
  String? _errorMessage;
  List<Publication> _publications = const [];

  /// Corpus-wide papers-per-year from OpenAlex `group_by` — covers every
  /// matching work, not just the loaded (most-cited) pages. Empty when the
  /// aggregation call failed; [trends] then falls back to loaded data.
  List<TrendPoint> _corpusTrends = const [];
  int? _yearFrom;
  int? _yearTo;
  int _page = 1;
  int _totalCount = 0;
  bool _isLoadingMore = false;

  // Bumped on every mutation of _publications/_yearFrom/_yearTo so the memo
  // cache below knows when to recompute. Analytics getters are read on every
  // rebuild of several screens at once, but the underlying data only changes
  // on search/loadMore/setYearRange — recomputing on every read does
  // redundant O(n) / O(n log n) work once result sets span multiple pages.
  int _generation = 0;
  final Map<String, Object?> _cache = {};
  final Map<String, int> _cacheGeneration = {};

  T _memo<T>(String key, T Function() compute) {
    if (_cacheGeneration[key] != _generation) {
      _cache[key] = compute();
      _cacheGeneration[key] = _generation;
    }
    return _cache[key] as T;
  }

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

  List<Publication> get filteredPublications => _memo('filteredPublications', () {
        if (!hasYearFilter) return _publications;
        return _publications.where((p) {
          final y = p.publicationYear;
          if (y == null) return false;
          if (_yearFrom != null && y < _yearFrom!) return false;
          if (_yearTo != null && y > _yearTo!) return false;
          return true;
        }).toList();
      });

  void setYearRange(int? from, int? to) {
    _yearFrom = from;
    _yearTo = to;
    _generation++;
    notifyListeners();
  }

  /// True when [trends] reflects the whole corpus (group_by aggregation)
  /// rather than only the loaded most-cited pages.
  bool get hasCorpusTrends => _corpusTrends.isNotEmpty;

  // ── Computed analytics (all respect year filter, memoized per generation) ──

  /// Papers published per year. Prefers the corpus-wide aggregation so the
  /// chart shows the topic's real publication activity; falls back to the
  /// loaded publications if the aggregation call failed.
  List<TrendPoint> get trends => _memo('trends', () {
        if (_corpusTrends.isEmpty) {
          return AnalyticsCalculator.publicationTrends(filteredPublications);
        }
        if (!hasYearFilter) return _corpusTrends;
        return _corpusTrends
            .where((p) =>
                (_yearFrom == null || p.year >= _yearFrom!) &&
                (_yearTo == null || p.year <= _yearTo!))
            .toList();
      });

  /// Total works matching the topic within the active year filter, from the
  /// corpus aggregation when available (otherwise the loaded set).
  int get totalWorksInRange => _memo('totalWorksInRange', () {
        if (_corpusTrends.isEmpty) return filteredPublications.length;
        return trends.fold(0, (sum, p) => sum + p.count);
      });
  List<JournalStat> get journals => _memo(
      'journals', () => AnalyticsCalculator.topJournals(filteredPublications));
  List<AuthorStat> get authors => _memo(
      'authors', () => AnalyticsCalculator.topAuthors(filteredPublications));
  List<Publication> get influentialPapers => _memo('influentialPapers',
      () => AnalyticsCalculator.influentialPapers(filteredPublications));
  DashboardSummary get summary =>
      _memo('summary', () => AnalyticsCalculator.summary(filteredPublications));
  List<TrendPoint> get citationTrends => _memo('citationTrends',
      () => AnalyticsCalculator.citationTrends(filteredPublications));
  List<KeywordStat> get topKeywords => _memo(
      'topKeywords', () => AnalyticsCalculator.topKeywords(filteredPublications));
  List<InstitutionStat> get topInstitutions => _memo('topInstitutions',
      () => AnalyticsCalculator.topInstitutions(filteredPublications));
  List<CountryStat> get topCountries => _memo(
      'topCountries', () => AnalyticsCalculator.topCountries(filteredPublications));
  List<AuthorImpact> get authorImpacts => _memo(
      'authorImpacts', () => AnalyticsCalculator.authorImpact(filteredPublications));
  List<MapEntry<String, int>> get workTypes => _memo('workTypes',
      () => AnalyticsCalculator.workTypeDistribution(filteredPublications));

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
    _corpusTrends = const [];
    _generation++;
    notifyListeners();

    try {
      // Fetch the first result page and the corpus-wide year aggregation in
      // parallel. The aggregation is best-effort: on failure the trend chart
      // falls back to the loaded publications instead of failing the search.
      final pageFuture = _searchPublications(nextKeyword, page: 1);
      final trendsFuture = _getYearCounts(nextKeyword)
          .catchError((Object _) => const <TrendPoint>[]);

      final result = await pageFuture;
      final corpusTrends = await trendsFuture;
      if (_keyword != nextKeyword) return; // a newer search took over

      _publications = result.publications;
      _totalCount = result.totalCount;
      _corpusTrends = corpusTrends;
      _status = result.publications.isEmpty
          ? ResearchStatus.empty
          : ResearchStatus.success;
      _generation++;
    } catch (error) {
      if (_keyword != nextKeyword) return;
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
      final result =
          await _searchPublications(keywordAtRequest, page: nextPage);
      if (keywordAtRequest == _keyword) {
        // Mutate in place instead of spreading into a new list — appending
        // one page at a time would otherwise re-copy every previously
        // loaded publication on each call to loadMore().
        _publications.addAll(result.publications);
        _totalCount = result.totalCount;
        _page = nextPage;
        _generation++;
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
