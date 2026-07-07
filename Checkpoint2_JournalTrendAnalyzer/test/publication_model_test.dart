import 'package:flutter_test/flutter_test.dart';
import 'package:journexa/features/research/data/models/publication.dart';
import 'package:journexa/core/utils/abstract_parser.dart';

void main() {
  group('Publication.fromJson', () {
    test('parses a fully-populated OpenAlex work', () {
      final json = {
        'id': 'https://openalex.org/W123',
        'doi': 'https://doi.org/10.1/x',
        'display_name': 'A <b>Great</b> Paper',
        'publication_year': 2021,
        'cited_by_count': 42,
        'type': 'article',
        'counts_by_year': [
          {'year': 2021, 'cited_by_count': 10},
          {'year': 2022, 'cited_by_count': 0}, // filtered out: c == 0
          {'year': 'bad', 'cited_by_count': 5}, // filtered out: year not int
        ],
        'authorships': [
          {
            'author': {'display_name': 'Ada Lovelace'},
            'institutions': [
              {'display_name': 'Analytical Engines Inc'}
            ],
            'countries': ['GB'],
          },
          {
            'author': {'display_name': 'Ada Lovelace'}, // duplicate, deduped
            'institutions': [],
            'countries': ['GB'],
          },
        ],
        'primary_location': {
          'source': {'display_name': 'Journal of Computing'}
        },
        'concepts': [
          {'display_name': 'Computer Science', 'level': 1, 'score': 0.5},
          {'display_name': 'Too Broad', 'level': 0, 'score': 0.9}, // filtered: level < 1
          {'display_name': 'Too Weak', 'level': 2, 'score': 0.1}, // filtered: score < 0.2
        ],
        'abstract_inverted_index': {
          'Hello': [0],
          'world': [1],
        },
      };

      final pub = Publication.fromJson(json);

      expect(pub.id, 'https://openalex.org/W123');
      expect(pub.doi, 'https://doi.org/10.1/x');
      expect(pub.title, 'A Great Paper'); // HTML tags stripped
      expect(pub.publicationYear, 2021);
      expect(pub.citedByCount, 42);
      expect(pub.workType, 'article');
      expect(pub.authors, ['Ada Lovelace']); // deduplicated
      expect(pub.institutions, ['Analytical Engines Inc']);
      expect(pub.countries, ['GB']);
      expect(pub.keywords, ['Computer Science']);
      expect(pub.journalName, 'Journal of Computing');
      expect(pub.abstractText, 'Hello world');
      expect(pub.citationsByYear, hasLength(1));
      expect(pub.citationsByYear.single.year, 2021);
      expect(pub.citationsByYear.single.citedByCount, 10);
    });

    test('falls back to "title" then "Untitled publication" for the name', () {
      expect(
        Publication.fromJson({'title': 'Plain title'}).title,
        'Plain title',
      );
      expect(Publication.fromJson(const {}).title, 'Untitled publication');
    });

    test('falls back to host_venue when primary_location has no source', () {
      final pub = Publication.fromJson({
        'host_venue': {'display_name': 'Legacy Venue'},
      });
      expect(pub.journalName, 'Legacy Venue');
    });

    test('defaults missing/malformed fields to empty without throwing', () {
      final pub = Publication.fromJson({
        'authorships': 'not-a-list',
        'concepts': null,
        'counts_by_year': 12345,
      });

      expect(pub.id, '');
      expect(pub.citedByCount, 0);
      expect(pub.publicationYear, isNull);
      expect(pub.authors, isEmpty);
      expect(pub.institutions, isEmpty);
      expect(pub.countries, isEmpty);
      expect(pub.keywords, isEmpty);
      expect(pub.citationsByYear, isEmpty);
      expect(pub.journalName, isNull);
      expect(pub.abstractText, isNull);
    });

    test('parses publication_year and cited_by_count from numeric or string JSON', () {
      final pub = Publication.fromJson({
        'publication_year': '2019',
        'cited_by_count': 7.0,
      });

      expect(pub.publicationYear, 2019);
      expect(pub.citedByCount, 7);
    });
  });

  group('parseAbstractInvertedIndex', () {
    test('reconstructs word order from position indices', () {
      final text = parseAbstractInvertedIndex({
        'fox': [2],
        'quick': [0],
        'brown': [1],
      });
      expect(text, 'quick brown fox');
    });

    test('returns null for empty or non-map input', () {
      expect(parseAbstractInvertedIndex(null), isNull);
      expect(parseAbstractInvertedIndex('nope'), isNull);
      expect(parseAbstractInvertedIndex(const <String, dynamic>{}), isNull);
    });
  });
}
