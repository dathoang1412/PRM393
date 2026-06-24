import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/publication.dart';
import '../providers/research_provider.dart';
import '../utils/analytics_calculator.dart';
import '../widgets/empty_view.dart';
import '../widgets/error_view.dart';
import '../widgets/loading_view.dart';
import '../widgets/publication_card.dart';
import 'publication_detail_screen.dart';

const _kQuickTopics = [
  'Artificial Intelligence',
  'Machine Learning',
  'Data Science',
  'Cybersecurity',
  'Blockchain',
  'Internet of Things',
  'Quantum Computing',
  'Bioinformatics',
];

const _kDesktopBreak = 700.0;
const _kSidebarWidth = 320.0;

class SearchScreen extends StatefulWidget {
  const SearchScreen({this.onSearchSuccess, super.key});

  final VoidCallback? onSearchSuccess;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    final keyword = context.read<ResearchProvider>().keyword;
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
    final provider = context.read<ResearchProvider>();
    await provider.search(topic);
    if (!mounted) return;
    if (provider.status == ResearchStatus.success) {
      widget.onSearchSuccess?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ResearchProvider>();
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= _kDesktopBreak) {
          return _buildDesktopLayout(context, provider);
        }
        return _buildMobileLayout(context, provider);
      },
    );
  }

  // ── Desktop ─────────────────────────────────────────────────────────────────

  Widget _buildDesktopLayout(BuildContext context, ResearchProvider provider) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _DesktopSidebar(
          controller: _controller,
          provider: provider,
          onSearch: _search,
        ),
        const VerticalDivider(
          width: 1,
          thickness: 1,
          color: Color(0xFFE2E8F0),
        ),
        Expanded(child: _buildDesktopResults(context, provider)),
      ],
    );
  }

  Widget _buildDesktopResults(BuildContext context, ResearchProvider provider) {
    if (provider.status != ResearchStatus.success) {
      return _buildStateWidget(context, provider);
    }

    final pubs = provider.publications;
    final totalCit = AnalyticsCalculator.totalCitations(pubs);
    final avgCit =
        pubs.isEmpty ? 0.0 : totalCit / pubs.length;
    final yearRange = AnalyticsCalculator.yearRange(pubs);
    final fmtCompact = NumberFormat.compact();
    final hasMoreToLoad = provider.hasMore;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          provider.keyword,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          provider.resultsSummary(
                              suffix: ' · sorted by citations'),
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: const Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Quick-stats banner
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.12),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _StatPill(
                      icon: Icons.format_quote,
                      label: '${fmtCompact.format(totalCit)} total citations',
                    ),
                    const SizedBox(width: 16),
                    _StatPill(
                      icon: Icons.calculate_outlined,
                      label: '${avgCit.toStringAsFixed(1)} avg per paper',
                    ),
                    if (yearRange != null) ...[
                      const SizedBox(width: 16),
                      _StatPill(
                        icon: Icons.date_range_outlined,
                        label: '${yearRange.min}–${yearRange.max}',
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
        const Divider(height: 1, color: Color(0xFFE2E8F0)),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final cols = constraints.maxWidth > 700 ? 2 : 1;
              return GridView.builder(
                padding: const EdgeInsets.all(20),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: cols,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  mainAxisExtent: 160,
                ),
                itemCount: pubs.length,
                itemBuilder: (context, index) {
                  final pub = pubs[index];
                  return PublicationCard(
                    publication: pub,
                    onTap: () => _pushDetail(context, pub),
                  );
                },
              );
            },
          ),
        ),
        if (hasMoreToLoad || provider.isLoadingMore)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: _LoadMoreFooter(provider: provider),
          ),
      ],
    );
  }

  Widget _buildStateWidget(BuildContext context, ResearchProvider provider) {
    return switch (provider.status) {
      ResearchStatus.idle => const EmptyView(
          icon: Icons.travel_explore,
          title: 'Start with a topic',
          message: 'Enter a keyword to retrieve live OpenAlex publications.',
        ),
      ResearchStatus.loading =>
        const LoadingView(message: 'Fetching OpenAlex publications…'),
      ResearchStatus.empty => const EmptyView(
          icon: Icons.search_off,
          title: 'No publications found',
          message: 'Try a broader topic or a different keyword.',
        ),
      ResearchStatus.error => ErrorView(
          message: provider.errorMessage ?? 'Something went wrong.',
          onRetry: () => _search(_controller.text),
        ),
      ResearchStatus.success => const SizedBox.shrink(),
    };
  }

  // ── Mobile ───────────────────────────────────────────────────────────────────

  Widget _buildMobileLayout(BuildContext context, ResearchProvider provider) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          title: const Text('Journal Trend Analyzer'),
          actions: [
            IconButton(
              tooltip: 'Search topic',
              onPressed: () => _search(_controller.text),
              icon: const Icon(Icons.search),
            ),
          ],
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Explore publication trends',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Search OpenAlex for scholarly works, then review trends, journals, authors, and influential papers.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF64748B),
                      ),
                ),
                const SizedBox(height: 16),
                _buildSearchField(),
                const SizedBox(height: 10),
                _buildQuickTopicsRow(context, provider),
                const SizedBox(height: 10),
                _buildSearchButton(provider),
                if (provider.status == ResearchStatus.success)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(
                      provider.resultsSummary(
                          suffix: ' found for "${provider.keyword}"'),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                    ),
                  ),
                const SizedBox(height: 4),
              ],
            ),
          ),
        ),
        _buildMobileResults(context, provider),
        if (provider.status == ResearchStatus.success &&
            (provider.hasMore || provider.isLoadingMore))
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: _LoadMoreFooter(provider: provider),
            ),
          ),
      ],
    );
  }

  Widget _buildMobileResults(BuildContext context, ResearchProvider provider) {
    switch (provider.status) {
      case ResearchStatus.idle:
        return const SliverFillRemaining(
          hasScrollBody: false,
          child: EmptyView(
            icon: Icons.travel_explore,
            title: 'Start with a topic',
            message: 'Enter a keyword to retrieve live OpenAlex publications.',
          ),
        );
      case ResearchStatus.loading:
        return const SliverFillRemaining(
          hasScrollBody: false,
          child: LoadingView(message: 'Fetching OpenAlex publications…'),
        );
      case ResearchStatus.empty:
        return const SliverFillRemaining(
          hasScrollBody: false,
          child: EmptyView(
            icon: Icons.search_off,
            title: 'No publications found',
            message: 'Try a broader topic or a different keyword.',
          ),
        );
      case ResearchStatus.error:
        return SliverFillRemaining(
          hasScrollBody: false,
          child: ErrorView(
            message: provider.errorMessage ?? 'Something went wrong.',
            onRetry: () => _search(_controller.text),
          ),
        );
      case ResearchStatus.success:
        return SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          sliver: SliverList.separated(
            itemCount: provider.publications.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final publication = provider.publications[index];
              return PublicationCard(
                publication: publication,
                onTap: () => _pushDetail(context, publication),
              );
            },
          ),
        );
    }
  }

  // ── Shared helpers ───────────────────────────────────────────────────────────

  Widget _buildSearchField() {
    return Semantics(
      label: 'Research topic search field',
      child: TextField(
        controller: _controller,
        textInputAction: TextInputAction.search,
        onSubmitted: _search,
        decoration: InputDecoration(
          labelText: 'Research topic',
          hintText: 'Cybersecurity, data science, blockchain…',
          prefixIcon: const Icon(Icons.manage_search),
          suffixIcon: IconButton(
            tooltip: 'Clear',
            onPressed: _controller.clear,
            icon: const Icon(Icons.clear),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickTopicsRow(BuildContext context, ResearchProvider provider) {
    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _kQuickTopics.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (context, index) {
          final topic = _kQuickTopics[index];
          final isActive = provider.keyword == topic &&
              provider.status == ResearchStatus.success;
          return GestureDetector(
            onTap: () => _search(topic),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: isActive
                    ? Theme.of(context).colorScheme.primary
                    : const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isActive
                      ? Theme.of(context).colorScheme.primary
                      : const Color(0xFFBFDBFE),
                ),
              ),
              child: Text(
                topic,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: isActive
                          ? Colors.white
                          : const Color(0xFF1D4ED8),
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSearchButton(ResearchProvider provider) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: provider.status == ResearchStatus.loading
            ? null
            : () => _search(_controller.text),
        icon: const Icon(Icons.search),
        label: const Text('Search OpenAlex'),
      ),
    );
  }

  void _pushDetail(BuildContext context, Publication publication) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PublicationDetailScreen(publication: publication),
      ),
    );
  }
}

