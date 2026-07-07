import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../providers/research_provider.dart';
import '../utils/analytics_calculator.dart';
import '../widgets/donut_chart.dart';
import '../widgets/empty_view.dart';
import '../widgets/horizontal_bar_chart.dart';
import '../widgets/insight_note.dart';
import '../widgets/metric_tile.dart';
import '../widgets/publication_card.dart';
import '../widgets/scatter_plot_widget.dart';
import '../widgets/year_range_filter.dart';
import 'publication_detail_screen.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  void _export(BuildContext context, ResearchProvider provider) {
    final csv = AnalyticsCalculator.exportCsv(
      provider.filteredPublications,
      provider.keyword,
    );
    Clipboard.setData(ClipboardData(text: csv));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('CSV copied to clipboard'),
        backgroundColor: Color(0xFF059669),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ResearchProvider>();

    if (provider.publications.isEmpty) {
      return const EmptyView(
        icon: Icons.bar_chart,
        title: 'No rankings yet',
        message: 'Search a topic to rank journals, authors, and more.',
      );
    }

    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Keywords · ${provider.keyword}'),
          actions: [
            IconButton(
              icon: const Icon(Icons.download_outlined),
              tooltip: 'Export CSV to clipboard',
              onPressed: () => _export(context, provider),
            ),
            const SizedBox(width: 4),
          ],
          bottom: const TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              Tab(icon: Icon(Icons.menu_book_outlined, size: 16), text: 'Journals'),
              Tab(icon: Icon(Icons.person_outline, size: 16), text: 'Authors'),
              Tab(icon: Icon(Icons.label_outline, size: 16), text: 'Keywords'),
              Tab(icon: Icon(Icons.account_balance_outlined, size: 16), text: 'Institutions'),
              Tab(icon: Icon(Icons.star_outline, size: 16), text: 'Top Papers'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _JournalsTab(provider: provider),
            _AuthorsTab(provider: provider),
            _KeywordsTab(provider: provider),
            _InstitutionsTab(provider: provider),
            _PapersTab(provider: provider),
          ],
        ),
      ),
    );
  }
}

// ── Journals Tab ──────────────────────────────────────────────────────────────

class _JournalsTab extends StatelessWidget {
  const _JournalsTab({required this.provider});
  final ResearchProvider provider;

  static const _color = Color(0xFF7C3AED);

  @override
  Widget build(BuildContext context) {
    final journals = provider.journals;
    final total = provider.filteredPublications.length;
    final top5Pct = total == 0
        ? 0.0
        : journals.take(5).fold(0, (s, j) => s + j.publicationCount) /
            total *
            100;
    final multiVenue = journals.where((j) => j.publicationCount > 1).length;

    final items = journals
        .take(20)
        .map((j) => BarItem(label: j.name, value: j.publicationCount))
        .toList();

    return _TabScaffold(
      kpiTiles: [
        MetricTile(
          icon: Icons.menu_book_outlined,
          label: 'Unique venues',
          value: '${journals.length}',
          subtitle: 'journals & conferences',
          iconColor: _color,
        ),
        MetricTile(
          icon: Icons.hub_outlined,
          label: 'Top-5 share',
          value: '${top5Pct.toStringAsFixed(0)}%',
          subtitle: 'of all publications',
          iconColor: _color,
        ),
        MetricTile(
          icon: Icons.repeat_outlined,
          label: 'Multi-paper',
          value: '$multiVenue venues',
          subtitle: 'published 2+ papers',
          iconColor: _color,
        ),
      ],
      insight: journals.isNotEmpty
          ? InsightNote(
              icon: Icons.info_outline,
              color: _color,
              text:
                  '"${journals.first.name}" leads with ${journals.first.publicationCount} papers, representing ${total == 0 ? 0 : (journals.first.publicationCount / total * 100).toStringAsFixed(0)}% of all results.',
            )
          : null,
      filterRow: const YearRangeFilter(),
      sections: items.isEmpty
          ? [
              const _ChartSection(
                icon: Icons.menu_book_outlined,
                iconColor: _color,
                title: 'Journal Ranking',
                subtitle: 'No venue data available',
                child: _EmptyInline(),
              ),
            ]
          : [
              _DualSection(
                chartTitle: 'Journal Ranking',
                chartSubtitle: 'By number of matching publications',
                listTitle: 'Full Ranking',
                listSubtitle: 'All venues sorted by output',
                icon: Icons.menu_book_outlined,
                color: _color,
                chartChild: HorizontalBarChart(
                  items: items.take(10).toList(),
                  color: _color,
                  maxItems: 10,
                ),
                listItems: journals.take(20).toList().asMap().entries.map((e) {
                  return _RankRow(
                    rank: e.key + 1,
                    name: e.value.name,
                    count: e.value.publicationCount,
                    total: total,
                    color: _color,
                    unit: 'papers',
                  );
                }).toList(),
              ),
            ],
    );
  }
}

