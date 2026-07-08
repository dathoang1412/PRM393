import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// One KPI line in the exported report.
typedef ReportStat = ({String label, String value});

/// One ranked line (journal/author) in the exported report.
typedef ReportRank = ({String name, String detail});

/// Builds the dashboard-analytics PDF report and writes it to a temp file.
/// Pure data-in/file-out — Firebase upload happens in StorageService.
Future<File> buildDashboardReportPdf({
  required String topic,
  required List<ReportStat> stats,
  required List<ReportRank> topJournals,
  required List<ReportRank> topAuthors,
}) async {
  const pine = PdfColor.fromInt(0xFF0F5D4E);
  const ink = PdfColor.fromInt(0xFF222D3A);
  const muted = PdfColor.fromInt(0xFF5D6672);

  final doc = pw.Document();
  doc.addPage(
    pw.MultiPage(
      build: (context) => [
        pw.Text('JOURNEXA',
            style: const pw.TextStyle(
                fontSize: 22, fontWeight: pw.FontWeight.bold, color: pine)),
        pw.Text('Research Dashboard Report',
            style: const pw.TextStyle(fontSize: 12, color: muted)),
        pw.SizedBox(height: 4),
        pw.Text('Topic: $topic',
            style: const pw.TextStyle(
                fontSize: 14, fontWeight: pw.FontWeight.bold, color: ink)),
        pw.Text('Generated: ${DateTime.now()}',
            style: const pw.TextStyle(fontSize: 9, color: muted)),
        pw.Divider(color: pine),
        pw.SizedBox(height: 8),
        pw.Text('Key metrics',
            style: const pw.TextStyle(
                fontSize: 12, fontWeight: pw.FontWeight.bold, color: pine)),
        pw.SizedBox(height: 4),
        pw.TableHelper.fromTextArray(
          headers: ['Metric', 'Value'],
          data: [
            for (final s in stats) [s.label, s.value],
          ],
          headerStyle: const pw.TextStyle(
              fontWeight: pw.FontWeight.bold, color: PdfColors.white),
          headerDecoration: const pw.BoxDecoration(color: pine),
          cellStyle: const pw.TextStyle(fontSize: 10),
        ),
        pw.SizedBox(height: 14),
        pw.Text('Top journals',
            style: const pw.TextStyle(
                fontSize: 12, fontWeight: pw.FontWeight.bold, color: pine)),
        pw.SizedBox(height: 4),
        for (final (i, j) in topJournals.indexed)
          pw.Bullet(
              text: '${i + 1}. ${j.name} — ${j.detail}',
              style: const pw.TextStyle(fontSize: 10)),
        pw.SizedBox(height: 14),
        pw.Text('Top authors',
            style: const pw.TextStyle(
                fontSize: 12, fontWeight: pw.FontWeight.bold, color: pine)),
        pw.SizedBox(height: 4),
        for (final (i, a) in topAuthors.indexed)
          pw.Bullet(
              text: '${i + 1}. ${a.name} — ${a.detail}',
              style: const pw.TextStyle(fontSize: 10)),
        pw.SizedBox(height: 20),
        pw.Text('Data source: OpenAlex (api.openalex.org) · PRM393 Lab 03',
            style: const pw.TextStyle(fontSize: 8, color: muted)),
      ],
    ),
  );

  final dir = await getTemporaryDirectory();
  final file = File(
      '${dir.path}/journexa_report_${DateTime.now().millisecondsSinceEpoch}.pdf');
  await file.writeAsBytes(await doc.save());
  return file;
}
