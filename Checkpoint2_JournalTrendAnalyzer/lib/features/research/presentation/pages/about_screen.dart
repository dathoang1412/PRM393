import 'package:flutter/material.dart';

import 'package:journexa/core/theme/app_colors.dart';

/// About page: what the app does, where the data comes from, and how the
/// analysis pipeline works.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 12),
                Center(
                  child: Container(
                    width: 64,
                    height: 64,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.25),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.auto_stories,
                        color: Colors.white, size: 30),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Journexa',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Explore scholarly publication trends, venues, authors, '
                  'and influential papers for any research topic.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.inkSecondary,
                        height: 1.5,
                      ),
                ),
                const SizedBox(height: 10),
                const Center(child: _VersionChip(label: 'Version 1.0.0')),
                const SizedBox(height: 24),
                const _AboutCard(
                  icon: Icons.public,
                  title: 'Data source',
                  children: [
                    _AboutRow(
                      icon: Icons.dataset_outlined,
                      title: 'OpenAlex',
                      subtitle:
                          'Live bibliographic data from api.openalex.org — an '
                          'open catalog of scholarly works, authors, and venues.',
                    ),
                    _AboutRow(
                      icon: Icons.sort,
                      title: 'Ranked by citations',
                      subtitle:
                          'Results are fetched 100 per page, sorted by total '
                          'citation count.',
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const _AboutCard(
                  icon: Icons.route_outlined,
                  title: 'How it works',
                  children: [
                    _AboutRow(
                      icon: Icons.search,
                      title: '1 · Search a topic',
                      subtitle:
                          'Enter any research keyword to retrieve matching '
                          'publications.',
                    ),
                    _AboutRow(
                      icon: Icons.insights_outlined,
                      title: '2 · Review insights',
                      subtitle:
                          'Dashboards chart publication and citation activity '
                          'over time, filterable by year range.',
                    ),
                    _AboutRow(
                      icon: Icons.leaderboard_outlined,
                      title: '3 · Compare rankings',
                      subtitle:
                          'Rank journals, authors, keywords, and institutions; '
                          'export any view as CSV.',
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const _AboutCard(
                  icon: Icons.build_outlined,
                  title: 'Built with',
                  children: [
                    _AboutRow(
                      icon: Icons.flutter_dash,
                      title: 'Flutter · Material 3',
                      subtitle:
                          'Provider for state management, fl_chart for '
                          'visualizations, clean architecture project layout.',
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  'PRM393 · Checkpoint 2',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.inkMuted,
                        letterSpacing: 0.4,
                      ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _VersionChip extends StatelessWidget {
  const _VersionChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primaryWash,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primaryBorder),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _AboutCard extends StatelessWidget {
  const _AboutCard({
    required this.icon,
    required this.title,
    required this.children,
  });

  final IconData icon;
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _AboutRow extends StatelessWidget {
  const _AboutRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.primaryWash,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 14, color: AppColors.primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.inkSecondary,
                        height: 1.45,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