// ── Authors Tab ───────────────────────────────────────────────────────────────

class _AuthorsTab extends StatelessWidget {
  const _AuthorsTab({required this.provider});
  final ResearchProvider provider;

  static const _color = Color(0xFF1D4ED8);

  @override
  Widget build(BuildContext context) {
    final authors = provider.authors;
    final impacts = provider.authorImpacts;
    final total = provider.filteredPublications.length;

    final fmtCompact = NumberFormat.compact();
    final topAuthorCit = impacts.isNotEmpty ? impacts.first.totalCitations : 0;
    final uniqueAuthors = authors.length;

    final items = authors
        .take(15)
        .map((a) => BarItem(label: a.name, value: a.publicationCount))
        .toList();

    return _TabScaffold(
      kpiTiles: [
        MetricTile(
          icon: Icons.people_outline,
          label: 'Unique authors',
          value: '$uniqueAuthors',
          subtitle: 'across all papers',
          iconColor: _color,
        ),
        MetricTile(
          icon: Icons.workspace_premium_outlined,
          label: 'Most prolific',
          value: authors.isNotEmpty ? authors.first.name : 'N/A',
          subtitle: authors.isNotEmpty
              ? '${authors.first.publicationCount} papers'
              : null,
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
                  '$uniqueAuthors unique contributors found across $total papers.',
            )
          : null,
      filterRow: const YearRangeFilter(),
      sections: items.isEmpty
          ? [
              const _ChartSection(
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
                listSubtitle: 'All authors sorted by output',
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
                  return _RankRow(
                    rank: e.key + 1,
                    name: e.value.name,
                    count: e.value.publicationCount,
                    total: total,
                    color: _color,
                    unit: 'papers',
                    badge: (impactCit != null && impactCit > 0)
                        ? '${fmtCompact.format(impactCit)} cit.'
                        : null,
                  );
                }).toList(),
              ),
              if (impacts.length >= 3)
                _ChartSection(
                  icon: Icons.scatter_plot_outlined,
                  iconColor: _color,
                  title: 'Author Impact Matrix',
                  subtitle: 'Publications vs total citations — tap a dot',
                  child: SizedBox(
                    height: 280,
                    child: ScatterPlotWidget(
                      data: impacts,
                      color: _color,
                    ),
                  ),
                ),
            ],
    );
  }
}

// ── Keywords Tab ──────────────────────────────────────────────────────────────

class _KeywordsTab extends StatelessWidget {
  const _KeywordsTab({required this.provider});
  final ResearchProvider provider;

  static const _color = Color(0xFF0891B2);

