import 'dart:io';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
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
}
