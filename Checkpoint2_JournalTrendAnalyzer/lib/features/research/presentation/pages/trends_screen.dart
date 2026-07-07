import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../providers/research_provider.dart';
import '../utils/analytics_calculator.dart';
import '../widgets/empty_view.dart';
import '../widgets/horizontal_bar_chart.dart';
import '../widgets/insight_note.dart';
import '../widgets/metric_tile.dart';
import '../widgets/trend_chart.dart';
import '../widgets/year_range_filter.dart';

const _kGap = 16.0;
const _kGapSm = 10.0;
const _kMaxW = 1400.0;
const _kChartH = 252.0;

class TrendsScreen extends StatelessWidget {
  const TrendsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ResearchProvider>();

    if (provider.publications.isEmpty) {
      return const EmptyView(
        icon: Icons.trending_up,
        title: 'No trends yet',
        message: 'Search a topic to explore publication and citation trends.',
      );
    }

    final filtered = provider.filteredPublications;
    final trends = provider.trends;
    final citTrends = provider.citationTrends;
    final fmtCompact = NumberFormat.compact();
    final fmtDecimal = NumberFormat.decimalPattern();

    final totalCit = AnalyticsCalculator.totalCitations(filtered);
    final growthRate = AnalyticsCalculator.pubGrowthRate(trends);
    final yearRange = AnalyticsCalculator.yearRange(filtered);
    final sorted = [...trends]..sort((a, b) => b.count.compareTo(a.count));
    final peakYear = sorted.isNotEmpty ? sorted.first : null;

    final keywords = provider.topKeywords
        .take(15)
        .map((k) => BarItem(label: k.name, value: k.count))
        .toList();
    final countries = provider.topCountries
        .take(15)
        .map((c) => BarItem(label: c.name, value: c.count))
        .toList();

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding:
              const EdgeInsets.fromLTRB(_kGap, _kGap, _kGap, 0),
          sliver: SliverToBoxAdapter(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: _kMaxW),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final w = constraints.maxWidth;
                    final isWide = w > 900;
                    final isMed = w > 560;

                    // ── Year filter header ─────────────────────────────────
                    const filterSection = _FilterRow();

                    // ── KPI tiles ──────────────────────────────────────────
                    final isPositive = growthRate >= 0;
                    final growthLabel = growthRate == 0
                        ? 'Stable'
                        : '${isPositive ? '+' : ''}${growthRate.toStringAsFixed(0)}%';

                    const kpiCount = 4;
                    const targetTileH = 100.0;
                    final crossCount = isMed ? kpiCount : 2;
                    final kpiAspect =
                        (w - (crossCount - 1) * _kGapSm) /
                            crossCount /
                            targetTileH;

                    final kpiGrid = GridView.count(
                      crossAxisCount: crossCount,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: _kGapSm,
                      crossAxisSpacing: _kGapSm,
                      childAspectRatio: kpiAspect,
                      children: [
                        MetricTile(
                          icon: Icons.article_outlined,
                          label: 'Publications',
                          value: fmtDecimal.format(filtered.length),
                          subtitle: yearRange != null
                              ? '${yearRange.min}–${yearRange.max}'
                              : null,
                          iconColor: const Color(0xFF1D4ED8),
                        ),
                        MetricTile(
                          icon: Icons.format_quote,
                          label: 'Total citations',
                          value: fmtCompact.format(totalCit),
                          subtitle: 'across all papers',
                          iconColor: const Color(0xFFD97706),
                        ),
                        MetricTile(
                          icon: Icons.calendar_today_outlined,
                          label: 'Peak year',
                          value: peakYear?.year.toString() ?? 'N/A',
                          subtitle: peakYear != null
                              ? '${peakYear.count} papers'
                              : null,
                          iconColor: const Color(0xFF059669),
                        ),
                        MetricTile(
                          icon: isPositive
                              ? Icons.trending_up
                              : Icons.trending_down,
                          label: '5-yr growth',
                          value: growthLabel,
                          subtitle: 'vs prior 5 years',
                          iconColor: isPositive
                              ? const Color(0xFF059669)
                              : const Color(0xFFDC2626),
                        ),
                      ],
                    );