  @override
  Widget build(BuildContext context) {
    final keywords = provider.topKeywords;
    final total = provider.filteredPublications.length;
    final papersWithConcepts = provider.filteredPublications
        .where((p) => p.keywords.isNotEmpty)
        .length;
    final coveragePct =
        total == 0 ? 0.0 : papersWithConcepts / total * 100;

    final items = keywords
        .take(20)
        .map((k) => BarItem(label: k.name, value: k.count))
        .toList();

    final donutSlices = keywords.take(6).toList().asMap().entries.map((e) {
      return DonutSlice(
        label: e.value.name,
        value: e.value.count,
        color: _kPalette[e.key % _kPalette.length],
      );
    }).toList();

    return _TabScaffold(
      kpiTiles: [
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
          value: keywords.isNotEmpty ? keywords.first.name : 'N/A',
          subtitle: keywords.isNotEmpty
              ? '${keywords.first.count} papers'
              : null,
          iconColor: _color,
        ),
      ],
      insight: keywords.isNotEmpty
          ? InsightNote(
              icon: Icons.lightbulb_outline,
              color: _color,
              text:
                  '"${keywords.first.name}" appears in ${keywords.first.count} papers. '
                  'Top-5 concepts cover ${AnalyticsCalculator.topConcentration(keywords.map((k) => MapEntry(k.name, k.count)).toList(), 5).toStringAsFixed(0)}% of all concept mentions.',
            )
          : null,
      filterRow: const YearRangeFilter(),
      sections: items.isEmpty
          ? [
              const _ChartSection(
                icon: Icons.label_outline,
                iconColor: _color,
                title: 'Research Keywords',
                subtitle: 'No keyword data found',
                child: _EmptyInline(),
              ),
            ]
          : [
              // Donut + bar chart side-by-side on wide, stacked on narrow
              _KeywordsLayout(
                donutSlices: donutSlices,
                barItems: items,
                color: _color,
              ),
            ],
    );
  }

  static const _kPalette = [
    Color(0xFF0891B2),
    Color(0xFF1D4ED8),
    Color(0xFF7C3AED),
    Color(0xFF059669),
    Color(0xFFD97706),
    Color(0xFFEA580C),
  ];
}

class _KeywordsLayout extends StatelessWidget {
  const _KeywordsLayout({
    required this.donutSlices,
    required this.barItems,
    required this.color,
  });

  final List<DonutSlice> donutSlices;
  final List<BarItem> barItems;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 680;

        final donutCard = _ChartSection(
          icon: Icons.donut_large_outlined,
          iconColor: color,
          title: 'Top 6 Concepts',
          subtitle: 'Share of keyword mentions',
          child: donutSlices.isEmpty
              ? const _EmptyInline()
              : DonutChart(
                  slices: donutSlices,
                  centerLabel: 'Concepts',
                ),
        );

        final barCard = _ChartSection(
          icon: Icons.label_outline,
          iconColor: color,
          title: 'Top 20 Keywords',
          subtitle: 'By number of papers mentioning each concept',
          child: HorizontalBarChart(
            items: barItems,
            color: color,
            maxItems: 20,
          ),
        );

        if (isWide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 4, child: donutCard),
              const SizedBox(width: 14),
              Expanded(flex: 6, child: barCard),
            ],
          );
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            donutCard,
            const SizedBox(height: 14),
            barCard,
          ],
        );
      },
    );
  }
}

// ── Institutions Tab ──────────────────────────────────────────────────────────

class _InstitutionsTab extends StatelessWidget {
  const _InstitutionsTab({required this.provider});
  final ResearchProvider provider;

  static const _color = Color(0xFFD97706);

  @override
  Widget build(BuildContext context) {
    final institutions = provider.topInstitutions;
    final total = provider.filteredPublications.length;
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
          subtitle: institutions.isNotEmpty
              ? '${institutions.first.count} papers'
              : null,
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
                  '"${institutions.first.name}" leads with ${institutions.first.count} publications (${(institutions.first.count / total * 100).toStringAsFixed(0)}% of results). '
                  '${institutions.length} unique institutions identified.',
            )
          : null,
      filterRow: const YearRangeFilter(),
      sections: items.isEmpty
          ? [
              const _ChartSection(
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
                listSubtitle: 'All institutions sorted by output',
                icon: Icons.account_balance_outlined,
                color: _color,
                chartChild: HorizontalBarChart(
                  items: items.take(10).toList(),
                  color: _color,
                  maxItems: 10,
                ),
                listItems:
                    institutions.take(20).toList().asMap().entries.map((e) {
                  return _RankRow(
                    rank: e.key + 1,
                    name: e.value.name,
                    count: e.value.count,
                    total: total,
                    color: _color,
                    unit: 'papers',
                  );
                }).toList(),
              ),
            ],
    );
  }
}

// ── Papers Tab ────────────────────────────────────────────────────────────────

class _PapersTab extends StatelessWidget {
  const _PapersTab({required this.provider});
  final ResearchProvider provider;

