class ExamType {
  String code;
  List<String> criteria;
  String? customRubric;
  
  ExamType(this.code, this.criteria, {this.customRubric});
}

final List<ExamType> defaultExamTypes = [
  ExamType('Type A', ['Criterion A1', 'Criterion A2', 'Criterion A3']),
  ExamType('Type B', ['Criterion B1', 'Criterion B2', 'Criterion B3']),
  ExamType('Type C', ['Criterion C1', 'Criterion C2', 'Criterion C3']),
];
