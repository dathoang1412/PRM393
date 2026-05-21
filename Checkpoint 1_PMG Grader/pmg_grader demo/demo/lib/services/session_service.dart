import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class GradingSession {
  final String id;
  final String name;
  final DateTime createdAt;
  final DateTime lastModified;

  // File paths
  final String? gradingGuideDocPath;
  final String? markInputXlsxPath;
  final String? examImagePath;
  final String? studentZipPath;

  // Derived info
  final String? examCode;
  final String? markerName;
  final int totalStudents;
  final int gradedCount;

  GradingSession({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.lastModified,
    this.gradingGuideDocPath,
    this.markInputXlsxPath,
    this.examImagePath,
    this.studentZipPath,
    this.examCode,
    this.markerName,
    this.totalStudents = 0,
    this.gradedCount = 0,
  });

  bool get isComplete =>
      gradingGuideDocPath != null &&
      markInputXlsxPath != null &&
      examImagePath != null &&
      studentZipPath != null;

  double get progress =>
      totalStudents == 0 ? 0.0 : gradedCount / totalStudents;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'createdAt': createdAt.toIso8601String(),
        'lastModified': lastModified.toIso8601String(),
        'gradingGuideDocPath': gradingGuideDocPath,
        'markInputXlsxPath': markInputXlsxPath,
        'examImagePath': examImagePath,
        'studentZipPath': studentZipPath,
        'examCode': examCode,
        'markerName': markerName,
        'totalStudents': totalStudents,
        'gradedCount': gradedCount,
      };

  factory GradingSession.fromJson(Map<String, dynamic> json) => GradingSession(
        id: json['id'] as String,
        name: json['name'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        lastModified: DateTime.parse(json['lastModified'] as String),
        gradingGuideDocPath: json['gradingGuideDocPath'] as String?,
        markInputXlsxPath: json['markInputXlsxPath'] as String?,
        examImagePath: json['examImagePath'] as String?,
        studentZipPath: json['studentZipPath'] as String?,
        examCode: json['examCode'] as String?,
        markerName: json['markerName'] as String?,
        totalStudents: json['totalStudents'] as int? ?? 0,
        gradedCount: json['gradedCount'] as int? ?? 0,
      );

  GradingSession copyWith({
    String? name,
    DateTime? lastModified,
    String? gradingGuideDocPath,
    String? markInputXlsxPath,
    String? examImagePath,
    String? studentZipPath,
    String? examCode,
    String? markerName,
    int? totalStudents,
    int? gradedCount,
  }) =>
      GradingSession(
        id: id,
        name: name ?? this.name,
        createdAt: createdAt,
        lastModified: lastModified ?? this.lastModified,
        gradingGuideDocPath: gradingGuideDocPath ?? this.gradingGuideDocPath,
        markInputXlsxPath: markInputXlsxPath ?? this.markInputXlsxPath,
        examImagePath: examImagePath ?? this.examImagePath,
        studentZipPath: studentZipPath ?? this.studentZipPath,
        examCode: examCode ?? this.examCode,
        markerName: markerName ?? this.markerName,
        totalStudents: totalStudents ?? this.totalStudents,
        gradedCount: gradedCount ?? this.gradedCount,
      );
}

class SessionService {
  static const _sessionsKey = 'pmg_grader_sessions';

  Future<List<GradingSession>> loadSessions() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_sessionsKey);
    if (raw == null) return [];
    try {
      final List<dynamic> decoded = jsonDecode(raw);
      return decoded
          .map((e) => GradingSession.fromJson(e as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => b.lastModified.compareTo(a.lastModified));
    } catch (_) {
      return [];
    }
  }

  Future<void> saveSession(GradingSession session) async {
    final prefs = await SharedPreferences.getInstance();
    final sessions = await loadSessions();
    final idx = sessions.indexWhere((s) => s.id == session.id);
    if (idx >= 0) {
      sessions[idx] = session;
    } else {
      sessions.insert(0, session);
    }
    await prefs.setString(
        _sessionsKey, jsonEncode(sessions.map((s) => s.toJson()).toList()));
  }

  Future<void> deleteSession(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final sessions = await loadSessions();
    sessions.removeWhere((s) => s.id == id);
    await prefs.setString(
        _sessionsKey, jsonEncode(sessions.map((s) => s.toJson()).toList()));
    await deleteSessionProgress(id);
  }

  Future<Map<String, dynamic>?> loadSessionProgress(String sessionId) async {
    try {
      final appData = await getApplicationSupportDirectory();
      final file = File(p.join(appData.path, 'PMG_Grader_Data', 'session_${sessionId}_progress.json'));
      if (await file.exists()) {
        final content = await file.readAsString();
        return jsonDecode(content) as Map<String, dynamic>;
      }
    } catch (e) {
      // Ignore
    }
    return null;
  }

  Future<void> saveSessionProgress(String sessionId, Map<String, dynamic> data) async {
    try {
      final appData = await getApplicationSupportDirectory();
      final file = File(p.join(appData.path, 'PMG_Grader_Data', 'session_${sessionId}_progress.json'));
      await file.create(recursive: true);
      await file.writeAsString(jsonEncode(data));
    } catch (e) {
      // Ignore
    }
  }

  Future<void> deleteSessionProgress(String sessionId) async {
    try {
      final appData = await getApplicationSupportDirectory();
      final file = File(p.join(appData.path, 'PMG_Grader_Data', 'session_${sessionId}_progress.json'));
      if (await file.exists()) {
        await file.delete();
      }
      // Also delete extracted zip folder to save disk space
      final extractDir = Directory(p.join(appData.path, 'PMG_Grader_Data', 'Extracted_$sessionId'));
      if (await extractDir.exists()) {
        await extractDir.delete(recursive: true);
      }
    } catch (e) {
      // Ignore
    }
  }

  GradingSession createNewSession() {
    final now = DateTime.now();
    return GradingSession(
      id: now.millisecondsSinceEpoch.toString(),
      name: 'Phiên chấm ${_formatDate(now)}',
      createdAt: now,
      lastModified: now,
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/'
        '${dt.month.toString().padLeft(2, '0')}/'
        '${dt.year} '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }
}
