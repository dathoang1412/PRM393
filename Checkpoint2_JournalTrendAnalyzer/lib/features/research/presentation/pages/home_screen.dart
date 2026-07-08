import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:journexa/core/theme/app_colors.dart';
import 'package:journexa/core/widgets/empty_view.dart';
import 'package:journexa/core/widgets/error_view.dart';
import 'package:journexa/core/widgets/loading_view.dart';
import 'package:journexa/core/widgets/metric_tile.dart';
import 'package:journexa/core/widgets/section_card.dart';
import 'package:journexa/features/research/data/models/publication.dart';
import 'package:journexa/features/research/domain/usecases/analytics_calculator.dart';
import '../viewmodels/research_viewmodel.dart';
import '../widgets/filter_header.dart';
import '../widgets/publication_card.dart';
import '../widgets/trend_chart.dart';
import 'publication_detail_screen.dart';

const _kQuickTopics = [
  'Artificial Intelligence',
  'Machine Learning',
  'Cybersecurity',
  'Blockchain',
  'Quantum Computing',
  'Bioinformatics',
];

/// Home (Lab 03 spec 4.2): topic search plus the research dashboard —
/// KPIs, publication trend chart, most influential publication, and the
/// publication list. Tapping a publication opens its detail page.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    final keyword = context.read<ResearchViewModel>().keyword;
    _controller = TextEditingController(
      text: keyword.isNotEmpty ? keyword : 'Artificial Intelligence',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _search(String topic) async {
    _controller.text = topic;
    FocusScope.of(context).unfocus();
    await context.read<ResearchViewModel>().search(topic);
  }

  void _openDetail(Publication publication) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PublicationDetailScreen(publication: publication),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ResearchViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text('Journexa')),
      body: CustomScrollView(
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
                    children: [
                      _buildSearchField(vm),
                      const SizedBox(height: 10),
                      _buildQuickTopics(vm),
                    ],
                  ),
                ),
              ),
            ),
          ),
          ..._buildBody(context, vm),
          const SliverPadding(padding: EdgeInsets.only(bottom: 28)),
        ],
      ),
    );
  }

  Widget _buildSearchField(ResearchViewModel vm) {
    return TextField(
      key: const Key('topicSearchField'),
      controller: _controller,
      textInputAction: TextInputAction.search,
      onSubmitted: _search,
      decoration: InputDecoration(
        hintText: 'Search a research topic…',
        prefixIcon: const Icon(Icons.manage_search),
        suffixIcon: IconButton(
          key: const Key('searchButton'),
          tooltip: 'Search',
          onPressed: vm.status == ResearchStatus.loading
              ? null
              : () => _search(_controller.text),
          icon: const Icon(Icons.search),
        ),
        isDense: true,
      ),
    );
  }

  Widget _buildQuickTopics(ResearchViewModel vm) {
    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _kQuickTopics.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (context, index) {
          final topic = _kQuickTopics[index];
          final isActive = vm.keyword == topic &&
              vm.status == ResearchStatus.success;
          return GestureDetector(
            onTap: () => _search(topic),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isActive ? AppColors.primary : AppColors.primaryWash,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color:
                      isActive ? AppColors.primary : AppColors.primaryBorder,
                ),
              ),
              child: Text(
                topic,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: isActive ? Colors.white : AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          );
        },
      ),
    );
  }

  List<Widget> _buildBody(BuildContext context, ResearchViewModel vm) {
    switch (vm.status) {
      case ResearchStatus.idle:
        return const [
          SliverFillRemaining(
            hasScrollBody: false,
            child: EmptyView(
              icon: Icons.travel_explore,
              title: 'Start with a topic',
              message:
                  'Search any research topic to build its live dashboard.',
            ),
          ),
        ];
      case ResearchStatus.loading:
        return const [
          SliverFillRemaining(
            hasScrollBody: false,
            child: LoadingView(message: 'Loading…'),
          ),
        ];
      case ResearchStatus.empty:
        return const [
          SliverFillRemaining(
            hasScrollBody: false,
            child: EmptyView(
              icon: Icons.search_off,
              title: 'No publications found',
              message: 'Try a broader topic or a different keyword.',
            ),
          ),
        ];
      case ResearchStatus.error:
        return [
          SliverFillRemaining(
            hasScrollBody: false,
            child: ErrorView(
              message: vm.errorMessage ?? 'Something went wrong.',
              onRetry: () => _search(_controller.text),
            ),
          ),
        ];
      case ResearchStatus.success:
        return _buildDashboard(context, vm);
    }
  }

  // ── Dashboard (spec 4.2) ────────────────────────────────────────────────

  List<Widget> _buildDashboard(BuildContext context, ResearchViewModel vm) {
    final fmt = NumberFormat.decimalPattern();
    final filtered = vm.filteredPublications;
    final summary = vm.summary;

    final byCount = [...vm.trends]..sort((a, b) => b.count.compareTo(a.count));
    final peakYear = byCount.isNotEmpty ? byCount.first : null;
    final topPaper = summary.mostInfluentialPaper;

    final metrics = <Widget>[
      MetricTile(
        icon: Icons.article_outlined,
        label: 'Total publications',
        value: fmt.format(vm.totalWorksInRange),
        subtitle: vm.hasCorpusTrends
            ? 'analyzing top ${fmt.format(filtered.length)} by citations'
            : null,
        iconColor: AppColors.seriesPublications,
      ),
      MetricTile(
        icon: Icons.format_quote,
        label: 'Avg citations',
        value: summary.averageCitations.toStringAsFixed(1),
        subtitle:
            'median: ${AnalyticsCalculator.medianCitations(filtered)}',
        iconColor: AppColors.seriesCitations,
      ),
      MetricTile(
        icon: Icons.calendar_month_outlined,
        label: 'Most active year',
        value: peakYear?.year.toString() ?? 'N/A',
        subtitle:
            peakYear != null ? '${fmt.format(peakYear.count)} papers' : null,
        iconColor: AppColors.seriesCountries,
      ),
      MetricTile(
        icon: Icons.person_outline,
        label: 'Top author',
        value: summary.topAuthor?.name ?? 'N/A',
        subtitle: summary.topAuthor != null
            ? '${summary.topAuthor!.publicationCount} papers'
            : null,
        iconColor: AppColors.seriesAuthors,
      ),
      MetricTile(
        icon: Icons.menu_book_outlined,
        label: 'Top journal',
        value: summary.topJournal?.name ?? 'N/A',
        subtitle: summary.topJournal != null
            ? '${summary.topJournal!.publicationCount} papers'
            : null,
        iconColor: AppColors.seriesVenues,
      ),
      MetricTile(
        icon: Icons.star_outline,
        label: 'Total citations',
        value: NumberFormat.compact()
            .format(AnalyticsCalculator.totalCitations(filtered)),
        subtitle: 'across loaded papers',
        iconColor: AppColors.seriesPapers,
      ),
    ];

    return [
      SliverToBoxAdapter(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final w = constraints.maxWidth;
                  final crossCount = w > 560 ? 3 : 2;
                  final aspect =
                      (w - (crossCount - 1) * 10) / crossCount / 100.0;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              vm.keyword,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primaryDark,
                                  ),
                            ),
                          ),
                          Text(
                            vm.resultsSummary(),
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: AppColors.inkSecondary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const FilterHeader(),
                      const SizedBox(height: 14),
                      GridView.count(
                        crossAxisCount: crossCount,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        childAspectRatio: aspect,
                        children: metrics,
                      ),
                      const SizedBox(height: 14),
                      SectionCard(
                        icon: Icons.show_chart,
                        iconColor: AppColors.seriesPublications,
                        title: 'Publication Trend',
                        subtitle: vm.hasCorpusTrends
                            ? 'Papers per year — all matching works on OpenAlex'
                            : 'Papers per year (loaded results)',
                        child: SizedBox(
                          height: 240,
                          child: TrendChart(points: vm.trends, unit: 'papers'),
                        ),
                      ),
                      if (topPaper != null) ...[
                        const SizedBox(height: 14),
                        SectionCard(
                          icon: Icons.workspace_premium_outlined,
                          iconColor: AppColors.seriesPapers,
                          title: 'Most Influential Publication',
                          subtitle: 'Highest citation count for this topic',
                          child: PublicationCard(
                            publication: topPaper,
                            onTap: () => _openDetail(topPaper),
                          ),
                        ),
                      ],
                      const SizedBox(height: 18),
                      Text(
                        'Publications',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.ink,
                                ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Sorted by citations — tap to view details.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.inkSecondary,
                            ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
        sliver: SliverList.separated(
          itemCount: filtered.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final publication = filtered[index];
            return Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: PublicationCard(
                  publication: publication,
                  onTap: () => _openDetail(publication),
                ),
              ),
            );
          },
        ),
      ),
      if (vm.hasMore || vm.isLoadingMore)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Center(
              child: vm.isLoadingMore
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : OutlinedButton.icon(
                      onPressed: vm.loadMore,
                      icon: const Icon(Icons.expand_more),
                      label: Text(
                        'Load more (${NumberFormat.decimalPattern().format(vm.publications.length)}'
                        ' of ${NumberFormat.decimalPattern().format(vm.totalCount)})',
                      ),
                    ),
            ),
          ),
        ),
    ];
  }
}
