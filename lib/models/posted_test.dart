class PostedTest {
  final String testCode;
  final int subjectId;
  final String subjectName;
  final DateTime testDate;
  final int totalMarks;
  final String portion;
  final String chapter;
  final String createdBy;
  final String className;
  final String board;
  final int durationMinutes;
  final DateTime registrationEndDate;
  final DateTime writingAllowedTill;

  const PostedTest({
    required this.testCode,
    required this.subjectId,
    required this.subjectName,
    required this.testDate,
    required this.totalMarks,
    required this.portion,
    required this.chapter,
    required this.createdBy,
    required this.className,
    required this.board,
    required this.durationMinutes,
    required this.registrationEndDate,
    required this.writingAllowedTill,
  });

  factory PostedTest.fromJson(Map<String, dynamic> json) {
    return PostedTest(
      testCode: json['testCode'] ?? '',
      subjectId: json['subjectId'] ?? 0,
      subjectName: json['subjectName'] ?? '',
      testDate: DateTime.parse(json['testDate']),
      totalMarks: json['totalMarks'] ?? 0,
      portion: json['portion'] ?? '',
      chapter: json['chapter'] ?? '',
      createdBy: json['createdBy'] ?? '',
      className: json['className'] ?? '',
      board: json['board'] ?? '',
      durationMinutes: json['durationMinutes'] ?? 0,
      registrationEndDate: DateTime.parse(
        json['registrationEndDate'],
      ),
      writingAllowedTill: DateTime.parse(
        json['writingAllowedTill'],
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'testCode': testCode,
      'subjectId': subjectId,
      'subjectName': subjectName,
      'testDate': testDate.toIso8601String(),
      'totalMarks': totalMarks,
      'portion': portion,
      'chapter': chapter,
      'createdBy': createdBy,
      'className': className,
      'board': board,
      'durationMinutes': durationMinutes,
      'registrationEndDate':
      registrationEndDate.toIso8601String(),
      'writingAllowedTill':
      writingAllowedTill.toIso8601String(),
    };
  }

  PostedTest copyWith({
    String? testCode,
    int? subjectId,
    String? subjectName,
    DateTime? testDate,
    int? totalMarks,
    String? portion,
    String? chapter,
    String? createdBy,
    String? className,
    String? board,
    int? durationMinutes,
    DateTime? registrationEndDate,
    DateTime? writingAllowedTill,
  }) {
    return PostedTest(
      testCode: testCode ?? this.testCode,
      subjectId: subjectId ?? this.subjectId,
      subjectName: subjectName ?? this.subjectName,
      testDate: testDate ?? this.testDate,
      totalMarks: totalMarks ?? this.totalMarks,
      portion: portion ?? this.portion,
      chapter: chapter ?? this.chapter,
      createdBy: createdBy ?? this.createdBy,
      className: className ?? this.className,
      board: board ?? this.board,
      durationMinutes:
      durationMinutes ?? this.durationMinutes,
      registrationEndDate:
      registrationEndDate ??
          this.registrationEndDate,
      writingAllowedTill:
      writingAllowedTill ??
          this.writingAllowedTill,
    );
  }
}