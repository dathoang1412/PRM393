import 'publication.dart';

/// One page of search results plus the total match count reported by
/// OpenAlex, so callers know whether more pages are available.
class OpenAlexPage {
  const OpenAlexPage({required this.publications, required this.totalCount});

  final List<Publication> publications;
  final int totalCount;
}
