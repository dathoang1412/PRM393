import 'package:journexa/features/research/data/models/trend_point.dart';
import 'package:journexa/features/research/domain/repositories/publication_repository.dart';

/// Fetches corpus-wide publication counts per year for a topic, powering
/// the trend charts with unbiased data (the paged search results only cover
/// the most-cited papers).
class GetYearCounts {
  const GetYearCounts(this._repository);

  final PublicationRepository _repository;

  Future<List<TrendPoint>> call(String keyword) {
    return _repository.yearCounts(keyword);
  }
}
