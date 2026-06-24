import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class DonutSlice {
  const DonutSlice({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;
}

class DonutChart extends StatefulWidget {
  const DonutChart({required this.slices, this.centerLabel, super.key});

  final List<DonutSlice> slices;
  final String? centerLabel;

  @override
  State<DonutChart> createState() => _DonutChartState();
}

class _DonutChartState extends State<DonutChart> {
  int? _touchedIndex;

  @override
  void didUpdateWidget(DonutChart old) {
    super.didUpdateWidget(old);
    if (old.slices != widget.slices) _touchedIndex = null;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.slices.isEmpty) {
      return const Center(child: Text('No data available.'));
    }

    final total = widget.slices.fold<int>(0, (sum, s) => sum + s.value);
    final touched =
        _touchedIndex != null && _touchedIndex! < widget.slices.length
        ? widget.slices[_touchedIndex!]
        : null;
    final fmt = NumberFormat.compact();

    // ── Fixed-size donut ──────────────────────────────────────────────────────
    // Always use a controlled size — never let the chart expand to fill card.
    const chartDiameter = 210.0;

    final pieWidget = SizedBox(
      width: chartDiameter,
      height: chartDiameter,
      child: Stack(
        alignment: Alignment.center,
        children: [
          PieChart(
            PieChartData(
              sections: widget.slices.asMap().entries.map((e) {
                final isTouched = _touchedIndex == e.key;
                return PieChartSectionData(
                  value: e.value.value.toDouble(),
                  color: e.value.color,
                  radius: isTouched ? 62 : 50,
                  title: '',
                );
              }).toList(),
              centerSpaceRadius: 38,
              sectionsSpace: 2,
              startDegreeOffset: -90,
              pieTouchData: PieTouchData(
                touchCallback: (event, response) {
                  setState(() {
                    if (!event.isInterestedForInteractions ||
                        response?.touchedSection == null) {
                      _touchedIndex = null;
                    } else {
                      final idx = response!.touchedSection!.touchedSectionIndex;
                      _touchedIndex = idx >= 0 ? idx : null;
                    }
                  });
                },
              ),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                touched != null ? fmt.format(touched.value) : fmt.format(total),
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color:
                      touched?.color ?? Theme.of(context).colorScheme.primary,
                ),
              ),
              Text(
                touched != null
                    ? touched.label
                    : (widget.centerLabel ?? 'Total'),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: const Color(0xFF94A3B8),
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );

    // ── Legend items ──────────────────────────────────────────────────────────
    // The outer Row splits into: [Expanded(dot+label)] [4px] [SizedBox(30, %)].
    // Inside the Expanded, Row(mainAxisAlignment.end) pushes dot+label to the
    // RIGHT so the empty space falls on the LEFT — label sits close to %
    // without touching it, and % values stay column-aligned at a fixed position.
    List<Widget> buildLegendItems() {
      return widget.slices.asMap().entries.map((e) {
        final isTouched = _touchedIndex == e.key;
        final pct = total == 0 ? 0 : (e.value.value / total * 100);
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: isTouched ? 12 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: e.value.color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  e.value.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isTouched
                        ? const Color(0xFF1E293B)
                        : const Color(0xFF64748B),
                    fontWeight: isTouched ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 11,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              // % fixed-width column — position never changes regardless of label length
              SizedBox(
                width: 30,
                child: Text(
                  '${pct.toStringAsFixed(0)}%',
                  textAlign: TextAlign.right,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: e.value.color,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList();
    }

    // ── Responsive layout ─────────────────────────────────────────────────────
    return LayoutBuilder(
      builder: (context, constraints) {
        final availW = constraints.maxWidth;

        const leadingGap = 20.0;
        const hGap = 80.0;
        const minLegendW = 100.0;
        const maxLegendW = 180.0;

        final useRow =
            availW >= leadingGap + chartDiameter + hGap + minLegendW;

        // Fixed-width legend column: fills remaining space up to 280 px.
        // SizedBox gives Row children a tight width so Expanded(label) works
        // correctly and % values column-align at a consistent position.
        final legendW = (availW - leadingGap - chartDiameter - hGap).clamp(
          minLegendW,
          maxLegendW,
        );

        final legendColumn = SizedBox(
          width: legendW,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: buildLegendItems(),
          ),
        );

        if (useRow) {
          // Align.centerRight pushes the group to the right edge of the content
          // area, so % values sit at the same distance from the right as the
          // count numbers in adjacent leaderboard cards.
          return Align(
            alignment: Alignment.centerRight,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(width: leadingGap),
                pieWidget,
                const SizedBox(width: hGap),
                legendColumn,
              ],
            ),
          );
        }

        // Narrow: chart on top, legend centered below. Scrollable because the
        // combined intrinsic height (chart + all legend rows) can exceed the
        // fixed chart-card height on screens too narrow for the side-by-side row.
        return SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(child: pieWidget),
              const SizedBox(height: 16),
              Center(child: legendColumn),
            ],
          ),
        );
      },
    );
  }
}
