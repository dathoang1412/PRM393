import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../providers/research_provider.dart';
import '../widgets/empty_view.dart';
import '../widgets/metric_tile.dart';
import '../widgets/trend_chart.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  static const _colorPublications = Color(0xFF1E40AF);
  static const _colorCitations = Color(0xFFD97706);
  static const _colorYear = Color(0xFF059669);
  static const _colorVenue = Color(0xFF7C3AED);
  static const _colorAuthor = Color(0xFF2563EB);
  static const _colorPaper = Color(0xFFEA580C);

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ResearchProvider>();
    if (provider.publications.isEmpty) {
      return const EmptyView(
        icon: Icons.query_stats,
        title: 'No dashboard yet',
        message: 'Search a topic first to generate trend insights.',
      );
    }

    final summary = provider.summary;
    final numberFormat = NumberFormat.decimalPattern();

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          title: Text('Dashboard: ${provider.keyword}'),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 600;
                  return GridView.count(
                    crossAxisCount: 3,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: isWide ? 2.5 : 0.95,
                    children: [
                      MetricTile(
                        icon: Icons.article_outlined,
                        label: 'Publications',
                        value: numberFormat.format(summary.totalPublications),
                        iconColor: _colorPublications,
                      ),
                      MetricTile(
                        icon: Icons.format_quote,
                        label: 'Avg citations',
                        value: summary.averageCitations.toStringAsFixed(1),
                        iconColor: _colorCitations,
                      ),
                      MetricTile(
                        icon: Icons.calendar_today_outlined,
                        label: 'Active year',
                        value: summary.mostActiveYear?.toString() ?? 'N/A',
                        iconColor: _colorYear,
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              _HighlightsCard(
                items: [
                  _HighlightItem(
                    icon: Icons.menu_book_outlined,
                    label: 'Top venue',
                    value: summary.topJournal?.name ?? 'N/A',
                    color: _colorVenue,
                  ),
                  _HighlightItem(
                    icon: Icons.person_outline,
                    label: 'Top author',
                    value: summary.topAuthor?.name ?? 'N/A',
                    color: _colorAuthor,
                  ),
                  _HighlightItem(
                    icon: Icons.workspace_premium_outlined,
                    label: 'Top paper',
                    value: summary.mostInfluentialPaper?.title ?? 'N/A',
                    color: _colorPaper,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _TrendCard(summary: summary),
            ]),
          ),
        ),
      ],
    );
  }
}

class _HighlightItem {
  const _HighlightItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;
}

class _HighlightsCard extends StatelessWidget {
  const _HighlightsCard({required this.items});

  final List<_HighlightItem> items;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            for (var index = 0; index < items.length; index++) ...[
              if (index > 0) const Divider(height: 14),
              _HighlightRow(item: items[index]),
            ],
          ],
        ),
      ),
    );
  }
}

class _HighlightRow extends StatelessWidget {
  const _HighlightRow({required this.item});

  final _HighlightItem item;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: item.color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(7),
          ),
          child: Icon(item.icon, size: 16, color: item.color),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: const Color(0xFF64748B),
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                item.value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      height: 1.25,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TrendCard extends StatelessWidget {
  const _TrendCard({required this.summary});

  final dynamic summary;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E40AF).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.show_chart,
                    size: 16,
                    color: Color(0xFF1E40AF),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Publication activity by year',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 260,
              child: TrendChart(points: summary.trends),
            ),
          ],
        ),
      ),
    );
  }
}
