import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
import 'package:journexa/features/research/data/models/publication.dart';
import '../viewmodels/research_viewmodel.dart';
import '../widgets/filter_header.dart';
import '../widgets/notification_bell.dart';
import '../widgets/rank_row.dart';
import '../widgets/topic_context_bar.dart';
import 'journal_detail_screen.dart';

/// Per-journal aggregate for the selected topic.
class JournalAgg {
  const JournalAgg({
    required this.name,
    required this.publicationCount,
    required this.totalCitations,
  });

  final String name;
  final int publicationCount;
  final int totalCitations;

  double get avgCitations =>
      publicationCount == 0 ? 0 : totalCitations / publicationCount;
}

List<JournalAgg> aggregateJournals(List<Publication> publications) {
  final counts = <String, int>{};
  final citations = <String, int>{};
  for (final p in publications) {
    final name = p.journalName;
    if (name == null) continue;
    counts[name] = (counts[name] ?? 0) + 1;
    citations[name] = (citations[name] ?? 0) + p.citedByCount;
  }
  final list = counts.entries
      .map((e) => JournalAgg(
            name: e.key,
            publicationCount: e.value,
            totalCitations: citations[e.key] ?? 0,
          ))
      .toList()
    ..sort((a, b) => b.publicationCount.compareTo(a.publicationCount));
  return list;
}

/// Journals tab (spec 4.4): journal-level analysis for the loaded topic —
/// ranking chart, publication and citation statistics per journal. Tapping
/// a journal opens the Journal Detail screen.
class JournalsScreen extends StatelessWidget {
  const JournalsScreen({this.onSearchTopic, super.key});

  /// Jumps to the Home tab so the user can load a topic first.
  final VoidCallback? onSearchTopic;

  static const _color = AppColors.seriesVenues;

  void _openDetail(BuildContext context, JournalAgg journal) {
    AnalyticsService.instance.logViewJournal(journal.name);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => JournalDetailScreen(journalName: journal.name),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ResearchViewModel>();
    final maxJournals = context.watch<RemoteConfigService>().maxJournals;

    return Scaffold(
      appBar: AppBar(
        title: const AppBarBrandTitle('Journals'),
        actions: const [NotificationBell(), SizedBox(width: 4)],
      ),
      body: vm.publications.isEmpty
          ? EmptyView(
              icon: Icons.menu_book_outlined,
              title: 'No journal analysis yet',
              message: 'Search a topic on Home to rank its journals.',
              actionLabel: onSearchTopic != null ? 'Search a topic' : null,
              onAction: onSearchTopic,
            )
          : Column(
              children: [
                TopicContextBar(onChangeTopic: onSearchTopic),
                Expanded(child: _buildBody(context, vm, maxJournals)),
              ],
            ),
    );
  }

  Widget _buildBody(
      BuildContext context, ResearchViewModel vm, int maxJournals) {
    final fmtCompact = NumberFormat.compact();
    final journals = aggregateJournals(vm.filteredPublications);
    final shown = journals.take(maxJournals).toList();
    final total = vm.filteredPublications.length;
    final top5Pct = total == 0
        ? 0.0
        : journals.take(5).fold(0, (s, j) => s + j.publicationCount) /
            total *
            100;

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
                        icon: Icons.format_quote,
                        label: 'Most cited venue',
                        value: journals.isEmpty
                            ? 'N/A'
                            : ([...journals]..sort((a, b) => b.totalCitations
                                    .compareTo(a.totalCitations)))
                                .first
                                .name,
                        iconColor: _color,
                      ),
                    ],
                  );
                }),
                if (journals.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  InsightNote(
                    icon: Icons.info_outline,
                    color: _color,
                    text:
                        '"${journals.first.name}" leads with ${journals.first.publicationCount} papers. '
                        'Showing top $maxJournals venues (Remote Config).',
                  ),
                ],
                const SizedBox(height: 14),
                SectionCard(
                  icon: Icons.bar_chart,
                  iconColor: _color,
                  title: 'Journal Contribution',
                  subtitle: 'Publications per venue (top $maxJournals)',
                  child: HorizontalBarChart(
                    items: shown
                        .map((j) =>
                            BarItem(label: j.name, value: j.publicationCount))
                        .toList(),
                    color: _color,
                    maxItems: maxJournals,
                  ),
                ),
                const SizedBox(height: 14),
                SectionCard(
                  icon: Icons.format_list_numbered,
                  iconColor: _color,
                  title: 'Citation Statistics by Journal',
                  subtitle: 'Tap a journal for details',
                  child: Column(
                    children: shown.asMap().entries.map((e) {
                      final j = e.value;
                      return RankRow(
                        rank: e.key + 1,
                        name: j.name,
                        count: j.publicationCount,
                        total: total,
                        color: _color,
                        badge:
                            '${fmtCompact.format(j.totalCitations)} cit · avg ${j.avgCitations.toStringAsFixed(0)}',
                        onTap: () => _openDetail(context, j),
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
