import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:journexa/core/theme/app_colors.dart';
import 'package:journexa/core/widgets/metric_tile.dart';
import 'package:journexa/core/widgets/section_card.dart';
import 'package:journexa/features/research/domain/usecases/analytics_calculator.dart';
import '../viewmodels/research_viewmodel.dart';
import '../widgets/publication_card.dart';
import '../widgets/rank_row.dart';
import '../widgets/trend_chart.dart';
import 'publication_detail_screen.dart';

/// Keyword Detail (spec 4.7): trend, related journals/publications, and the
/// author ranking for one keyword within the loaded topic.
class KeywordDetailScreen extends StatelessWidget {
  const KeywordDetailScreen({required this.keyword, super.key});

  final String keyword;

  static const _color = AppColors.seriesKeywords;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ResearchViewModel>();
    final pubs = vm.filteredPublications
        .where((p) => p.keywords.contains(keyword))
        .toList()
      ..sort((a, b) => b.citedByCount.compareTo(a.citedByCount));

    final trends = AnalyticsCalculator.publicationTrends(pubs);
    final journals = AnalyticsCalculator.topJournals(pubs).take(8).toList();
    final authors = AnalyticsCalculator.topAuthors(pubs).take(10).toList();
    final totalCit = AnalyticsCalculator.totalCitations(pubs);
    final fmt = NumberFormat.decimalPattern();

    return Scaffold(
      appBar: AppBar(title: const Text('Keyword Analysis')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Header ────────────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primaryDark, AppColors.primary],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.label_outline,
                            color: Colors.white, size: 22),
                        const SizedBox(height: 8),
                        Text(
                          keyword,
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Within topic "${vm.keyword}"',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                  color:
                                      Colors.white.withValues(alpha: 0.8)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  LayoutBuilder(builder: (context, constraints) {
                    final aspect =
                        (constraints.maxWidth - 2 * 10) / 3 / 100.0;
                    return GridView.count(
                      crossAxisCount: 3,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: aspect,
                      children: [
                        MetricTile(
                          icon: Icons.article_outlined,
                          label: 'Publications',
                          value: fmt.format(pubs.length),
                          subtitle: 'mention this concept',
                          iconColor: _color,
                        ),
                        MetricTile(
                          icon: Icons.format_quote,
                          label: 'Total citations',
                          value: NumberFormat.compact().format(totalCit),
                          iconColor: _color,
                        ),
                        MetricTile(
                          icon: Icons.people_outline,
                          label: 'Contributors',
                          value: '${authors.length}+',
                          subtitle: 'ranked below',
                          iconColor: _color,
                        ),
                      ],
                    );
                  }),
                  if (trends.length >= 2) ...[
                    const SizedBox(height: 14),
                    SectionCard(
                      icon: Icons.show_chart,
                      iconColor: _color,
                      title: 'Publication Trend',
                      subtitle: 'Papers mentioning "$keyword" per year',
                      child: SizedBox(
                        height: 200,
                        child: TrendChart(
                          points: trends,
                          color: _color,
                          unit: 'papers',
                        ),
                      ),
                    ),
                  ],
                  if (authors.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    SectionCard(
                      icon: Icons.people_outline,
                      iconColor: AppColors.seriesAuthors,
                      title: 'Top Contributing Authors',
                      subtitle: 'Ranked by publications for this keyword',
                      child: Column(
                        children: authors.asMap().entries.map((e) {
                          return RankRow(
                            rank: e.key + 1,
                            name: e.value.name,
                            count: e.value.publicationCount,
                            total: pubs.length,
                            color: AppColors.seriesAuthors,
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                  if (journals.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    SectionCard(
                      icon: Icons.menu_book_outlined,
                      iconColor: AppColors.seriesVenues,
                      title: 'Related Journals',
                      subtitle: 'Venues publishing on this keyword',
                      child: Column(
                        children: journals.asMap().entries.map((e) {
                          return RankRow(
                            rank: e.key + 1,
                            name: e.value.name,
                            count: e.value.publicationCount,
                            total: pubs.length,
                            color: AppColors.seriesVenues,
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  Text(
                    'Related Publications (${pubs.length})',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                  ),
                  const SizedBox(height: 10),
                  ...pubs.take(20).map((p) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: PublicationCard(
                          publication: p,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  PublicationDetailScreen(publication: p),
                            ),
                          ),
                        ),
                      )),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
