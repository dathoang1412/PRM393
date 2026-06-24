import 'dart:math';

import '../models/author_impact.dart';
import '../models/author_stat.dart';
import '../models/country_stat.dart';
import '../models/dashboard_summary.dart';
import '../models/institution_stat.dart';
import '../models/journal_stat.dart';
import '../models/keyword_stat.dart';
import '../models/publication.dart';
import '../models/trend_point.dart';

class AnalyticsCalculator {
  const AnalyticsCalculator._();

  // ── Core analytics ────────────────────────────────────────────────────────────

  static List<TrendPoint> publicationTrends(List<Publication> publications) {
    final counts = <int, int>{};
    for (final pub in publications) {
      final year = pub.publicationYear;
      if (year == null) continue;
      counts[year] = (counts[year] ?? 0) + 1;
    }
    return counts.entries
        .map((e) => TrendPoint(year: e.key, count: e.value))
        .toList()
      ..sort((a, b) => a.year.compareTo(b.year));
  }

  static List<JournalStat> topJournals(List<Publication> publications) {
    final counts = <String, int>{};
    for (final pub in publications) {
      final name = pub.journalName ?? 'Unknown venue';
      counts[name] = (counts[name] ?? 0) + 1;
    }
    return _rank(counts)
        .map((e) => JournalStat(name: e.key, publicationCount: e.value))
        .toList();
  }

  static List<AuthorStat> topAuthors(List<Publication> publications) {
    final counts = <String, int>{};
    for (final pub in publications) {
      for (final author in pub.authors) {
        counts[author] = (counts[author] ?? 0) + 1;
      }
    }
    return _rank(counts)
        .map((e) => AuthorStat(name: e.key, publicationCount: e.value))
        .toList();
  }

  static List<Publication> influentialPapers(List<Publication> publications) {
    return [...publications]
      ..sort((a, b) => b.citedByCount.compareTo(a.citedByCount));
  }