// ── Load-more footer (paginates beyond the first page of results) ────────────

class _LoadMoreFooter extends StatelessWidget {
  const _LoadMoreFooter({required this.provider});

  final ResearchProvider provider;

  @override
  Widget build(BuildContext context) {
    if (provider.isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    final fmt = NumberFormat.decimalPattern();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: OutlinedButton.icon(
          onPressed: provider.loadMore,
          icon: const Icon(Icons.expand_more),
          label: Text(
            'Load more (${fmt.format(provider.publications.length)} of '
            '${fmt.format(provider.totalCount)})',
          ),
        ),
      ),
    );
  }
}

// ── Stat pill for desktop result header ──────────────────────────────────────

class _StatPill extends StatelessWidget {
  const _StatPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: primary),
        const SizedBox(width: 5),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: primary,
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}

// ── Desktop Sidebar ───────────────────────────────────────────────────────────

class _DesktopSidebar extends StatelessWidget {
  const _DesktopSidebar({
    required this.controller,
    required this.provider,
    required this.onSearch,
  });

  final TextEditingController controller;
  final ResearchProvider provider;
  final ValueChanged<String> onSearch;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: _kSidebarWidth,
      child: Container(
        color: Colors.white,
        child: SafeArea(
          right: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Gradient header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      colorScheme.primary,
                      const Color(0xFF2563EB),
                    ],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.auto_stories,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Journal Trend Analyzer',
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.2,
                                  ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Explore publication trends\nvia OpenAlex open data',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.85),
                            height: 1.5,
                          ),
                    ),
                  ],
                ),
              ),

              // Search controls
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Research topic',
                        style:
                            Theme.of(context).textTheme.labelLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF475569),
                                ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: controller,
                        textInputAction: TextInputAction.search,
                        onSubmitted: onSearch,
                        decoration: InputDecoration(
                          hintText: 'Cybersecurity, machine learning…',
                          prefixIcon: const Icon(Icons.manage_search, size: 20),
                          suffixIcon: IconButton(
                            tooltip: 'Clear',
                            onPressed: controller.clear,
                            icon: const Icon(Icons.clear, size: 18),
                          ),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Quick topics',
                        style:
                            Theme.of(context).textTheme.labelLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF475569),
                                ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: _kQuickTopics.map((topic) {
                          final isActive =
                              provider.keyword == topic &&
                                  provider.status == ResearchStatus.success;
                          return GestureDetector(
                            onTap: () => onSearch(topic),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: isActive
                                    ? colorScheme.primary
                                    : const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isActive
                                      ? colorScheme.primary
                                      : const Color(0xFFBFDBFE),
                                ),
                              ),
                              child: Text(
                                topic,
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
                                      color: isActive
                                          ? Colors.white
                                          : const Color(0xFF1D4ED8),
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed:
                              provider.status == ResearchStatus.loading
                                  ? null
                                  : () => onSearch(controller.text),
                          icon: provider.status == ResearchStatus.loading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.search),
                          label: Text(
                            provider.status == ResearchStatus.loading
                                ? 'Searching…'
                                : 'Search OpenAlex',
                          ),
                        ),
                      ),
                      if (provider.status == ResearchStatus.success) ...[
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color:
                                colorScheme.primary.withValues(alpha: 0.07),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: colorScheme.primary.withValues(alpha: 0.15),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.check_circle_outline,
                                size: 14,
                                color: colorScheme.primary,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  provider.resultsSummary(suffix: ' found'),
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: colorScheme.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
