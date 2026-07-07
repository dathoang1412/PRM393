import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../providers/research_provider.dart';
import 'package:journexa/features/research/domain/usecases/analytics_calculator.dart';
import 'package:journexa/core/widgets/donut_chart.dart';
import 'package:journexa/core/widgets/empty_view.dart';
import 'package:journexa/core/widgets/horizontal_bar_chart.dart';
import 'package:journexa/core/widgets/insight_note.dart';
import 'package:journexa/core/widgets/metric_tile.dart';
import 'package:journexa/core/theme/app_colors.dart';
import 'package:journexa/core/widgets/section_card.dart';
import '../widgets/filter_header.dart';
import '../widgets/publication_card.dart';
import '../widgets/trend_chart.dart';
import 'publication_detail_screen.dart';

// ── Design tokens ─────────────────────────────────────────────────────────────
const _kGap = 16.0;
const _kGapSm = 10.0;
const _kMaxContentWidth = 1400.0;
const _kChartHeight = 252.0;

/// Dashboard tab body — hosted inside [TrendsHubScreen], which owns the
/// app bar, context bar, and CSV export.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({this.onChangeTopic, super.key});

  /// Switches back to the Research tab from the empty state.
  final VoidCallback? onChangeTopic;

  static const _colorPublications = AppColors.seriesPublications;
  static const _colorCitations = AppColors.seriesCitations;
  static const _colorVenue = AppColors.seriesVenues;
  static const _colorAuthor = AppColors.seriesAuthors;
  static const _colorPaper = AppColors.seriesPapers;
  static const _colorKeyword = AppColors.seriesKeywords;
  static const _colorCountry = AppColors.seriesCountries;

  static const _donutPalette = AppColors.chartPalette;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ResearchProvider>();

    if (provider.publications.isEmpty) {
      return EmptyView(
        icon: Icons.dashboard_outlined,
        title: 'No dashboard yet',
        message: 'Search a topic first to generate trend insights.',
        actionLabel: onChangeTopic != null ? 'Search a topic' : null,
        onAction: onChangeTopic,
      );
    }
    return _buildBody(context, provider);
  }

  Widget _buildBody(BuildContext context, ResearchProvider provider) {
    final filtered = provider.filteredPublications;
    final summary = provider.summary;
    final fmt = NumberFormat.decimalPattern();
    final fmtCompact = NumberFormat.compact();

    final totalCit = AnalyticsCalculator.totalCitations(filtered);
    final medCit = AnalyticsCalculator.medianCitations(filtered);
    final yearRange = AnalyticsCalculator.yearRange(filtered);
    final growthRate = AnalyticsCalculator.pubGrowthRate(provider.trends);

    // Most active year from the corpus-wide trend when available, so the KPI
    // reflects the topic's real peak rather than the loaded sample's.
    final byCount = [...provider.trends]
      ..sort((a, b) => b.count.compareTo(a.count));
    final peakYear = byCount.isNotEmpty ? byCount.first : null;

    final metrics = [
      MetricTile(
        icon: Icons.article_outlined,
        label: 'Total publications',
        value: fmt.format(provider.totalWorksInRange),
        subtitle: provider.hasCorpusTrends
            ? 'analyzing top ${fmt.format(filtered.length)} by citations'
            : (provider.hasYearFilter
                ? 'of ${provider.publications.length} loaded'
                : (yearRange != null
                    ? '${yearRange.min}–${yearRange.max}'
                    : null)),
        iconColor: _colorPublications,
      ),
      MetricTile(
        icon: Icons.format_quote,
        label: 'Avg citations',
        value: summary.averageCitations.toStringAsFixed(1),
        subtitle: 'median: $medCit',
        iconColor: _colorCitations,
      ),
      MetricTile(
        icon: Icons.calendar_month_outlined,
        label: 'Most active year',
        value: peakYear?.year.toString() ?? 'N/A',
        subtitle:
            peakYear != null ? '${fmt.format(peakYear.count)} papers' : null,
        iconColor: _colorCountry,
      ),
      MetricTile(
        icon: Icons.menu_book_outlined,
        label: 'Top venue',
        value: summary.topJournal?.name ?? 'N/A',
        subtitle: summary.topJournal != null
            ? '${summary.topJournal!.publicationCount} papers'
            : null,
        iconColor: _colorVenue,
      ),
      MetricTile(
        icon: Icons.person_outline,
        label: 'Top author',
        value: summary.topAuthor?.name ?? 'N/A',
        subtitle: summary.topAuthor != null
            ? '${summary.topAuthor!.publicationCount} papers'
            : null,
        iconColor: _colorAuthor,
      ),
      MetricTile(
        icon: Icons.star_outline,
        label: 'Total citations',
        value: fmtCompact.format(totalCit),
        subtitle: 'across all papers',
        iconColor: _colorPaper,
      ),
    ];

    final citTrends = provider.citationTrends;
    final typeEntries = provider.workTypes;
    final donutSlices = typeEntries.take(7).toList().asMap().entries.map((e) {
      return DonutSlice(
        label: e.value.key,
        value: e.value.value,
        color: _donutPalette[e.key % _donutPalette.length],
      );
    }).toList();

    final keywordItems = provider.topKeywords
        .take(6)
        .map((k) => BarItem(label: k.name, value: k.count))
        .toList();

    final countryItems = provider.topCountries
        .take(6)
        .map((c) => BarItem(label: c.name, value: c.count))
        .toList();

    // Spec 4.7: the dashboard must surface the most influential paper.
    final topPaper = summary.mostInfluentialPaper;
    final paperCard = topPaper != null
        ? SectionCard(
            icon: Icons.workspace_premium_outlined,
            iconColor: _colorPaper,
            title: 'Most Influential Paper',
            subtitle: 'Highest citation count for this topic',
            child: PublicationCard(
              publication: topPaper,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      PublicationDetailScreen(publication: topPaper),
                ),
              ),
            ),
          )
        : null;

    // Growth insight note
    Widget? insightWidget;
    if (!provider.hasYearFilter &&
        growthRate != 0 &&
        provider.trends.length >= 4) {
      final isPositive = growthRate > 0;
      final pct = growthRate.abs().toStringAsFixed(0);
      insightWidget = InsightNote(
        icon: isPositive ? Icons.trending_up : Icons.trending_down,
        color: isPositive
            ? const Color(0xFF12896B)
            : const Color(0xFFB42318),
        text: isPositive
            ? 'Publication volume grew $pct% in the last 5 years vs. the prior 5-year period.'
            : 'Publication volume declined $pct% in the last 5 years vs. the prior 5-year period.',
      );
    } else if (provider.hasYearFilter) {
      insightWidget = InsightNote(
        icon: Icons.filter_alt_outlined,
        color: const Color(0xFF6D4FA3),
        text:
            'Showing ${filtered.length} of ${provider.publications.length} publications in the selected year range.',
      );
    }

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
              _kGap, _kGap, _kGap, 0),
          sliver: SliverToBoxAdapter(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints:
                    const BoxConstraints(maxWidth: _kMaxContentWidth),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final w = constraints.maxWidth;
                    final isWide = w > 900;
                    final isMed = w > 580;

                    // ── Year filter header ─────────────────────────────────
                    const filterSection = FilterHeader();

                    // ── KPI metric grid ────────────────────────────────────
                    const targetTileH = 100.0;
                    final crossCount = isWide ? 3 : (isMed ? 3 : 2);
                    final metricAspect =
                        (w - (crossCount - 1) * _kGapSm) /
                            crossCount /
                            targetTileH;

                    final metricGrid = GridView.count(
                      crossAxisCount: crossCount,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: _kGapSm,
                      crossAxisSpacing: _kGapSm,
                      childAspectRatio: metricAspect,
                      children: metrics,
                    );

                    // ── Chart cards ────────────────────────────────────────
                    final pubTrendCard = SectionCard(
                      icon: Icons.show_chart,
                      iconColor: _colorPublications,
                      title: 'Publication Activity',
                      subtitle: provider.hasCorpusTrends
                          ? 'Papers per year — all matching works on OpenAlex'
                          : 'Papers per year (loaded results)',
                      child: SizedBox(
                        height: _kChartHeight,
                        child: TrendChart(
                          points: provider.trends,
                          unit: 'papers',
                        ),
                      ),
                    );

                    final citTrendCard = citTrends.isNotEmpty
                        ? SectionCard(
                            icon: Icons.format_quote,
                            iconColor: _colorCitations,
                            title: 'Citation Activity',
                            subtitle: 'Citations received per calendar year',
                            child: SizedBox(
                              height: _kChartHeight,
                              child: TrendChart(
                                points: citTrends,
                                color: _colorCitations,
                                unit: 'citations',
                              ),
                            ),
                          )
                        : null;

                    final donutCard = donutSlices.isNotEmpty
                        ? SectionCard(
                            icon: Icons.donut_large_outlined,
                            iconColor: _colorVenue,
                            title: 'Publication Type Distribution',
                            subtitle: 'Breakdown by work type',
                            child: SizedBox(
                              height: _kChartHeight,
                              child: DonutChart(
                                slices: donutSlices,
                                centerLabel: 'Works',
                              ),
                            ),
                          )
                        : null;

                    final keywordsCard = keywordItems.isNotEmpty
                        ? SectionCard(
                            icon: Icons.label_outline,
                            iconColor: _colorKeyword,
                            title: 'Top Research Keywords',
                            subtitle: 'Most frequent OpenAlex concepts',
                            child: HorizontalBarChart(
                              items: keywordItems,
                              color: _colorKeyword,
                              maxItems: 6,
                            ),
                          )
                        : null;

                    final countriesCard = countryItems.isNotEmpty
                        ? SectionCard(
                            icon: Icons.public_outlined,
                            iconColor: _colorCountry,
                            title: 'Research by Country',
                            subtitle: 'Publications by author country',
                            child: HorizontalBarChart(
                              items: countryItems,
                              color: _colorCountry,
                              maxItems: 6,
                            ),
                          )
                        : null;

                    if (isWide) {
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          filterSection,
                          const SizedBox(height: _kGap),
                          metricGrid,
                          if (insightWidget != null) ...[
                            const SizedBox(height: _kGapSm),
                            insightWidget,
                          ],
                          if (paperCard != null) ...[
                            const SizedBox(height: _kGap),
                            paperCard,
                          ],
                          const SizedBox(height: _kGap),
                          // Row 1: pub chart (60%) + donut (40%)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(flex: 6, child: pubTrendCard),
                              if (donutCard != null) ...[
                                const SizedBox(width: _kGap),
                                Expanded(flex: 4, child: donutCard),
                              ],
                            ],
                          ),
                          // Row 2: cit chart (50%) + keywords (50%)
                          if (citTrendCard != null ||
                              keywordsCard != null) ...[
                            const SizedBox(height: _kGap),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (citTrendCard != null)
                                  Expanded(child: citTrendCard),
                                if (citTrendCard != null &&
                                    keywordsCard != null)
                                  const SizedBox(width: _kGap),
                                if (keywordsCard != null)
                                  Expanded(child: keywordsCard),
                              ],
                            ),
                          ],
                          if (countriesCard != null) ...[
                            const SizedBox(height: _kGap),
                            countriesCard,
                          ],
                        ],
                      );
                    }

                    // Medium / mobile stacked
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        filterSection,
                        const SizedBox(height: _kGap),
                        metricGrid,
                        if (insightWidget != null) ...[
                          const SizedBox(height: _kGapSm),
                          insightWidget,
                        ],
                        if (paperCard != null) ...[
                          const SizedBox(height: _kGap),
                          paperCard,
                        ],
                        const SizedBox(height: _kGap),
                        pubTrendCard,
                        if (citTrendCard != null) ...[
                          const SizedBox(height: _kGap),
                          citTrendCard,
                        ],
                        if (donutCard != null) ...[
                          const SizedBox(height: _kGap),
                          donutCard,
                        ],
                        if (keywordsCard != null) ...[
                          const SizedBox(height: _kGap),
                          keywordsCard,
                        ],
                        if (countriesCard != null) ...[
                          const SizedBox(height: _kGap),
                          countriesCard,
                        ],
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
        const SliverPadding(padding: EdgeInsets.only(bottom: 28)),
      ],
    );
  }
}
