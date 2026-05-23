import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

import '../models/exam_type.dart';
import '../models/grading_collection.dart';
import '../models/submission.dart';
import '../services/file_service.dart';
import '../services/gemini_service.dart';
import '../services/grading_export_service.dart';
import '../services/session_service.dart';
import '../widgets/content_viewer_widget.dart';
import '../widgets/grading_panel_widget.dart';
import '../widgets/sidebar_widget.dart';

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
  final TextEditingController _commentController = TextEditingController();
  final TextEditingController _markerController = TextEditingController();
  final List<TextEditingController> _scoreControllers = [];

  final List<GradingCollection> _collections = [];
  int _collectionIndex = -1;
  int _currentIndex = -1;
  int _tabIndex = 0;
  bool _isLoading = false;
  bool _isAiGrading = false;
  bool _isAiPaused = false;
  bool _stopAiGrading = false;
  int _aiGradingDone = 0;
  int _aiGradingTotal = 0;
  int _aiGradingCurrent = 0;
  String _aiGradingLabel = '';
  http.Client? _activeAiClient;
  double _collectionSidebarWidth = 300;
  double _submissionSidebarWidth = 280;

  GradingCollection? get _collection {
    if (_collectionIndex < 0 || _collectionIndex >= _collections.length) return null;
    return _collections[_collectionIndex];
  }

  Submission? get _currentSubmission {
    final collection = _collection;
    if (collection == null || _currentIndex < 0 || _currentIndex >= collection.submissions.length) return null;
    return collection.submissions[_currentIndex];
  }

  @override
  void initState() {
    super.initState();
    if (widget.session.markerName?.isNotEmpty == true) {
      _markerController.text = widget.session.markerName!;
    }
    _markerController.addListener(_handleMarkerChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _initializeSession());
  }

  @override
  void dispose() {
    for (final controller in _scoreControllers) {
      controller.dispose();
    }
    _markerController.removeListener(_handleMarkerChanged);
    _commentController.dispose();
    _markerController.dispose();
    super.dispose();
  }

  Future<void> _initializeSession() async {
    setState(() => _isLoading = true);
    try {
      final progress = await _sessionService.loadSessionProgress(widget.session.id);
      final collection = _restoreCollection(progress);

      if (widget.session.gradingGuideDocPath != null && !collection.hasRubric) {
        final rubric = await _fileService.extractDocxTextFromPath(widget.session.gradingGuideDocPath!);
        if (rubric != null && rubric.trim().isNotEmpty) {
          collection.applyRubric(_fileNameFromPath(widget.session.gradingGuideDocPath!), rubric);
        }
      }

      if (widget.session.studentZipPath != null && collection.submissions.isEmpty) {
        final extractPath = await _fileService.extractZipFromPath(
          widget.session.studentZipPath!,
          widget.session.id,
        );
        if (extractPath != null) {
          collection.submissions = _fileService.loadSubmissionsFromFolder(extractPath);
          for (final sub in collection.submissions) {
            sub.examType = collection.selectedExamType;
            sub.initScores(collection.selectedExamType);
          }
          collection.touch();
        }
      }

      setState(() {
        _collections
          ..clear()
          ..add(collection);
        _collectionIndex = 0;
        final savedIndex = progress?['currentIndex'] as int?;
        _currentIndex = collection.submissions.isEmpty
            ? -1
            : (savedIndex != null && savedIndex >= 0 && savedIndex < collection.submissions.length)
                ? savedIndex
                : 0;
        _tabIndex = progress?['tabIndex'] as int? ?? (collection.submissions.isEmpty ? 0 : 3);
        if (_currentIndex >= 0) {
          _loadSubmission(_currentIndex);
        } else {
          _clearScoreControllers();
        }
      });
      await _updateAndSaveSession();
    } catch (e) {
      _showSnackBar('Failed to restore session: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  GradingCollection _restoreCollection(Map<String, dynamic>? progress) {
    final collection = GradingCollection.create(
      progress?['collectionName'] as String? ?? widget.session.name,
    );
    collection.apiKey = progress?['collectionApiKey'] as String? ?? '';

    final selectedCode = progress?['selectedExamTypeCode'] as String?;
    final customRubrics = progress?['customRubrics'] as Map<String, dynamic>?;
    final customCriteria = progress?['customCriteria'] as Map<String, dynamic>?;
    for (final exam in collection.examTypes) {
      final rubric = customRubrics?[exam.code];
      if (rubric is String) exam.customRubric = rubric;

      final criteria = customCriteria?[exam.code];
      if (criteria is List) {
        exam.criteria = criteria.whereType<Map<String, dynamic>>().map((item) {
          return Criterion(
            item['name'] as String? ?? 'Question',
            (item['maxScore100'] as num?)?.toDouble() ?? 0.0,
          );
        }).toList();
      }
    }
    if (selectedCode != null) {
      collection.selectedExamType = collection.examTypes.firstWhere(
        (exam) => exam.code == selectedCode,
        orElse: () => collection.selectedExamType,
      );
    }
    collection.rubricFileName = progress?['rubricFileName'] as String?;
    collection.rubricContent = progress?['rubricContent'] as String?;
    if (collection.rubricContent?.isNotEmpty == true) {
      collection.selectedExamType.customRubric = collection.rubricContent;
    }
    collection.examFileName = progress?['examFileName'] as String?;
    collection.examContent = progress?['examContent'] as String?;

    final savedSubmissions = progress?['submissions'] as List<dynamic>?;
    if (savedSubmissions != null) {
      collection.submissions = savedSubmissions.whereType<Map<String, dynamic>>().map((item) {
        final sub = Submission(
          fileName: item['fileName'] as String? ?? '',
          filePath: item['filePath'] as String? ?? '',
          content: item['content'] as String? ?? '',
        );
        final examCode = item['examTypeCode'] as String?;
        sub.examType = collection.examTypes.firstWhere(
          (exam) => exam.code == examCode,
          orElse: () => collection.selectedExamType,
        );
        sub.scores = _doubleList(item['scores']);
        sub.aiScores = _doubleList(item['aiScores']);
        sub.aiComments = (item['aiComments'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
        sub.comment = item['comment'] as String? ?? '';
        sub.aiComment = item['aiComment'] as String? ?? '';
        sub.hasAiGraded = item['hasAiGraded'] as bool? ?? false;
        sub.opened = item['opened'] as bool? ?? false;
        sub.graded = item['graded'] as bool? ?? false;
        sub.initScores(sub.examType ?? collection.selectedExamType);
        return sub;
      }).toList();
    }
    collection.touch();
    return collection;
  }

  List<double> _doubleList(dynamic value) {
    return (value as List<dynamic>?)?.whereType<num>().map((e) => e.toDouble()).toList() ?? [];
  }

  String _fileNameFromPath(String path) {
    final normalized = path.replaceAll('\\', '/');
    return normalized.split('/').last;
  }

  Future<void> _updateAndSaveSession() async {
    final totalStudents = _collections.fold<int>(0, (sum, c) => sum + c.totalSubmissions);
    final gradedCount = _collections.fold<int>(0, (sum, c) => sum + c.reviewedCount);
    final markerName = _markerController.text.trim();
    final updatedSession = widget.session.copyWith(
      totalStudents: totalStudents,
      gradedCount: gradedCount,
      markerName: markerName.isEmpty ? null : markerName,
      lastModified: DateTime.now(),
    );
    await _sessionService.saveSession(updatedSession);

    final collection = _collection;
    if (collection == null) return;
    await _sessionService.saveSessionProgress(widget.session.id, {
      'collectionName': collection.name,
      'collectionApiKey': collection.apiKey,
      'currentIndex': _currentIndex,
      'tabIndex': _tabIndex,
      'selectedExamTypeCode': collection.selectedExamType.code,
      'rubricFileName': collection.rubricFileName,
      'rubricContent': collection.rubricContent,
      'examFileName': collection.examFileName,
      'examContent': collection.examContent,
      'customRubrics': {
        for (final exam in collection.examTypes)
          if (exam.customRubric != null) exam.code: exam.customRubric,
      },
      'customCriteria': {
        for (final exam in collection.examTypes)
          exam.code: exam.criteria.map((criterion) => {
                'name': criterion.name,
                'maxScore100': criterion.maxScore100,
              }).toList(),
      },
      'submissions': collection.submissions.map((sub) => {
            'fileName': sub.fileName,
            'filePath': sub.filePath,
            'content': sub.content,
            'scores': sub.scores,
            'comment': sub.comment,
            'aiScores': sub.aiScores,
            'aiComments': sub.aiComments,
            'aiComment': sub.aiComment,
            'hasAiGraded': sub.hasAiGraded,
            'opened': sub.opened,
            'graded': sub.graded,
            'examTypeCode': sub.examType?.code,
          }).toList(),
    });
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _handleMarkerChanged() {
    _updateAndSaveSession();
  }

  void _createCollection([String? name]) {
    final nextName = name?.trim().isNotEmpty == true ? name!.trim() : 'Collection ${_collections.length + 1}';
    final collection = GradingCollection.create(nextName);
    setState(() {
      _collections.add(collection);
      _collectionIndex = _collections.length - 1;
      _currentIndex = -1;
      _tabIndex = 0;
      _clearScoreControllers();
    });
    _updateAndSaveSession();
  }

  Future<void> _showCreateCollectionDialog() async {
    final controller = TextEditingController(text: 'PMG grading batch ${_collections.length + 1}');
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New collection'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Collection name'),
          onSubmitted: (value) => Navigator.pop(context, value),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text('Create')),
        ],
      ),
    );
    controller.dispose();
    if (name != null) _createCollection(name);
  }

  void _selectCollection(int index) {
    _saveCurrentScores();
    final collection = _collections[index];
    setState(() {
      _collectionIndex = index;
      _currentIndex = collection.submissions.isEmpty ? -1 : 0;
      _tabIndex = 0;
      if (_currentIndex >= 0) {
        _loadSubmission(_currentIndex);
      } else {
        _clearScoreControllers();
      }
    });
  }

  Future<void> _renameCollection(int index) async {
    if (index < 0 || index >= _collections.length) return;
    final collection = _collections[index];
    final controller = TextEditingController(text: collection.name);
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename collection'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Collection name'),
          onSubmitted: (value) => Navigator.pop(context, value),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text('Rename')),
        ],
      ),
    );
    controller.dispose();

    final trimmedName = name?.trim();
    if (trimmedName == null || trimmedName.isEmpty) return;
    setState(() {
      collection.name = trimmedName;
      collection.touch();
    });
    await _updateAndSaveSession();
  }

  Future<void> _deleteCollection(int index) async {
    if (index < 0 || index >= _collections.length) return;
    final collection = _collections[index];
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete collection?'),
        content: Text(
          'This will remove "${collection.name}" from the current workspace. This action cannot be undone.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFCF222E),
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    setState(() {
      _collections.removeAt(index);
      if (_collections.isEmpty) {
        _collectionIndex = -1;
        _currentIndex = -1;
        _tabIndex = 0;
        _clearScoreControllers();
        return;
      }

      if (_collectionIndex >= _collections.length) {
        _collectionIndex = _collections.length - 1;
      } else if (index < _collectionIndex) {
        _collectionIndex--;
      }

      final selected = _collections[_collectionIndex];
      _currentIndex = selected.submissions.isEmpty ? -1 : 0;
      _tabIndex = 0;
      if (_currentIndex >= 0) {
        _loadSubmission(_currentIndex);
      } else {
        _clearScoreControllers();
      }
    });
    await _updateAndSaveSession();
  }

  Future<void> _importExamFile() async {
    final collection = _collection;
    if (collection == null) return;

    setState(() => _isLoading = true);
    try {
      final picked = await _fileService.pickAndReadTextDocument(
        extensions: ['docx', 'txt'],
        dialogTitle: 'Import exam file',
      );
      if (picked == null) return;
      setState(() {
        collection.applyExam(picked.fileName, picked.content);
        for (final sub in collection.submissions) {
          sub.examType ??= collection.selectedExamType;
        }
      });
      await _updateAndSaveSession();
      _showSnackBar('Exam imported');
    } catch (e) {
      _showSnackBar('Failed to import exam: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _importRubricFile() async {
    final collection = _collection;
    if (collection == null) return;

    setState(() => _isLoading = true);
    try {
      final picked = await _fileService.pickAndReadTextDocument(
        extensions: ['docx', 'txt'],
        dialogTitle: 'Import rubric file',
      );
      if (picked == null) return;
      setState(() {
        collection.applyRubric(picked.fileName, picked.content);
        _loadSubmission(_currentIndex);
      });
      await _updateAndSaveSession();
      _showSnackBar('Rubric imported');
    } catch (e) {
      _showSnackBar('Failed to import rubric: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _importSubmissionsZip() async {
    final collection = _collection;
    if (collection == null) return;

    setState(() => _isLoading = true);
    try {
      final extractPath = await _fileService.pickAndExtractZip(widget.session.id);
      if (extractPath == null) return;
      final loaded = _fileService.loadSubmissionsFromFolder(extractPath);
      _applySubmissions(loaded);
      await _updateAndSaveSession();
      _showSnackBar('${loaded.length} submissions imported');
    } catch (e) {
      _showSnackBar('Failed to import zip: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _importSubmissionsFolder() async {
    final collection = _collection;
    if (collection == null) return;

    setState(() => _isLoading = true);
    try {
      final loaded = await _fileService.pickAndLoadSubmissionFolder();
      if (loaded.isEmpty) return;
      _applySubmissions(loaded);
      await _updateAndSaveSession();
      _showSnackBar('${loaded.length} submissions imported');
    } catch (e) {
      _showSnackBar('Failed to import folder: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _applySubmissions(List<Submission> submissions) {
    final collection = _collection;
    if (collection == null) return;

    setState(() {
      for (final sub in submissions) {
        sub.examType = collection.selectedExamType;
        sub.initScores(collection.selectedExamType);
      }
      collection.submissions = submissions;
      collection.touch();
      _currentIndex = submissions.isEmpty ? -1 : 0;
      _tabIndex = submissions.isEmpty ? 0 : 3;
      if (_currentIndex >= 0) {
        _loadSubmission(_currentIndex);
      } else {
        _clearScoreControllers();
      }
    });
    _updateAndSaveSession();
  }

  void _clearScoreControllers() {
    for (final controller in _scoreControllers) {
      controller.dispose();
    }
    _scoreControllers.clear();
    _commentController.clear();
  }

  void _loadSubmission(int index) {
    final collection = _collection;
    if (collection == null || index < 0 || index >= collection.submissions.length) return;

    final sub = collection.submissions[index];
    sub.opened = true;
    sub.examType ??= collection.selectedExamType;
    final exam = sub.examType ?? collection.selectedExamType;
    sub.initScores(exam);

    _clearScoreControllers();
    for (var i = 0; i < exam.criteria.length; i++) {
      final controller = TextEditingController(text: sub.scores[i].toString());
      controller.addListener(() {
        if (mounted) setState(() {});
      });
      _scoreControllers.add(controller);
    }
    _commentController.text = sub.comment;
    collection.touch();
  }

  void _saveCurrentScores({bool markComplete = false}) {
    final collection = _collection;
    final sub = _currentSubmission;
    if (collection == null || sub == null) return;

    final exam = sub.examType ?? collection.selectedExamType;
    sub.initScores(exam);
    for (var i = 0; i < exam.criteria.length; i++) {
      if (i >= _scoreControllers.length) continue;
      final parsed = double.tryParse(_scoreControllers[i].text) ?? 0.0;
      sub.scores[i] = parsed.clamp(0.0, exam.criteria[i].maxScore10).toDouble();
    }
    sub.comment = _commentController.text;
    sub.opened = true;
    if (markComplete) {
      sub.graded = true;
    }
    collection.touch();
    _updateAndSaveSession();
  }

  void _nextSubmission() {
    final collection = _collection;
    if (collection == null) return;
    _saveCurrentScores();
    if (_currentIndex < collection.submissions.length - 1) {
      setState(() {
        _currentIndex++;
        _loadSubmission(_currentIndex);
      });
    }
  }

  void _prevSubmission() {
    _saveCurrentScores();
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
        _loadSubmission(_currentIndex);
      });
    }
  }

  Future<void> _askAi() async {
    final collection = _collection;
    final sub = _currentSubmission;
    if (collection == null || sub == null) return;
    if (collection.apiKey.trim().isEmpty) {
      _showSnackBar('Set this collection API key first');
      return;
    }

    final exam = sub.examType ?? collection.selectedExamType;
    _activeAiClient?.close();
    _activeAiClient = http.Client();
    setState(() {
      _isAiGrading = true;
      _isAiPaused = false;
      _stopAiGrading = false;
      _aiGradingDone = collection.aiGradedCount;
      _aiGradingTotal = collection.totalSubmissions;
      _aiGradingCurrent = collection.submissions.indexOf(sub) + 1;
      _aiGradingLabel = 'AI is grading ${sub.fileName}';
    });
    try {
      await _geminiService.gradeSubmission(sub, exam, collection.apiKey, client: _activeAiClient);
      collection.touch();
      setState(() {
        _aiGradingDone = collection.aiGradedCount;
        _aiGradingLabel = 'AI grading completed for ${sub.fileName}';
      });
    } catch (e) {
      if (_stopAiGrading) {
        _showSnackBar('AI grading stopped.');
      } else {
        _showSnackBar('AI grading failed: $e');
      }
    } finally {
      _activeAiClient?.close();
      _activeAiClient = null;
      if (mounted) {
        setState(() {
          _isAiGrading = false;
          _isAiPaused = false;
          _stopAiGrading = false;
          _aiGradingDone = 0;
          _aiGradingTotal = 0;
          _aiGradingCurrent = 0;
          _aiGradingLabel = '';
        });
      }
    }
  }

  Future<void> _gradeAllWithAi() async {
    final collection = _collection;
    if (collection == null || collection.submissions.isEmpty) return;
    if (collection.apiKey.trim().isEmpty) {
      _showSnackBar('Set this collection API key first');
      return;
    }

    final pending = collection.submissions.asMap().entries.where((entry) => !entry.value.hasAiGraded).toList();
    if (pending.isEmpty) {
      _showSnackBar('All submissions already have AI results.');
      return;
    }

    _activeAiClient?.close();
    _activeAiClient = http.Client();
    setState(() {
      _tabIndex = 3;
      _isAiGrading = true;
      _isAiPaused = false;
      _stopAiGrading = false;
      _aiGradingDone = collection.aiGradedCount;
      _aiGradingTotal = collection.totalSubmissions;
      _aiGradingCurrent = 0;
      _aiGradingLabel = 'Starting AI pregrade...';
    });
    try {
      for (var i = 0; i < pending.length; i++) {
        if (_stopAiGrading || _isAiPaused) break;

        final originalIndex = pending[i].key;
        final sub = pending[i].value;
        if (sub.hasAiGraded) {
          continue;
        }

        if (mounted) {
          setState(() {
            _currentIndex = originalIndex;
            _aiGradingDone = collection.aiGradedCount;
            _aiGradingCurrent = originalIndex + 1;
            _aiGradingLabel = 'AI pregrading ${sub.fileName}';
            if (originalIndex >= 0) {
              _loadSubmission(originalIndex);
            }
          });
        }
        final exam = sub.examType ?? collection.selectedExamType;
        await _geminiService.gradeSubmission(sub, exam, collection.apiKey, client: _activeAiClient);
        if (mounted) {
          setState(() {
            _aiGradingDone = collection.aiGradedCount;
          });
        }
      }
      collection.touch();
      setState(() {
        _tabIndex = 3;
        _currentIndex = collection.submissions.indexWhere((sub) => !sub.graded);
        if (_currentIndex < 0) _currentIndex = 0;
        _loadSubmission(_currentIndex);
      });
      if (_stopAiGrading) {
        _showSnackBar('AI pregrade stopped. You can resume later.');
      } else if (_isAiPaused) {
        _showSnackBar('AI pregrade paused. Resume when ready.');
      } else {
        _showSnackBar('AI grading completed. Review each AI result and save the final human mark.');
      }
    } catch (e) {
      if (_stopAiGrading) {
        _showSnackBar('AI pregrade stopped. You can resume later.');
      } else {
        _showSnackBar('AI grading stopped: $e');
      }
    } finally {
      _activeAiClient?.close();
      _activeAiClient = null;
      if (mounted) {
        setState(() {
          _isAiGrading = false;
          _isAiPaused = false;
          _stopAiGrading = false;
          _aiGradingDone = 0;
          _aiGradingTotal = 0;
          _aiGradingCurrent = 0;
          _aiGradingLabel = '';
        });
      }
    }
  }

  void _pauseAiGrading() {
    if (!_isAiGrading) return;
    setState(() {
      _isAiPaused = true;
      _aiGradingLabel = 'Pausing after the current submission...';
    });
  }

  void _stopAiPregrade() {
    if (!_isAiGrading) return;
    setState(() {
      _stopAiGrading = true;
      _isAiGrading = false;
      _aiGradingLabel = 'Stopping AI pregrade...';
    });
    _activeAiClient?.close();
    _activeAiClient = null;
  }

  void _copyAiToTeacher() {
    final collection = _collection;
    final sub = _currentSubmission;
    if (collection == null || sub == null || !sub.hasAiGraded) return;

    final exam = sub.examType ?? collection.selectedExamType;
    sub.initScores(exam);
    setState(() {
      for (var i = 0; i < exam.criteria.length; i++) {
        if (i < sub.aiScores.length && i < _scoreControllers.length) {
          _scoreControllers[i].text = sub.aiScores[i].clamp(0.0, exam.criteria[i].maxScore10).toString();
        }
      }
      _commentController.text = sub.aiComment;
      _saveCurrentScores();
    });
  }

  Future<void> _exportData() async {
    final collection = _collection;
    if (collection == null) return;
    final markerName = _markerController.text.trim();
    if (markerName.isEmpty) {
      _showSnackBar('Enter marker name before export');
      return;
    }
    if (collection.submissions.isEmpty) {
      _showSnackBar('Import submissions before export');
      return;
    }

    _saveCurrentScores();
    try {
      await _exportService.exportCollection(collection, markerName);
      setState(() {});
      _showSnackBar('Excel exported');
    } catch (e) {
      _showSnackBar('Export failed: $e');
    }
  }

  Future<void> _showConfigureCriteriaDialog(ExamType exam) async {
    final newCriteria = await showDialog<List<Criterion>>(
      context: context,
      builder: (context) => _ConfigureCriteriaDialog(exam: exam),
    );

    final collection = _collection;
    if (newCriteria == null || collection == null) return;
    setState(() {
      exam.criteria = newCriteria;
      for (final sub in collection.submissions) {
        if (sub.examType == exam || sub.examType == null) sub.initScores(exam);
      }
      collection.touch();
      _loadSubmission(_currentIndex);
    });
  }

  void _showCollectionApiKeyDialog(GradingCollection collection) {
    final keyController = TextEditingController(text: collection.apiKey);
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('API key - ${collection.name}'),
        content: TextField(
          controller: keyController,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'Gemini API key',
            helperText: 'Stored separately for this collection.',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              setState(() => collection.apiKey = keyController.text.trim());
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    ).whenComplete(keyController.dispose);
  }

  @override
  Widget build(BuildContext context) {
    final collection = _collection;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FA),
      body: Stack(
        children: [
          Row(
            children: [
              _buildCollectionSidebar(),
              Expanded(
                child: collection == null ? _buildNoCollectionState() : _buildCollectionWorkspace(collection),
              ),
            ],
          ),
          if (_isLoading)
            Container(
              color: Colors.black26,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _buildCollectionSidebar() {
    return SizedBox(
      width: _collectionSidebarWidth,
      child: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(right: BorderSide(color: Color(0xFFD0D7DE))),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 16, 14),
                  child: Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.fact_check_outlined, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'PMG Grader',
                          style: GoogleFonts.outfit(
                            color: const Color(0xFF24292F),
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: _collection == null ? null : () => _showCollectionApiKeyDialog(_collection!),
                        icon: Icon(
                          Icons.key_outlined,
                          color: _collection == null ? const Color(0xFFD0D7DE) : const Color(0xFF57606A),
                        ),
                        tooltip: 'Collection API key',
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ElevatedButton.icon(
                    onPressed: _showCreateCollectionDialog,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('New collection'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F172A),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      minimumSize: const Size(double.infinity, 40),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Text(
                    'Collections',
                    style: GoogleFonts.inter(color: const Color(0xFF57606A), fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    itemCount: _collections.length,
                    itemBuilder: (context, index) {
                      final collection = _collections[index];
                      final selected = index == _collectionIndex;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: ListTile(
                          selected: selected,
                          selectedTileColor: const Color(0xFFF6F8FA),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                            side: selected ? const BorderSide(color: Color(0xFFD0D7DE)) : BorderSide.none,
                          ),
                          leading: Icon(
                            Icons.folder_outlined,
                            color: selected ? const Color(0xFF0969DA) : const Color(0xFF57606A),
                            size: 20,
                          ),
                          title: Text(
                            collection.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              color: const Color(0xFF24292F),
                              fontSize: 13,
                              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                            ),
                          ),
                          subtitle: Text(
                            '${collection.totalSubmissions} submissions',
                            style: GoogleFonts.inter(color: const Color(0xFF57606A), fontSize: 11),
                          ),
                          trailing: PopupMenuButton<String>(
                            tooltip: 'Collection actions',
                            icon: const Icon(Icons.more_horiz, size: 18, color: Color(0xFF57606A)),
                            onSelected: (value) {
                              if (value == 'rename') {
                                _renameCollection(index);
                              } else if (value == 'delete') {
                                _deleteCollection(index);
                              }
                            },
                            itemBuilder: (context) => const [
                              PopupMenuItem(
                                value: 'rename',
                                child: Row(
                                  children: [
                                    Icon(Icons.drive_file_rename_outline, size: 18),
                                    SizedBox(width: 8),
                                    Text('Rename'),
                                  ],
                                ),
                              ),
                              PopupMenuDivider(),
                              PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete_outline, size: 18, color: Color(0xFFCF222E)),
                                    SizedBox(width: 8),
                                    Text('Delete', style: TextStyle(color: Color(0xFFCF222E))),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          onTap: () => _selectCollection(index),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 0,
            right: 0,
            bottom: 0,
            child: _resizeHandle(
              onDrag: (delta) {
                setState(() {
                  _collectionSidebarWidth = (_collectionSidebarWidth + delta).clamp(240.0, 480.0);
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _resizeHandle({required ValueChanged<double> onDrag}) {
    return MouseRegion(
      cursor: SystemMouseCursors.resizeColumn,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onHorizontalDragUpdate: (details) => onDrag(details.delta.dx),
        child: SizedBox(
          width: 10,
          child: Center(
            child: Container(
              width: 2,
              decoration: BoxDecoration(
                color: const Color(0xFFD0D7DE),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNoCollectionState() {
    return Center(
      child: SizedBox(
        width: 520,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.inventory_2_outlined, size: 68, color: Color(0xFF57606A)),
            const SizedBox(height: 18),
            Text(
              'Create a grading collection',
              style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: const Color(0xFF24292F)),
            ),
            const SizedBox(height: 8),
            Text(
              'A collection groups one exam file, one rubric, submissions, AI results, teacher review, and export output.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF57606A), height: 1.5),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _showCreateCollectionDialog,
              icon: const Icon(Icons.add),
              label: const Text('New collection'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF238636),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCollectionWorkspace(GradingCollection collection) {
    return Column(
      children: [
        _buildHeader(collection),
        _buildTabs(),
        Expanded(
          child: switch (_tabIndex) {
            0 => _buildOverview(collection),
            1 => _buildSubmissions(collection),
            2 => _buildRubric(collection),
            3 => _buildGrading(collection),
            _ => _buildExport(collection),
          },
        ),
      ],
    );
  }

  Widget _buildHeader(GradingCollection collection) {
    return Container(
      padding: const EdgeInsets.fromLTRB(28, 18, 28, 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFD0D7DE))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.folder_open_outlined, color: Color(0xFF57606A)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  collection.name,
                  style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: const Color(0xFF24292F)),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              _statusBadge(_statusText(collection.status)),
              const SizedBox(width: 16),
              OutlinedButton.icon(
                onPressed: () => _showCollectionApiKeyDialog(collection),
                icon: Icon(
                  collection.apiKey.trim().isEmpty ? Icons.key_off_outlined : Icons.key_outlined,
                  size: 18,
                ),
                label: Text(collection.apiKey.trim().isEmpty ? 'Set API key' : 'API key set'),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                onPressed: collection.submissions.isEmpty || !_hasAiPending(collection) || _isAiGrading ? null : _gradeAllWithAi,
                icon: const Icon(Icons.smart_toy_outlined, size: 18),
                label: Text(_aiPregradeActionLabel(collection)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F172A),
                  foregroundColor: Colors.white,
                  elevation: 0,
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 220,
                height: 38,
                child: TextField(
                  controller: _markerController,
                  decoration: const InputDecoration(
                    hintText: 'Marker name',
                    prefixIcon: Icon(Icons.person_outline, size: 18),
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton.icon(
                onPressed: _exportData,
                icon: const Icon(Icons.download_outlined, size: 18),
                label: const Text('Export'),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _metric('${collection.totalSubmissions}', 'Submissions'),
              _metric('${collection.aiGradedCount}', 'AI graded'),
              _metric('${collection.reviewedCount}', 'Reviewed'),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    minHeight: 8,
                    value: collection.reviewedProgress,
                    backgroundColor: const Color(0xFFEAEef2),
                    valueColor: const AlwaysStoppedAnimation(Color(0xFF238636)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    const tabs = ['Overview', 'Submissions', 'Rubric', 'Grading', 'Export'];
    return Container(
      height: 48,
      color: Colors.white,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        itemBuilder: (context, index) {
          final selected = index == _tabIndex;
          return InkWell(
            onTap: () {
              _saveCurrentScores();
              setState(() => _tabIndex = index);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: selected ? const Color(0xFFFF7B72) : Colors.transparent, width: 2),
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                tabs[index],
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: const Color(0xFF24292F),
                ),
              ),
            ),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemCount: tabs.length,
      ),
    );
  }

  Widget _buildOverview(GradingCollection collection) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _actionPanel(
                title: 'Exam file',
                subtitle: collection.examFileName ?? 'Import .docx or .txt exam file',
                icon: Icons.description_outlined,
                actionLabel: collection.hasExam ? 'Replace exam' : 'Import exam',
                onPressed: _importExamFile,
              ),
              _actionPanel(
                title: 'Submissions',
                subtitle: collection.submissions.isEmpty ? 'Import ZIP or folder of .txt files' : '${collection.submissions.length} files ready',
                icon: Icons.source_outlined,
                actionLabel: 'Import ZIP',
                onPressed: _importSubmissionsZip,
                secondaryLabel: 'Import folder',
                secondaryAction: _importSubmissionsFolder,
              ),
              _actionPanel(
                title: 'Optional AI pregrade',
                subtitle: collection.hasRubric
                    ? 'Run AI for all submissions, then review one by one.'
                    : 'Uses current criteria. Lecturers can still mark manually.',
                icon: Icons.smart_toy_outlined,
                actionLabel: _aiPregradeActionLabel(collection),
                onPressed: collection.submissions.isEmpty || !_hasAiPending(collection) || _isAiGrading ? null : _gradeAllWithAi,
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text('Recent submissions', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          _submissionTable(collection, limit: 8),
        ],
      ),
    );
  }

  Widget _buildSubmissions(GradingCollection collection) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Submissions', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold)),
              const Spacer(),
              OutlinedButton.icon(onPressed: _importSubmissionsFolder, icon: const Icon(Icons.folder_open), label: const Text('Folder')),
              const SizedBox(width: 8),
              ElevatedButton.icon(onPressed: _importSubmissionsZip, icon: const Icon(Icons.folder_zip), label: const Text('ZIP')),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(child: _submissionTable(collection)),
        ],
      ),
    );
  }

  Widget _buildRubric(GradingCollection collection) {
    final preview = collection.rubricContent ?? collection.examContent ?? '';
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 320,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _actionPanel(
                  title: 'Exam',
                  subtitle: collection.examFileName ?? 'No exam imported',
                  icon: Icons.article_outlined,
                  actionLabel: 'Import exam',
                  onPressed: _importExamFile,
                  fullWidth: true,
                ),
                const SizedBox(height: 14),
                _actionPanel(
                  title: 'Rubric',
                  subtitle: collection.rubricFileName ?? 'Optional. AI can use criteria without it.',
                  icon: Icons.rule_outlined,
                  actionLabel: 'Import rubric',
                  onPressed: _importRubricFile,
                  fullWidth: true,
                ),
                const SizedBox(height: 14),
                _examTypeSelector(collection),
              ],
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: _panelDecoration(),
              child: preview.trim().isEmpty
                  ? const Center(child: Text('No exam or rubric preview yet'))
                  : SingleChildScrollView(
                      child: SelectableText(
                        preview,
                        style: GoogleFonts.firaCode(fontSize: 13, height: 1.5, color: const Color(0xFF24292F)),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrading(GradingCollection collection) {
    if (collection.submissions.isEmpty) {
      return _centerMessage('Import submissions to start grading.');
    }

    return Column(
      children: [
        Container(
          height: 46,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          decoration: const BoxDecoration(
            color: Color(0xFFF6F8FA),
            border: Border(bottom: BorderSide(color: Color(0xFFD0D7DE))),
          ),
          child: Row(
            children: [
              const Icon(Icons.edit_note_outlined, size: 20, color: Color(0xFF57606A)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Manual review is the final marking flow. Optional AI pregrade only prepares suggestions.',
                  style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF57606A), fontWeight: FontWeight.w500),
                ),
              ),
              OutlinedButton.icon(
                onPressed: !_hasAiPending(collection) || _isAiGrading ? null : _gradeAllWithAi,
                icon: const Icon(Icons.smart_toy_outlined, size: 16),
                label: Text(_aiPregradeActionLabel(collection)),
              ),
            ],
          ),
        ),
        if (_isAiGrading) _buildAiGradingProgress(),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SidebarWidget(
                width: _submissionSidebarWidth,
                submissions: collection.submissions,
                currentIndex: _currentIndex,
                onSubmissionSelected: (index) {
                  _saveCurrentScores();
                  setState(() {
                    _currentIndex = index;
                    _loadSubmission(index);
                  });
                },
              ),
              _resizeHandle(
                onDrag: (delta) {
                  setState(() {
                    _submissionSidebarWidth = (_submissionSidebarWidth + delta).clamp(220.0, 460.0);
                  });
                },
              ),
              Expanded(
                child: ContentViewerWidget(
                  submission: collection.submissions[_currentIndex],
                  currentIndex: _currentIndex,
                  totalSubmissions: collection.submissions.length,
                  examTypes: collection.examTypes,
                  onExamTypeChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      collection.submissions[_currentIndex].examType = value;
                      collection.selectedExamType = value;
                      collection.touch();
                      _loadSubmission(_currentIndex);
                    });
                  },
                  onImportDocxRubric: _importRubricFile,
                  onConfigureCriteria: () => _showConfigureCriteriaDialog(
                    collection.submissions[_currentIndex].examType ?? collection.selectedExamType,
                  ),
                  onPrev: _currentIndex > 0 ? _prevSubmission : null,
                  onNext: _currentIndex < collection.submissions.length - 1 ? _nextSubmission : null,
                ),
              ),
              GradingPanelWidget(
                submission: collection.submissions[_currentIndex],
                onAskAi: _askAi,
                onCopyAiToTeacher: _copyAiToTeacher,
                onSaveScores: () {
                  _saveCurrentScores(markComplete: true);
                  if (_currentIndex < collection.submissions.length - 1) {
                    _nextSubmission();
                  } else {
                    setState(() {});
                    _showSnackBar('All submissions reviewed');
                  }
                },
                scoreControllers: _scoreControllers,
                commentController: _commentController,
                hasNext: _currentIndex < collection.submissions.length - 1,
                isAiGrading: _isAiGrading,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildExport(GradingCollection collection) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Export readiness', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 14),
          _checkRow(collection.hasExam, 'Exam file imported'),
          _checkRow(collection.submissions.isNotEmpty, 'Submissions imported'),
          _checkRow(_markerController.text.trim().isNotEmpty, 'Marker name entered'),
          _checkRow(collection.reviewedCount == collection.totalSubmissions && collection.totalSubmissions > 0, 'All submissions reviewed'),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _exportData,
            icon: const Icon(Icons.download_outlined),
            label: const Text('Export Excel'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF238636),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAiGradingProgress() {
    final hasTotal = _aiGradingTotal > 0;
    final progress = hasTotal ? (_aiGradingDone / _aiGradingTotal).clamp(0.0, 1.0) : null;
    final countText = hasTotal ? 'Bài $_aiGradingCurrent / $_aiGradingTotal - Done $_aiGradingDone' : '';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFFEFF6FF),
        border: Border(bottom: BorderSide(color: Color(0xFFBFDBFE))),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2.4),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _aiGradingLabel.isEmpty ? 'AI grading in progress...' : _aiGradingLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1E3A8A),
                  ),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    minHeight: 6,
                    value: progress,
                    backgroundColor: Colors.white,
                    valueColor: const AlwaysStoppedAnimation(Color(0xFF0969DA)),
                  ),
                ),
              ],
            ),
          ),
          if (countText.isNotEmpty) ...[
            const SizedBox(width: 12),
            Text(
              countText,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1E3A8A),
              ),
            ),
          ],
          const SizedBox(width: 12),
          OutlinedButton.icon(
            onPressed: _pauseAiGrading,
            icon: const Icon(Icons.pause_circle_outline, size: 16),
            label: const Text('Pause'),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: _stopAiPregrade,
            icon: const Icon(Icons.stop_circle_outlined, size: 16),
            label: const Text('Stop'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFCF222E),
              side: const BorderSide(color: Color(0xFFFFB3BA)),
            ),
          ),
        ],
      ),
    );
  }

  String _aiPregradeActionLabel(GradingCollection collection) {
    final hasAnyAiResult = collection.submissions.any((sub) => sub.hasAiGraded);
    final hasPending = _hasAiPending(collection);
    if (hasAnyAiResult && hasPending) return 'Continue AI pregrade';
    if (!hasPending && collection.submissions.isNotEmpty) return 'AI pregrade done';
    return 'Optional AI pregrade';
  }

  bool _hasAiPending(GradingCollection collection) {
    return collection.submissions.any((sub) => !sub.hasAiGraded);
  }

  Widget _submissionTable(GradingCollection collection, {int? limit}) {
    final items = limit == null ? collection.submissions : collection.submissions.take(limit).toList();
    if (items.isEmpty) return _centerMessage('No submissions imported.');

    return Container(
      decoration: _panelDecoration(),
      clipBehavior: Clip.antiAlias,
      child: ListView.separated(
        shrinkWrap: limit != null,
        itemCount: items.length,
        separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFD8DEE4)),
        itemBuilder: (context, index) {
          final sub = items[index];
          final realIndex = collection.submissions.indexOf(sub);
          final status = _submissionStatus(sub);
          return ListTile(
            leading: Icon(
              status.icon,
              color: status.color,
            ),
            title: Text(sub.fileName, maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text('AI ${sub.aiTotal.toStringAsFixed(1)} | Teacher ${sub.total.toStringAsFixed(1)}'),
            trailing: _coloredBadge(status.label, status.color),
            onTap: () {
              _saveCurrentScores();
              setState(() {
                _tabIndex = 3;
                _currentIndex = realIndex;
                _loadSubmission(realIndex);
              });
            },
          );
        },
      ),
    );
  }

  _SubmissionStatus _submissionStatus(Submission submission) {
    if (submission.graded) {
      return const _SubmissionStatus(
        label: 'Human complete',
        icon: Icons.check_circle_outline,
        color: Color(0xFF1A7F37),
      );
    }
    if (submission.hasAiGraded) {
      return const _SubmissionStatus(
        label: 'AI graded',
        icon: Icons.smart_toy_outlined,
        color: Color(0xFF2DA44E),
      );
    }
    if (submission.opened) {
      return const _SubmissionStatus(
        label: 'Clicked',
        icon: Icons.pending_outlined,
        color: Color(0xFFBF8700),
      );
    }
    return const _SubmissionStatus(
      label: 'Open',
      icon: Icons.radio_button_unchecked,
      color: Color(0xFF57606A),
    );
  }

  Widget _actionPanel({
    required String title,
    required String subtitle,
    required IconData icon,
    required String actionLabel,
    required VoidCallback? onPressed,
    String? secondaryLabel,
    VoidCallback? secondaryAction,
    bool fullWidth = false,
  }) {
    return Container(
      width: fullWidth ? double.infinity : 330,
      padding: const EdgeInsets.all(18),
      decoration: _panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF57606A)),
              const SizedBox(width: 10),
              Expanded(child: Text(title, style: GoogleFonts.outfit(fontSize: 17, fontWeight: FontWeight.bold))),
            ],
          ),
          const SizedBox(height: 8),
          Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF57606A))),
          const SizedBox(height: 16),
          Row(
            children: [
              ElevatedButton(onPressed: onPressed, child: Text(actionLabel)),
              if (secondaryLabel != null) ...[
                const SizedBox(width: 8),
                OutlinedButton(onPressed: secondaryAction, child: Text(secondaryLabel)),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _examTypeSelector(GradingCollection collection) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Exam criteria', style: GoogleFonts.outfit(fontSize: 17, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          DropdownButtonFormField<ExamType>(
            value: collection.selectedExamType,
            items: collection.examTypes.map((exam) => DropdownMenuItem(value: exam, child: Text('Exam ${exam.code}'))).toList(),
            onChanged: (value) {
              if (value == null) return;
              setState(() {
                collection.selectedExamType = value;
                for (final sub in collection.submissions) {
                  sub.examType ??= value;
                  sub.initScores(sub.examType ?? value);
                }
                collection.touch();
                _loadSubmission(_currentIndex);
              });
            },
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => _showConfigureCriteriaDialog(collection.selectedExamType),
            icon: const Icon(Icons.tune_outlined),
            label: const Text('Configure criteria'),
          ),
        ],
      ),
    );
  }

  Widget _metric(String value, String label) {
    return Padding(
      padding: const EdgeInsets.only(right: 24),
      child: RichText(
        text: TextSpan(
          text: value,
          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF24292F)),
          children: [
            TextSpan(
              text: ' $label',
              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: const Color(0xFF57606A)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFDDF4FF),
        border: Border.all(color: const Color(0xFF54AEFF)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(text, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF0969DA))),
    );
  }

  Widget _coloredBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        border: Border.all(color: color.withValues(alpha: 0.35)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }

  Widget _checkRow(bool ok, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(ok ? Icons.check_circle_outline : Icons.error_outline, color: ok ? const Color(0xFF1A7F37) : const Color(0xFF9A6700)),
          const SizedBox(width: 10),
          Text(text, style: GoogleFonts.inter(fontSize: 14)),
        ],
      ),
    );
  }

  Widget _centerMessage(String message) {
    return Center(
      child: Text(message, style: GoogleFonts.inter(color: const Color(0xFF57606A))),
    );
  }

  BoxDecoration _panelDecoration() {
    return BoxDecoration(
      color: Colors.white,
      border: Border.all(color: const Color(0xFFD0D7DE)),
      borderRadius: BorderRadius.circular(6),
    );
  }

  String _statusText(CollectionStatus status) {
    return switch (status) {
      CollectionStatus.draft => 'Draft',
      CollectionStatus.ready => 'Ready',
      CollectionStatus.grading => 'Grading',
      CollectionStatus.exported => 'Exported',
    };
  }
}

