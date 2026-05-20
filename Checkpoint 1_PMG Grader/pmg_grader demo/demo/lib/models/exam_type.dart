class Criterion {
  final String name;
  final double maxScore100;

  Criterion(this.name, this.maxScore100);

  double get maxScore10 => maxScore100 / 10;
}

class ExamType {
  String code;
  List<Criterion> criteria;
  String? customRubric;
  
  ExamType(this.code, this.criteria, {this.customRubric});

  double get totalMaxScore10 => criteria.fold(0.0, (sum, c) => sum + c.maxScore10);
}

final List<ExamType> defaultExamTypes = [
  ExamType('1', [
    Criterion('Question 1', 20),
    Criterion('Question 2', 20),
    Criterion('Question 3', 30),
    Criterion('Question 4', 30),
  ]),
  ExamType('2', [
    Criterion('Question 1', 30),
    Criterion('Question 2', 30),
    Criterion('Question 3', 40),
  ]),
  ExamType('3', [
    Criterion('Question 1', 30),
    Criterion('Question 2', 30),
    Criterion('Question 3', 40),
  ]),
];

