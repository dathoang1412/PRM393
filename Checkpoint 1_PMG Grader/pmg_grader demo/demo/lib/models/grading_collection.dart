import 'exam_type.dart';
import 'submission.dart';

enum CollectionStatus {
  draft,
  ready,
  grading,
  exported,
}

class GradingCollection {
  final String id;
  String name;
  String? examFileName;
  String? examContent;
  String? rubricFileName;
  String? rubricContent;
  String apiKey;
  List<Submission> submissions;
  List<ExamType> examTypes;
  ExamType selectedExamType;
  CollectionStatus status;
  DateTime createdAt;
  DateTime updatedAt;

  GradingCollection({
    required this.id,
    required this.name,
    required this.examTypes,
    required this.selectedExamType,
    this.examFileName,
    this.examContent,
    this.rubricFileName,
    this.rubricContent,
    this.apiKey = '',
    List<Submission>? submissions,
    this.status = CollectionStatus.draft,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : submissions = submissions ?? [],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  factory GradingCollection.create(String name) {
    final exams = createDefaultExamTypes();
    return GradingCollection(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: name,
      examTypes: exams,
      selectedExamType: exams.first,
    );
  }

  int get totalSubmissions => submissions.length;
  int get aiGradedCount => submissions.where((sub) => sub.hasAiGraded).length;
  int get reviewedCount => submissions.where((sub) => sub.graded).length;
  bool get hasExam => examContent != null && examContent!.trim().isNotEmpty;
  bool get hasRubric => rubricContent != null && rubricContent!.trim().isNotEmpty;

  double get reviewedProgress {
    if (submissions.isEmpty) return 0;
    return reviewedCount / submissions.length;
  }

  void touch() {
    updatedAt = DateTime.now();
    if (status != CollectionStatus.exported) {
      status = submissions.isEmpty || !hasExam ? CollectionStatus.draft : CollectionStatus.ready;
      if (reviewedCount > 0 || aiGradedCount > 0) {
        status = CollectionStatus.grading;
      }
    }
  }

  void applyRubric(String fileName, String content) {
    rubricFileName = fileName;
    rubricContent = content;
    selectedExamType.customRubric = content;
    touch();
  }

  void applyExam(String fileName, String content) {
    examFileName = fileName;
    examContent = content;
    if (rubricContent == null || rubricContent!.trim().isEmpty) {
      selectedExamType.customRubric = content;
    }
    touch();
  }
}
