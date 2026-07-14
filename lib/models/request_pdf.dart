class RequestPdfStudent {
  final String name;
  final String rollNo;
  final String studentClass;
  final String board;
  final String phone;

  const RequestPdfStudent({
    required this.name,
    required this.rollNo,
    required this.studentClass,
    required this.board,
    required this.phone,
  });

  factory RequestPdfStudent.fromJson(Map<String, dynamic> json) {
    return RequestPdfStudent(
      name: json['name']?.toString() ?? '',
      rollNo: json['roll_no']?.toString() ?? '',
      studentClass: json['class']?.toString() ?? '',
      board: json['board']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
    );
  }
}

class RequestPdfTest {
  final String testCode;

  const RequestPdfTest({required this.testCode});

  factory RequestPdfTest.fromJson(Map<String, dynamic> json) {
    return RequestPdfTest(testCode: json['test_code']?.toString() ?? '');
  }
}

class RequestPdfData {
  final RequestPdfStudent student;
  final List<RequestPdfTest> tests;

  const RequestPdfData({required this.student, required this.tests});

  factory RequestPdfData.fromJson(Map<String, dynamic> json) {
    final studentJson =
        json['student'] as Map<String, dynamic>? ?? <String, dynamic>{};

    final testsJson = json['tests'] as List<dynamic>? ?? <dynamic>[];

    return RequestPdfData(
      student: RequestPdfStudent.fromJson(studentJson),
      tests: testsJson
          .whereType<Map<String, dynamic>>()
          .map(RequestPdfTest.fromJson)
          .toList(),
    );
  }
}
