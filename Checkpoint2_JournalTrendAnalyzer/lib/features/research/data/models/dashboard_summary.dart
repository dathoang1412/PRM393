import 'author_stat.dart';
import 'journal_stat.dart';
import 'publication.dart';
import 'trend_point.dart';

class DashboardSummary {
  const DashboardSummary({
    required this.totalPublications,
    required this.averageCitations,
    required this.trends,
    this.mostActiveYear,
    this.topJournal,
    this.topAuthor,
    this.mostInfluentialPaper,
  });

  final int totalPublications;
  final double averageCitations;
  final int? mostActiveYear;
  final JournalStat? topJournal;
  final AuthorStat? topAuthor;
  final Publication? mostInfluentialPaper;
  final List<TrendPoint> trends;
}
