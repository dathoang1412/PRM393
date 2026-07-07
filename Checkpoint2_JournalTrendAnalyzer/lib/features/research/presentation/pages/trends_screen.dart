import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../providers/research_provider.dart';
import 'package:journexa/features/research/domain/usecases/analytics_calculator.dart';
import 'package:journexa/core/widgets/empty_view.dart';
import 'package:journexa/core/widgets/horizontal_bar_chart.dart';
import 'package:journexa/core/widgets/insight_note.dart';
import 'package:journexa/core/widgets/metric_tile.dart';
import 'package:journexa/core/widgets/section_card.dart';
import '../widgets/filter_header.dart';
import '../widgets/trend_chart.dart';

const _kGap = 16.0;
const _kGapSm = 10.0;
const _kMaxW = 1400.0;
const _kChartH = 252.0;

/// Trend-analysis tab body — hosted inside [TrendsHubScreen], which owns
/// the app bar, context bar, and CSV export.
class TrendsScreen extends StatelessWidget {
  const TrendsScreen({this.onChangeTopic, super.key});

  /// Switches back to the Research tab from the empty state.
  final VoidCallback? onChangeTopic;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ResearchProvider>();

    if (provider.publications.isEmpty) {
      return EmptyView(
        icon: Icons.trending_up,
        title: 'No trends yet',
        message: 'Search a topic to explore publication and citation trends.',
        actionLabel: onChangeTopic != null ? 'Search a topic' : null,
        onAction: onChangeTopic,
      );
    }
    return _buildBody(context, provider);
  }

  Widget _buildBody(BuildContext context, ResearchProvider provider) {
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
                    const filterSection = FilterHeader();

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
                          label: 'Total works',
                          value:
                              fmtDecimal.format(provider.totalWorksInRange),
                          subtitle: provider.hasCorpusTrends
                              ? 'matching this topic'
                              : (yearRange != null
                                  ? '${yearRange.min}–${yearRange.max}'
                                  : null),
                          iconColor: const Color(0xFF2E67B2),
                        ),
                        MetricTile(
                          icon: Icons.format_quote,
                          label: 'Total citations',
                          value: fmtCompact.format(totalCit),
                          subtitle: 'across all papers',
                          iconColor: const Color(0xFFB45309),
                        ),
                        MetricTile(
                          icon: Icons.calendar_today_outlined,
                          label: 'Peak year',
                          value: peakYear?.year.toString() ?? 'N/A',
                          subtitle: peakYear != null
                              ? '${peakYear.count} papers'
                              : null,
                          iconColor: const Color(0xFF12896B),
                        ),
                        MetricTile(
                          icon: isPositive
                              ? Icons.trending_up
                              : Icons.trending_down,
                          label: '5-yr growth',
                          value: growthLabel,
                          subtitle: 'vs prior 5 years',
                          iconColor: isPositive
                              ? const Color(0xFF12896B)
                              : const Color(0xFFB42318),
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
                            ? const Color(0xFF12896B)
                            : const Color(0xFFB42318),
                        text: isPositive
                            ? 'Publication output grew ${growthRate.abs().toStringAsFixed(0)}% in the last 5 years (${DateTime.now().year - 4}–${DateTime.now().year}) compared to the prior 5-year period.'
                            : 'Publication output declined ${growthRate.abs().toStringAsFixed(0)}% in the last 5 years. This may reflect research focus shifts or data coverage limits.',
                      );
                    }

                    // ── Chart cards ────────────────────────────────────────
                    final pubChart = SectionCard(
                      icon: Icons.show_chart,
                      iconColor: const Color(0xFF2E67B2),
                      title: 'Publication Activity',
                      subtitle: provider.hasCorpusTrends
                          ? 'Papers per year — all matching works on OpenAlex'
                          : 'Papers per year (loaded results)',
                      child: SizedBox(
                        height: _kChartH,
                        child: TrendChart(
                          points: trends,
                          color: const Color(0xFF2E67B2),
                        ),
                      ),
                    );

                    final citChart = citTrends.isNotEmpty
                        ? SectionCard(
                            icon: Icons.format_quote,
                            iconColor: const Color(0xFFB45309),
                            title: 'Citation Activity',
                            subtitle:
                                'Citations per year — top-cited loaded papers',
                            child: SizedBox(
                              height: _kChartH,
                              child: TrendChart(
                                points: citTrends,
                                color: const Color(0xFFB45309),
                                unit: 'citations',
                              ),
                            ),
                          )
                        : null;

                    final kwChart = keywords.isNotEmpty
                        ? SectionCard(
                            icon: Icons.label_outline,
                            iconColor: const Color(0xFF6D4FA3),
                            title: 'Top Research Keywords',
                            subtitle: 'Most frequent OpenAlex concepts',
                            child: HorizontalBarChart(
                              items: keywords,
                              color: const Color(0xFF6D4FA3),
                              maxItems: 15,
                            ),
                          )
                        : null;

                    final ctryChart = countries.isNotEmpty
                        ? SectionCard(
                            icon: Icons.public_outlined,
                            iconColor: const Color(0xFF12896B),
                            title: 'Research by Country',
                            subtitle:
                                'Publications by author country of affiliation',
                            child: HorizontalBarChart(
                              items: countries,
                              color: const Color(0xFF12896B),
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
