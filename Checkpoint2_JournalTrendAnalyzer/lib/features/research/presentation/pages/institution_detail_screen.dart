import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:journexa/core/theme/app_colors.dart';
import 'package:journexa/core/widgets/app_bar_brand_title.dart';
import 'package:journexa/core/widgets/metric_tile.dart';
import 'package:journexa/core/widgets/section_card.dart';
import 'package:journexa/features/research/domain/usecases/analytics_calculator.dart';
import '../viewmodels/research_viewmodel.dart';
import '../widgets/notification_bell.dart';
import '../widgets/publication_card.dart';
import '../widgets/trend_chart.dart';
import 'publication_detail_screen.dart';

/// Institution Detail: stats and related publications for one institution
/// within the loaded topic. Reachable from Rankings → Institutions and from
/// institution tags on Publication Detail.
class InstitutionDetailScreen extends StatelessWidget {
  const InstitutionDetailScreen({required this.institutionName, super.key});

  final String institutionName;

  static const _color = AppColors.seriesCitations;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ResearchViewModel>();
    final pubs = vm.filteredPublications
        .where((p) => p.institutions.contains(institutionName))
        .toList()
      ..sort((a, b) => b.citedByCount.compareTo(a.citedByCount));

    final totalCit = AnalyticsCalculator.totalCitations(pubs);
    final avgCit = pubs.isEmpty ? 0.0 : totalCit / pubs.length;
    final trends = AnalyticsCalculator.publicationTrends(pubs);
    final fmt = NumberFormat.decimalPattern();

    return Scaffold(
      appBar: AppBar(
        title: const AppBarBrandTitle('Institution Details'),
        actions: const [NotificationBell(), SizedBox(width: 4)],
      ),
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
                        const Icon(Icons.account_balance_outlined,
                            color: Colors.white, size: 22),
                        const SizedBox(height: 8),
                        Text(
                          institutionName,
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
                  // ── KPIs ──────────────────────────────────────────────
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
                          subtitle: 'in loaded results',
                          iconColor: _color,
                        ),
                        MetricTile(
                          icon: Icons.format_quote,
                          label: 'Total citations',
                          value: NumberFormat.compact().format(totalCit),
                          iconColor: _color,
                        ),
                        MetricTile(
                          icon: Icons.calculate_outlined,
                          label: 'Avg citations',
                          value: avgCit.toStringAsFixed(1),
                          subtitle: 'per publication',
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
                      title: 'Publication Activity',
                      subtitle: 'Papers from this institution per year',
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
                  const SizedBox(height: 18),
                  Text(
                    'Related Publications (${pubs.length})',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                  ),
                  const SizedBox(height: 10),
                  ...pubs.map((p) => Padding(
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
