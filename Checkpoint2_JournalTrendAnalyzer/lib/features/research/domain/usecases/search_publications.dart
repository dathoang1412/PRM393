import 'package:journexa/features/research/data/models/openalex_page.dart';
import 'package:journexa/features/research/domain/repositories/publication_repository.dart';

/// Searches OpenAlex for publications matching a keyword, one page at a time.
class SearchPublications {
  const SearchPublications(this._repository);

  final PublicationRepository _repository;

  Future<OpenAlexPage> call(String keyword, {int page = 1}) {
    return _repository.search(keyword, page: page);
  }
}
