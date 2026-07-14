class Test {
  final int? testId;
  final String? testName;
  final String? testCode;
  final int? subjectId;
  final String? subjectName;
  final DateTime? testDate;
  final int? totalMarks;
  final int? durationMinutes;
  final DateTime? registrationEndDate;
  final DateTime? writingAllowedTill;
  final String? portion;
  final bool isRegistered;
  final DateTime? writingDate;
  final String? registeredSlotLabel;

  const Test({
    this.testId,
    this.testName,
    this.testCode,
    this.subjectId,
    this.subjectName,
    this.testDate,
    this.totalMarks,
    this.durationMinutes,
    this.registrationEndDate,
    this.writingAllowedTill,
    this.portion,
    this.isRegistered = false,
    this.writingDate,
    this.registeredSlotLabel,
  });

  factory Test.fromJson(Map<String, dynamic> json) {
    return Test(
      testId: json['test_id'] as int?,
      testName: json['test_name'] as String?,
      testCode: json['test_code'] as String?,
      subjectId: json['subject_id'] as int?,
      subjectName: json['subject_name'] as String?,
      testDate: _parseDate(json['test_date']),
      totalMarks: json['total_marks'] as int?,
      durationMinutes: json['duration_minutes'] as int?,
      registrationEndDate: _parseDate(json['registration_end_date']),
      writingAllowedTill: _parseDate(json['writing_allowed_till']),
      portion: json['portion'] as String?,
      isRegistered: json['is_registered'] == true,
      writingDate: _parseDate(json['writing_date']),
      registeredSlotLabel: json['registered_slot_label'] as String?,
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) {
      return null;
    }

    return DateTime.tryParse(value.toString());
  }

  Test copyWith({
    int? testId,
    String? testName,
    String? testCode,
    int? subjectId,
    String? subjectName,
    DateTime? testDate,
    int? totalMarks,
    int? durationMinutes,
    DateTime? registrationEndDate,
    DateTime? writingAllowedTill,
    String? portion,
    bool? isRegistered,
    DateTime? writingDate,
    String? registeredSlotLabel,
  }) {
    return Test(
      testId: testId ?? this.testId,
      testName: testName ?? this.testName,
      testCode: testCode ?? this.testCode,
      subjectId: subjectId ?? this.subjectId,
      subjectName: subjectName ?? this.subjectName,
      testDate: testDate ?? this.testDate,
      totalMarks: totalMarks ?? this.totalMarks,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      registrationEndDate: registrationEndDate ?? this.registrationEndDate,
      writingAllowedTill: writingAllowedTill ?? this.writingAllowedTill,
      portion: portion ?? this.portion,
      isRegistered: isRegistered ?? this.isRegistered,
      writingDate: writingDate ?? this.writingDate,
      registeredSlotLabel: registeredSlotLabel ?? this.registeredSlotLabel,
    );
  }
}
