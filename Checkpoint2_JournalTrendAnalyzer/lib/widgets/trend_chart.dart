import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/trend_point.dart';

class TrendChart extends StatelessWidget {
  const TrendChart({required this.points, super.key});

  final List<TrendPoint> points;

  static List<int> _labelYears(List<TrendPoint> pts, {int target = 5}) {
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

    final yInterval = _yInterval(maxY);
    final chartMaxY = maxY == 0
        ? yInterval
        : ((maxY / yInterval).ceil() * yInterval).toDouble() + yInterval * 0.5;

    final lastPointIndex = sortedPoints.length - 1;
    final hasSinglePoint = sortedPoints.length == 1;
    final minX = hasSinglePoint ? -1.0 : 0.0;
    final maxX = hasSinglePoint ? 1.0 : lastPointIndex.toDouble();
    final xPadding = hasSinglePoint ? 0.0 : 0.35;

    final primary = Theme.of(context).colorScheme.primary;
    final labelStyle = GoogleFonts.firaCode(
      fontSize: 10,
      color: const Color(0xFF94A3B8),
    );

    final showLabels = _labelYears(sortedPoints, target: 8).toSet();

    return Semantics(
      label: 'Line chart showing publications grouped by year',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final minChartWidth = constraints.maxWidth;
          final preferredChartWidth = sortedPoints.length * 42.0;
          final maxComfortableWidth = minChartWidth * 1.8;
          final scrollChartWidth =
              preferredChartWidth > maxComfortableWidth
                  ? maxComfortableWidth
                  : preferredChartWidth;
          final chartWidth = scrollChartWidth < minChartWidth
              ? minChartWidth
              : scrollChartWidth;

          return Scrollbar(
            thumbVisibility: chartWidth > minChartWidth,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: chartWidth,
                child: LineChart(
                  LineChartData(
                    minX: minX - xPadding,
                    maxX: maxX + xPadding,
                    minY: 0,
                    maxY: chartMaxY,
                    clipData: const FlClipData.none(),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: yInterval,
                      getDrawingHorizontalLine: (_) => const FlLine(
                        color: Color(0xFFEEF2F7),
                        strokeWidth: 1,
                      ),
                    ),
                    borderData: FlBorderData(
                      show: true,
                      border: const Border(
                        left: BorderSide(color: Color(0xFFE2E8F0)),
                        bottom: BorderSide(color: Color(0xFFE2E8F0)),
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
                          reservedSize: 32,
                          interval: yInterval,
                          getTitlesWidget: (value, meta) {
                            if (value == 0 || value == chartMaxY) {
                              return const SizedBox.shrink();
                            }
                            if (value != value.truncateToDouble()) {
                              return const SizedBox.shrink();
                            }
                            return Text(
                              value.toInt().toString(),
                              style: labelStyle,
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
                            final index = value.toInt();
                            if (index < 0 || index >= sortedPoints.length) {
                              return const SizedBox.shrink();
                            }
                            final year = sortedPoints[index].year;
                            if (!showLabels.contains(year)) {
                              return const SizedBox.shrink();
                            }
                            return Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(year.toString(), style: labelStyle),
                            );
                          },
                        ),
                      ),
                    ),
                    lineBarsData: [
                      LineChartBarData(
                        spots: sortedPoints
                            .asMap()
                            .entries
                            .map(
                              (entry) => FlSpot(
                                entry.key.toDouble(),
                                entry.value.count.toDouble(),
                              ),
                            )
                            .toList(),
                        isCurved: sortedPoints.length > 2,
                        curveSmoothness: 0.3,
                        color: primary,
                        barWidth: 2,
                        dotData: FlDotData(
                          show: true,
                          getDotPainter: (spot, percent, bar, index) =>
                              FlDotCirclePainter(
                            radius: 2.5,
                            color: Colors.white,
                            strokeWidth: 1.5,
                            strokeColor: primary,
                          ),
                        ),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              primary.withValues(alpha: 0.18),
                              primary.withValues(alpha: 0.0),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
