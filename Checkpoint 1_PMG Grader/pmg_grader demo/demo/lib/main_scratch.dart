import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart' as excel_pkg;
import 'package:path/path.dart' as p;
import 'package:google_fonts/google_fonts.dart';
import 'package:archive/archive.dart';
import 'package:archive/archive_io.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const GraderApp());
}

class GraderApp extends StatelessWidget {
  const GraderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PMG Grader',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366F1),
          brightness: Brightness.light,
        ),
        textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme),
      ),
      home: const MainGradingScreen(),
    );
  }
}

class ExamType {
  String code;
  List<String> criteria;
  ExamType(this.code, this.criteria);
}

class Submission {
  final String fileName;
  final String filePath;
  final String content;

  double score1 = 0;
  double score2 = 0;
  double score3 = 0;
  String comment = "";

  double aiScore1 = 0;
  double aiScore2 = 0;
  double aiScore3 = 0;
  String aiComment = "";
  bool hasAiGraded = false;

  bool graded = false;
  ExamType? examType;

  Submission({
    required this.fileName,
    required this.filePath,
    required this.content,
  });

  double get total => score1 + score2 + score3;
  double get aiTotal => aiScore1 + aiScore2 + aiScore3;
}

class MainGradingScreen extends StatefulWidget {
  const MainGradingScreen({super.key});

  @override
  State<MainGradingScreen> createState() => _MainGradingScreenState();
}

class _MainGradingScreenState extends State<MainGradingScreen> {
  List<Submission> submissions = [];
  int currentIndex = -1;
  String? folderPath;
  bool isLoading = false;

  String apiKey = "";

  final TextEditingController _score1Controller = TextEditingController();
  final TextEditingController _score2Controller = TextEditingController();
  final TextEditingController _score3Controller = TextEditingController();
  final TextEditingController _commentController = TextEditingController();
  final TextEditingController _markerController = TextEditingController(
    text: "Teacher",
  );

  List<ExamType> examTypes = [
    ExamType('Type A', ['Criterion A1', 'Criterion A2', 'Criterion A3']),
    ExamType('Type B', ['Criterion B1', 'Criterion B2', 'Criterion B3']),
    ExamType('Type C', ['Criterion C1', 'Criterion C2', 'Criterion C3']),
  ];
  ExamType? selectedGlobalExamType;

  @override
  void initState() {
    super.initState();
    selectedGlobalExamType = examTypes.first;
    _loadApiKey();
  }

