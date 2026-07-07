import 'package:flutter_test/flutter_test.dart';
import 'package:journexa/features/research/data/models/publication.dart';
import 'package:journexa/features/research/data/models/trend_point.dart';
import 'package:journexa/features/research/data/models/year_count.dart';
import 'package:journexa/features/research/domain/usecases/analytics_calculator.dart';

Publication _pub({
  String id = 'p1',
  int? year,
  int citations = 0,
  List<String> authors = const [],
  String? journal,
  List<String> keywords = const [],
  List<String> institutions = const [],
  List<String> countries = const [],
  List<YearCount> citationsByYear = const [],
  String? workType,
  String title = 'Untitled',
}) {
  return Publication(
    id: id,
    title: title,
    publicationYear: year,
    citedByCount: citations,
    authors: authors,
    journalName: journal,
    keywords: keywords,
    institutions: institutions,
    countries: countries,
    citationsByYear: citationsByYear,
    workType: workType,
  );
}

void main() {
  group('publicationTrends', () {
    test('counts by year and sorts ascending, ignoring null years', () {
      final pubs = [
        _pub(year: 2020),
        _pub(year: 2018),
        _pub(year: 2020),
        _pub(year: null),
      ];

      final trends = AnalyticsCalculator.publicationTrends(pubs);

      expect(trends.map((t) => t.year), [2018, 2020]);
      expect(trends.firstWhere((t) => t.year == 2020).count, 2);
    });
  });

  group('topJournals', () {
    test('ranks by count desc, ties broken alphabetically', () {
      final pubs = [
        _pub(journal: 'Beta'),
        _pub(journal: 'Alpha'),
        _pub(journal: 'Alpha'),
      ];

      final journals = AnalyticsCalculator.topJournals(pubs);

      expect(journals.map((j) => j.name), ['Alpha', 'Beta']);
      expect(journals.first.publicationCount, 2);
    });

    test('falls back to "Unknown venue" when journalName is null', () {
      final journals = AnalyticsCalculator.topJournals([_pub()]);
      expect(journals.single.name, 'Unknown venue');
    });
  });

  group('topAuthors', () {
    test('counts publications per author across the dataset', () {
      final pubs = [
        _pub(authors: const ['Ada', 'Grace']),
        _pub(authors: const ['Ada']),
      ];

      final authors = AnalyticsCalculator.topAuthors(pubs);

      expect(authors.first.name, 'Ada');
      expect(authors.first.publicationCount, 2);
    });
  });

  group('influentialPapers', () {
    test('sorts by citedByCount descending without mutating input', () {
      final low = _pub(id: 'low', citations: 1);
      final high = _pub(id: 'high', citations: 100);
      final input = [low, high];

      final sorted = AnalyticsCalculator.influentialPapers(input);

      expect(sorted.map((p) => p.id), ['high', 'low']);
      expect(input.map((p) => p.id), ['low', 'high']);
    });
  });

  group('summary', () {
    test('aggregates totals, average, and top entities', () {
      final pubs = [
        _pub(id: 'a', year: 2020, citations: 10, authors: const ['Ada'], journal: 'J1'),
        _pub(id: 'b', year: 2020, citations: 30, authors: const ['Ada'], journal: 'J1'),
      ];

      final summary = AnalyticsCalculator.summary(pubs);

      expect(summary.totalPublications, 2);
      expect(summary.averageCitations, 20);
      expect(summary.mostActiveYear, 2020);
      expect(summary.topJournal?.name, 'J1');
      expect(summary.topAuthor?.name, 'Ada');
      expect(summary.mostInfluentialPaper?.id, 'b');
    });

    test('handles an empty dataset without throwing', () {
      final summary = AnalyticsCalculator.summary(const []);

      expect(summary.totalPublications, 0);
      expect(summary.averageCitations, 0);
      expect(summary.mostActiveYear, isNull);
      expect(summary.topJournal, isNull);
      expect(summary.topAuthor, isNull);
      expect(summary.mostInfluentialPaper, isNull);
    });
  });

  group('citationTrends', () {
    test('sums per-paper citationsByYear across the dataset', () {
      final pubs = [
        _pub(citationsByYear: const [YearCount(year: 2020, citedByCount: 5)]),
        _pub(citationsByYear: const [YearCount(year: 2020, citedByCount: 7)]),
      ];

      final trends = AnalyticsCalculator.citationTrends(pubs);

      expect(trends.single.year, 2020);
      expect(trends.single.count, 12);
    });
  });

  group('topKeywords / topInstitutions / topCountries', () {
    test('rank by frequency across publications', () {
      final pubs = [
        _pub(
          keywords: const ['AI', 'ML'],
          institutions: const ['MIT'],
          countries: const ['US'],
        ),
        _pub(keywords: const ['AI'], institutions: const ['MIT', 'Stanford']),
      ];

      expect(AnalyticsCalculator.topKeywords(pubs).first.name, 'AI');
      expect(AnalyticsCalculator.topInstitutions(pubs).first.name, 'MIT');
      expect(AnalyticsCalculator.topCountries(pubs).single.name, 'United States');
    });
  });

  group('authorImpact', () {
    test('combines publication count and total citations per author', () {
      final pubs = [
        _pub(authors: const ['Ada'], citations: 10),
        _pub(authors: const ['Ada'], citations: 5),
        _pub(authors: const ['Grace'], citations: 100),
      ];

      final impact = AnalyticsCalculator.authorImpact(pubs);

      expect(impact.first.name, 'Grace');
      expect(impact.first.totalCitations, 100);
      final ada = impact.firstWhere((a) => a.name == 'Ada');
      expect(ada.publicationCount, 2);
      expect(ada.totalCitations, 15);
    });
  });

  group('workTypeDistribution', () {
    test('labels known types and falls back to Other', () {
      final pubs = [
        _pub(workType: 'article'),
        _pub(workType: 'article'),
        _pub(workType: 'made-up-type'),
        _pub(workType: null),
      ];

      final dist = AnalyticsCalculator.workTypeDistribution(pubs);
      final byLabel = {for (final e in dist) e.key: e.value};

      expect(byLabel['Article'], 2);
      expect(byLabel['Other'], 2);
    });
  });

  group('yearRange', () {
    test('returns min/max across publications', () {
      final range = AnalyticsCalculator.yearRange([
        _pub(year: 2015),
        _pub(year: 2022),
        _pub(year: null),
      ]);

      expect(range, isNotNull);
      expect(range!.min, 2015);
      expect(range.max, 2022);
    });

    test('returns null when no publication has a year', () {
      expect(AnalyticsCalculator.yearRange([_pub(year: null)]), isNull);
    });
  });

  group('pubGrowthRate', () {
    test('returns 0 with fewer than two data points', () {
      expect(AnalyticsCalculator.pubGrowthRate(const []), 0);
      expect(
        AnalyticsCalculator.pubGrowthRate(const [TrendPoint(year: 2020, count: 5)]),
        0,
      );
    });

    test('computes percentage growth between last-5 and prior-5 years', () {
      final trends = [
        const TrendPoint(year: 2010, count: 10), // prior window
        const TrendPoint(year: 2019, count: 20), // recent window
      ];

      // recent (>=2015): 20; prior (2010..2014): 10 -> +100%
      expect(AnalyticsCalculator.pubGrowthRate(trends), 100.0);
    });

    test('returns 100 when prior window is empty but recent has data', () {
      final trends = [const TrendPoint(year: 2023, count: 5)];
      // length 1 already short-circuits to 0 — use 2 points both in recent window.
      final trendsTwoRecent = [
        const TrendPoint(year: 2022, count: 5),
        const TrendPoint(year: 2023, count: 5),
      ];
      expect(AnalyticsCalculator.pubGrowthRate(trends), 0);
      expect(AnalyticsCalculator.pubGrowthRate(trendsTwoRecent), 100.0);
    });
  });

  group('totalCitations / medianCitations / highlyCited', () {
    test('totalCitations sums citedByCount', () {
      final pubs = [_pub(citations: 3), _pub(citations: 7)];
      expect(AnalyticsCalculator.totalCitations(pubs), 10);
    });

    test('medianCitations handles odd and even counts', () {
      expect(
        AnalyticsCalculator.medianCitations(
            [_pub(citations: 1), _pub(citations: 5), _pub(citations: 3)]),
        3,
      );
      expect(
        AnalyticsCalculator.medianCitations(
            [_pub(citations: 1), _pub(citations: 2), _pub(citations: 3), _pub(citations: 4)]),
        2,
      );
      expect(AnalyticsCalculator.medianCitations(const []), 0);
    });

    test('highlyCited counts publications at/above the threshold', () {
      final pubs = [_pub(citations: 99), _pub(citations: 100), _pub(citations: 500)];
      expect(AnalyticsCalculator.highlyCited(pubs), 2);
      expect(AnalyticsCalculator.highlyCited(pubs, threshold: 500), 1);
    });
  });

  group('topConcentration', () {
    test('returns the share of the top-N entries', () {
      final ranked = [
        const MapEntry('a', 60),
        const MapEntry('b', 30),
        const MapEntry('c', 10),
      ];

      expect(AnalyticsCalculator.topConcentration(ranked, 1), 60);
      expect(AnalyticsCalculator.topConcentration(ranked, 2), 90);
      expect(AnalyticsCalculator.topConcentration(const [], 5), 0);
    });
  });

  group('exportCsv', () {
    test('includes header, totals, and escapes embedded quotes', () {
      final pubs = [
        _pub(title: 'A "Great" Paper', year: 2021, citations: 5, journal: 'Nature'),
      ];

      final csv = AnalyticsCalculator.exportCsv(pubs, 'ai');

      expect(csv, contains('# Topic: ai'));
      expect(csv, contains('# Total publications: 1'));
      expect(csv, contains('"A ""Great"" Paper"'));
    });
  });

  group('labelWorkType', () {
    test('maps known OpenAlex types and falls back to Other', () {
      expect(AnalyticsCalculator.labelWorkType('article'), 'Article');
      expect(AnalyticsCalculator.labelWorkType('preprint'), 'Preprint');
      expect(AnalyticsCalculator.labelWorkType('nonsense'), 'Other');
    });
  });
}
