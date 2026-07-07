import '../utils/abstract_parser.dart';
import 'year_count.dart';

class Publication {
  const Publication({
    required this.id,
    required this.title,
    required this.citedByCount,
    required this.authors,
    required this.keywords,
    required this.institutions,
    required this.countries,
    required this.citationsByYear,
    this.doi,
    this.publicationYear,
    this.journalName,
    this.abstractText,
    this.workType,
  });

  final String id;
  final String? doi;
  final String title;
  final int? publicationYear;
  final int citedByCount;
  final List<String> authors;
  final String? journalName;
  final String? abstractText;
  final String? workType;

  // enriched fields
  final List<String> keywords;
  final List<String> institutions;
  final List<String> countries;
  final List<YearCount> citationsByYear;

  factory Publication.fromJson(Map<String, dynamic> json) {
    final authorships = json['authorships'];

    // ── Authors ──────────────────────────────────────────────────────────────
    final authors = authorships is List
        ? authorships
            .whereType<Map<String, dynamic>>()
            .map((item) => item['author'])
            .whereType<Map<String, dynamic>>()
            .map((a) => a['display_name'])
            .whereType<String>()
            .where((name) => name.trim().isNotEmpty)
            .toSet()
            .toList()
        : <String>[];

    // ── Institutions from authorships ─────────────────────────────────────────
    final institutions = authorships is List
        ? authorships
            .whereType<Map<String, dynamic>>()
            .expand((a) {
              final insts = a['institutions'];
              if (insts is! List) return <String>[];
              return insts
                  .whereType<Map<String, dynamic>>()
                  .map((i) => i['display_name'])
                  .whereType<String>()
                  .where((n) => n.trim().isNotEmpty);
            })
            .toSet()
            .toList()
        : <String>[];

    // ── Countries from authorships ────────────────────────────────────────────
    final countries = authorships is List
        ? authorships
            .whereType<Map<String, dynamic>>()
            .expand((a) {
              final cs = a['countries'];
              if (cs is! List) return <String>[];
              return cs.whereType<String>();
            })
            .toSet()
            .toList()
        : <String>[];

    // ── Keywords from concepts ────────────────────────────────────────────────
    final concepts = json['concepts'];
    final keywords = concepts is List
        ? concepts
            .whereType<Map<String, dynamic>>()
            .where((c) {
              final level = c['level'];
              final score = c['score'];
              return (level is int && level >= 1) &&
                  (score is num && score >= 0.2);
            })
            .map((c) => c['display_name'])
            .whereType<String>()
            .where((n) => n.trim().isNotEmpty)
            .toList()
        : <String>[];

    // ── Citations by year ─────────────────────────────────────────────────────
    final cby = json['counts_by_year'];
    final citationsByYear = cby is List
        ? cby
            .whereType<Map<String, dynamic>>()
            .where((yc) {
              final y = yc['year'];
              final c = yc['cited_by_count'];
              return y is int && c is int && c > 0;
            })
            .map((yc) => YearCount(
                  year: yc['year'] as int,
                  citedByCount: yc['cited_by_count'] as int,
                ))
            .toList()
        : <YearCount>[];

    return Publication(
      id: _stringValue(json['id']) ?? '',
      doi: _stringValue(json['doi']),
      title: _stringValue(json['display_name']) ??
          _stringValue(json['title']) ??
          'Untitled publication',
      publicationYear: _intValue(json['publication_year']),
      citedByCount: _intValue(json['cited_by_count']) ?? 0,
      workType: _stringValue(json['type']),
      authors: authors,
      institutions: institutions,
      countries: countries,
      keywords: keywords,
      citationsByYear: citationsByYear,
      journalName: _extractJournalName(json),
      abstractText: parseAbstractInvertedIndex(json['abstract_inverted_index']),
    );
  }

  static String? _extractJournalName(Map<String, dynamic> json) {
    final primaryLocation = json['primary_location'];
    if (primaryLocation is Map<String, dynamic>) {
      final source = primaryLocation['source'];
      if (source is Map<String, dynamic>) {
        final name = _stringValue(source['display_name']);
        if (name != null) return name;
      }
    }
    final hostVenue = json['host_venue'];
    if (hostVenue is Map<String, dynamic>) {
      return _stringValue(hostVenue['display_name']);
    }
    return null;
  }

  static String? _stringValue(Object? value) {
    if (value is! String) return null;
    final stripped = value.replaceAll(RegExp(r'<[^>]*>'), '').trim();
    return stripped.isNotEmpty ? stripped : null;
  }

  static int? _intValue(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
}
