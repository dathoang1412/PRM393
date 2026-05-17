import 'dart:io';
import 'package:excel/excel.dart' as excel_pkg;
import 'package:file_picker/file_picker.dart';
import '../models/submission.dart';

class GradingExportService {
  Future<void> exportToExcel(List<Submission> submissions, String markerName) async {
    if (submissions.isEmpty) return;

    var excel = excel_pkg.Excel.createExcel();
    excel_pkg.Sheet sheetObject = excel['Sheet1'];

    sheetObject.appendRow([
      excel_pkg.TextCellValue('Alias'),
      excel_pkg.TextCellValue('Marker'),
      excel_pkg.TextCellValue('Exam Code'),
      excel_pkg.TextCellValue('Human Q1'),
      excel_pkg.TextCellValue('Human Q2'),
      excel_pkg.TextCellValue('Human Q3'),
      excel_pkg.TextCellValue('Human Total'),
      excel_pkg.TextCellValue('Human Comment'),
      excel_pkg.TextCellValue('AI Q1'),
      excel_pkg.TextCellValue('AI Q2'),
      excel_pkg.TextCellValue('AI Q3'),
      excel_pkg.TextCellValue('AI Total'),
      excel_pkg.TextCellValue('AI Comment'),
    ]);

    for (var sub in submissions) {
      sheetObject.appendRow([
        excel_pkg.TextCellValue(sub.fileName),
        excel_pkg.TextCellValue(markerName),
        excel_pkg.TextCellValue(sub.examType?.code ?? ''),
        excel_pkg.DoubleCellValue(sub.score1),
        excel_pkg.DoubleCellValue(sub.score2),
        excel_pkg.DoubleCellValue(sub.score3),
        excel_pkg.DoubleCellValue(sub.total),
        excel_pkg.TextCellValue(sub.comment),
        excel_pkg.DoubleCellValue(sub.aiScore1),
        excel_pkg.DoubleCellValue(sub.aiScore2),
        excel_pkg.DoubleCellValue(sub.aiScore3),
        excel_pkg.DoubleCellValue(sub.aiTotal),
        excel_pkg.TextCellValue(sub.aiComment),
      ]);
    }

    final bytes = excel.encode();
    if (bytes != null) {
      String? outputFile = await FilePicker.saveFile(
        dialogTitle: 'Export Excel',
        fileName: 'grading_results.xlsx',
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
      );

      if (outputFile != null) {
        if (!outputFile.endsWith('.xlsx')) {
          outputFile += '.xlsx';
        }
        final file = File(outputFile);
        await file.writeAsBytes(bytes);
      }
    }
  }
}
