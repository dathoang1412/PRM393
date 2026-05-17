import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/submission.dart';
import '../models/exam_type.dart';
import '../services/file_service.dart';
import '../services/gemini_service.dart';
import '../services/grading_export_service.dart';

class MainGradingScreen extends StatefulWidget {
  const MainGradingScreen({super.key});

  @override
  State<MainGradingScreen> createState() => _MainGradingScreenState();
}

class _MainGradingScreenState extends State<MainGradingScreen> {
  final FileService _fileService = FileService();
  final GeminiService _geminiService = GeminiService();
  final GradingExportService _exportService = GradingExportService();

  List<Submission> submissions = [];
  int currentIndex = -1;
  bool isLoading = false;
  String apiKey = "";

  final TextEditingController _score1Controller = TextEditingController();
  final TextEditingController _score2Controller = TextEditingController();
  final TextEditingController _score3Controller = TextEditingController();
  final TextEditingController _commentController = TextEditingController();
  final TextEditingController _markerController = TextEditingController(text: "Teacher");

  ExamType? selectedGlobalExamType;

  @override
  void initState() {
    super.initState();
    selectedGlobalExamType = defaultExamTypes.first;
    _loadApiKey();
  }

  Future<void> _loadApiKey() async {
    final key = await _geminiService.getApiKey();
    setState(() => apiKey = key);
  }