                    // ── Insight note ───────────────────────────────────────
                    Widget? insightWidget;
                    if (trends.length >= 4) {
                      insightWidget = InsightNote(
                        icon: isPositive
                            ? Icons.trending_up
                            : Icons.trending_down,
                        color: isPositive
                            ? const Color(0xFF059669)
                            : const Color(0xFFDC2626),
                        text: isPositive
                            ? 'Publication output grew ${growthRate.abs().toStringAsFixed(0)}% in the last 5 years (${DateTime.now().year - 4}–${DateTime.now().year}) compared to the prior 5-year period.'
                            : 'Publication output declined ${growthRate.abs().toStringAsFixed(0)}% in the last 5 years. This may reflect research focus shifts or data coverage limits.',
                      );
                    }

                    // ── Chart cards ────────────────────────────────────────
                    final pubChart = _Section(
                      icon: Icons.show_chart,
                      iconColor: const Color(0xFF1D4ED8),
                      title: 'Publication Activity',
                      subtitle: 'Number of papers published per year',
                      child: SizedBox(
                        height: _kChartH,
                        child: TrendChart(
                          points: trends,
                          color: const Color(0xFF1D4ED8),
                        ),
                      ),
                    );

                    final citChart = citTrends.isNotEmpty
                        ? _Section(
                            icon: Icons.format_quote,
                            iconColor: const Color(0xFFD97706),
                            title: 'Citation Activity',
                            subtitle:
                                'Total citations received per calendar year',
                            child: SizedBox(
                              height: _kChartH,
                              child: TrendChart(
                                points: citTrends,
                                color: const Color(0xFFD97706),
                                unit: 'citations',
                              ),
                            ),
                          )
                        : null;

                    final kwChart = keywords.isNotEmpty
                        ? _Section(
                            icon: Icons.label_outline,
                            iconColor: const Color(0xFF7C3AED),
                            title: 'Top Research Keywords',
                            subtitle: 'Most frequent OpenAlex concepts',
                            child: HorizontalBarChart(
                              items: keywords,
                              color: const Color(0xFF7C3AED),
                              maxItems: 15,
                            ),
                          )
                        : null;

                    final ctryChart = countries.isNotEmpty
                        ? _Section(
                            icon: Icons.public_outlined,
                            iconColor: const Color(0xFF059669),
                            title: 'Research by Country',
                            subtitle:
                                'Publications by author country of affiliation',
                            child: HorizontalBarChart(
                              items: countries,
                              color: const Color(0xFF059669),
                              maxItems: 15,
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
                          kpiGrid,
                          if (insightWidget != null) ...[
                            const SizedBox(height: _kGapSm),
                            insightWidget,
                          ],
                          const SizedBox(height: _kGap),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: pubChart),
                              if (citChart != null) ...[
                                const SizedBox(width: _kGap),
                                Expanded(child: citChart),
                              ],
                            ],
                          ),
                          if (kwChart != null || ctryChart != null) ...[
                            const SizedBox(height: _kGap),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (kwChart != null) Expanded(child: kwChart),
                                if (kwChart != null && ctryChart != null)
                                  const SizedBox(width: _kGap),
                                if (ctryChart != null)
                                  Expanded(child: ctryChart),
                              ],
                            ),
                          ],
                        ],
                      );
                    }

                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        filterSection,
                        const SizedBox(height: _kGap),
                        kpiGrid,
                        if (insightWidget != null) ...[
                          const SizedBox(height: _kGapSm),
                          insightWidget,
                        ],
                        const SizedBox(height: _kGap),
                        pubChart,
                        if (citChart != null) ...[
                          const SizedBox(height: _kGap),
                          citChart,
                        ],
                        if (kwChart != null) ...[
                          const SizedBox(height: _kGap),
                          kwChart,
                        ],
                        if (ctryChart != null) ...[
                          const SizedBox(height: _kGap),
                          ctryChart,
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

// ── Filter row ────────────────────────────────────────────────────────────────

class _FilterRow extends StatelessWidget {
  const _FilterRow();

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

class _Section extends StatelessWidget {
  const _Section({
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
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: child,
          ),
        ],
      ),
    );
  }
}