  static DashboardSummary summary(List<Publication> publications) {
    final trends = publicationTrends(publications);
    final journals = topJournals(publications);
    final authors = topAuthors(publications);
    final papers = influentialPapers(publications);
    final citationTotal = publications.fold<int>(
      0,
      (total, pub) => total + pub.citedByCount,
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

  static List<TrendPoint> citationTrends(List<Publication> publications) {
    final totals = <int, int>{};
    for (final pub in publications) {
      for (final yc in pub.citationsByYear) {
        totals[yc.year] = (totals[yc.year] ?? 0) + yc.citedByCount;
      }
    }
    return totals.entries
        .map((e) => TrendPoint(year: e.key, count: e.value))
        .toList()
      ..sort((a, b) => a.year.compareTo(b.year));
  }

  static List<KeywordStat> topKeywords(List<Publication> publications) {
    final counts = <String, int>{};
    for (final pub in publications) {
      for (final kw in pub.keywords) {
        counts[kw] = (counts[kw] ?? 0) + 1;
      }
    }
    return _rank(counts)
        .map((e) => KeywordStat(name: e.key, count: e.value))
        .toList();
  }

  static List<InstitutionStat> topInstitutions(
      List<Publication> publications) {
    final counts = <String, int>{};
    for (final pub in publications) {
      for (final inst in pub.institutions) {
        counts[inst] = (counts[inst] ?? 0) + 1;
      }
    }
    return _rank(counts)
        .map((e) => InstitutionStat(name: e.key, count: e.value))
        .toList();
  }

  static List<CountryStat> topCountries(List<Publication> publications) {
    final counts = <String, int>{};
    for (final pub in publications) {
      for (final code in pub.countries) {
        counts[code] = (counts[code] ?? 0) + 1;
      }
    }
    return _rank(counts)
        .map((e) => CountryStat(
              code: e.key,
              name: _countryName(e.key),
              count: e.value,
            ))
        .toList();
  }

  static List<AuthorImpact> authorImpact(List<Publication> publications) {
    final pubCounts = <String, int>{};
    final citCounts = <String, int>{};
    for (final pub in publications) {
      for (final author in pub.authors) {
        pubCounts[author] = (pubCounts[author] ?? 0) + 1;
        citCounts[author] = (citCounts[author] ?? 0) + pub.citedByCount;
      }
    }
    return pubCounts.entries
        .map((e) => AuthorImpact(
              name: e.key,
              publicationCount: e.value,
              totalCitations: citCounts[e.key] ?? 0,
            ))
        .toList()
      ..sort((a, b) => b.totalCitations.compareTo(a.totalCitations));
  }

  static List<MapEntry<String, int>> workTypeDistribution(
      List<Publication> publications) {
    final counts = <String, int>{};
    for (final pub in publications) {
      final type = labelWorkType(pub.workType ?? 'other');
      counts[type] = (counts[type] ?? 0) + 1;
    }
    return _rank(counts);
  }

  // ── Insight analytics ─────────────────────────────────────────────────────────

  /// Year span (min, max) of publications in the dataset.
  static ({int min, int max})? yearRange(List<Publication> publications) {
    final years = publications
        .map((p) => p.publicationYear)
        .whereType<int>()
        .toList();
    if (years.isEmpty) return null;
    return (min: years.reduce(min), max: years.reduce(max));
  }

  /// Publication growth: last-5-year count vs prior-5-year count as percentage.
  static double pubGrowthRate(List<TrendPoint> trends) {
    if (trends.length < 2) return 0;
    final sorted = [...trends]..sort((a, b) => a.year.compareTo(b.year));
    final maxYear = sorted.last.year;
    final recent = sorted
        .where((t) => t.year >= maxYear - 4)
        .fold(0, (s, t) => s + t.count);
    final prior = sorted
        .where((t) => t.year >= maxYear - 9 && t.year < maxYear - 4)
        .fold(0, (s, t) => s + t.count);
    if (prior == 0) return recent > 0 ? 100.0 : 0.0;
    return (recent - prior) / prior * 100.0;
  }

  /// Sum of all citation counts.
  static int totalCitations(List<Publication> publications) =>
      publications.fold(0, (sum, p) => sum + p.citedByCount);

  /// Median citation count across all publications.
  static int medianCitations(List<Publication> publications) {
    if (publications.isEmpty) return 0;
    final sorted = publications.map((p) => p.citedByCount).toList()..sort();
    final mid = sorted.length ~/ 2;
    return sorted.length.isEven
        ? (sorted[mid - 1] + sorted[mid]) ~/ 2
        : sorted[mid];
  }

  /// Count of publications with citations >= threshold.
  static int highlyCited(List<Publication> publications,
          {int threshold = 100}) =>
      publications.where((p) => p.citedByCount >= threshold).length;

  /// Concentration of top-N items as % of total count.
  static double topConcentration(List<MapEntry<String, int>> ranked, int n) {
    if (ranked.isEmpty) return 0;
    final total = ranked.fold(0, (s, e) => s + e.value);
    if (total == 0) return 0;
    final topN = ranked.take(n).fold(0, (s, e) => s + e.value);
    return topN / total * 100;
  }

  /// Export publications as CSV string (designed for clipboard copy).
  static String exportCsv(List<Publication> publications, String keyword) {
    final now = DateTime.now();
    final sb = StringBuffer();
    sb.writeln('# Journal Trend Analyzer — Export Report');
    sb.writeln('# Topic: $keyword');
    sb.writeln(
        '# Generated: ${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} '
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}');
    sb.writeln('# Total publications: ${publications.length}');
    sb.writeln('# Total citations: ${totalCitations(publications)}');
    sb.writeln('');
    sb.writeln('"Title","Year","Citations","Venue","First Author","DOI"');
    for (final p in publications) {
      sb.writeln([
        _csv(p.title),
        p.publicationYear?.toString() ?? '',
        p.citedByCount.toString(),
        _csv(p.journalName ?? ''),
        _csv(p.authors.isNotEmpty ? p.authors.first : ''),
        p.doi ?? '',
      ].join(','));
    }
    return sb.toString();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────────

  static List<MapEntry<String, int>> _rank(Map<String, int> counts) {
    return counts.entries.toList()
      ..sort((a, b) {
        final byCount = b.value.compareTo(a.value);
        return byCount == 0 ? a.key.compareTo(b.key) : byCount;
      });
  }

  static String _csv(String value) {
    final escaped = value.replaceAll('"', '""');
    return '"$escaped"';
  }

  /// Human-readable label for an OpenAlex work `type` value. Shared between
  /// analytics breakdowns and the publication detail screen so the two
  /// never drift apart.
  static String labelWorkType(String raw) => switch (raw) {
        'article' => 'Article',
        'review' => 'Review',
        'book-chapter' => 'Book chapter',
        'conference-paper' => 'Conference',
        'preprint' => 'Preprint',
        'dataset' => 'Dataset',
        'dissertation' => 'Dissertation',
        'letter' => 'Letter',
        'editorial' => 'Editorial',
        _ => 'Other',
      };

  static String _countryName(String code) =>
      _kCountryNames[code.toUpperCase()] ?? code;

  static const _kCountryNames = {
    'US': 'United States',
    'CN': 'China',
    'GB': 'United Kingdom',
    'DE': 'Germany',
    'FR': 'France',
    'JP': 'Japan',
    'IN': 'India',
    'AU': 'Australia',
    'CA': 'Canada',
    'IT': 'Italy',
    'KR': 'South Korea',
    'BR': 'Brazil',
    'NL': 'Netherlands',
    'ES': 'Spain',
    'RU': 'Russia',
    'CH': 'Switzerland',
    'SE': 'Sweden',
    'SG': 'Singapore',
    'PL': 'Poland',
    'TR': 'Turkey',
    'PT': 'Portugal',
    'BE': 'Belgium',
    'TW': 'Taiwan',
    'IR': 'Iran',
    'VN': 'Vietnam',
    'MX': 'Mexico',
    'NO': 'Norway',
    'DK': 'Denmark',
    'FI': 'Finland',
    'AT': 'Austria',
    'CZ': 'Czech Republic',
    'IL': 'Israel',
    'HK': 'Hong Kong',
    'ZA': 'South Africa',
    'EG': 'Egypt',
    'SA': 'Saudi Arabia',
    'MY': 'Malaysia',
    'PK': 'Pakistan',
    'GR': 'Greece',
    'HU': 'Hungary',
    'RO': 'Romania',
    'UA': 'Ukraine',
    'ID': 'Indonesia',
    'NZ': 'New Zealand',
    'TH': 'Thailand',
    'NG': 'Nigeria',
    'AR': 'Argentina',
    'CL': 'Chile',
    'CO': 'Colombia',
  };
}
