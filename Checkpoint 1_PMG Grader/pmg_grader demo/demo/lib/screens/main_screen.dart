import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/submission.dart';
import '../models/exam_type.dart';
import '../services/file_service.dart';
import '../services/gemini_service.dart';
import '../services/grading_export_service.dart';
import '../services/session_service.dart';
import '../widgets/app_bar_widget.dart';
import '../widgets/sidebar_widget.dart';
import '../widgets/content_viewer_widget.dart';
import '../widgets/grading_panel_widget.dart';

class MainGradingScreen extends StatefulWidget {
  final GradingSession session;
  const MainGradingScreen({super.key, required this.session});

  @override
  State<MainGradingScreen> createState() => _MainGradingScreenState();
}

class _MainGradingScreenState extends State<MainGradingScreen> {
  final FileService _fileService = FileService();
  final GeminiService _geminiService = GeminiService();
  final GradingExportService _exportService = GradingExportService();
  final SessionService _sessionService = SessionService();

  List<Submission> submissions = [];
  int currentIndex = -1;
  bool isLoading = false;
  String apiKey = "";

  final List<TextEditingController> _scoreControllers = [];
  final TextEditingController _commentController = TextEditingController();
  final TextEditingController _markerController = TextEditingController(text: ""); // empty by default for validation

  ExamType? selectedGlobalExamType;
  final List<ExamType> sessionExamTypes = [];

  @override
  void initState() {
    super.initState();
    sessionExamTypes.addAll(defaultExamTypes.map((e) => ExamType(
      e.code,
      e.criteria.map((c) => Criterion(c.name, c.maxScore100)).toList(),
      customRubric: e.customRubric,
    )));
    selectedGlobalExamType = sessionExamTypes.first;
    _loadApiKey();
    // Pre-fill marker name from session if available
    if (widget.session.markerName != null && widget.session.markerName!.isNotEmpty) {
      _markerController.text = widget.session.markerName!;
    }
    _markerController.addListener(() {
      _updateAndSaveSession();
    });
    // Start session initialization asynchronously
    WidgetsBinding.instance.addPostFrameCallback((_) => _initializeSession());
  }

