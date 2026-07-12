import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:journexa/core/firebase/analytics_service.dart';
import 'package:journexa/core/theme/app_colors.dart';
import 'package:journexa/core/widgets/app_bar_brand_title.dart';
import 'package:journexa/core/widgets/metric_tile.dart';
import 'package:journexa/core/widgets/section_card.dart';
import 'package:journexa/features/research/data/models/publication.dart';
import 'package:journexa/features/research/data/models/trend_point.dart';
import 'package:journexa/features/research/domain/usecases/analytics_calculator.dart';
import '../widgets/notification_bell.dart';
import 'author_detail_screen.dart';
import 'institution_detail_screen.dart';
import 'keyword_detail_screen.dart';

class PublicationDetailScreen extends StatefulWidget {
  const PublicationDetailScreen({required this.publication, super.key});

  final Publication publication;

  @override
  State<PublicationDetailScreen> createState() =>
      _PublicationDetailScreenState();
}

class _PublicationDetailScreenState extends State<PublicationDetailScreen> {
  @override
  void initState() {
    super.initState();
    AnalyticsService.instance.logViewPublication(
      widget.publication.title,
      widget.publication.publicationYear,
    );
  }

  /// Opens the original publication — the DOI when available, otherwise the
  /// OpenAlex record page.
  Future<void> _openOriginal() async {
    final pub = widget.publication;
    final url = pub.doi ?? pub.id;
    final uri = Uri.tryParse(url);
    final opened = uri != null &&
        await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open the publication link'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  static Color _citationColor(int count) {
    if (count > 500) return const Color(0xFFB45309);
    if (count > 50) return const Color(0xFF12896B);
    if (count > 5) return const Color(0xFF2E67B2);
    return const Color(0xFF5D6672);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final pub = widget.publication;
    final fmt = NumberFormat.decimalPattern();
    final citColor = _citationColor(pub.citedByCount);

    // Convert per-paper citationsByYear to TrendPoint for the chart
    final citTrend = pub.citationsByYear
        .map((yc) => TrendPoint(year: yc.year, count: yc.citedByCount))
        .toList()
      ..sort((a, b) => a.year.compareTo(b.year));

    return Scaffold(
      appBar: AppBar(
        title: const AppBarBrandTitle('Publication Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_new),
            tooltip: 'View original publication',
            onPressed: _openOriginal,
          ),
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
          const NotificationBell(),
          const SizedBox(width: 4),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: ElevatedButton.icon(
          onPressed: _openOriginal,
          icon: const Icon(Icons.open_in_new, size: 18),
          label: const Text('View original publication'),
        ),
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
                  colors: [Color(0xFF0F5D4E), Color(0xFF0A4237)],
                ),
              ),
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (pub.publicationYear != null) ...[
                        _HeaderBadge(
                          pub.publicationYear.toString(),
                          color: Colors.white,
                          textColor: AppColors.primaryDark,
                        ),
                        const SizedBox(width: 8),
                      ],
                      if (pub.workType != null)
                        _HeaderBadge(
                            AnalyticsCalculator.labelWorkType(pub.workType!)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    pub.title,
                    style: GoogleFonts.inter(
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
                      style: GoogleFonts.inter(
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

            // ── KPI grid — same MetricTile used on every other screen ─────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  const cols = 2;
                  final aspect =
                      (constraints.maxWidth - (cols - 1) * 10) / cols / 84.0;
                  return GridView.count(
                    crossAxisCount: cols,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: aspect,
                    children: [
                      MetricTile(
                        icon: Icons.calendar_today_outlined,
                        label: 'Year',
                        value: pub.publicationYear?.toString() ?? 'Unknown',
                        iconColor: AppColors.seriesCountries,
                      ),
                      MetricTile(
                        icon: Icons.format_quote,
                        label: 'Citations',
                        value: fmt.format(pub.citedByCount),
                        iconColor: AppColors.seriesCitations,
                      ),
                      MetricTile(
                        icon: Icons.menu_book_outlined,
                        label: 'Venue',
                        value: pub.journalName ?? 'Unknown venue',
                        iconColor: AppColors.seriesVenues,
                      ),
                      MetricTile(
                        icon: Icons.link,
                        label: 'DOI',
                        value: pub.doi != null
                            ? pub.doi!
                                .replaceFirst('https://doi.org/', '')
                                .replaceFirst('http://doi.org/', '')
                            : 'Not available',
                        iconColor: colorScheme.primary,
                      ),
                    ],
                  );
                },
              ),
            ),

            // ── Citation trend chart ──────────────────────────────────────────
            if (citTrend.length >= 2) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                child: SectionCard(
                  icon: Icons.show_chart,
                  iconColor: citColor,
                  title: 'Citation Trend',
                  subtitle: 'Citations received per calendar year',
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
              child: SectionCard(
                icon: Icons.people_outline,
                iconColor: colorScheme.primary,
                title: 'Authors (${pub.authors.length})',
                subtitle: 'From OpenAlex metadata',
                child: pub.authors.isEmpty
                    ? const Text('Unknown authors')
                    : Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: pub.authors
                            .map((a) => _TagChip(
                                  label: a,
                                  color: colorScheme.primary,
                                  onTap: () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          AuthorDetailScreen(authorName: a),
                                    ),
                                  ),
                                ))
                            .toList(),
                      ),
              ),
            ),

            // ── Institutions section ──────────────────────────────────────────
            if (pub.institutions.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                child: SectionCard(
                  icon: Icons.account_balance_outlined,
                  iconColor: AppColors.seriesCitations,
                  title: 'Institutions (${pub.institutions.length})',
                  subtitle: 'Author affiliations',
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: pub.institutions
                        .map((inst) => _TagChip(
                              label: inst,
                              color: AppColors.seriesCitations,
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => InstitutionDetailScreen(
                                      institutionName: inst),
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                ),
              ),

            // ── Keywords / concepts ───────────────────────────────────────────
            if (pub.keywords.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                child: SectionCard(
                  icon: Icons.label_outline,
                  iconColor: AppColors.seriesAuthors,
                  title: 'Research Concepts',
                  subtitle: 'OpenAlex-assigned topics',
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: pub.keywords
                        .map((kw) => _TagChip(
                              label: kw,
                              color: AppColors.seriesAuthors,
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      KeywordDetailScreen(keyword: kw),
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                ),
              ),

            // ── Abstract ──────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
              child: SectionCard(
                icon: Icons.article_outlined,
                iconColor: AppColors.inkSecondary,
                title: 'Abstract',
                subtitle: 'As indexed by OpenAlex',
                child: Text(
                  pub.abstractText ?? 'No abstract available from OpenAlex.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        height: 1.75,
                        color: AppColors.ink,
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
      color: const Color(0xFF8F8D84),
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
            left: BorderSide(color: Color(0xFFE6E2D8)),
            bottom: BorderSide(color: Color(0xFFE6E2D8)),
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

class _TagChip extends StatelessWidget {
  const _TagChip({required this.label, required this.color, this.onTap});

  final String label;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
          ),
          if (onTap != null) ...[
            const SizedBox(width: 4),
            Icon(Icons.arrow_outward, size: 12, color: color),
          ],
        ],
      ),
    );

    if (onTap == null) return chip;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: chip,
      ),
    );
  }
}

class _HeaderBadge extends StatelessWidget {
  const _HeaderBadge(this.label, {this.color, this.textColor});

  final String label;
  final Color? color;
  final Color? textColor;

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
          color: textColor ?? Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
