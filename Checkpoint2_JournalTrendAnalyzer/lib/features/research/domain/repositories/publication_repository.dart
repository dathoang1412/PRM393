import 'package:journexa/features/research/data/models/openalex_page.dart';
import 'package:journexa/features/research/data/models/trend_point.dart';

/// Contract for fetching publications, implemented by the data layer
/// ([PublicationRepositoryImpl]) so the presentation layer never depends on
/// a concrete data source.
abstract class PublicationRepository {
  Future<OpenAlexPage> search(String keyword, {int page = 1});

  /// Publication counts per year across the entire corpus matching
  /// [keyword] (not just the loaded pages).
  Future<List<TrendPoint>> yearCounts(String keyword);
}
