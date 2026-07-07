import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:journexa/core/utils/app_feedback.dart';
import 'package:journexa/features/research/domain/usecases/analytics_calculator.dart';
import '../providers/research_provider.dart';
import '../widgets/topic_context_bar.dart';
import 'dashboard_screen.dart';
import 'trends_screen.dart';

/// The Trends tab: hosts the Research Dashboard and Trend Analysis screens
/// as two sub-tabs sharing one app bar, topic context bar, and CSV export.
class TrendsHubScreen extends StatelessWidget {
  const TrendsHubScreen({this.onChangeTopic, this.onOpenRankings, super.key});

  /// Switches back to the Research tab so the user can load another topic.
  final VoidCallback? onChangeTopic;

  /// Opens the Rankings screen — analysis and rankings are one workflow, so
  /// the jump is available right from the app bar.
  final VoidCallback? onOpenRankings;

  void _exportCsv(BuildContext context, ResearchProvider provider) {
    final csv = AnalyticsCalculator.exportCsv(
      provider.filteredPublications,
      provider.keyword,
    );
    Clipboard.setData(ClipboardData(text: csv));
    showSuccessSnackBar(
      context,
      'CSV copied — ${provider.filteredPublications.length} papers',
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ResearchProvider>();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Trends'),
          actions: [
            if (onOpenRankings != null)
              IconButton(
                icon: const Icon(Icons.leaderboard_outlined),
                tooltip: 'Rankings',
                onPressed:
                    provider.publications.isEmpty ? null : onOpenRankings,
              ),
            IconButton(
              icon: const Icon(Icons.download_outlined),
              tooltip: 'Export CSV to clipboard',
              onPressed: provider.publications.isEmpty
                  ? null
                  : () => _exportCsv(context, provider),
            ),
            const SizedBox(width: 4),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(
                  icon: Icon(Icons.dashboard_outlined, size: 16),
                  text: 'Dashboard'),
              Tab(
                  icon: Icon(Icons.show_chart, size: 16),
                  text: 'Trend Analysis'),
            ],
          ),
        ),
        body: Column(
          children: [
            TopicContextBar(onChangeTopic: onChangeTopic),
            Expanded(
              child: TabBarView(
                children: [
                  DashboardScreen(onChangeTopic: onChangeTopic),
                  TrendsScreen(onChangeTopic: onChangeTopic),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