  @override
  Widget build(BuildContext context) {
    final filtered = provider.filteredPublications;
    final papers = provider.influentialPapers.take(20).toList();
    final fmtCompact = NumberFormat.compact();
    final fmtDecimal = NumberFormat.decimalPattern();

    final totalCit = AnalyticsCalculator.totalCitations(filtered);
    final highCit = AnalyticsCalculator.highlyCited(filtered);
    final medCit = AnalyticsCalculator.medianCitations(filtered);

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const _AnalyticsFilterHeader(child: YearRangeFilter()),
                const SizedBox(height: 14),
                LayoutBuilder(builder: (context, constraints) {
                  const count = 3;
                  const targetH = 100.0;
                  final aspect =
                      (constraints.maxWidth - (count - 1) * 10.0) /
                          count /
                          targetH;
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
                        iconColor: const Color(0xFFD97706),
                      ),
                      MetricTile(
                        icon: Icons.emoji_events_outlined,
                        label: 'Highly cited',
                        value: '$highCit papers',
                        subtitle: '≥100 citations each',
                        iconColor: const Color(0xFFEA580C),
                      ),
                      MetricTile(
                        icon: Icons.bar_chart_outlined,
                        label: 'Median cit.',
                        value: fmtCompact.format(medCit),
                        subtitle: 'per paper',
                        iconColor: const Color(0xFF1D4ED8),
                      ),
                    ],
                  );
                }),
                const SizedBox(height: 10),
                const InsightNote(
                  icon: Icons.sort,
                  color: Color(0xFF1D4ED8),
                  text:
                      'Sorted by total citation count. Tap any paper to read its abstract and metadata.',
                ),
                const SizedBox(height: 14),
              ],
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
                return PublicationCard(
                  publication: paper,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          PublicationDetailScreen(publication: paper),
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

// ── Shared layout widgets ─────────────────────────────────────────────────────

/// Wraps a tab with a filter row + KPI grid + insight note + scrollable sections.
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
              constraints: const BoxConstraints(maxWidth: 1400),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (filterRow != null) ...[
                      _AnalyticsFilterHeader(child: filterRow!),
                      const SizedBox(height: 14),
                    ],
                    LayoutBuilder(builder: (context, constraints) {
                      const count = 3;
                      const targetH = 100.0;
                      final aspect =
                          (constraints.maxWidth - (count - 1) * 10.0) /
                              count /
                              targetH;
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
                constraints: const BoxConstraints(maxWidth: 1400),
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

      final chart = _ChartSection(
        icon: icon,
        iconColor: color,
        title: chartTitle,
        subtitle: chartSubtitle,
        child: chartChild,
      );

      final rankList = _ChartSection(
        icon: Icons.format_list_numbered,
        iconColor: color,
        title: listTitle,
        subtitle: listSubtitle,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: listItems,
        ),
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
        children: [
          chart,
          const SizedBox(height: 14),
          rankList,
        ],
      );
    });
  }
}

/// Card wrapping a chart or list section — consistent with Dashboard card style.
class _ChartSection extends StatelessWidget {
  const _ChartSection({
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

/// A single ranked row: rank + name + share bar + count badge + optional badge.
class _RankRow extends StatelessWidget {
  const _RankRow({
    required this.rank,
    required this.name,
    required this.count,
    required this.total,
    required this.color,
    required this.unit,
    this.badge,
  });

  final int rank;
  final String name;
  final int count;
  final int total;
  final Color color;
  final String unit;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final pct = total == 0 ? 0.0 : count / total;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              '$rank',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: rank <= 3 ? color : const Color(0xFF94A3B8),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1E293B),
                      ),
                ),
                const SizedBox(height: 3),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: pct,
                    minHeight: 4,
                    backgroundColor: const Color(0xFFE2E8F0),
                    color: color.withValues(alpha: rank <= 3 ? 1.0 : 0.5),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (badge != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFEEF2FF),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                badge!,
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: color),
              ),
            ),
            const SizedBox(width: 6),
          ],
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
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

/// Inline filter header matching Dashboard and Trends style.
class _AnalyticsFilterHeader extends StatelessWidget {
  const _AnalyticsFilterHeader({required this.child});
  final Widget child;

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
        Expanded(child: child),
      ],
    );
  }
}