  Future<void> _loadApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      apiKey = prefs.getString('openai_api_key') ?? "";
    });
  }

  Future<void> _saveApiKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('openai_api_key', key);
    setState(() {
      apiKey = key;
    });
  }

  @override
  void dispose() {
    _score1Controller.dispose();
    _score2Controller.dispose();
    _score3Controller.dispose();
    _commentController.dispose();
    _markerController.dispose();
    super.dispose();
  }

  Future<void> _pickZipAndExtract() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['zip'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() => isLoading = true);
      try {
        final bytes = File(result.files.single.path!).readAsBytesSync();
        final archive = ZipDecoder().decodeBytes(bytes);

        final appData = await getApplicationSupportDirectory();
        final extractPath = p.join(
          appData.path,
          'PMG_Grader_Data',
          'Extracted_${DateTime.now().millisecondsSinceEpoch}',
        );

        for (final file in archive) {
          final filename = file.name;
          if (file.isFile && filename.endsWith('.txt')) {
            final data = file.content as List<int>;
            final outFile = File(p.join(extractPath, filename));
            outFile.createSync(recursive: true);
            outFile.writeAsBytesSync(data);
          }
        }

        folderPath = extractPath;
        _loadSubmissionsFromFolder(extractPath);
      } catch (e) {
        setState(() => isLoading = false);
        _showError('Error extracting zip: $e');
      }
    }
  }

  void _loadSubmissionsFromFolder(String path) {
    try {
      final dir = Directory(path);
      final files = dir
          .listSync(recursive: true)
          .where((file) => p.extension(file.path) == '.txt')
          .toList();

      List<Submission> loadedSubmissions = [];
      for (var file in files) {
        if (file is File) {
          final content = file.readAsStringSync();
          loadedSubmissions.add(
            Submission(
              fileName: p.basename(file.path),
              filePath: file.path,
              content: content,
            ),
          );
        }
      }

      setState(() {
        submissions = loadedSubmissions;
        if (submissions.isNotEmpty) {
          currentIndex = 0;
          _loadSubmission(0);
        }
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      _showError('Error loading files: $e');
    }
  }

  void _showError(String msg) {
    if (mounted)
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _loadSubmission(int index) {
    if (index < 0 || index >= submissions.length) return;

    final sub = submissions[index];
    _score1Controller.text = sub.score1.toString();
    _score2Controller.text = sub.score2.toString();
    _score3Controller.text = sub.score3.toString();
    _commentController.text = sub.comment;
    if (sub.examType == null && selectedGlobalExamType != null) {
      sub.examType = selectedGlobalExamType;
    }
  }

  void _saveCurrentScores() {
    if (currentIndex == -1) return;

    final sub = submissions[currentIndex];
    sub.score1 = double.tryParse(_score1Controller.text) ?? 0;
    sub.score2 = double.tryParse(_score2Controller.text) ?? 0;
    sub.score3 = double.tryParse(_score3Controller.text) ?? 0;
    sub.comment = _commentController.text;
    sub.graded = true;
  }

  void _nextSubmission() {
    _saveCurrentScores();
    if (currentIndex < submissions.length - 1) {
      setState(() {
        currentIndex++;
        _loadSubmission(currentIndex);
      });
    }
  }

  void _prevSubmission() {
    _saveCurrentScores();
    if (currentIndex > 0) {
      setState(() {
        currentIndex--;
        _loadSubmission(currentIndex);
      });
    }
  }

  Future<void> _askAi() async {
    if (apiKey.isEmpty) {
      _showError("Please set OpenAI API Key in Settings.");
      return;
    }
    if (currentIndex == -1) return;

    final sub = submissions[currentIndex];
    final exam = sub.examType ?? selectedGlobalExamType!;

    setState(() => isLoading = true);

    try {
      final prompt =
          '''
You are an expert grader. Grade this student's submission based on these 3 criteria:
1. ${exam.criteria[0]}
2. ${exam.criteria[1]}
3. ${exam.criteria[2]}

Submission content:
${sub.content}

Return ONLY valid JSON (no markdown block, just the json object):
{
  "score1": <number>,
  "score2": <number>,
  "score3": <number>,
  "comment": "<string comment>"
}
''';

      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-3.5-turbo',
          'messages': [
            {
              'role': 'system',
              'content':
                  'You are a helpful grading assistant. You reply only with valid JSON.',
            },
            {'role': 'user', 'content': prompt},
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final resultText = data['choices'][0]['message']['content'];
        final resultJson = jsonDecode(resultText);

        setState(() {
          sub.aiScore1 = (resultJson['score1'] as num).toDouble();
          sub.aiScore2 = (resultJson['score2'] as num).toDouble();
          sub.aiScore3 = (resultJson['score3'] as num).toDouble();
          sub.aiComment = resultJson['comment']?.toString() ?? "";
          sub.hasAiGraded = true;
        });
      } else {
        _showError("OpenAI Error: ${response.statusCode}");
      }
    } catch (e) {
      _showError("Error calling AI: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _copyAiToTeacher() {
    if (currentIndex == -1) return;
    final sub = submissions[currentIndex];
    if (!sub.hasAiGraded) return;

    setState(() {
      _score1Controller.text = sub.aiScore1.toString();
      _score2Controller.text = sub.aiScore2.toString();
      _score3Controller.text = sub.aiScore3.toString();
      _commentController.text = sub.aiComment;
      _saveCurrentScores();
    });
  }

  Future<void> _exportToExcel() async {
    _saveCurrentScores();
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
      excel_pkg.TextCellValue('AI Total'),
      excel_pkg.TextCellValue('AI Comment'),
    ]);

    for (int i = 0; i < submissions.length; i++) {
      final sub = submissions[i];
      sheetObject.appendRow([
        excel_pkg.TextCellValue(sub.fileName),
        excel_pkg.TextCellValue(_markerController.text),
        excel_pkg.TextCellValue(sub.examType?.code ?? ''),
        excel_pkg.DoubleCellValue(sub.score1),
        excel_pkg.DoubleCellValue(sub.score2),
        excel_pkg.DoubleCellValue(sub.score3),
        excel_pkg.DoubleCellValue(sub.total),
        excel_pkg.TextCellValue(sub.comment),
        excel_pkg.DoubleCellValue(sub.aiTotal),
        excel_pkg.TextCellValue(sub.aiComment),
      ]);
    }

    final bytes = excel.encode();
    if (bytes != null) {
      String? outputFile = await FilePicker.platform.saveFile(
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
        _showError('Excel exported successfully!');
      }
    }
  }

  void _showSettingsDialog() {
    final TextEditingController keyCtrl = TextEditingController(text: apiKey);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Settings"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("OpenAI API Key:"),
            TextField(
              controller: keyCtrl,
              obscureText: true,
              decoration: const InputDecoration(hintText: "sk-..."),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              _saveApiKey(keyCtrl.text);
              Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          Column(
            children: [
              _buildAppBar(),
              Expanded(
                child: submissions.isEmpty
                    ? _buildEmptyState()
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildSidebar(),
                          Expanded(child: _buildMainContent()),
                          _buildGradingPanel(),
                        ],
                      ),
              ),
            ],
          ),
          if (isLoading)
            Container(
              color: Colors.black26,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor.withOpacity(0.1),
          ),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.auto_stories_rounded,
            size: 32,
            color: Color(0xFF6366F1),
          ),
          const SizedBox(width: 12),
          Text(
            'PMG GRADER',
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              color: const Color(0xFF1E293B),
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showSettingsDialog,
            tooltip: "Settings",
          ),
          const SizedBox(width: 16),
          ElevatedButton.icon(
            onPressed: _pickZipAndExtract,
            icon: const Icon(Icons.folder_zip_rounded),
            label: const Text('Load Zip'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
            ),
          ),
          const SizedBox(width: 12),
          if (submissions.isNotEmpty)
            OutlinedButton.icon(
              onPressed: _exportToExcel,
              icon: const Icon(Icons.file_download_rounded),
              label: const Text('Export Excel'),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.folder_zip_rounded,
            size: 80,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
          ),
          const SizedBox(height: 24),
          const Text(
            'No submissions loaded',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Select a .zip file containing submissions',
            style: TextStyle(color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _pickZipAndExtract,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
            child: const Text('Load Submissions Zip'),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 250,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          right: BorderSide(
            color: Theme.of(context).dividerColor.withOpacity(0.1),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Submissions (${submissions.length})',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Color(0xFF1E293B),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: submissions.length,
              itemBuilder: (context, index) {
                final sub = submissions[index];
                final isSelected = index == currentIndex;
                return ListTile(
                  selected: isSelected,
                  selectedTileColor: Theme.of(
                    context,
                  ).colorScheme.primary.withOpacity(0.1),
                  leading: Icon(
                    sub.graded
                        ? Icons.check_circle
                        : Icons.description_outlined,
                    color: sub.graded
                        ? Colors.green
                        : (isSelected
                              ? Theme.of(context).colorScheme.primary
                              : Colors.grey),
                  ),
                  title: Text(
                    sub.fileName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      fontSize: 13,
                    ),
                  ),
                  onTap: () {
                    _saveCurrentScores();
                    setState(() {
                      currentIndex = index;
                      _loadSubmission(index);
                    });
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    if (currentIndex == -1) return const SizedBox();
    final sub = submissions[currentIndex];

    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                sub.fileName,
                style: GoogleFonts.outfit(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E293B),
                ),
              ),
              const Spacer(),
              Text(
                'Submission ${currentIndex + 1} of ${submissions.length}',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text(
                "Exam Type:",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 8),
              DropdownButton<ExamType>(
                value: sub.examType,
                items: examTypes
                    .map((e) => DropdownMenuItem(value: e, child: Text(e.code)))
                    .toList(),
                onChanged: (val) {
                  setState(() {
                    sub.examType = val;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Theme.of(context).dividerColor.withOpacity(0.1),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: SelectableText(
                sub.content,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 15,
                  height: 1.5,
                  color: Color(0xFF334155),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton.filledTonal(
                onPressed: currentIndex > 0 ? _prevSubmission : null,
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
                padding: const EdgeInsets.all(16),
              ),
              const SizedBox(width: 32),
              IconButton.filled(
                onPressed: currentIndex < submissions.length - 1
                    ? _nextSubmission
                    : null,
                icon: const Icon(Icons.arrow_forward_ios_rounded),
                padding: const EdgeInsets.all(16),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGradingPanel() {
    if (currentIndex == -1) return const SizedBox();
    final sub = submissions[currentIndex];
    final exam = sub.examType ?? selectedGlobalExamType!;

    return Container(
      width: 500,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          left: BorderSide(
            color: Theme.of(context).dividerColor.withOpacity(0.1),
          ),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFFF1F5F9),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'AI ASSISTANT',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'HUMAN GRADER',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Row(
              children: [
                // AI Panel
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      border: Border(right: BorderSide(color: Colors.black12)),
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ElevatedButton.icon(
                            onPressed: _askAi,
                            icon: const Icon(Icons.smart_toy),
                            label: const Text('Grade with AI'),
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 40),
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (sub.hasAiGraded) ...[
                            _buildAiScore(exam.criteria[0], sub.aiScore1),
                            _buildAiScore(exam.criteria[1], sub.aiScore2),
                            _buildAiScore(exam.criteria[2], sub.aiScore3),
                            const Divider(),
                            const Text(
                              'AI Comment:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              sub.aiComment,
                              style: const TextStyle(fontSize: 13),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: _copyAiToTeacher,
                              icon: const Icon(Icons.copy),
                              label: const Text('Trust & Copy'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green.shade50,
                                foregroundColor: Colors.green.shade700,
                                minimumSize: const Size(double.infinity, 40),
                              ),
                            ),
                          ] else
                            const Padding(
                              padding: EdgeInsets.only(top: 32.0),
                              child: Center(
                                child: Text(
                                  'No AI suggestions yet.',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Human Panel
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildScoreField(exam.criteria[0], _score1Controller),
                          const SizedBox(height: 12),
                          _buildScoreField(exam.criteria[1], _score2Controller),
                          const SizedBox(height: 12),
                          _buildScoreField(exam.criteria[2], _score3Controller),
                          const Divider(height: 32),
                          _buildCommentField(),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.secondaryContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'TOTAL',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Builder(
                                  builder: (context) {
                                    double t =
                                        (double.tryParse(
                                              _score1Controller.text,
                                            ) ??
                                            0) +
                                        (double.tryParse(
                                              _score2Controller.text,
                                            ) ??
                                            0) +
                                        (double.tryParse(
                                              _score3Controller.text,
                                            ) ??
                                            0);
                                    return Text(
                                      t.toStringAsFixed(1),
                                      style: GoogleFonts.outfit(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSecondaryContainer,
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                _saveCurrentScores();
                                if (currentIndex < submissions.length - 1) {
                                  _nextSubmission();
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                              ),
                              child: Text(
                                currentIndex < submissions.length - 1
                                    ? 'Save & Next'
                                    : 'Finish Grading',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAiScore(String label, double score) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 4),
          Text(
            score.toString(),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Color(0xFF475569),
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
          ),
          onChanged: (_) => setState(() {}),
        ),
      ],
    );
  }

  Widget _buildCommentField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Comment',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Color(0xFF475569),
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _commentController,
          maxLines: 4,
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            hintText: 'Enter feedback...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
          ),
        ),
      ],
    );
  }
}
