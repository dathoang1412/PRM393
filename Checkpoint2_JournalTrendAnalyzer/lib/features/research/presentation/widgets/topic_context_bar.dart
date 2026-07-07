import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:journexa/core/theme/app_colors.dart';
import '../providers/research_provider.dart';

/// A slim strip under the app bar that keeps the current search context
/// visible on analytics screens: which topic is loaded, how many papers,
/// and a one-tap way back to Search to change it.
class TopicContextBar extends StatelessWidget {
  const TopicContextBar({this.onChangeTopic, super.key});

  final VoidCallback? onChangeTopic;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ResearchProvider>();
    if (provider.keyword.isEmpty) return const SizedBox.shrink();

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.primaryWash,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          const Icon(Icons.travel_explore,
              size: 14, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: provider.keyword,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  TextSpan(
                    text: '  ·  ${provider.resultsSummary()}',
                    style: const TextStyle(color: AppColors.inkSecondary),
                  ),
                  if (provider.hasYearFilter)
                    const TextSpan(
                      text: '  ·  year filter on',
                      style: TextStyle(color: AppColors.accent),
                    ),
                ],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          if (onChangeTopic != null)
            TextButton.icon(
              onPressed: onChangeTopic,
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              icon: const Icon(Icons.edit_outlined, size: 13),
              label: const Text('Change topic'),
            ),
        ],
      ),
    );
  }
}
