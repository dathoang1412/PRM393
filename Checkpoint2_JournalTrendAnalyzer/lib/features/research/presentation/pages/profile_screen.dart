import 'package:flutter/material.dart';

import 'package:journexa/core/theme/app_colors.dart';
import 'about_screen.dart';

/// Profile tab — a deliberate placeholder. Accounts and personalization are
/// out of scope for this checkpoint; the page reserves the space and links
/// to the About page.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                Center(
                  child: Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      color: AppColors.primaryWash,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primaryBorder),
                    ),
                    child: const Icon(Icons.person_outline,
                        size: 40, color: AppColors.primary),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Guest Researcher',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Sign-in and personalization are coming in a future release.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.inkSecondary,
                      ),
                ),
                const SizedBox(height: 26),
                const _PlaceholderRow(
                  icon: Icons.bookmark_outline,
                  title: 'Saved topics',
                  subtitle: 'Pin the research topics you follow',
                ),
                const SizedBox(height: 10),
                const _PlaceholderRow(
                  icon: Icons.history,
                  title: 'Search history',
                  subtitle: 'Revisit previous topic analyses',
                ),
                const SizedBox(height: 10),
                const _PlaceholderRow(
                  icon: Icons.tune,
                  title: 'Preferences',
                  subtitle: 'Default year range and export options',
                ),
                const SizedBox(height: 18),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.info_outline,
                        size: 20, color: AppColors.primary),
                    title: Text(
                      'About Journexa',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    trailing: const Icon(Icons.chevron_right,
                        size: 20, color: AppColors.inkMuted),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const AboutScreen()),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A disabled-looking feature row with a "SOON" badge.
class _PlaceholderRow extends StatelessWidget {
  const _PlaceholderRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.inkMuted),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.inkSecondary,
                        ),
                  ),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.inkMuted,
                        ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.wash,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'SOON',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.inkMuted,
                      fontWeight: FontWeight.w700,
                      fontSize: 9,
                      letterSpacing: 0.8,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
