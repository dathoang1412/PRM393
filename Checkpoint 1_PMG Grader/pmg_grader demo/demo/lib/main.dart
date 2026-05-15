import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart' as excel_pkg;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:google_fonts/google_fonts.dart';

void main() {
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
          brightness: Brightness.dark,
        ),
        textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
      ),
      home: const MainGradingScreen(),
    );
  }
}

class Submission {
  final String fileName;
  final String filePath;
  final String content;
  double score1 = 0;
  double score2 = 0;
  double score3 = 0;
  String comment = "";
  bool graded = false;

  Submission({
    required this.fileName,
    required this.filePath,
    required this.content,
  });

  double get total => score1 + score2 + score3;
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
  String markerName = "Teacher";

  final TextEditingController _score1Controller = TextEditingController();
  final TextEditingController _score2Controller = TextEditingController();
  final TextEditingController _score3Controller = TextEditingController();
  final TextEditingController _commentController = TextEditingController();
  final TextEditingController _markerController = TextEditingController(text: "Teacher");

  @override
  void dispose() {
    _score1Controller.dispose();
    _score2Controller.dispose();
    _score3Controller.dispose();
    _commentController.dispose();
    _markerController.dispose();
    super.dispose();
  }

  Future<void> _pickFolder() async {
    print('Picking folder...');
    String? result;
    try {
      result = await FilePicker.getDirectoryPath();
      print('Picker result: $result');
    } catch (e) {
      print('Error picking folder: $e');
    }

    if (result != null) {
      setState(() {
        isLoading = true;
        folderPath = result;
        submissions = [];
        currentIndex = -1;
      });

      try {
        final dir = Directory(result);
        final files = dir.listSync().where((file) => p.extension(file.path) == '.txt').toList();

        List<Submission> loadedSubmissions = [];
        for (var file in files) {
          if (file is File) {
            final content = await file.readAsString();
            loadedSubmissions.add(Submission(
              fileName: p.basename(file.path),
              filePath: file.path,
              content: content,
            ));
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
        print('Error processing directory: $e');
        setState(() => isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error loading files: $e')),
          );
        }
      }
    }
  }

  void _loadSubmission(int index) {
    if (index < 0 || index >= submissions.length) return;
    
    final sub = submissions[index];
    _score1Controller.text = sub.score1.toString();
    _score2Controller.text = sub.score2.toString();
    _score3Controller.text = sub.score3.toString();
    _commentController.text = sub.comment;
  }

  void _saveCurrentScores() {
    if (currentIndex == -1) return;
    
    setState(() {
      final sub = submissions[currentIndex];
      sub.score1 = double.tryParse(_score1Controller.text) ?? 0;
      sub.score2 = double.tryParse(_score2Controller.text) ?? 0;
      sub.score3 = double.tryParse(_score3Controller.text) ?? 0;
      sub.comment = _commentController.text;
      sub.graded = true;
    });
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

  Future<void> _exportToExcel() async {
    _saveCurrentScores();
    if (submissions.isEmpty) return;

    var excel = excel_pkg.Excel.createExcel();
    excel_pkg.Sheet sheetObject = excel['Sheet1'];

    // Header
    sheetObject.appendRow([
      excel_pkg.TextCellValue('Alias'),
      excel_pkg.TextCellValue('Marker'),
      excel_pkg.TextCellValue('Question 1'),
      excel_pkg.TextCellValue('Question 2'),
      excel_pkg.TextCellValue('Question 3'),
      excel_pkg.TextCellValue('Total'),
      excel_pkg.TextCellValue('Comment'),
    ]);

    for (int i = 0; i < submissions.length; i++) {
      final sub = submissions[i];
      sheetObject.appendRow([
        excel_pkg.TextCellValue(sub.fileName),
        excel_pkg.TextCellValue(_markerController.text),
        excel_pkg.DoubleCellValue(sub.score1),
        excel_pkg.DoubleCellValue(sub.score2),
        excel_pkg.DoubleCellValue(sub.score3),
        excel_pkg.DoubleCellValue(sub.total),
        excel_pkg.TextCellValue(sub.comment),
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
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Excel exported successfully!')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.surface,
              Theme.of(context).colorScheme.primaryContainer.withOpacity(0.1),
            ],
          ),
        ),
        child: Column(
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
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withOpacity(0.5),
        border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.1))),
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_stories_rounded, size: 32, color: Color(0xFF6366F1)),
          const SizedBox(width: 12),
          Text(
            'PMG GRADER',
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const Spacer(),
          if (folderPath != null)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: SizedBox(
                width: 150,
                child: TextField(
                  controller: _markerController,
                  decoration: const InputDecoration(
                    labelText: 'Marker Name',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ),
          ElevatedButton.icon(
            onPressed: _pickFolder,
            icon: const Icon(Icons.folder_open_rounded),
            label: const Text('Open Folder'),
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
          Icon(Icons.folder_special_rounded, size: 80, color: Theme.of(context).colorScheme.primary.withOpacity(0.5)),
          const SizedBox(height: 24),
          const Text(
            'No folder selected',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text('Select a folder containing .txt files to start grading'),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _pickFolder,
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16)),
            child: const Text('Get Started'),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        border: Border(right: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.1))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Submissions (${submissions.length})',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
                  selectedTileColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  leading: Icon(
                    sub.graded ? Icons.check_circle : Icons.description_outlined,
                    color: sub.graded ? Colors.green : (isSelected ? Theme.of(context).colorScheme.primary : null),
                  ),
                  title: Text(
                    sub.fileName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 13,
                    ),
                  ),
                  subtitle: sub.graded ? Text('Score: ${sub.total.toStringAsFixed(1)}') : null,
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
                style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Text(
                'Submission ${currentIndex + 1} of ${submissions.length}',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.05)),
              ),
              child: SelectableText(
                sub.content,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 15, height: 1.5),
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
                onPressed: currentIndex < submissions.length - 1 ? _nextSubmission : null,
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
    return Container(
      width: 320,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withOpacity(0.5),
        border: Border(left: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.1))),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'GRADING',
              style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2, fontSize: 12),
            ),
            const SizedBox(height: 24),
            _buildScoreField('Question 1', _score1Controller),
            const SizedBox(height: 16),
            _buildScoreField('Question 2', _score2Controller),
            const SizedBox(height: 16),
            _buildScoreField('Question 3', _score3Controller),
            const Divider(height: 48),
            _buildCommentField(),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('TOTAL SCORE', style: TextStyle(fontWeight: FontWeight.bold)),
                  Builder(
                    builder: (context) {
                      double t = (double.tryParse(_score1Controller.text) ?? 0) +
                                 (double.tryParse(_score2Controller.text) ?? 0) +
                                 (double.tryParse(_score3Controller.text) ?? 0);
                      return Text(
                        t.toStringAsFixed(1),
                        style: GoogleFonts.outfit(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  _saveCurrentScores();
                  if (currentIndex < submissions.length - 1) {
                    _nextSubmission();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('All scores saved!')),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(currentIndex < submissions.length - 1 ? 'Save & Next' : 'Finish Grading'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: Colors.white70)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.black12,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
        const Text('Comment', style: const TextStyle(fontSize: 13, color: Colors.white70)),
        const SizedBox(height: 8),
        TextField(
          controller: _commentController,
          maxLines: 5,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.black12,
            hintText: 'Enter feedback...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
      ],
    );
  }
}
