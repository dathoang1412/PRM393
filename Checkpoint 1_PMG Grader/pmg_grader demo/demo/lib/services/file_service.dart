import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:excel/excel.dart' as excel_pkg;
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/submission.dart';

class FileService {
  Future<String?> pickAndExtractZip(String sessionId) async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['zip'],
    );

    if (result == null || result.files.single.path == null) return null;
    return extractZipFromPath(result.files.single.path!, sessionId, forceRefresh: true);
  }

  Future<String?> extractZipFromPath(
    String zipFilePath,
    String sessionId, {
    bool forceRefresh = false,
  }) async {
    try {
      final appData = await getApplicationSupportDirectory();
      final extractPath = p.join(appData.path, 'PMG_Grader_Data', 'Extracted_$sessionId');
      final normalizedExtractPath = p.normalize(p.absolute(extractPath));
      final dir = Directory(extractPath);

      if (forceRefresh && await dir.exists()) {
        await dir.delete(recursive: true);
      } else if (await dir.exists()) {
        final files = dir
            .listSync(recursive: true)
            .where((file) => p.extension(file.path).toLowerCase() == '.txt')
            .toList();
        if (files.isNotEmpty) return extractPath;
      }

      final bytes = await File(zipFilePath).readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);

      for (final file in archive) {
        final filename = file.name;
        if (!file.isFile || p.extension(filename).toLowerCase() != '.txt') continue;

        final outputPath = p.normalize(p.absolute(p.join(extractPath, filename)));
        final isInsideExtractPath = p.isWithin(normalizedExtractPath, outputPath) || outputPath == normalizedExtractPath;
        if (!isInsideExtractPath) {
          throw Exception('Unsafe zip entry path: $filename');
        }

        final outFile = File(outputPath);
        await outFile.create(recursive: true);
        await outFile.writeAsBytes(file.content as List<int>);
      }
      return extractPath;
    } catch (_) {
      return null;
    }
  }

  List<Submission> loadSubmissionsFromFolder(String path) {
    final dir = Directory(path);
    final files = dir
        .listSync(recursive: true)
        .where((file) => p.extension(file.path).toLowerCase() == '.txt')
        .toList();

    final loadedSubmissions = <Submission>[];
    for (final file in files) {
      if (file is File) {
        final content = file.readAsStringSync();
        loadedSubmissions.add(Submission(
          fileName: p.basename(file.path),
          filePath: file.path,
          content: content,
        ));
      }
    }
    loadedSubmissions.sort((a, b) => a.fileName.toLowerCase().compareTo(b.fileName.toLowerCase()));
    return loadedSubmissions;
  }

  Future<List<Submission>> pickAndLoadSubmissionFolder() async {
    final folderPath = await FilePicker.getDirectoryPath(
      dialogTitle: 'Select submissions folder',
    );

    if (folderPath == null) return [];
    return loadSubmissionsFromFolder(folderPath);
  }

  Future<PickedTextFile?> pickAndReadTextDocument({
    required List<String> extensions,
    required String dialogTitle,
  }) async {
    final result = await FilePicker.pickFiles(
      dialogTitle: dialogTitle,
      type: FileType.custom,
      allowedExtensions: extensions,
    );

    if (result == null || result.files.single.path == null) return null;

    final path = result.files.single.path!;
    final extension = p.extension(path).toLowerCase();
    final name = p.basename(path);

    if (extension == '.docx') {
      final content = await parseDocxFile(path);
      return PickedTextFile(fileName: name, content: content);
    }

    final content = await File(path).readAsString();
    return PickedTextFile(fileName: name, content: content);
  }

  Future<String?> pickAndParseDocx() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['docx'],
    );

    if (result == null || result.files.single.path == null) return null;
    return extractDocxTextFromPath(result.files.single.path!);
  }

  Future<String?> extractDocxTextFromPath(String path) async {
    try {
      return await parseDocxFile(path);
    } catch (e) {
      throw Exception('Failed to parse Word document: $e');
    }
  }

  Future<String?> extractMarkerName(String path) async {
    try {
      final bytes = File(path).readAsBytesSync();
      final workbook = excel_pkg.Excel.decodeBytes(bytes);
      for (final table in workbook.tables.keys) {
        final sheet = workbook.tables[table];
        if (sheet == null || sheet.maxRows == 0) continue;

        var markerColIndex = -1;
        final searchLimit = sheet.maxRows > 5 ? 5 : sheet.maxRows;
        for (var r = 0; r < searchLimit; r++) {
          final row = sheet.rows[r];
          for (var c = 0; c < row.length; c++) {
            final val = row[c]?.value?.toString().trim().toLowerCase();
            if (val == 'marker' || val == 'nguoi cham') {
              markerColIndex = c;
              break;
            }
          }
          if (markerColIndex != -1) {
            for (var r2 = r + 1; r2 < sheet.maxRows; r2++) {
              if (markerColIndex < sheet.rows[r2].length) {
                final cellVal = sheet.rows[r2][markerColIndex]?.value?.toString().trim();
                if (cellVal != null && cellVal.isNotEmpty) return cellVal;
              }
            }
          }
        }

        for (var r = 2; r < sheet.maxRows; r++) {
          if (sheet.rows[r].length > 1) {
            final cellVal = sheet.rows[r][1]?.value?.toString().trim();
            if (cellVal != null && cellVal.isNotEmpty) return cellVal;
          }
        }
      }
    } catch (_) {
      // Best-effort extraction for the home screen.
    }
    return null;
  }

  Future<String> parseDocxFile(String path) async {
    final bytes = await File(path).readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);

    final docFile = archive.firstWhere(
      (file) => file.name == 'word/document.xml',
      orElse: () => throw Exception('Invalid DOCX format: word/document.xml not found'),
    );

    final xmlContent = utf8.decode(docFile.content as List<int>);
    final buffer = StringBuffer();
    final regExp = RegExp(r'<[^>]+>|[^<]+');
    final matches = regExp.allMatches(xmlContent);
    var inText = false;

    for (final match in matches) {
      final token = match.group(0)!;
      if (token.startsWith('<')) {
        final tagName = token.toLowerCase();
        if (tagName == '<w:t>' || tagName.startsWith('<w:t ')) {
          inText = true;
        } else if (tagName == '</w:t>') {
          inText = false;
        } else if (tagName == '<w:p>' || tagName.startsWith('<w:p ')) {
          _writeLineBreak(buffer);
        } else if (tagName == '<w:tr>' || tagName.startsWith('<w:tr ')) {
          _writeLineBreak(buffer);
        } else if (tagName == '<w:tc>' || tagName.startsWith('<w:tc ')) {
          buffer.write('\t');
        } else if (tagName.contains('w:br')) {
          buffer.write('\n');
        } else if (tagName.contains('w:tab')) {
          buffer.write('\t');
        }
      } else if (inText) {
        buffer.write(token);
      }
    }

    final text = buffer
        .toString()
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&apos;', "'");

    return text.split('\n').map((line) => line.trim()).where((line) => line.isNotEmpty).join('\n');
  }

  void _writeLineBreak(StringBuffer buffer) {
    final current = buffer.toString();
    if (current.isNotEmpty && !current.endsWith('\n')) {
      buffer.write('\n');
    }
  }
}

class PickedTextFile {
  final String fileName;
  final String content;

  PickedTextFile({
    required this.fileName,
    required this.content,
  });
}