  Future<void> _saveApiKey(String key) async {
    await _geminiService.saveApiKey(key);
    setState(() => apiKey = key);
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

  void _showSnackBar(String msg) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _pickZipAndExtract() async {
    setState(() => isLoading = true);
    try {
      final extractPath = await _fileService.pickAndExtractZip();
      if (extractPath != null) {
        final loadedSubmissions = _fileService.loadSubmissionsFromFolder(extractPath);
        setState(() {
          submissions = loadedSubmissions;
          if (submissions.isNotEmpty) {
            currentIndex = 0;
            _loadSubmission(0);
          }
        });
      }
    } catch (e) {
      _showSnackBar('Error loading zip: $e');
    } finally {
      setState(() => isLoading = false);
    }
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
      _showSnackBar("Please set Gemini API Key in Settings.");
      return;
    }
    if (currentIndex == -1) return;
    
    final sub = submissions[currentIndex];
    final exam = sub.examType ?? selectedGlobalExamType!;
    
    setState(() => isLoading = true);

    try {
      await _geminiService.gradeSubmission(sub, exam, apiKey);
      setState(() {});
    } catch (e, stack) {
      print("========== Grader Error Logging ==========");
      print("Error calling Gemini: $e");
      print("Stack trace: $stack");
      print("=========================================");
      _showSnackBar(e.toString());
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

  Future<void> _exportData() async {
    _saveCurrentScores();
    try {
      await _exportService.exportToExcel(submissions, _markerController.text);
      _showSnackBar('Exported successfully!');
    } catch (e) {
      _showSnackBar('Error exporting: $e');
    }
  }

  Future<void> _importDocxRubric() async {
    if (currentIndex == -1) return;
    final sub = submissions[currentIndex];
    final exam = sub.examType ?? selectedGlobalExamType;
    if (exam == null) {
      _showSnackBar("Please assign an exam type first.");
      return;
    }

    setState(() => isLoading = true);
    try {
      final rubricText = await _fileService.pickAndParseDocx();
      if (rubricText != null) {
        setState(() {
          exam.customRubric = rubricText;
          _showSnackBar("Successfully imported Word rubric for ${exam.code}!");
        });
      }
    } catch (e) {
      _showSnackBar("Failed to import Word rubric: $e");
    } finally {
      setState(() => isLoading = false);
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
            const Text("Gemini API Key:"),
            TextField(
              controller: keyCtrl,
              obscureText: true,
              decoration: const InputDecoration(hintText: "Enter AI Studio Key"),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
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
              onPressed: _exportData,
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
          Icon(Icons.folder_zip_rounded, size: 80, color: Theme.of(context).colorScheme.primary.withOpacity(0.5)),
          const SizedBox(height: 24),
          const Text(
            'No submissions loaded',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
          ),
          const SizedBox(height: 8),
          const Text('Select a .zip file containing submissions to extract and grade.', style: TextStyle(color: Color(0xFF64748B))),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _pickZipAndExtract,
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16)),
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
        border: Border(right: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.1))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Submissions (${submissions.length})',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B)),
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
                    color: sub.graded ? Colors.green : (isSelected ? Theme.of(context).colorScheme.primary : Colors.grey),
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
                style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B)),
              ),
              const Spacer(),
              Text(
                'Submission ${currentIndex + 1} of ${submissions.length}',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text("Exam Type:", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              DropdownButton<ExamType>(
                value: sub.examType,
                items: defaultExamTypes.map((e) => DropdownMenuItem(value: e, child: Text(e.code))).toList(),
                onChanged: (val) {
                  setState(() {
                    sub.examType = val;
                  });
                },
              ),
              const SizedBox(width: 24),
              ElevatedButton.icon(
                onPressed: _importDocxRubric,
                icon: const Icon(Icons.description_rounded, size: 18),
                label: const Text("Import Rubric Word (.docx)"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF1F5F9),
                  foregroundColor: const Color(0xFF475569),
                  elevation: 0,
                ),
              ),
              const SizedBox(width: 12),
              if (sub.examType?.customRubric != null && sub.examType!.customRubric!.isNotEmpty)
                Row(
                  children: [
                    const Icon(Icons.check_circle_rounded, color: Colors.green, size: 18),
                    const SizedBox(width: 4),
                    Text(
                      "Word Rubric Loaded",
                      style: GoogleFonts.outfit(
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                )
              else
                Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, color: Colors.grey, size: 18),
                    const SizedBox(width: 4),
                    Text(
                      "Using Default Rubric",
                      style: GoogleFonts.outfit(
                        color: Colors.grey,
                        fontWeight: FontWeight.normal,
                        fontSize: 13,
                      ),
                    ),
                  ],
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
                border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.1)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: SelectableText(
                sub.content,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 15, height: 1.5, color: Color(0xFF334155)),
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
    if (currentIndex == -1) return const SizedBox();
    final sub = submissions[currentIndex];
    final exam = sub.examType ?? selectedGlobalExamType!;

    return Container(
      width: 500,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(left: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.1))),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFFF1F5F9),
            child: Row(
              children: [
                Expanded(
                  child: Text('AI ASSISTANT', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                ),
                Expanded(
                  child: Text('HUMAN GRADER', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.secondary)),
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
                            style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 40)),
                          ),
                          const SizedBox(height: 16),
                          if (sub.hasAiGraded) ...[
                            _buildAiScore(exam.criteria[0], sub.aiScore1),
                            _buildAiScore(exam.criteria[1], sub.aiScore2),
                            _buildAiScore(exam.criteria[2], sub.aiScore3),
                            const Divider(),
                            const Text('AI Comment:', style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text(sub.aiComment, style: const TextStyle(fontSize: 13)),
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
                            )
                          ] else
                            const Padding(
                              padding: EdgeInsets.only(top: 32.0),
                              child: Center(child: Text('No AI suggestions yet.', style: TextStyle(color: Colors.grey))),
                            )
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
                              color: Theme.of(context).colorScheme.secondaryContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('TOTAL', style: TextStyle(fontWeight: FontWeight.bold)),
                                Builder(
                                  builder: (context) {
                                    double t = (double.tryParse(_score1Controller.text) ?? 0) +
                                               (double.tryParse(_score2Controller.text) ?? 0) +
                                               (double.tryParse(_score3Controller.text) ?? 0);
                                    return Text(
                                      t.toStringAsFixed(1),
                                      style: GoogleFonts.outfit(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context).colorScheme.onSecondaryContainer,
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
                              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                              child: Text(currentIndex < submissions.length - 1 ? 'Save & Next' : 'Finish Grading'),
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
          Text(score.toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildScoreField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF475569))),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
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
        const Text('Comment', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF475569))),
        const SizedBox(height: 6),
        TextField(
          controller: _commentController,
          maxLines: 4,
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            hintText: 'Enter feedback...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
          ),
        ),
      ],
    );
  }
}
