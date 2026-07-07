import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'package:journexa/core/theme/app_colors.dart';
import '../providers/research_provider.dart';

/// Curated topics surfaced on the landing page; tapping one runs a live
/// OpenAlex search and jumps to the Research tab.
const _kTrendingTopics = [
  'Large Language Models',
  'Generative Artificial Intelligence',
  'Climate Change Mitigation',
  'Quantum Machine Learning',
  'CRISPR Gene Editing',
  'Sustainable Energy Systems',
  'Digital Health and Telemedicine',
  'Autonomous Vehicles',
];

/// Landing page: journal-cover hero, a resume card for the loaded topic,
/// shortcuts into the main tabs, and trending topics that start a search.
class HomeScreen extends StatelessWidget {
  const HomeScreen({
    required this.onOpenResearch,
    required this.onOpenTrends,
    required this.onOpenRankings,
    required this.onSearchTopic,
    super.key,
  });

  final VoidCallback onOpenResearch;
  final VoidCallback onOpenTrends;

  /// Opens the Rankings screen on a specific tab (0 Journals, 1 Authors, …)
  /// so each shortcut lands exactly where its label promises.
  final ValueChanged<int> onOpenRankings;
  final ValueChanged<String> onSearchTopic;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ResearchProvider>();
    final hasTopic = provider.keyword.isNotEmpty &&
        provider.status == ResearchStatus.success;

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _JournalCoverHero(),
                if (hasTopic) ...[
                  const SizedBox(height: 14),
                  _ResumeCard(
                    keyword: provider.keyword,
                    summary: provider.resultsSummary(suffix: ' loaded'),
                    onTap: onOpenTrends,
                  ),
                ],
                const SizedBox(height: 20),
                Text(
                  'Explore',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                ),
                const SizedBox(height: 10),
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: _FeatureCard(
                          icon: Icons.travel_explore,
                          title: 'Journal Research',
                          subtitle: 'Search 250M+ scholarly works',
                          dark: true,
                          onTap: onOpenResearch,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _FeatureCard(
                          icon: Icons.show_chart,
                          title: 'Trend Analysis',
                          subtitle: 'Dashboard & activity over time',
                          onTap: onOpenTrends,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: _FeatureCard(
                          icon: Icons.menu_book_outlined,
                          title: 'Leading Journals',
                          subtitle: 'Top publishing venues',
                          onTap: () => onOpenRankings(0),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _FeatureCard(
                          icon: Icons.people_outline,
                          title: 'Top Authors',
                          subtitle: 'Influential researchers',
                          onTap: () => onOpenRankings(1),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Trending Research Topics',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tap a topic to run a live OpenAlex search.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.inkSecondary,
                      ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _kTrendingTopics
                      .map((t) => _TopicPill(
                            label: t,
                            onTap: () => onSearchTopic(t),
                          ))
                      .toList(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Journal-cover hero ────────────────────────────────────────────────────────

class _JournalCoverHero extends StatelessWidget {
  const _JournalCoverHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primaryDark, AppColors.primary],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.3),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'POWERED BY OPENALEX',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.35)),
                ),
                child: Text(
                  'OPEN ACCESS',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              'JOURNEXA',
              style: GoogleFonts.fraunces(
                color: Colors.white,
                fontSize: 34,
                fontWeight: FontWeight.w700,
                letterSpacing: 4,
                height: 1.1,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Journal Trend Analyzer & Bibliometrics',
            style: GoogleFonts.fraunces(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 13.5,
              fontStyle: FontStyle.italic,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Resume card — jump back into the loaded topic ─────────────────────────────

class _ResumeCard extends StatelessWidget {
  const _ResumeCard({
    required this.keyword,
    required this.summary,
    required this.onTap,
  });

  final String keyword;
  final String summary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primaryWash,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.primaryBorder),
          ),
          child: Row(
            children: [
              const Icon(Icons.play_circle_outline,
                  size: 20, color: AppColors.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Continue: $keyword',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryDark,
                          ),
                    ),
                    Text(
                      summary,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.inkSecondary,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward,
                  size: 16, color: AppColors.primary),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Feature shortcut card (compact, used in the 2×2 grid) ────────────────────

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.dark = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final fg = dark ? Colors.white : AppColors.ink;
    final fgSub = dark
        ? Colors.white.withValues(alpha: 0.75)
        : AppColors.inkSecondary;
    final iconBg = dark
        ? Colors.white.withValues(alpha: 0.15)
        : AppColors.primaryWash;
    final iconFg = dark ? Colors.white : AppColors.primary;

    return Material(
      color: dark ? AppColors.primaryDark : Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: dark ? AppColors.primaryDark : AppColors.border,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: iconBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, size: 18, color: iconFg),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.arrow_outward,
                    size: 14,
                    color: dark
                        ? Colors.white.withValues(alpha: 0.6)
                        : AppColors.inkMuted,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: fg,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: fgSub,
                      height: 1.4,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Trending topic pill ───────────────────────────────────────────────────────

class _TopicPill extends StatelessWidget {
  const _TopicPill({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.border),
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppColors.primaryDark,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
      ),
    );
  }
}
