import '../models/author_stat.dart';
import '../models/dashboard_summary.dart';
import '../models/journal_stat.dart';
import '../models/publication.dart';
import '../models/trend_point.dart';

class AnalyticsCalculator {
  const AnalyticsCalculator._();

  static List<TrendPoint> publicationTrends(List<Publication> publications) {
    final counts = <int, int>{};
    for (final publication in publications) {
      final year = publication.publicationYear;
      if (year == null) continue;
      counts[year] = (counts[year] ?? 0) + 1;
    }

    final points = counts.entries
        .map((entry) => TrendPoint(year: entry.key, count: entry.value))
        .toList()
      ..sort((a, b) => a.year.compareTo(b.year));
    return points;
  }

  static List<JournalStat> topJournals(List<Publication> publications) {
    final counts = <String, int>{};
    for (final publication in publications) {
      final name = publication.journalName;
      if (name == null || name.trim().isEmpty) continue;
      counts[name] = (counts[name] ?? 0) + 1;
    }
    return _rank(counts)
        .map((entry) => JournalStat(name: entry.key, publicationCount: entry.value))
        .toList();
  }

  static List<AuthorStat> topAuthors(List<Publication> publications) {
    final counts = <String, int>{};
    for (final publication in publications) {
      for (final author in publication.authors) {
        counts[author] = (counts[author] ?? 0) + 1;
      }
    }
    return _rank(counts)
        .map((entry) => AuthorStat(name: entry.key, publicationCount: entry.value))
        .toList();
  }

  static List<Publication> influentialPapers(List<Publication> publications) {
    final sorted = [...publications]
      ..sort((a, b) => b.citedByCount.compareTo(a.citedByCount));
    return sorted;
  }

  static DashboardSummary summary(List<Publication> publications) {
    final trends = publicationTrends(publications);
    final journals = topJournals(publications);
    final authors = topAuthors(publications);
    final papers = influentialPapers(publications);
    final citationTotal = publications.fold<int>(
      0,
      (total, publication) => total + publication.citedByCount,
    );
    final activeYear = [...trends]..sort((a, b) => b.count.compareTo(a.count));

    return DashboardSummary(
      totalPublications: publications.length,
      averageCitations:
          publications.isEmpty ? 0 : citationTotal / publications.length,
      trends: trends,
      mostActiveYear: activeYear.isEmpty ? null : activeYear.first.year,
      topJournal: journals.isEmpty ? null : journals.first,
      topAuthor: authors.isEmpty ? null : authors.first,
      mostInfluentialPaper: papers.isEmpty ? null : papers.first,
    );
  }

  static List<MapEntry<String, int>> _rank(Map<String, int> counts) {
    final ranked = counts.entries.toList()
      ..sort((a, b) {
        final byCount = b.value.compareTo(a.value);
        return byCount == 0 ? a.key.compareTo(b.key) : byCount;
      });
    return ranked;
  }
}