  Future<void> _initializeSession() async {
    setState(() => isLoading = true);
    try {
      // 1. Load progress file if exists
      final progress = await _sessionService.loadSessionProgress(widget.session.id);

      // 2. Restore custom rubrics and criteria from progress
      if (progress != null) {
        final customRubrics = progress['customRubrics'] as Map<String, dynamic>?;
        if (customRubrics != null) {
          customRubrics.forEach((code, rubric) {
            final exam = sessionExamTypes.firstWhere((e) => e.code == code, orElse: () => sessionExamTypes.first);
            exam.customRubric = rubric as String?;
          });
        }

        final customCriteria = progress['customCriteria'] as Map<String, dynamic>?;
        if (customCriteria != null) {
          customCriteria.forEach((code, criteriaList) {
            final exam = sessionExamTypes.firstWhere((e) => e.code == code, orElse: () => sessionExamTypes.first);
            if (criteriaList is List) {
              exam.criteria = criteriaList.map((c) {
                final map = c as Map<String, dynamic>;
                return Criterion(map['name'] as String, (map['maxScore100'] as num).toDouble());
              }).toList();
            }
          });
        }

        final selectedCode = progress['selectedGlobalExamTypeCode'] as String?;
        if (selectedCode != null) {
          selectedGlobalExamType = sessionExamTypes.firstWhere((e) => e.code == selectedCode, orElse: () => sessionExamTypes.first);
        }
      }

      // 3. Load Zip and Student Submissions
      if (widget.session.studentZipPath != null) {
        final extractPath = await _fileService.extractZipFromPath(widget.session.studentZipPath!, widget.session.id);
        if (extractPath != null) {
          final loadedSubmissions = _fileService.loadSubmissionsFromFolder(extractPath);
          
          // 4. Map progress to loaded submissions
          if (progress != null && progress['submissions'] != null) {
            final savedSubs = progress['submissions'] as List<dynamic>;
            for (var sub in loadedSubmissions) {
              final match = savedSubs.firstWhere(
                (s) => s['fileName'] == sub.fileName,
                orElse: () => null,
              );
              if (match != null) {
                sub.scores = (match['scores'] as List<dynamic>).map((e) => (e as num).toDouble()).toList();
                sub.comment = match['comment'] as String? ?? "";
                sub.aiScores = (match['aiScores'] as List<dynamic>).map((e) => (e as num).toDouble()).toList();
                sub.aiComments = (match['aiComments'] as List<dynamic>).map((e) => e.toString()).toList();
                sub.aiComment = match['aiComment'] as String? ?? "";
                sub.hasAiGraded = match['hasAiGraded'] as bool? ?? false;
                sub.graded = match['graded'] as bool? ?? false;
                final subExamTypeCode = match['examTypeCode'] as String?;
                if (subExamTypeCode != null) {
                  sub.examType = sessionExamTypes.firstWhere((e) => e.code == subExamTypeCode, orElse: () => selectedGlobalExamType ?? sessionExamTypes.first);
                }
              }
            }
          }

          // 4.5. Load Alias-Marker mappings and assign markers to submissions
          Map<String, String> aliasMarkerMappings = {};
          if (widget.session.markInputXlsxPath != null) {
            aliasMarkerMappings = await _fileService.extractAliasMarkerMappings(widget.session.markInputXlsxPath!);
            
            // Assign markers to submissions based on filename matching alias
            for (var submission in loadedSubmissions) {
              final alias = _extractAliasFromFileName(submission.fileName);
              if (alias != null && aliasMarkerMappings.containsKey(alias)) {
                submission.marker = aliasMarkerMappings[alias];
              }
            }
          }

          setState(() {
            submissions = loadedSubmissions;
            int savedIndex = progress?['currentIndex'] as int? ?? 0;
            if (savedIndex >= 0 && savedIndex < submissions.length) {
              currentIndex = savedIndex;
            } else if (submissions.isNotEmpty) {
              currentIndex = 0;
            }
            if (currentIndex != -1) {
              _loadSubmission(currentIndex);
            }
          });
        }
      }

      // 5. Load Rubric Docx if any
      if (widget.session.gradingGuideDocPath != null && (selectedGlobalExamType?.customRubric == null || selectedGlobalExamType!.customRubric!.isEmpty)) {
        final rubricText = await _fileService.extractDocxTextFromPath(widget.session.gradingGuideDocPath!);
        if (rubricText != null) {
          setState(() {
            if (selectedGlobalExamType != null) {
              selectedGlobalExamType!.customRubric = rubricText;
            }
            for (var sub in submissions) {
              if (sub.examType != null) {
                sub.examType!.customRubric = rubricText;
              }
            }
          });
        }
      }
    } catch (e) {
      _showSnackBar("Lỗi khi khôi phục tiến trình: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _updateAndSaveSession() async {
    final gradedCount = submissions.where((s) => s.graded).length;
    final totalStudents = submissions.length;
    final markerName = _markerController.text.trim();

    final updatedSession = widget.session.copyWith(
      gradedCount: gradedCount,
      totalStudents: totalStudents,
      markerName: markerName.isNotEmpty ? markerName : null,
      lastModified: DateTime.now(),
    );

    await _sessionService.saveSession(updatedSession);

    // Save detailed progress to JSON file
    final progressData = {
      'currentIndex': currentIndex,
      'selectedGlobalExamTypeCode': selectedGlobalExamType?.code,
      'customRubrics': {
        for (var exam in sessionExamTypes)
          if (exam.customRubric != null) exam.code: exam.customRubric
      },
      'customCriteria': {
        for (var exam in sessionExamTypes)
          exam.code: exam.criteria.map((c) => {
            'name': c.name,
            'maxScore100': c.maxScore100,
          }).toList()
      },
      'submissions': submissions.map((sub) => {
        'fileName': sub.fileName,
        'scores': sub.scores,
        'comment': sub.comment,
        'aiScores': sub.aiScores,
        'aiComments': sub.aiComments,
        'aiComment': sub.aiComment,
        'hasAiGraded': sub.hasAiGraded,
        'graded': sub.graded,
        'examTypeCode': sub.examType?.code,
      }).toList(),
    };

    await _sessionService.saveSessionProgress(widget.session.id, progressData);
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
    for (var ctrl in _scoreControllers) {
      ctrl.dispose();
    }
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
      final extractPath = await _fileService.pickAndExtractZip(widget.session.id);
      if (extractPath != null) {
        final loadedSubmissions = _fileService.loadSubmissionsFromFolder(extractPath);
        setState(() {
          submissions = loadedSubmissions;
          if (submissions.isNotEmpty) {
            currentIndex = 0;
            _loadSubmission(0);
          }
        });
        _updateAndSaveSession();
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
    if (sub.examType == null && selectedGlobalExamType != null) {
      sub.examType = selectedGlobalExamType;
    }

    final exam = sub.examType ?? selectedGlobalExamType!;
    sub.initScores(exam);

    // Dispose old score controllers
    for (var ctrl in _scoreControllers) {
      ctrl.dispose();
    }
    _scoreControllers.clear();

    // Create new score controllers
    for (int i = 0; i < exam.criteria.length; i++) {
      final val = sub.scores[i];
      final ctrl = TextEditingController(text: val.toString());
      ctrl.addListener(() {
        setState(() {}); // refresh the UI for Total Score calculation
      });
      _scoreControllers.add(ctrl);
    }

    _commentController.text = sub.comment;
  }

  void _saveCurrentScores() {
    if (currentIndex == -1) return;
    
    final sub = submissions[currentIndex];
    final exam = sub.examType ?? selectedGlobalExamType!;
    sub.initScores(exam);

    for (int i = 0; i < exam.criteria.length; i++) {
      if (i < _scoreControllers.length) {
        sub.scores[i] = double.tryParse(_scoreControllers[i].text) ?? 0.0;
      }
    }
    sub.comment = _commentController.text;
    sub.graded = true;
    _updateAndSaveSession();
  }

  void _saveScoresWithoutMarking() {
    if (currentIndex == -1) return;
    
    final sub = submissions[currentIndex];
    final exam = sub.examType ?? selectedGlobalExamType!;
    sub.initScores(exam);

    for (int i = 0; i < exam.criteria.length; i++) {
      if (i < _scoreControllers.length) {
        sub.scores[i] = double.tryParse(_scoreControllers[i].text) ?? 0.0;
      }
    }
    sub.comment = _commentController.text;
    // Don't set sub.graded = true here
    _updateAndSaveSession();
  }

  void _nextSubmission() {
    if (currentIndex < submissions.length - 1) {
      setState(() {
        currentIndex++;
        _loadSubmission(currentIndex);
      });
    }
  }

  void _prevSubmission() {
    if (currentIndex > 0) {
      setState(() {
        currentIndex--;
        _loadSubmission(currentIndex);
      });
    }
  }

  String? _extractAliasFromFileName(String fileName) {
    // Try to extract numeric alias from filename (e.g., "1.txt", "submission_2.txt", etc.)
    final nameWithoutExt = fileName.replaceAll(RegExp(r'\.[^.]+$'), ''); // Remove extension
    final numbers = RegExp(r'\d+').allMatches(nameWithoutExt).map((m) => m.group(0)!).toList();
    
    if (numbers.isNotEmpty) {
      // Return the first number found as string
      return numbers.first;
    }
    
    // If no numbers found, try to match the filename directly as alias
    return nameWithoutExt.trim();
  }

  Future<void> _askAi() async {
    if (apiKey.isEmpty) {
      _showSnackBar("Vui lòng đặt Gemini API Key trong phần cài đặt (Settings).");
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
      debugPrint("========== Grader Error Logging ==========");
      debugPrint("Error calling Gemini: $e");
      debugPrint("Stack trace: $stack");
      debugPrint("=========================================");
      _showSnackBar(e.toString());
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _copyAiToTeacher() {
    if (currentIndex == -1) return;
    final sub = submissions[currentIndex];
    if (!sub.hasAiGraded) return;

    final exam = sub.examType ?? selectedGlobalExamType!;
    sub.initScores(exam);

    setState(() {
      for (int i = 0; i < exam.criteria.length; i++) {
        if (i < sub.aiScores.length && i < _scoreControllers.length) {
          _scoreControllers[i].text = sub.aiScores[i].toString();
        }
      }
      _commentController.text = sub.aiComment;
      _saveScoresWithoutMarking();
    });
  }

  Future<void> _exportData() async {
    final markerName = _markerController.text.trim();
    if (markerName.isEmpty) {
      _showSnackBar("Vui lòng nhập tên người chấm trước khi xuất Excel!");
      return;
    }

    _saveScoresWithoutMarking();
    try {
      await _exportService.exportToExcel(submissions, markerName);
      _showSnackBar('Xuất tệp Excel thành công!');
    } catch (e) {
      _showSnackBar('Lỗi khi xuất tệp: $e');
    }
  }

  void _onRubricChanged(String newRubric) {
    setState(() {
      if (selectedGlobalExamType != null) {
        selectedGlobalExamType!.customRubric = newRubric;
      }
      if (currentIndex != -1) {
        final sub = submissions[currentIndex];
        final exam = sub.examType ?? selectedGlobalExamType;
        if (exam != null) {
          exam.customRubric = newRubric;
        }
      }
    });
    _updateAndSaveSession();
  }

  Future<void> _showConfigureCriteriaDialog(ExamType exam) async {
    final newCriteria = await showDialog<List<Criterion>>(
      context: context,
      builder: (context) => _ConfigureCriteriaDialog(exam: exam),
    );

    if (newCriteria != null) {
      setState(() {
        exam.criteria = newCriteria;
        // Sync and re-initialize scores/aiScores for all submissions of this exam type
        for (var sub in submissions) {
          if (sub.examType == exam || (sub.examType == null && selectedGlobalExamType == exam)) {
            sub.initScores(exam);
          }
        }
        // Reload controllers for active submission
        _loadSubmission(currentIndex);
        _showSnackBar("Cập nhật tiêu chí đề thi thành công!");
      });
      _updateAndSaveSession();
    }
  }

  void _showSettingsDialog() {
    final TextEditingController keyCtrl = TextEditingController(text: apiKey);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Cài đặt API Key"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Gemini API Key:"),
            TextField(
              controller: keyCtrl,
              obscureText: true,
              decoration: const InputDecoration(hintText: "Nhập khóa AI Studio Key"),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Hủy")),
          ElevatedButton(
            onPressed: () {
              _saveApiKey(keyCtrl.text);
              Navigator.pop(context);
            },
            child: const Text("Lưu"),
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
              AppBarWidget(
                markerController: _markerController,
                onLoadZip: _pickZipAndExtract,
                onExportExcel: _exportData,
                onShowSettings: _showSettingsDialog,
                hasSubmissions: submissions.isNotEmpty,
                currentSubmission: currentIndex >= 0 && currentIndex < submissions.length 
                    ? submissions[currentIndex] 
                    : null,
              ),
              Expanded(
                child: submissions.isEmpty
                    ? _buildEmptyState()
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SidebarWidget(
                            submissions: submissions,
                            currentIndex: currentIndex,
                            onSubmissionSelected: (index) {
                              _saveScoresWithoutMarking();
                              setState(() {
                                currentIndex = index;
                                _loadSubmission(index);
                              });
                            },
                          ),
                          Expanded(
                            child: ContentViewerWidget(
                              submission: submissions[currentIndex],
                              currentIndex: currentIndex,
                              totalSubmissions: submissions.length,
                              onExamTypeChanged: (val) {
                                setState(() {
                                  submissions[currentIndex].examType = val;
                                  _loadSubmission(currentIndex); // reload controllers for new type
                                });
                                _updateAndSaveSession();
                              },
                              onConfigureCriteria: () => _showConfigureCriteriaDialog(submissions[currentIndex].examType ?? selectedGlobalExamType ?? sessionExamTypes.first),
                              onPrev: currentIndex > 0 ? _prevSubmission : null,
                              onNext: currentIndex < submissions.length - 1 ? _nextSubmission : null,
                              examTypes: sessionExamTypes,
                              examImagePath: widget.session.examImagePath,
                            ),
                          ),
                          GradingPanelWidget(
                            submission: submissions[currentIndex],
                            onAskAi: _askAi,
                            onCopyAiToTeacher: _copyAiToTeacher,
                            onSaveScores: () {
                              _saveCurrentScores();
                              if (currentIndex < submissions.length - 1) {
                                _nextSubmission();
                              } else {
                                _showSnackBar("Đã hoàn tất chấm điểm toàn bộ bài nộp!");
                              }
                            },
                            scoreControllers: _scoreControllers,
                            commentController: _commentController,
                            hasNext: currentIndex < submissions.length - 1,
                            onRubricChanged: _onRubricChanged,
                          ),
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_zip_rounded, size: 80, color: const Color(0xFF6366F1).withValues(alpha: 0.5)),
          const SizedBox(height: 24),
          Text(
            'Chưa có bài nộp nào được tải lên',
            style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B)),
          ),
          const SizedBox(height: 8),
          const Text('Chọn một tệp .zip chứa các bài nộp để bắt đầu chấm điểm.', style: TextStyle(color: Color(0xFF64748B))),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _pickZipAndExtract,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            ),
            child: const Text('Tải tệp .zip bài nộp'),
          ),
        ],
      ),
    );
  }
}

