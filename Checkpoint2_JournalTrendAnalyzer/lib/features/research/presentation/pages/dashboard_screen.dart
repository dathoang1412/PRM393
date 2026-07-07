import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../providers/research_provider.dart';
import '../utils/analytics_calculator.dart';
import '../widgets/donut_chart.dart';
import '../widgets/empty_view.dart';
import '../widgets/horizontal_bar_chart.dart';
import '../widgets/insight_note.dart';
import '../widgets/metric_tile.dart';
import '../widgets/trend_chart.dart';
import '../widgets/year_range_filter.dart';

// ── Design tokens ─────────────────────────────────────────────────────────────
const _kGap = 16.0;
const _kGapSm = 10.0;
const _kMaxContentWidth = 1400.0;
const _kChartHeight = 252.0;

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  static const _colorPublications = Color(0xFF1D4ED8);
  static const _colorCitations = Color(0xFFD97706);
  static const _colorVenue = Color(0xFF7C3AED);
  static const _colorAuthor = Color(0xFF0891B2);
  static const _colorPaper = Color(0xFFEA580C);
  static const _colorKeyword = Color(0xFF7C3AED);
  static const _colorCountry = Color(0xFF059669);

  static const _donutPalette = [
    Color(0xFF1D4ED8),
    Color(0xFF7C3AED),
    Color(0xFF059669),
    Color(0xFFD97706),
    Color(0xFF0891B2),
    Color(0xFFEA580C),
    Color(0xFF64748B),
  ];

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ResearchProvider>();

    if (provider.publications.isEmpty) {
      return const EmptyView(
        icon: Icons.dashboard_outlined,
        title: 'No dashboard yet',
        message: 'Search a topic first to generate trend insights.',
      );
    }

    final filtered = provider.filteredPublications;
    final summary = provider.summary;
    final fmt = NumberFormat.decimalPattern();
    final fmtCompact = NumberFormat.compact();

    final totalCit = AnalyticsCalculator.totalCitations(filtered);
    final medCit = AnalyticsCalculator.medianCitations(filtered);
    final highCit = AnalyticsCalculator.highlyCited(filtered);
    final yearRange = AnalyticsCalculator.yearRange(filtered);
    final growthRate = AnalyticsCalculator.pubGrowthRate(provider.trends);

    final metrics = [
      MetricTile(
        icon: Icons.article_outlined,
        label: 'Publications',
        value: fmt.format(summary.totalPublications),
        subtitle: provider.hasYearFilter
            ? 'of ${provider.publications.length} total'
            : (yearRange != null ? '${yearRange.min}–${yearRange.max}' : null),
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
        icon: Icons.emoji_events_outlined,
        label: 'Highly cited',
        value: '$highCit papers',
        subtitle: '>100 citations each',
        iconColor: const Color(0xFFD97706),
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
            ? const Color(0xFF059669)
            : const Color(0xFFDC2626),
        text: isPositive
            ? 'Publication volume grew $pct% in the last 5 years vs. the prior 5-year period.'
            : 'Publication volume declined $pct% in the last 5 years vs. the prior 5-year period.',
      );
    } else if (provider.hasYearFilter) {
      insightWidget = InsightNote(
        icon: Icons.filter_alt_outlined,
        color: const Color(0xFF7C3AED),
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
                    const filterSection = _FilterHeader();

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
                    final pubTrendCard = _SectionCard(
                      icon: Icons.show_chart,
                      iconColor: _colorPublications,
                      title: 'Publication Activity',
                      subtitle: 'Papers published per year',
                      child: SizedBox(
                        height: _kChartHeight,
                        child: TrendChart(
                          points: summary.trends,
                          unit: 'papers',
                        ),
                      ),
                    );

                    final citTrendCard = citTrends.isNotEmpty
                        ? _SectionCard(
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
                        ? _SectionCard(
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
                        ? _SectionCard(
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
                        ? _SectionCard(
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

// ── Filter header row ─────────────────────────────────────────────────────────

class _FilterHeader extends StatelessWidget {
  const _FilterHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0xFFBFDBFE)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.calendar_month_outlined,
                  size: 12, color: Color(0xFF1D4ED8)),
              const SizedBox(width: 5),
              Text(
                'YEAR FILTER',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: const Color(0xFF1D4ED8),
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                      fontSize: 10,
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        const Expanded(child: YearRangeFilter()),
      ],
    );
  }
}

// ── Section card ──────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: Color(0xFFE8EDF5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Card header with top-accent bar
          Container(
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.03),
              border: Border(
                top: BorderSide(color: iconColor, width: 2.5),
                bottom: const BorderSide(color: Color(0xFFEEF2FF)),
              ),
            ),
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Icon(icon, size: 14, color: iconColor),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style:
                            Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF1E293B),
                                  fontSize: 13,
                                ),
                      ),
                      Text(
                        subtitle,
                        style:
                            Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: const Color(0xFF94A3B8),
                                  fontSize: 11,
                                ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Card body
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: child,
          ),
        ],
      ),
    );
  }
}
