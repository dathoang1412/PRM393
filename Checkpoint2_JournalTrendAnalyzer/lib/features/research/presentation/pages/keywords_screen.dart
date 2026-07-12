import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:journexa/core/firebase/analytics_service.dart';
import 'package:journexa/core/firebase/remote_config_service.dart';
import 'package:journexa/core/theme/app_colors.dart';
import 'package:journexa/core/widgets/app_bar_brand_title.dart';
import 'package:journexa/core/widgets/empty_view.dart';
import 'package:journexa/core/widgets/horizontal_bar_chart.dart';
import 'package:journexa/core/widgets/insight_note.dart';
import 'package:journexa/core/widgets/metric_tile.dart';
import 'package:journexa/core/widgets/section_card.dart';
import 'package:journexa/features/research/data/models/keyword_stat.dart';
import 'package:journexa/features/research/domain/usecases/analytics_calculator.dart';
import '../viewmodels/research_viewmodel.dart';
import '../widgets/filter_header.dart';
import '../widgets/notification_bell.dart';
import '../widgets/rank_row.dart';
import '../widgets/topic_context_bar.dart';
import 'keyword_detail_screen.dart';

/// Keywords tab (spec 4.6): keyword frequency and trend analysis for the
/// loaded topic. Tapping a keyword opens the Keyword Detail screen.
class KeywordsScreen extends StatelessWidget {
  const KeywordsScreen({this.onSearchTopic, super.key});

  /// Jumps to the Home tab so the user can load a topic first.
  final VoidCallback? onSearchTopic;

  static const _color = AppColors.seriesKeywords;

  void _openDetail(BuildContext context, String keyword) {
    AnalyticsService.instance.logViewKeyword(keyword);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => KeywordDetailScreen(keyword: keyword),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ResearchViewModel>();
    final maxKeywords = context.watch<RemoteConfigService>().maxKeywords;

    return Scaffold(
      appBar: AppBar(
        title: const AppBarBrandTitle('Keywords'),
        actions: const [NotificationBell(), SizedBox(width: 4)],
      ),
      body: vm.publications.isEmpty
          ? EmptyView(
              icon: Icons.label_outline,
              title: 'No keyword analysis yet',
              message: 'Search a topic on Home to analyze its keywords.',
              actionLabel: onSearchTopic != null ? 'Search a topic' : null,
              onAction: onSearchTopic,
            )
          : Column(
              children: [
                TopicContextBar(onChangeTopic: onSearchTopic),
                Expanded(child: _buildBody(context, vm, maxKeywords)),
              ],
            ),
    );
  }

  Widget _buildBody(
      BuildContext context, ResearchViewModel vm, int maxKeywords) {
    final keywords = vm.topKeywords;
    final total = vm.filteredPublications.length;
    final papersWithConcepts =
        vm.filteredPublications.where((p) => p.keywords.isNotEmpty).length;
    final coveragePct =
        total == 0 ? 0.0 : papersWithConcepts / total * 100;

    // "Trending" = most frequent keywords among recent papers (last 5 years
    // of the loaded set).
    final cutoff = DateTime.now().year - 4;
    final recentPubs = vm.filteredPublications
        .where((p) => (p.publicationYear ?? 0) >= cutoff)
        .toList();
    final trending = AnalyticsCalculator.topKeywords(recentPubs)
        .take(8)
        .toList(growable: false);

    final shown = keywords.take(maxKeywords).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const FilterHeader(),
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
                        icon: Icons.tag,
                        label: 'Unique concepts',
                        value: '${keywords.length}',
                        subtitle: 'from OpenAlex',
                        iconColor: _color,
                      ),
                      MetricTile(
                        icon: Icons.library_books_outlined,
                        label: 'Coverage',
                        value: '${coveragePct.toStringAsFixed(0)}%',
                        subtitle: 'papers with concepts',
                        iconColor: _color,
                      ),
                      MetricTile(
                        icon: Icons.star_rate_outlined,
                        label: 'Top concept',
                        value:
                            keywords.isNotEmpty ? keywords.first.name : 'N/A',
                        subtitle: keywords.isNotEmpty
                            ? '${keywords.first.count} papers'
                            : null,
                        iconColor: _color,
                      ),
                    ],
                  );
                }),
                if (keywords.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  InsightNote(
                    icon: Icons.lightbulb_outline,
                    color: _color,
                    text:
                        '"${keywords.first.name}" appears in ${keywords.first.count} papers. '
                        'Showing top $maxKeywords keywords (Remote Config).',
                  ),
                ],
                if (trending.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  SectionCard(
                    icon: Icons.trending_up,
                    iconColor: _color,
                    title: 'Trending Keywords',
                    subtitle: 'Most frequent in papers from $cutoff onward',
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: trending
                          .map((k) => _KeywordChip(
                                stat: k,
                                onTap: () => _openDetail(context, k.name),
                              ))
                          .toList(),
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                SectionCard(
                  icon: Icons.bar_chart,
                  iconColor: _color,
                  title: 'Keyword Frequency',
                  subtitle: 'Papers mentioning each concept (top $maxKeywords)',
                  child: HorizontalBarChart(
                    items: shown
                        .map((k) => BarItem(label: k.name, value: k.count))
                        .toList(),
                    color: _color,
                    maxItems: maxKeywords,
                  ),
                ),
                const SizedBox(height: 14),
                SectionCard(
                  icon: Icons.format_list_numbered,
                  iconColor: _color,
                  title: 'Keyword Ranking',
                  subtitle: 'Tap a keyword for trend analysis',
                  child: Column(
                    children: shown.asMap().entries.map((e) {
                      return RankRow(
                        rank: e.key + 1,
                        name: e.value.name,
                        count: e.value.count,
                        total: total,
                        color: _color,
                        onTap: () => _openDetail(context, e.value.name),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _KeywordChip extends StatelessWidget {
  const _KeywordChip({required this.stat, required this.onTap});

  final KeywordStat stat;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primaryWash,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.primaryBorder),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                stat.name,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(width: 6),
              Text(
                '${stat.count}',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
