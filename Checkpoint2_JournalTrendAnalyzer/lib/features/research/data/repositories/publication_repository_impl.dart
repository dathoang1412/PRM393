import '../services/openalex_service.dart';

class PublicationRepository {
  const PublicationRepository({required OpenAlexService service})
      : _service = service;

  final OpenAlexService _service;

  Future<OpenAlexPage> search(String keyword, {int page = 1}) {
    return _service.searchWorks(keyword, page: page);
  }
}
