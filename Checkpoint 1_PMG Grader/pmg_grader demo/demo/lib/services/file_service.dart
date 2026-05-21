import 'dart:io';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:excel/excel.dart' as excel_pkg;
import '../models/submission.dart';

class FileService {
  Future<String?> pickAndExtractZip() async {
    FilePickerResult? result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['zip'],
    );

    if (result != null && result.files.single.path != null) {
      final bytes = File(result.files.single.path!).readAsBytesSync();
      final archive = ZipDecoder().decodeBytes(bytes);
      
      final appData = await getApplicationSupportDirectory();
      final extractPath = p.join(appData.path, 'PMG_Grader_Data', 'Extracted_${DateTime.now().millisecondsSinceEpoch}');
      
      for (final file in archive) {
        final filename = file.name;
        if (file.isFile && filename.endsWith('.txt')) {
          final data = file.content as List<int>;
          final outFile = File(p.join(extractPath, filename));
          outFile.createSync(recursive: true);
          outFile.writeAsBytesSync(data);
        }
      }
      return extractPath;
    }
    return null;
  }

  Future<String?> extractZipFromPath(String zipFilePath) async {
    try {
      final bytes = File(zipFilePath).readAsBytesSync();
      final archive = ZipDecoder().decodeBytes(bytes);

      final appData = await getApplicationSupportDirectory();
      final extractPath = p.join(appData.path, 'PMG_Grader_Data', 'Extracted_${DateTime.now().millisecondsSinceEpoch}');

      for (final file in archive) {
        final filename = file.name;
        if (file.isFile && filename.endsWith('.txt')) {
          final data = file.content as List<int>;
          final outFile = File(p.join(extractPath, filename));
          outFile.createSync(recursive: true);
          outFile.writeAsBytesSync(data);
        }
      }
      return extractPath;
    } catch (e) {
      return null;
    }
  }

  List<Submission> loadSubmissionsFromFolder(String path) {
    final dir = Directory(path);
    final files = dir.listSync(recursive: true).where((file) => p.extension(file.path) == '.txt').toList();

    List<Submission> loadedSubmissions = [];
    for (var file in files) {
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

  Future<String?> extractDocxTextFromPath(String path) async {
    try {
      final bytes = File(path).readAsBytesSync();
      final archive = ZipDecoder().decodeBytes(bytes);
      
      final docFile = archive.firstWhere(
        (file) => file.name == 'word/document.xml',
        orElse: () => throw Exception('Invalid DOCX format: word/document.xml not found'),
      );
      
      final xmlContent = utf8.decode(docFile.content as List<int>);
      
      final buffer = StringBuffer();
      final regExp = RegExp(r'<[^>]+>|[^<]+');
      final matches = regExp.allMatches(xmlContent);
      
      bool inText = false;
      
      for (final match in matches) {
        final token = match.group(0)!;
        if (token.startsWith('<')) {
          final tagName = token.toLowerCase();
          if (tagName == '<w:t>' || tagName.startsWith('<w:t ')) {
            inText = true;
          } else if (tagName == '</w:t>') {
            inText = false;
          } else if (tagName == '<w:p>' || tagName.startsWith('<w:p ')) {
            // New paragraph, ensure a newline
            final current = buffer.toString();
            if (current.isNotEmpty && !current.endsWith('\n')) {
              buffer.write('\n');
            }
          } else if (tagName == '<w:tr>' || tagName.startsWith('<w:tr ')) {
            // Table row separator
            final current = buffer.toString();
            if (current.isNotEmpty && !current.endsWith('\n')) {
              buffer.write('\n');
            }
          } else if (tagName == '<w:tc>' || tagName.startsWith('<w:tc ')) {
            // Table column cell separator
            buffer.write('\t');
          } else if (tagName.contains('w:br')) {
            buffer.write('\n');
          } else if (tagName.contains('w:tab')) {
            buffer.write('\t');
          }
        } else {
          if (inText) {
            buffer.write(token);
          }
        }
      }
      
      String text = buffer.toString()
          .replaceAll('&lt;', '<')
          .replaceAll('&gt;', '>')
          .replaceAll('&amp;', '&')
          .replaceAll('&quot;', '"')
          .replaceAll('&apos;', "'");
          
      // Clean up whitespace and collapse multiple empty lines
      final lines = text.split('\n');
      final cleanLines = <String>[];
      for (var line in lines) {
        final trimmed = line.trim();
        if (trimmed.isNotEmpty) {
          cleanLines.add(trimmed);
        }
      }
      
      return cleanLines.join('\n');
    } catch (e) {
      throw Exception("Failed to parse Word document: $e");
    }
  }

  Future<String?> pickAndParseDocx() async {
    FilePickerResult? result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['docx'],
    );

    if (result != null && result.files.single.path != null) {
      return extractDocxTextFromPath(result.files.single.path!);
    }
    return null;
  }

  Future<String?> extractMarkerName(String path) async {
    try {
      final bytes = File(path).readAsBytesSync();
      var excel = excel_pkg.Excel.decodeBytes(bytes);
      for (var table in excel.tables.keys) {
        var sheet = excel.tables[table];
        if (sheet == null || sheet.maxRows == 0) continue;
        
        // Find "Marker" column index
        int markerColIndex = -1;
        final searchLimit = sheet.maxRows > 5 ? 5 : sheet.maxRows;
        for (int r = 0; r < searchLimit; r++) {
          final row = sheet.rows[r];
          for (int c = 0; c < row.length; c++) {
            final val = row[c]?.value?.toString().trim().toLowerCase();
            if (val == 'marker' || val == 'người chấm' || val == 'nguoi cham') {
              markerColIndex = c;
              break;
            }
          }
          if (markerColIndex != -1) {
            // Find first non-empty value below this header
            for (int r2 = r + 1; r2 < sheet.maxRows; r2++) {
              if (markerColIndex < sheet.rows[r2].length) {
                final cellVal = sheet.rows[r2][markerColIndex]?.value?.toString().trim();
                if (cellVal != null && cellVal.isNotEmpty) {
                  return cellVal;
                }
              }
            }
          }
        }
        
        // Fallback: look at column 1 (index 1), row 2 (index 2) onwards
        for (int r = 2; r < sheet.maxRows; r++) {
          if (sheet.rows[r].length > 1) {
            final cellVal = sheet.rows[r][1]?.value?.toString().trim();
            if (cellVal != null && cellVal.isNotEmpty) {
              return cellVal;
            }
          }
        }
      }
    } catch (e) {
      // Ignore or log error
    }
    return null;
  }
}
