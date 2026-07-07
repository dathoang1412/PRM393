import 'dart:async';
import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:journexa/features/research/data/datasources/openalex_service.dart';
import 'package:journexa/features/research/data/repositories/publication_repository_impl.dart';
import 'package:journexa/features/research/domain/usecases/get_year_counts.dart';
import 'package:journexa/features/research/domain/usecases/search_publications.dart';
import 'package:journexa/features/research/presentation/providers/research_provider.dart';

/// Builds a minimal OpenAlex `/works` search response body.
String _searchResponse({
  required String idPrefix,
  required int count,
  required int total,
}) {
  final results = List.generate(
    count,
    (i) => {
      'id': '$idPrefix-$i',
      'display_name': 'Title $idPrefix-$i',
      'cited_by_count': 0,
    },
  );
  return jsonEncode({'results': results, 'meta': {'count': total}});
}

/// Builds an OpenAlex `group_by=publication_year` aggregation body.
String _groupByResponse(Map<int, int> countsByYear, {int? total}) {
  return jsonEncode({
    'group_by': [
      for (final e in countsByYear.entries)
        {'key': '${e.key}', 'count': e.value},
    ],
    'meta': {
      'count': total ?? countsByYear.values.fold<int>(0, (a, b) => a + b),
    },
  });
}

ResearchProvider _providerWith(MockClientHandler handler) {
  final repository = PublicationRepositoryImpl(
    service: OpenAlexService(client: MockClient(handler)),
  );
  return ResearchProvider(
    searchPublications: SearchPublications(repository),
    getYearCounts: GetYearCounts(repository),
  );
}

bool _isGroupBy(http.Request request) =>
    request.url.queryParameters.containsKey('group_by');

