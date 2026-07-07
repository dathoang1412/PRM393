import 'package:flutter/material.dart';

class RankedStatItem {
  const RankedStatItem({required this.name, required this.count});

  final String name;
  final int count;
}

class RankedStatList extends StatelessWidget {
  const RankedStatList({required this.title, required this.items, super.key});

  final String title;
  final List<RankedStatItem> items;

  static Color _rankBg(int rank) => switch (rank) {
        1 => const Color(0xFFFEF3C7),
        2 => const Color(0xFFF1F5F9),
        3 => const Color(0xFFFFF1EE),
        _ => const Color(0xFFF8FAFC),
      };

  static Color _rankFg(int rank) => switch (rank) {
        1 => const Color(0xFFB45309),
        2 => const Color(0xFF64748B),
        3 => const Color(0xFFC2410C),
        _ => const Color(0xFF94A3B8),
      };

  static Color _barColor(int rank) => switch (rank) {
        1 => const Color(0xFFF59E0B),
        2 => const Color(0xFF94A3B8),
        3 => const Color(0xFFF97316),
        _ => const Color(0xFF3B82F6),
      };

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(child: Text('No ranking data available.'));
    }

    final maxCount = items.fold<int>(
      0,
      (prev, item) => item.count > prev ? item.count : prev,
    );

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length + 1,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
          );
        }

        final rank = index;
        final item = items[rank - 1];
        final percent = maxCount == 0 ? 0.0 : item.count / maxCount;
        final barColor = _barColor(rank);

        return Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _rankBg(rank),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '#$rank',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                      color: _rankFg(rank),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: percent,
                          minHeight: 6,
                          backgroundColor: const Color(0xFFE2E8F0),
                          color: barColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: barColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${item.count}',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: barColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
