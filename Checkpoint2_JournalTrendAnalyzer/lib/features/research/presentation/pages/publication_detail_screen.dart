import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../models/publication.dart';
import '../models/trend_point.dart';
import '../utils/analytics_calculator.dart';

class PublicationDetailScreen extends StatelessWidget {
  const PublicationDetailScreen({required this.publication, super.key});

  final Publication publication;

  static Color _citationColor(int count) {
    if (count > 500) return const Color(0xFFD97706);
    if (count > 50) return const Color(0xFF059669);
    if (count > 5) return const Color(0xFF1D4ED8);
    return const Color(0xFF64748B);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final pub = publication;
    final fmt = NumberFormat.decimalPattern();
    final citColor = _citationColor(pub.citedByCount);

    // Convert per-paper citationsByYear to TrendPoint for the chart
    final citTrend = pub.citationsByYear
        .map((yc) => TrendPoint(year: yc.year, count: yc.citedByCount))
        .toList()
      ..sort((a, b) => a.year.compareTo(b.year));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Publication Details'),
        actions: [
          if (pub.doi != null)
            IconButton(
              icon: const Icon(Icons.copy_outlined),
              tooltip: 'Copy DOI',
              onPressed: () {
                Clipboard.setData(ClipboardData(text: pub.doi!));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('DOI copied to clipboard'),
                    behavior: SnackBarBehavior.floating,
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
          const SizedBox(width: 4),
        ],
      ),
      body: SelectionArea(
        child: ListView(
          children: [
            // ── Gradient header ────────────────────────────────────────────────
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF1D4ED8), Color(0xFF1E3A8A)],
                ),
              ),
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (pub.publicationYear != null) ...[
                        _HeaderBadge(pub.publicationYear.toString()),
                        const SizedBox(width: 8),
                      ],
                      if (pub.workType != null)
                        _HeaderBadge(
                            AnalyticsCalculator.labelWorkType(pub.workType!),
                            color: Colors.white.withValues(alpha: 0.25)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    pub.title,
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      height: 1.4,
                    ),
                  ),
                  if (pub.authors.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      pub.authors.take(3).join(', ') +
                          (pub.authors.length > 3 ? ' et al.' : ''),
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  // Citation highlight
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.format_quote,
                                size: 16, color: Colors.white),
                            const SizedBox(width: 6),
                            Text(
                              '${fmt.format(pub.citedByCount)} citations',
                              style: GoogleFonts.spaceGrotesk(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── Meta grid ─────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: _MetaGrid(publication: pub),
            ),

            // ── Citation trend chart ──────────────────────────────────────────
            if (citTrend.length >= 2) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                child: _Section(
                  icon: Icons.show_chart,
                  iconColor: citColor,
                  title: 'Citation Trend',
                  child: SizedBox(
                    height: 160,
                    child: _MiniLineChart(
                      points: citTrend,
                      color: citColor,
                    ),
                  ),
                ),
              ),
            ],

            // ── Authors section ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: _Section(
                icon: Icons.people_outline,
                iconColor: colorScheme.primary,
                title: 'Authors (${pub.authors.length})',
                child: pub.authors.isEmpty
                    ? const Text('Unknown authors')
                    : Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: pub.authors
                            .map((a) => _TagChip(
                                  label: a,
                                  color: colorScheme.primary,
                                ))
                            .toList(),
                      ),
              ),
            ),

            // ── Institutions section ──────────────────────────────────────────
            if (pub.institutions.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                child: _Section(
                  icon: Icons.account_balance_outlined,
                  iconColor: const Color(0xFFD97706),
                  title: 'Institutions (${pub.institutions.length})',
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: pub.institutions
                        .map((inst) => _TagChip(
                              label: inst,
                              color: const Color(0xFFD97706),
                            ))
                        .toList(),
                  ),
                ),
              ),

            // ── Keywords / concepts ───────────────────────────────────────────
            if (pub.keywords.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                child: _Section(
                  icon: Icons.label_outline,
                  iconColor: const Color(0xFF0891B2),
                  title: 'Research Concepts',
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: pub.keywords
                        .map((kw) => _TagChip(
                              label: kw,
                              color: const Color(0xFF0891B2),
                            ))
                        .toList(),
                  ),
                ),
              ),

            // ── Abstract ──────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
              child: _Section(
                icon: Icons.article_outlined,
                iconColor: const Color(0xFF475569),
                title: 'Abstract',
                child: Text(
                  pub.abstractText ?? 'No abstract available from OpenAlex.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        height: 1.75,
                        color: const Color(0xFF374151),
                      ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Meta grid ─────────────────────────────────────────────────────────────────

class _MetaGrid extends StatelessWidget {
  const _MetaGrid({required this.publication});

  final Publication publication;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final fmt = NumberFormat.decimalPattern();

    final items = <(IconData, String, String, Color)>[
      (
        Icons.calendar_today_outlined,
        'Year',
        publication.publicationYear?.toString() ?? 'Unknown',
        const Color(0xFF059669),
      ),
      (
        Icons.format_quote,
        'Citations',
        fmt.format(publication.citedByCount),
        const Color(0xFFD97706),
      ),
      (
        Icons.menu_book_outlined,
        'Venue',
        publication.journalName ?? 'Unknown venue',
        const Color(0xFF7C3AED),
      ),
      (
        Icons.link,
        'DOI',
        publication.doi != null
            ? publication.doi!
                .replaceFirst('https://doi.org/', '')
                .replaceFirst('http://doi.org/', '')
            : 'Not available',
        colorScheme.primary,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final cols = constraints.maxWidth > 520 ? 2 : 1;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: cols == 1 ? 5.2 : 3.8,
          ),
          itemBuilder: (context, index) {
            final (icon, label, value, color) = items[index];
            return Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withValues(alpha: 0.15)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, size: 15, color: color),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          label.toUpperCase(),
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: const Color(0xFF94A3B8),
                                    fontWeight: FontWeight.w700,
                                    fontSize: 9,
                                    letterSpacing: 0.7,
                                  ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          value,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.spaceGrotesk(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: const Color(0xFF1E293B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// ── Mini line chart for per-paper citation history ────────────────────────────

class _MiniLineChart extends StatelessWidget {
  const _MiniLineChart({required this.points, required this.color});

  final List<TrendPoint> points;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) return const SizedBox.shrink();

    final maxY = points.map((p) => p.count).reduce((a, b) => a > b ? a : b);
    final chartMaxY = maxY == 0 ? 5.0 : (maxY * 1.3).ceilToDouble();

    final labelStyle = GoogleFonts.spaceGrotesk(
      fontSize: 10,
      fontWeight: FontWeight.w500,
      color: const Color(0xFF94A3B8),
    );

    final fmt = NumberFormat.compact();

    return LineChart(
      LineChartData(
        minX: points.first.year.toDouble(),
        maxX: points.last.year.toDouble(),
        minY: 0,
        maxY: chartMaxY,
        clipData: const FlClipData.all(),
        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            tooltipRoundedRadius: 6,
            getTooltipItems: (spots) => spots.map((spot) {
              return LineTooltipItem(
                '${spot.x.toInt()}: ${fmt.format(spot.y.toInt())} cit.',
                GoogleFonts.spaceGrotesk(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              );
            }).toList(),
          ),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(
          show: true,
          border: const Border(
            left: BorderSide(color: Color(0xFFDDE3F5)),
            bottom: BorderSide(color: Color(0xFFDDE3F5)),
          ),
        ),
        titlesData: FlTitlesData(
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 36,
              getTitlesWidget: (v, _) => Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Text(fmt.format(v.toInt()),
                    style: labelStyle, textAlign: TextAlign.right),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
              interval: 1,
              getTitlesWidget: (v, meta) {
                if (v != v.truncateToDouble()) return const SizedBox.shrink();
                final yr = v.toInt();
                final first = points.first.year;
                final last = points.last.year;
                final span = last - first;
                if (span <= 6 ||
                    yr == first ||
                    yr == last ||
                    (yr - first) % (span ~/ 4) == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(yr.toString(), style: labelStyle),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: points
                .map((p) => FlSpot(p.year.toDouble(), p.count.toDouble()))
                .toList(),
            isCurved: points.length > 3,
            curveSmoothness: 0.3,
            color: color,
            barWidth: 2.5,
            dotData: FlDotData(
              show: points.length <= 12,
              getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                radius: 3,
                color: color,
                strokeWidth: 1.5,
                strokeColor: Colors.white,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  color.withValues(alpha: 0.18),
                  color.withValues(alpha: 0.02),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared widgets ────────────────────────────────────────────────────────────

class _Section extends StatelessWidget {
  const _Section({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.child,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Icon(icon, size: 14, color: iconColor),
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1E293B),
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _HeaderBadge extends StatelessWidget {
  const _HeaderBadge(this.label, {this.color});

  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color ?? Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: GoogleFonts.spaceGrotesk(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
