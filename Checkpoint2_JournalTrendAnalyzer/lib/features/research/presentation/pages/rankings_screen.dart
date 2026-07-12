import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:journexa/core/theme/app_colors.dart';
import 'package:journexa/core/widgets/app_bar_brand_title.dart';
import 'package:journexa/core/widgets/empty_view.dart';
import 'package:journexa/core/widgets/horizontal_bar_chart.dart';
import 'package:journexa/core/widgets/insight_note.dart';
import 'package:journexa/core/widgets/metric_tile.dart';
import 'package:journexa/core/widgets/section_card.dart';
import 'package:journexa/features/research/domain/usecases/analytics_calculator.dart';
import '../viewmodels/research_viewmodel.dart';
import '../widgets/filter_header.dart';
import '../widgets/notification_bell.dart';
import '../widgets/publication_card.dart';
import '../widgets/rank_row.dart';
import '../widgets/scatter_plot_widget.dart';
import '../widgets/topic_context_bar.dart';
import 'author_detail_screen.dart';
import 'institution_detail_screen.dart';
import 'publication_detail_screen.dart';

/// Rankings: bonus leaderboard views beyond the Lab 03 minimum — Authors,
/// Institutions, and Top (most-cited) Papers for the loaded topic. Reached
/// from a dedicated icon on Home's AppBar; Journals and Keywords already
/// have their own top-level tabs so aren't duplicated here.
class RankingsScreen extends StatelessWidget {
  const RankingsScreen({this.onChangeTopic, this.initialTab = 0, super.key});

  /// Switches back to the Home tab so the user can load another topic.
  final VoidCallback? onChangeTopic;

  /// Which tab to land on (0 Authors, 1 Institutions, 2 Top Papers).
  final int initialTab;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ResearchViewModel>();