class _ConfigureCriteriaDialog extends StatefulWidget {
  final ExamType exam;

  const _ConfigureCriteriaDialog({required this.exam});

  @override
  State<_ConfigureCriteriaDialog> createState() => _ConfigureCriteriaDialogState();
}

class _ConfigureCriteriaDialogState extends State<_ConfigureCriteriaDialog> {
  late List<TextEditingController> _nameControllers;
  late List<TextEditingController> _scoreControllers;

  @override
  void initState() {
    super.initState();
    _nameControllers = widget.exam.criteria.map((c) => TextEditingController(text: c.name)).toList();
    _scoreControllers = widget.exam.criteria.map((c) => TextEditingController(text: c.maxScore100.toString())).toList();
  }

  @override
  void dispose() {
    for (var c in _nameControllers) {
      c.dispose();
    }
    for (var c in _scoreControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _addCriterion() {
    setState(() {
      _nameControllers.add(TextEditingController(text: 'Question ${_nameControllers.length + 1}'));
      _scoreControllers.add(TextEditingController(text: '10.0'));
    });
  }

  void _deleteCriterion(int index) {
    setState(() {
      _nameControllers[index].dispose();
      _nameControllers.removeAt(index);
      _scoreControllers[index].dispose();
      _scoreControllers.removeAt(index);
    });
  }

  double _calculateTotalSum() {
    double total = 0.0;
    for (var ctrl in _scoreControllers) {
      total += double.tryParse(ctrl.text) ?? 0.0;
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final totalSum = _calculateTotalSum();
    return AlertDialog(
      title: Text(
        'Cấu hình tiêu chí - ${widget.exam.code}',
        style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18),
      ),
      content: SizedBox(
        width: 500,
        height: 400,
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _nameControllers.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextField(
                            controller: _nameControllers[index],
                            decoration: const InputDecoration(
                              labelText: 'Tên tiêu chí',
                              isDense: true,
                            ),
                            style: GoogleFonts.inter(fontSize: 13),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: _scoreControllers[index],
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(
                              labelText: 'Điểm (Thang 100)',
                              isDense: true,
                            ),
                            style: GoogleFonts.inter(fontSize: 13),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                          onPressed: () => _deleteCriterion(index),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    onPressed: _addCriterion,
                    icon: const Icon(Icons.add),
                    label: const Text('Thêm tiêu chí'),
                  ),
                  Text(
                    'Tổng điểm: ${totalSum.toStringAsFixed(1)}/100',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      color: (totalSum - 100.0).abs() < 0.01 ? Colors.green.shade700 : const Color(0xFFE28743),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          onPressed: () {
            // Save criteria
            final newCriteria = <Criterion>[];
            for (int i = 0; i < _nameControllers.length; i++) {
              final name = _nameControllers[i].text.trim();
              final score = double.tryParse(_scoreControllers[i].text) ?? 10.0;
              newCriteria.add(Criterion(name.isNotEmpty ? name : 'Question ${i + 1}', score));
            }
            Navigator.pop(context, newCriteria);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6366F1),
            foregroundColor: Colors.white,
          ),
          child: const Text('Lưu thay đổi'),
        ),
      ],
    );
  }
}
