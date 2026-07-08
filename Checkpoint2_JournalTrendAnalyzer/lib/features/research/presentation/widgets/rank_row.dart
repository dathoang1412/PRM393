import 'package:flutter/material.dart';

import 'package:journexa/core/theme/app_colors.dart';

/// A single ranked row: rank number, name, share bar, count badge, optional
/// secondary badge. Shared by the Journals/Keywords screens and detail pages.
class RankRow extends StatelessWidget {
  const RankRow({
    required this.rank,
    required this.name,
    required this.count,
    required this.total,
    required this.color,
    this.badge,
    this.onTap,
    super.key,
  });

  final int rank;
  final String name;
  final int count;
  final int total;
  final Color color;
  final String? badge;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final pct = total == 0 ? 0.0 : count / total;
    final row = Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
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
                color: rank <= 3 ? color : AppColors.inkMuted,
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
                        color: AppColors.ink,
                      ),
                ),
                const SizedBox(height: 3),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: pct,
                    minHeight: 4,
                    backgroundColor: AppColors.wash,
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
                color: AppColors.wash,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                badge!,
                style: TextStyle(
                    fontSize: 10, fontWeight: FontWeight.w600, color: color),
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
          if (onTap != null) ...[
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right,
                size: 16, color: AppColors.inkMuted),
          ],
        ],
      ),
    );

    if (onTap == null) return row;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: row,
    );
  }
}
