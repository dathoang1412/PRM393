import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/trend_point.dart';

class TrendChart extends StatelessWidget {
  const TrendChart({
    required this.points,
    this.color,
    this.unit = 'papers',
    this.showPeakLine = true,
    super.key,
  });

  final List<TrendPoint> points;
  final Color? color;
  final String unit;
  final bool showPeakLine;

  static List<int> _labelYears(List<TrendPoint> pts, {int target = 6}) {
    if (pts.isEmpty) return [];
    final years = pts.map((p) => p.year).toList();
    if (years.length <= target) return years;
    return List.generate(target, (i) {
      final index = (i * (years.length - 1) / (target - 1)).round();
      return years[index];
    }).toSet().toList();
  }

  static double _yInterval(double maxY) {
    if (maxY <= 5) return 1;
    if (maxY <= 12) return 2;
    if (maxY <= 25) return 5;
    if (maxY <= 60) return 10;
    if (maxY <= 200) return 25;
    if (maxY <= 500) return 50;
    return (maxY / 5).ceilToDouble();
  }

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return const Center(child: Text('No yearly data available.'));
    }

    final sortedPoints = [...points]..sort((a, b) => a.year.compareTo(b.year));

    final maxY = sortedPoints
        .map((p) => p.count)
        .fold<int>(0, (prev, c) => c > prev ? c : prev)
        .toDouble();

    final peakPoint = sortedPoints.length > 1
        ? sortedPoints.reduce((a, b) => a.count >= b.count ? a : b)
        : sortedPoints.first;

    final yInterval = _yInterval(maxY);
    final chartMaxY = maxY == 0
        ? yInterval
        : ((maxY / yInterval).ceil() * yInterval).toDouble() + yInterval * 0.4;

    final minYear = sortedPoints.first.year.toDouble();
    final maxYear = sortedPoints.last.year.toDouble();
    final hasSinglePoint = sortedPoints.length == 1;
    final minX = hasSinglePoint ? minYear - 1 : minYear;
    final maxX = hasSinglePoint ? maxYear + 1 : maxYear;

    final primary = color ?? Theme.of(context).colorScheme.primary;
    final labelStyle = GoogleFonts.spaceGrotesk(
      fontSize: 10,
      fontWeight: FontWeight.w500,
      color: const Color(0xFF94A3B8),
    );

    final showLabels = _labelYears(sortedPoints).toSet();

    return LineChart(
      LineChartData(
        minX: minX,
        maxX: maxX,
        minY: 0,
        maxY: chartMaxY,
        clipData: const FlClipData.all(),
        extraLinesData: showPeakLine && sortedPoints.length > 2
            ? ExtraLinesData(
                verticalLines: [
                  VerticalLine(
                    x: peakPoint.year.toDouble(),
                    color: primary.withValues(alpha: 0.28),
                    strokeWidth: 1.5,
                    dashArray: [5, 5],
                    label: VerticalLineLabel(
                      show: true,
                      labelResolver: (_) => 'Peak ${peakPoint.year}',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: primary.withValues(alpha: 0.6),
                      ),
                      alignment: Alignment.topCenter,
                      padding: const EdgeInsets.only(top: 4),
                    ),
                  ),
                ],
              )
            : null,
        lineTouchData: LineTouchData(
          enabled: true,
          handleBuiltInTouches: true,
          getTouchedSpotIndicator: (barData, spotIndexes) {
            return spotIndexes.map((_) {
              return TouchedSpotIndicatorData(
                FlLine(
                  color: primary.withValues(alpha: 0.35),
                  strokeWidth: 1.5,
                  dashArray: [4, 4],
                ),
                FlDotData(
                  getDotPainter: (spot, percent, bar, idx) =>
                      FlDotCirclePainter(
                    radius: 6,
                    color: primary,
                    strokeWidth: 2.5,
                    strokeColor: Colors.white,
                  ),
                ),
              );
            }).toList();
          },
          touchTooltipData: LineTouchTooltipData(
            tooltipRoundedRadius: 8,
            tooltipPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            getTooltipItems: (spots) => spots.map((spot) {
              return LineTooltipItem(
                '${spot.x.toInt()}',
                GoogleFonts.spaceGrotesk(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
                children: [
                  TextSpan(
                    text: '\n${spot.y.toInt()} $unit',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Color(0xCCFFFFFF),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: yInterval,
          getDrawingHorizontalLine: (_) => const FlLine(
            color: Color(0xFFEEF2FF),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: const Border(
            left: BorderSide(color: Color(0xFFDDE3F5)),
            bottom: BorderSide(color: Color(0xFFDDE3F5)),
          ),
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 38,
              interval: yInterval,
              getTitlesWidget: (value, meta) {
                if (value == 0 || value == chartMaxY) {
                  return const SizedBox.shrink();
                }
                if (value != value.truncateToDouble()) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Text(
                    value.toInt().toString(),
                    style: labelStyle,
                    textAlign: TextAlign.right,
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: 1,
              getTitlesWidget: (value, meta) {
                if (value != value.truncateToDouble()) {
                  return const SizedBox.shrink();
                }
                final year = value.toInt();
                if (!showLabels.contains(year)) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(year.toString(), style: labelStyle),
                );
              },
            ),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: sortedPoints
                .map((p) => FlSpot(p.year.toDouble(), p.count.toDouble()))
                .toList(),
            isCurved: sortedPoints.length > 2,
            curveSmoothness: 0.3,
            color: primary,
            barWidth: 2.5,
            dotData: FlDotData(
              show: sortedPoints.length <= 15,
              getDotPainter: (spot, percent, bar, index) =>
                  FlDotCirclePainter(
                radius: 3,
                color: primary,
                strokeWidth: 2,
                strokeColor: Colors.white,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  primary.withValues(alpha: 0.18),
                  primary.withValues(alpha: 0.01),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
