import 'package:journexa/features/research/data/datasources/openalex_service.dart';
import 'package:journexa/features/research/data/models/openalex_page.dart';
import 'package:journexa/features/research/data/models/trend_point.dart';
import 'package:journexa/features/research/domain/repositories/publication_repository.dart';

class PublicationRepositoryImpl implements PublicationRepository {
  const PublicationRepositoryImpl({required OpenAlexService service})
      : _service = service;

  final OpenAlexService _service;

  @override
  Future<OpenAlexPage> search(String keyword, {int page = 1}) {
    return _service.searchWorks(keyword, page: page);
  }

  @override
  Future<List<TrendPoint>> yearCounts(String keyword) {
    return _service.yearCounts(keyword);
  }
}
