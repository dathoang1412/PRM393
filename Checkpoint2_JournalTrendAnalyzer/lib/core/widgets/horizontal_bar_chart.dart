import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class BarItem {
  const BarItem({required this.label, required this.value});

  final String label;
  final int value;
}

class HorizontalBarChart extends StatefulWidget {
  const HorizontalBarChart({
    required this.items,
    this.color,
    this.maxItems = 10,
    super.key,
  });

  final List<BarItem> items;
  final Color? color;
  final int maxItems;

  @override
  State<HorizontalBarChart> createState() => _HorizontalBarChartState();
}

class _HorizontalBarChartState extends State<HorizontalBarChart> {
  bool _animated = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _animated = true);
    });
  }

  @override
  void didUpdateWidget(HorizontalBarChart old) {
    super.didUpdateWidget(old);
    if (old.items != widget.items) {
      setState(() => _animated = false);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _animated = true);
      });
    }
  }

  static Color _rankColor(int rank) => switch (rank) {
        1 => const Color(0xFFD97706),
        2 => const Color(0xFF64748B),
        3 => const Color(0xFFEA580C),
        _ => const Color(0xFF94A3B8),
      };

  @override
  Widget build(BuildContext context) {
    final displayed = widget.items.take(widget.maxItems).toList();
    if (displayed.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('No data available.'),
        ),
      );
    }

    final maxValue = displayed.first.value;
    final barColor = widget.color ?? Theme.of(context).colorScheme.primary;
    final fmt = NumberFormat.compact();

    return LayoutBuilder(
      builder: (context, constraints) {
        const rankW = 34.0;
        const labelW = 145.0;
        const countW = 46.0;
        const gap = 8.0;
        final barMaxW = (constraints.maxWidth - rankW - labelW - countW - gap * 3)
            .clamp(60.0, double.infinity);

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: displayed.asMap().entries.map((entry) {
            final rank = entry.key + 1;
            final item = entry.value;
            final pct = maxValue == 0 ? 0.0 : item.value / maxValue;
            final rankColor = _rankColor(rank);

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Rank badge
                  Container(
                    width: rankW,
                    height: rankW,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: rank <= 3
                          ? rankColor.withValues(alpha: 0.12)
                          : const Color(0xFFF1F5F9),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$rank',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: rank <= 3
                            ? rankColor
                            : const Color(0xFF94A3B8),
                      ),
                    ),
                  ),
                  const SizedBox(width: gap),
                  // Label
                  SizedBox(
                    width: labelW,
                    child: Text(
                      item.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style:
                          Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF1E293B),
                              ),
                    ),
                  ),
                  const SizedBox(width: gap),
                  // Bar track + animated fill
                  SizedBox(
                    width: barMaxW,
                    height: 26,
                    child: Stack(
                      alignment: Alignment.centerLeft,
                      children: [
                        Container(
                          width: double.infinity,
                          height: 26,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        AnimatedContainer(
                          duration: Duration(
                              milliseconds: 500 + rank * 55),
                          curve: Curves.easeOut,
                          width: _animated
                              ? (barMaxW * pct).clamp(4.0, barMaxW)
                              : 0,
                          height: 26,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                barColor,
                                barColor.withValues(alpha: 0.68),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: gap),
                  // Count
                  SizedBox(
                    width: countW,
                    child: Text(
                      fmt.format(item.value),
                      textAlign: TextAlign.right,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: barColor,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
