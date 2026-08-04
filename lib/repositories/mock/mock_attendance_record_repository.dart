import 'package:flutter/foundation.dart';

import '../../data/mock/mock_student_data.dart';
import '../../models/attendance_record_model.dart';
import '../../models/student_model.dart';

class MockAttendanceRecordRepository {
  MockAttendanceRecordRepository._();

  static final MockAttendanceRecordRepository instance =
  MockAttendanceRecordRepository._();

  /// Mock Database
  final List<AttendanceRecordModel> _attendanceRecords = [];

  /// ------------------------------------------
  /// LOAD STUDENTS
  /// ------------------------------------------
  Future<List<StudentModel>> loadStudents({
    required String className,
    required String subject,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));

    return MockStudentData.students.where((student) {
      return student.className == className &&
          student.subject == subject;
    }).toList();
  }

  /// ------------------------------------------
  /// SAVE ATTENDANCE
  /// ------------------------------------------
  Future<void> saveAttendance({
    required List<AttendanceRecordModel> records,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));

    debugPrint("========== SAVE ATTENDANCE ==========");

    for (final record in records) {
      _attendanceRecords.removeWhere(
            (e) =>
        e.rollNo == record.rollNo &&
            e.subject == record.subject &&
            e.attendanceDate.year == record.attendanceDate.year &&
            e.attendanceDate.month == record.attendanceDate.month &&
            e.attendanceDate.day == record.attendanceDate.day,
      );

      _attendanceRecords.add(record);

      debugPrint(
        "SAVE -> "
            "${record.rollNo} | "
            "${record.studentName} | "
            "${record.className} | "
            "${record.subject} | "
            "${record.attendanceDate} | "
            "${record.isPresent ? "Present" : "Absent"}",
      );
    }

    debugPrint(
      "TOTAL RECORDS IN MEMORY : ${_attendanceRecords.length}",
    );

    debugPrint("=====================================");
  }

  /// ------------------------------------------
  /// TODAY ATTENDANCE
  /// ------------------------------------------
  Future<List<AttendanceRecordModel>> getTodayAttendance() async {
    await Future.delayed(const Duration(milliseconds: 250));

    final today = DateTime.now();

    return _attendanceRecords.where((record) {
      return record.attendanceDate.year == today.year &&
          record.attendanceDate.month == today.month &&
          record.attendanceDate.day == today.day;
    }).toList();
  }

  /// ------------------------------------------
  /// ATTENDANCE REPORT
  /// ------------------------------------------
  Future<List<AttendanceRecordModel>> getAttendanceReport({
    String? className,
    String? subject,
    String? keyword,
    DateTime? from,
    DateTime? to,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));

    debugPrint("");
    debugPrint("========== REPORT ==========");
    debugPrint("Stored Records : ${_attendanceRecords.length}");
    debugPrint("Class Filter   : $className");
    debugPrint("Subject Filter : $subject");
    debugPrint("Keyword        : $keyword");
    debugPrint("From           : $from");
    debugPrint("To             : $to");
    debugPrint("");

    final filtered = _attendanceRecords.where((record) {
      bool ok = true;

      if (className != null && className.isNotEmpty) {
        ok &= record.className == className;
      }

      if (subject != null && subject.isNotEmpty) {
        ok &= record.subject == subject;
      }

      if (keyword != null && keyword.isNotEmpty) {
        final search = keyword.toLowerCase();

        ok &= record.rollNo.toLowerCase().contains(search) ||
            record.studentName.toLowerCase().contains(search);
      }

      // Compare ONLY the date portion
      if (from != null) {
        final recordDate = DateTime(
          record.attendanceDate.year,
          record.attendanceDate.month,
          record.attendanceDate.day,
        );

        final fromDate = DateTime(
          from.year,
          from.month,
          from.day,
        );

        ok &= !recordDate.isBefore(fromDate);
      }

      if (to != null) {
        final recordDate = DateTime(
          record.attendanceDate.year,
          record.attendanceDate.month,
          record.attendanceDate.day,
        );

        final toDate = DateTime(
          to.year,
          to.month,
          to.day,
        );

        ok &= !recordDate.isAfter(toDate);
      }

      return ok;
    }).toList();

    debugPrint(
      "FILTERED RECORDS : ${filtered.length}",
    );

    for (final record in filtered) {
      debugPrint(
        "${record.rollNo} | "
            "${record.studentName} | "
            "${record.className} | "
            "${record.subject} | "
            "${record.attendanceDate} | "
            "${record.isPresent ? "Present" : "Absent"}",
      );
    }

    debugPrint("============================");
    debugPrint("");

    return filtered;
  }

  /// ------------------------------------------
  /// UPDATE ATTENDANCE
  /// ------------------------------------------
  Future<void> updateAttendance({
    required String rollNo,
    required bool present,
  }) async {
    await Future.delayed(const Duration(milliseconds: 250));

    final today = DateTime.now();

    for (final record in _attendanceRecords) {
      if (record.rollNo == rollNo &&
          record.attendanceDate.year == today.year &&
          record.attendanceDate.month == today.month &&
          record.attendanceDate.day == today.day) {
        record.isPresent = present;
      }
    }
  }

  /// ------------------------------------------
  /// REFRESH TODAY ATTENDANCE
  /// ------------------------------------------
  Future<List<AttendanceRecordModel>> refreshTodayAttendance() async {
    return getTodayAttendance();
  }
}