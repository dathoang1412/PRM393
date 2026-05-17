import 'exam_type.dart';

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
