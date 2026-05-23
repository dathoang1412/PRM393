import 'exam_type.dart';

class Submission {
  final String fileName;
  final String filePath;
  final String content;
  
  List<double> scores = [];
  String comment = "";
  
  List<double> aiScores = [];
  List<String> aiComments = [];
  String aiComment = "";
  bool hasAiGraded = false;

  bool graded = false;
  ExamType? examType;
  String? marker; // Marker assigned to this submission

  Submission({
    required this.fileName,
    required this.filePath,
    required this.content,
  });

  void initScores(ExamType exam) {
    if (scores.length != exam.criteria.length) {
      final newScores = List.filled(exam.criteria.length, 0.0);
      for (int i = 0; i < exam.criteria.length; i++) {
        if (i < scores.length) {
          newScores[i] = scores[i];
        }
      }
      scores = newScores;
    }
    if (aiScores.length != exam.criteria.length) {
      final newAiScores = List.filled(exam.criteria.length, 0.0);
      for (int i = 0; i < exam.criteria.length; i++) {
        if (i < aiScores.length) {
          newAiScores[i] = aiScores[i];
        }
      }
      aiScores = newAiScores;
    }
    if (aiComments.length != exam.criteria.length) {
      final newAiComments = List.filled(exam.criteria.length, "");
      for (int i = 0; i < exam.criteria.length; i++) {
        if (i < aiComments.length) {
          newAiComments[i] = aiComments[i];
        }
      }
      aiComments = newAiComments;
    }
  }

  double get total => scores.fold(0.0, (sum, s) => sum + s);
  double get aiTotal => aiScores.fold(0.0, (sum, s) => sum + s);
}

