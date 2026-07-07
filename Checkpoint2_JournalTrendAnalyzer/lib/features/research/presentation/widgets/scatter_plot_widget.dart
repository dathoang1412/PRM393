import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../models/author_impact.dart';

class ScatterPlotWidget extends StatefulWidget {
  const ScatterPlotWidget({
    required this.data,
    this.color,
    super.key,
  });

  final List<AuthorImpact> data;
  final Color? color;

  @override
  State<ScatterPlotWidget> createState() => _ScatterPlotWidgetState();
}

class _ScatterPlotWidgetState extends State<ScatterPlotWidget> {
  int? _touchedIndex;

  List<AuthorImpact> get _displayed => widget.data.take(60).toList();

  int _findIndex(ScatterSpot spot, List<AuthorImpact> data) {
    return data.indexWhere(
      (a) =>
          a.publicationCount == spot.x.round() &&
          a.totalCitations == spot.y.round(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = _displayed;
    if (data.length < 2) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(
            child: Text('Not enough author data for impact matrix.')),
      );
    }

    final primary = widget.color ?? Theme.of(context).colorScheme.primary;
    final fmt = NumberFormat.compact();

    final maxPubs =
        data.map((a) => a.publicationCount).reduce(max).toDouble();
    final maxCits =
        data.map((a) => a.totalCitations).reduce(max).toDouble();

    final labelStyle = GoogleFonts.spaceGrotesk(
      fontSize: 10,
      fontWeight: FontWeight.w500,
      color: const Color(0xFF94A3B8),
    );

    return ScatterChart(
      ScatterChartData(
        scatterSpots: data.asMap().entries.map((e) {
          final isTouched = _touchedIndex == e.key;
          return ScatterSpot(
            e.value.publicationCount.toDouble(),
            e.value.totalCitations.toDouble(),
            dotPainter: FlDotCirclePainter(
              radius: isTouched ? 8.5 : 5.5,
              color:
                  isTouched ? primary : primary.withValues(alpha: 0.5),
              strokeWidth: 1.5,
              strokeColor: Colors.white,
            ),
          );
        }).toList(),
        minX: 0,
        maxX: maxPubs * 1.2 + 1,
        minY: 0,
        maxY: maxCits * 1.2 + 1,
        scatterTouchData: ScatterTouchData(
          enabled: true,
          handleBuiltInTouches: true,
          touchCallback:
              (FlTouchEvent event, ScatterTouchResponse? response) {
            setState(() {
              if (!event.isInterestedForInteractions ||
                  response?.touchedSpot == null) {
                _touchedIndex = null;
              } else {
                final idx =
                    _findIndex(response!.touchedSpot!.spot, data);
                _touchedIndex = idx >= 0 ? idx : null;
              }
            });
          },
          touchTooltipData: ScatterTouchTooltipData(
            tooltipRoundedRadius: 8,
            getTooltipItems: (ScatterSpot spot) {
              final idx = _findIndex(spot, data);
              if (idx < 0) return null;
              final author = data[idx];
              return ScatterTooltipItem(
                author.name,
                textStyle: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
                children: [
                  TextSpan(
                    text:
                        '\n${author.publicationCount} pubs · ${fmt.format(author.totalCitations)} citations',
                    style: const TextStyle(
                      color: Color(0xCCFFFFFF),
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          drawHorizontalLine: true,
          horizontalInterval: maxCits > 4 ? maxCits / 4 : 1,
          verticalInterval: maxPubs > 4 ? maxPubs / 4 : 1,
          getDrawingHorizontalLine: (_) => const FlLine(
            color: Color(0xFFEEF2FF),
            strokeWidth: 1,
          ),
          getDrawingVerticalLine: (_) => const FlLine(
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
            axisNameWidget: Text('Total Citations', style: labelStyle),
            axisNameSize: 18,
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 46,
              getTitlesWidget: (value, meta) {
                if (value == 0 || value == meta.max) {
                  return const SizedBox.shrink();
                }
                return Text(fmt.format(value.toInt()),
                    style: labelStyle);
              },
            ),
          ),
          bottomTitles: AxisTitles(
            axisNameWidget: Text('Publications', style: labelStyle),
            axisNameSize: 18,
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 26,
              getTitlesWidget: (value, meta) {
                if (value == 0 || value == meta.max) {
                  return const SizedBox.shrink();
                }
                if (value != value.truncateToDouble()) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(value.toInt().toString(),
                      style: labelStyle),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
