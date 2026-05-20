import 'dart:io';
import 'package:excel/excel.dart' as excel_pkg;
import 'package:file_picker/file_picker.dart';
import '../models/submission.dart';
import '../models/exam_type.dart';

class GradingExportService {
  Future<void> exportToExcel(List<Submission> submissions, String markerName) async {
    if (submissions.isEmpty) return;

    var excel = excel_pkg.Excel.createExcel();
    excel_pkg.Sheet sheetObject = excel['Sheet1'];

    // Find the active exam type from submissions
    var exam = submissions.first.examType ?? defaultExamTypes.first;
    final int n = exam.criteria.length;
    final headerStyle = excel_pkg.CellStyle(
      backgroundColorHex: excel_pkg.ExcelColor.fromHexString('#FCE4D6'), // soft peach
      horizontalAlign: excel_pkg.HorizontalAlign.Center,
      bold: true,
    );

    final totalStyle = excel_pkg.CellStyle(
      backgroundColorHex: excel_pkg.ExcelColor.fromHexString('#FCE4D6'),
      horizontalAlign: excel_pkg.HorizontalAlign.Center,
      bold: true,
      fontColorHex: excel_pkg.ExcelColor.fromHexString('#0000D3'), // blue color
    );

    final commentStyle = excel_pkg.CellStyle(
      backgroundColorHex: excel_pkg.ExcelColor.fromHexString('#FFFF00'), // bright yellow for Comment
      horizontalAlign: excel_pkg.HorizontalAlign.Center,
      bold: true,
    );

    final textCenterStyle = excel_pkg.CellStyle(
      horizontalAlign: excel_pkg.HorizontalAlign.Center,
    );

    // Row 0 (First row): Question 1, 2, ... N, Total
    for (int i = 0; i < n; i++) {
      var cell = sheetObject.cell(excel_pkg.CellIndex.indexByColumnRow(columnIndex: i + 2, rowIndex: 0));
      cell.value = excel_pkg.TextCellValue('Question ${i + 1}');
      cell.cellStyle = headerStyle;
    }
    var totalHeaderCell = sheetObject.cell(excel_pkg.CellIndex.indexByColumnRow(columnIndex: n + 2, rowIndex: 0));
    totalHeaderCell.value = excel_pkg.TextCellValue('Total');
    totalHeaderCell.cellStyle = headerStyle;

    // Row 1 (Second row): Alias, Marker, max scores, total max score, Comment
    var aliasCell = sheetObject.cell(excel_pkg.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1));
    aliasCell.value = excel_pkg.TextCellValue('Alias');
    aliasCell.cellStyle = headerStyle;

    var markerCell = sheetObject.cell(excel_pkg.CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 1));
    markerCell.value = excel_pkg.TextCellValue('Marker');
    markerCell.cellStyle = headerStyle;

    for (int i = 0; i < n; i++) {
      var cell = sheetObject.cell(excel_pkg.CellIndex.indexByColumnRow(columnIndex: i + 2, rowIndex: 1));
      cell.value = excel_pkg.DoubleCellValue(exam.criteria[i].maxScore10);
      cell.cellStyle = headerStyle;
    }

    var totalMaxCell = sheetObject.cell(excel_pkg.CellIndex.indexByColumnRow(columnIndex: n + 2, rowIndex: 1));
    totalMaxCell.value = excel_pkg.DoubleCellValue(exam.totalMaxScore10);
    totalMaxCell.cellStyle = totalStyle; // blue bold text on peach background

    var commentCell = sheetObject.cell(excel_pkg.CellIndex.indexByColumnRow(columnIndex: n + 3, rowIndex: 1));
    commentCell.value = excel_pkg.TextCellValue('Comment');
    commentCell.cellStyle = commentStyle;

    // Row 2 onwards: Submissions
    for (int rowIndex = 0; rowIndex < submissions.length; rowIndex++) {
      final sub = submissions[rowIndex];
      sub.initScores(exam);

      // Alias (1-based index)
      var aliasValCell = sheetObject.cell(excel_pkg.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex + 2));
      aliasValCell.value = excel_pkg.IntCellValue(rowIndex + 1);
      aliasValCell.cellStyle = textCenterStyle;

      // Marker Name
      var markerValCell = sheetObject.cell(excel_pkg.CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex + 2));
      markerValCell.value = excel_pkg.TextCellValue(markerName);
      markerValCell.cellStyle = textCenterStyle;

      // Individual Question Scores
      for (int i = 0; i < n; i++) {
        var scoreCell = sheetObject.cell(excel_pkg.CellIndex.indexByColumnRow(columnIndex: i + 2, rowIndex: rowIndex + 2));
        scoreCell.value = excel_pkg.DoubleCellValue(sub.scores[i]);
        scoreCell.cellStyle = textCenterStyle;
      }

      // Total
      var totalValCell = sheetObject.cell(excel_pkg.CellIndex.indexByColumnRow(columnIndex: n + 2, rowIndex: rowIndex + 2));
      totalValCell.value = excel_pkg.DoubleCellValue(sub.total);
      totalValCell.cellStyle = excel_pkg.CellStyle(
        horizontalAlign: excel_pkg.HorizontalAlign.Center,
        bold: true,
        fontColorHex: excel_pkg.ExcelColor.fromHexString('#0000D3'),
      );

      // Comment
      var commentValCell = sheetObject.cell(excel_pkg.CellIndex.indexByColumnRow(columnIndex: n + 3, rowIndex: rowIndex + 2));
      commentValCell.value = excel_pkg.TextCellValue(sub.comment);
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
