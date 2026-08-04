class MarkEntry {
  final String rollNo;
  final String studentName;
  final String className;
  final String testCode;
  final int totalMarks;

  int marks;

  MarkEntry({
    required this.rollNo,
    required this.studentName,
    required this.className,
    required this.testCode,
    required this.totalMarks,
    this.marks = 0,
  });

  factory MarkEntry.fromJson(Map<String, dynamic> json) {
    return MarkEntry(
      rollNo: json['rollNo'] ?? '',
      studentName: json['studentName'] ?? '',
      className: json['className'] ?? '',
      testCode: json['testCode'] ?? '',
      totalMarks: json['totalMarks'] ?? 0,
      marks: json['marks'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'rollNo': rollNo,
      'studentName': studentName,
      'className': className,
      'testCode': testCode,
      'totalMarks': totalMarks,
      'marks': marks,
    };
  }
}