class _SubmissionStatus {
  final String label;
  final IconData icon;
  final Color color;

  const _SubmissionStatus({
    required this.label,
    required this.icon,
    required this.color,
  });
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
    for (final controller in _nameControllers) {
      controller.dispose();
    }
    for (final controller in _scoreControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  double get _total => _scoreControllers.fold(0.0, (sum, controller) => sum + (double.tryParse(controller.text) ?? 0.0));

  void _addCriterion() {
    setState(() {
      _nameControllers.add(TextEditingController(text: 'Question ${_nameControllers.length + 1}'));
      _scoreControllers.add(TextEditingController(text: '10'));
    });
  }

  void _deleteCriterion(int index) {
    setState(() {
      _nameControllers.removeAt(index).dispose();
      _scoreControllers.removeAt(index).dispose();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Configure criteria - Exam ${widget.exam.code}'),
      content: SizedBox(
        width: 540,
        height: 420,
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: _nameControllers.length,
                itemBuilder: (context, index) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: TextField(
                          controller: _nameControllers[index],
                          decoration: const InputDecoration(labelText: 'Name', isDense: true),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: _scoreControllers[index],
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(labelText: 'Points /100', isDense: true),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      IconButton(
                        onPressed: () => _deleteCriterion(index),
                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const Divider(),
            Row(
              children: [
                TextButton.icon(onPressed: _addCriterion, icon: const Icon(Icons.add), label: const Text('Add criterion')),
                const Spacer(),
                Text('Total: ${_total.toStringAsFixed(1)}/100'),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () {
            final criteria = <Criterion>[];
            for (var i = 0; i < _nameControllers.length; i++) {
              final name = _nameControllers[i].text.trim();
              final score = double.tryParse(_scoreControllers[i].text) ?? 0.0;
              criteria.add(Criterion(name.isEmpty ? 'Question ${i + 1}' : name, score.clamp(0.0, 100.0).toDouble()));
            }
            Navigator.pop(context, criteria);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
