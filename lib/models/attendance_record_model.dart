class AttendanceRecordModel {
  final String rollNo;
  final String studentName;
  final String className;
  final String board;
  final String subject;
  final DateTime attendanceDate;
  bool isPresent;

  AttendanceRecordModel({
    required this.rollNo,
    required this.studentName,
    required this.className,
    required this.board,
    required this.subject,
    required this.attendanceDate,
    required this.isPresent,
  });

  factory AttendanceRecordModel.fromJson(
      Map<String, dynamic> json,
      ) {
    return AttendanceRecordModel(
      rollNo: json['roll_no'],
      studentName: json['student_name'],
      className: json['class_name'],
      board: json['board'],
      subject: json['subject'],
      attendanceDate: DateTime.parse(json['attendance_date']),
      isPresent: json['is_present'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'roll_no': rollNo,
      'student_name': studentName,
      'class_name': className,
      'board': board,
      'subject': subject,
      'attendance_date': attendanceDate.toIso8601String(),
      'is_present': isPresent,
    };
  }
}