    if (vm.publications.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const AppBarBrandTitle('Rankings')),
        body: EmptyView(
          icon: Icons.leaderboard_outlined,
          title: 'No rankings yet',
          message: 'Search a topic on Home to rank authors and more.',
          actionLabel: onChangeTopic != null ? 'Search a topic' : null,
          onAction: onChangeTopic,
        ),
      );
    }

    return DefaultTabController(
      length: 3,
      initialIndex: initialTab,
      child: Scaffold(
        appBar: AppBar(
          title: const AppBarBrandTitle('Rankings'),
          actions: const [NotificationBell(), SizedBox(width: 4)],
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.person_outline, size: 16), text: 'Authors'),
              Tab(
                  icon: Icon(Icons.account_balance_outlined, size: 16),
                  text: 'Institutions'),
              Tab(icon: Icon(Icons.star_outline, size: 16), text: 'Top Papers'),
            ],
          ),
        ),
        body: Column(
          children: [
            TopicContextBar(onChangeTopic: onChangeTopic),
            Expanded(
              child: TabBarView(
                children: [
                  _AuthorsTab(vm: vm),
                  _InstitutionsTab(vm: vm),
                  _PapersTab(vm: vm),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Authors Tab ────────────────────────────────────────────────────────────

class _AuthorsTab extends StatelessWidget {
  const _AuthorsTab({required this.vm});
  final ResearchViewModel vm;

  static const _color = AppColors.seriesAuthors;

  void _openAuthor(BuildContext context, String name) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => AuthorDetailScreen(authorName: name)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authors = vm.authors;
    final impacts = vm.authorImpacts;
    final total = vm.filteredPublications.length;
    final fmtCompact = NumberFormat.compact();
    final topAuthorCit = impacts.isNotEmpty ? impacts.first.totalCitations : 0;

    final items = authors
        .take(15)
        .map((a) => BarItem(label: a.name, value: a.publicationCount))
        .toList();

    return _TabScaffold(
      kpiTiles: [
        MetricTile(
          icon: Icons.people_outline,
          label: 'Unique authors',
          value: '${authors.length}',
          subtitle: 'across all papers',
          iconColor: _color,
        ),
        MetricTile(
          icon: Icons.workspace_premium_outlined,
          label: 'Most prolific',
          value: authors.isNotEmpty ? authors.first.name : 'N/A',
          subtitle:
              authors.isNotEmpty ? '${authors.first.publicationCount} papers' : null,
          iconColor: _color,
        ),
        MetricTile(
          icon: Icons.format_quote,
          label: 'Most cited',
          value: impacts.isNotEmpty ? impacts.first.name : 'N/A',
          subtitle: impacts.isNotEmpty
              ? '${fmtCompact.format(topAuthorCit)} citations'
              : null,
          iconColor: _color,
        ),
      ],
      insight: authors.isNotEmpty && total > 0
          ? InsightNote(
              icon: Icons.person_pin_outlined,
              color: _color,
              text:
                  '${authors.first.name} is the most prolific author with ${authors.first.publicationCount} publications. '
                  '${authors.length} unique contributors found across $total papers.',
            )
          : null,
      filterRow: const FilterHeader(),
      sections: items.isEmpty
          ? [
              const SectionCard(
                icon: Icons.person_outline,
                iconColor: _color,
                title: 'Author Ranking',
                subtitle: 'No author data available',
                child: _EmptyInline(),
              ),
            ]
          : [
              _DualSection(
                chartTitle: 'Author Ranking',
                chartSubtitle: 'By number of publications',
                listTitle: 'Full Ranking',
                listSubtitle: 'Tap an author for details',
                icon: Icons.person_outline,
                color: _color,
                chartChild: HorizontalBarChart(
                  items: items,
                  color: _color,
                  maxItems: 15,
                ),
                listItems: authors.take(20).toList().asMap().entries.map((e) {
                  final impactCit = impacts
                      .where((i) => i.name == e.value.name)
                      .firstOrNull
                      ?.totalCitations;
                  return RankRow(
                    rank: e.key + 1,
                    name: e.value.name,
                    count: e.value.publicationCount,
                    total: total,
                    color: _color,
                    badge: (impactCit != null && impactCit > 0)
                        ? '${fmtCompact.format(impactCit)} cit.'
                        : null,
                    onTap: () => _openAuthor(context, e.value.name),
                  );
                }).toList(),
              ),
              if (impacts.length >= 3)
                SectionCard(
                  icon: Icons.scatter_plot_outlined,
                  iconColor: _color,
                  title: 'Author Impact Matrix',
                  subtitle: 'Publications vs total citations — tap a dot',
                  child: SizedBox(
                    height: 280,
                    child: ScatterPlotWidget(data: impacts, color: _color),
                  ),
                ),
            ],
    );
  }
}

// ── Institutions Tab ──────────────────────────────────────────────────────

class _InstitutionsTab extends StatelessWidget {
  const _InstitutionsTab({required this.vm});
  final ResearchViewModel vm;

  static const _color = AppColors.seriesCitations;

  void _openInstitution(BuildContext context, String name) {
    Navigator.of(context).push(
      MaterialPageRoute(
          builder: (_) => InstitutionDetailScreen(institutionName: name)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final institutions = vm.topInstitutions;
    final total = vm.filteredPublications.length;
    final top3Pct = total == 0
        ? 0.0
        : institutions.take(3).fold(0, (s, i) => s + i.count) / total * 100;

    final items = institutions
        .take(20)
        .map((i) => BarItem(label: i.name, value: i.count))
        .toList();

    return _TabScaffold(
      kpiTiles: [
        MetricTile(
          icon: Icons.account_balance_outlined,
          label: 'Institutions',
          value: '${institutions.length}',
          subtitle: 'unique affiliations',
          iconColor: _color,
        ),
        MetricTile(
          icon: Icons.star_rate_outlined,
          label: 'Top institution',
          value: institutions.isNotEmpty ? institutions.first.name : 'N/A',
          subtitle:
              institutions.isNotEmpty ? '${institutions.first.count} papers' : null,
          iconColor: _color,
        ),
        MetricTile(
          icon: Icons.hub_outlined,
          label: 'Top-3 share',
          value: '${top3Pct.toStringAsFixed(0)}%',
          subtitle: 'of all publications',
          iconColor: _color,
        ),
      ],
      insight: institutions.isNotEmpty && total > 0
          ? InsightNote(
              icon: Icons.account_balance_outlined,
              color: _color,
              text:
                  '"${institutions.first.name}" leads with ${institutions.first.count} publications '
                  '(${(institutions.first.count / total * 100).toStringAsFixed(0)}% of results). '
                  '${institutions.length} unique institutions identified.',
            )
          : null,
      filterRow: const FilterHeader(),
      sections: items.isEmpty
          ? [
              const SectionCard(
                icon: Icons.account_balance_outlined,
                iconColor: _color,
                title: 'Institution Ranking',
                subtitle: 'No institution data available',
                child: _EmptyInline(),
              ),
            ]
          : [
              _DualSection(
                chartTitle: 'Institution Ranking',
                chartSubtitle: 'By number of publications authored',
                listTitle: 'Full Ranking',
                listSubtitle: 'Tap an institution for details',
                icon: Icons.account_balance_outlined,
                color: _color,
                chartChild: HorizontalBarChart(
                  items: items.take(10).toList(),
                  color: _color,
                  maxItems: 10,
                ),
                listItems:
                    institutions.take(20).toList().asMap().entries.map((e) {
                  return RankRow(
                    rank: e.key + 1,
                    name: e.value.name,
                    count: e.value.count,
                    total: total,
                    color: _color,
                    onTap: () => _openInstitution(context, e.value.name),
                  );
                }).toList(),
              ),
            ],
    );
  }
}

// ── Top Papers Tab ─────────────────────────────────────────────────────────

class _PapersTab extends StatelessWidget {
  const _PapersTab({required this.vm});
  final ResearchViewModel vm;

  @override
  Widget build(BuildContext context) {
    final filtered = vm.filteredPublications;
    final papers = vm.influentialPapers.take(20).toList();
    final fmtCompact = NumberFormat.compact();
    final fmtDecimal = NumberFormat.decimalPattern();

    final totalCit = AnalyticsCalculator.totalCitations(filtered);
    final highCit = AnalyticsCalculator.highlyCited(filtered);
    final medCit = AnalyticsCalculator.medianCitations(filtered);

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const FilterHeader(),
                    const SizedBox(height: 14),
                    LayoutBuilder(builder: (context, constraints) {
                      const count = 3;
                      final aspect =
                          (constraints.maxWidth - (count - 1) * 10.0) /
                              count /
                              100.0;
                      return GridView.count(
                        crossAxisCount: count,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        childAspectRatio: aspect,
                        children: [
                          MetricTile(
                            icon: Icons.format_quote,
                            label: 'Total citations',
                            value: fmtDecimal.format(totalCit),
                            subtitle: 'across ${filtered.length} papers',
                            iconColor: AppColors.seriesCitations,
                          ),
                          MetricTile(
                            icon: Icons.emoji_events_outlined,
                            label: 'Highly cited',
                            value: '$highCit papers',
                            subtitle: '≥100 citations each',
                            iconColor: AppColors.seriesPapers,
                          ),
                          MetricTile(
                            icon: Icons.bar_chart_outlined,
                            label: 'Median cit.',
                            value: fmtCompact.format(medCit),
                            subtitle: 'per paper',
                            iconColor: AppColors.primary,
                          ),
                        ],
                      );
                    }),
                    const SizedBox(height: 10),
                    const InsightNote(
                      icon: Icons.sort,
                      color: AppColors.primary,
                      text:
                          'Sorted by total citation count. Tap any paper to read its abstract and metadata.',
                    ),
                    const SizedBox(height: 14),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (papers.isEmpty)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: Text('No papers in selected range.')),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            sliver: SliverList.separated(
              itemCount: papers.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final paper = papers[index];
                return Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 900),
                    child: PublicationCard(
                      publication: paper,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              PublicationDetailScreen(publication: paper),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

// ── Shared layout widgets ───────────────────────────────────────────────────

/// Wraps a tab with a filter row + KPI grid + insight note + scrollable
/// sections — the same layout Journals/Keywords use.
class _TabScaffold extends StatelessWidget {
  const _TabScaffold({
    required this.kpiTiles,
    required this.sections,
    this.insight,
    this.filterRow,
  });

  final List<Widget> kpiTiles;
  final Widget? insight;
  final Widget? filterRow;
  final List<Widget> sections;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (filterRow != null) ...[
                      filterRow!,
                      const SizedBox(height: 14),
                    ],
                    LayoutBuilder(builder: (context, constraints) {
                      const count = 3;
                      final aspect =
                          (constraints.maxWidth - (count - 1) * 10.0) /
                              count /
                              100.0;
                      return GridView.count(
                        crossAxisCount: count,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        childAspectRatio: aspect,
                        children: kpiTiles,
                      );
                    }),
                    if (insight != null) ...[
                      const SizedBox(height: 10),
                      insight!,
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          sliver: SliverList.separated(
            itemCount: sections.length,
            separatorBuilder: (_, __) => const SizedBox(height: 14),
            itemBuilder: (_, i) => Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: sections[i],
              ),
            ),
          ),
        ),
        const SliverPadding(padding: EdgeInsets.only(bottom: 28)),
      ],
    );
  }
}

/// On wide screens: bar chart left + rank list right. On narrow: stacked.
class _DualSection extends StatelessWidget {
  const _DualSection({
    required this.chartTitle,
    required this.chartSubtitle,
    required this.listTitle,
    required this.listSubtitle,
    required this.icon,
    required this.color,
    required this.chartChild,
    required this.listItems,
  });

  final String chartTitle;
  final String chartSubtitle;
  final String listTitle;
  final String listSubtitle;
  final IconData icon;
  final Color color;
  final Widget chartChild;
  final List<Widget> listItems;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final isWide = constraints.maxWidth > 680;

      final chart = SectionCard(
        icon: icon,
        iconColor: color,
        title: chartTitle,
        subtitle: chartSubtitle,
        child: chartChild,
      );

      final rankList = SectionCard(
        icon: Icons.format_list_numbered,
        iconColor: color,
        title: listTitle,
        subtitle: listSubtitle,
        child: Column(mainAxisSize: MainAxisSize.min, children: listItems),
      );

      if (isWide) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 5, child: chart),
            const SizedBox(width: 14),
            Expanded(flex: 5, child: rankList),
          ],
        );
      }

      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [chart, const SizedBox(height: 14), rankList],
      );
    });
  }
}

class _EmptyInline extends StatelessWidget {
  const _EmptyInline();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 20),
      child: Center(child: Text('No data in selected range.')),
    );
  }
}