void main() {
  setUpAll(() {
    // OpenAlexService reads dotenv.env directly; tests never call the real
    // dotenv.load(), so the env map must be initialized synchronously here.
    dotenv.testLoad();
  });

  group('ResearchProvider.search', () {
    test('populates publications, totalCount, and success status', () async {
      final provider = _providerWith((request) async {
        return http.Response(
          _searchResponse(idPrefix: 'P', count: 3, total: 3),
          200,
        );
      });

      await provider.search('ai');

      expect(provider.status, ResearchStatus.success);
      expect(provider.publications, hasLength(3));
      expect(provider.totalCount, 3);
      expect(provider.hasMore, isFalse);
    });

    test('rejects an empty keyword without making a network call', () async {
      var requested = false;
      final provider = _providerWith((request) async {
        requested = true;
        return http.Response(_searchResponse(idPrefix: 'P', count: 0, total: 0), 200);
      });

      await provider.search('   ');

      expect(provider.status, ResearchStatus.error);
      expect(provider.errorMessage, isNotNull);
      expect(requested, isFalse);
    });

    test('surfaces a friendly message on HTTP failure instead of a raw exception', () async {
      final provider = _providerWith((request) async {
        return http.Response('{"message":"bad params"}', 400);
      });

      await provider.search('ai');

      expect(provider.status, ResearchStatus.error);
      expect(provider.errorMessage, contains('rejected the request parameters'));
      expect(provider.errorMessage, isNot(contains('Exception')));
    });

    test('trends prefer the corpus-wide group_by aggregation', () async {
      final provider = _providerWith((request) async {
        if (_isGroupBy(request)) {
          return http.Response(
            _groupByResponse({2023: 40, 2024: 60}),
            200,
          );
        }
        // Loaded page holds only 2 papers — the trend must not come from it.
        return http.Response(
          _searchResponse(idPrefix: 'P', count: 2, total: 100),
          200,
        );
      });

      await provider.search('ai');

      expect(provider.hasCorpusTrends, isTrue);
      expect(
        provider.trends.map((t) => (t.year, t.count)),
        [(2023, 40), (2024, 60)],
      );
      expect(provider.totalWorksInRange, 100);

      // The year filter narrows the corpus counts too.
      provider.setYearRange(2024, 2024);
      expect(
        provider.trends.map((t) => (t.year, t.count)),
        [(2024, 60)],
      );
      expect(provider.totalWorksInRange, 60);
    });

    test('falls back to loaded publications when group_by fails', () async {
      final provider = _providerWith((request) async {
        // 400 fails immediately (5xx would be retried with backoff).
        if (_isGroupBy(request)) {
          return http.Response('{"message":"unavailable"}', 400);
        }
        return http.Response(
          _searchResponse(idPrefix: 'P', count: 3, total: 3),
          200,
        );
      });

      await provider.search('ai');

      // Search itself still succeeds; trends derive from the loaded set.
      expect(provider.status, ResearchStatus.success);
      expect(provider.hasCorpusTrends, isFalse);
      expect(provider.totalWorksInRange, provider.filteredPublications.length);
    });

    test('sets the empty status when OpenAlex returns no results', () async {
      final provider = _providerWith((request) async {
        return http.Response(_searchResponse(idPrefix: 'P', count: 0, total: 0), 200);
      });

      await provider.search('a topic with no matches');

      expect(provider.status, ResearchStatus.empty);
      expect(provider.publications, isEmpty);
    });
  });

  group('ResearchProvider.loadMore', () {
    test('appends the next page and updates totalCount/hasMore', () async {
      final provider = _providerWith((request) async {
        final page = request.url.queryParameters['page'];
        final idPrefix = page == '2' ? 'P2' : 'P1';
        return http.Response(_searchResponse(idPrefix: idPrefix, count: 2, total: 4), 200);
      });

      await provider.search('ai');
      expect(provider.publications, hasLength(2));
      expect(provider.hasMore, isTrue);

      await provider.loadMore();

      expect(provider.publications, hasLength(4));
      expect(provider.publications.map((p) => p.id), [
        'P1-0', 'P1-1', 'P2-0', 'P2-1',
      ]);
      expect(provider.hasMore, isFalse);
      expect(provider.isLoadingMore, isFalse);
    });

    test('is a no-op once every match has been fetched', () async {
      // Counts only paged /works calls; the group_by aggregation request
      // that accompanies every search is answered separately.
      var pageCallCount = 0;
      final provider = _providerWith((request) async {
        if (_isGroupBy(request)) {
          return http.Response(_groupByResponse({2024: 2}), 200);
        }
        pageCallCount++;
        return http.Response(_searchResponse(idPrefix: 'P', count: 2, total: 2), 200);
      });

      await provider.search('ai'); // 1 call; hasMore is already false (2 == total)
      await provider.loadMore();

      expect(pageCallCount, 1);
      expect(provider.publications, hasLength(2));
    });

    test('discards a page that resolves after the keyword has changed', () async {
      final pageTwoGate = Completer<void>();
      final provider = _providerWith((request) async {
        final params = request.url.queryParameters;
        if (params['search'] == 'topicA' && params['page'] == '2') {
          await pageTwoGate.future;
          return http.Response(_searchResponse(idPrefix: 'A2', count: 2, total: 10), 200);
        }
        if (params['search'] == 'topicA') {
          return http.Response(_searchResponse(idPrefix: 'A1', count: 2, total: 10), 200);
        }
        return http.Response(_searchResponse(idPrefix: 'B1', count: 1, total: 1), 200);
      });

      await provider.search('topicA');
      expect(provider.publications.map((p) => p.id), ['A1-0', 'A1-1']);
      expect(provider.hasMore, isTrue);

      final loadMoreFuture = provider.loadMore(); // blocked on pageTwoGate

      await provider.search('topicB');
      expect(provider.keyword, 'topicB');
      expect(provider.publications.map((p) => p.id), ['B1-0']);

      pageTwoGate.complete();
      await loadMoreFuture;

      // The stale topicA page-2 response must not be merged into topicB's
      // results, even though it resolved after the keyword had changed.
      expect(provider.keyword, 'topicB');
      expect(provider.publications.map((p) => p.id), ['B1-0']);
      expect(provider.isLoadingMore, isFalse);
    });
  });
}
