class AttendanceStudentModel {
  final String rollNo;
  final String name;
  final String board;
  final String className;
  final int subjectId;
  final String testCode;

  String status;

  AttendanceStudentModel({
    required this.rollNo,
    required this.name,
    required this.board,
    required this.className,
    required this.subjectId,
    required this.testCode,
    this.status = 'Present',
  });

  factory AttendanceStudentModel.fromJson(
      Map<String, dynamic> json,
      ) {
    return AttendanceStudentModel(
      rollNo: json['roll_no'] ?? '',
      name: json['name'] ?? '',
      board: json['board'] ?? '',
      className: json['class'] ?? '',
      subjectId: json['subject_id'] ?? 0,
      testCode: json['test_code'] ?? '',
      status: json['status'] ?? 'Present',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'roll_no': rollNo,
      'name': name,
      'board': board,
      'class': className,
      'subject_id': subjectId,
      'test_code': testCode,
      'status': status,
    };
  }

  AttendanceStudentModel copyWith({
    String? status,
  }) {
    return AttendanceStudentModel(
      rollNo: rollNo,
      name: name,
      board: board,
      className: className,
      subjectId: subjectId,
      testCode: testCode,
      status: status ?? this.status,
    );
  }
}