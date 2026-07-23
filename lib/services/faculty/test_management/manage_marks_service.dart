import 'dart:async';

import '../../../data/mock/mock_enter_marks_data.dart';
import '../../../models/mark_entry.dart';

class ManageMarksService {
  Future<List<MarkEntry>> getMarks({
    String? studentName,
    String? className,
    String? testCode,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));

    return mockMarkEntries.where((student) {
      final matchesName = studentName == null ||
          studentName.isEmpty ||
          student.studentName
              .toLowerCase()
              .contains(studentName.toLowerCase());

      final matchesClass = className == null ||
          className.isEmpty ||
          student.className == className;

      final matchesTest = testCode == null ||
          testCode.isEmpty ||
          student.testCode == testCode;

      return matchesName && matchesClass && matchesTest;
    }).toList();
  }

  Future<bool> updateMarks(MarkEntry student) async {
    await Future.delayed(const Duration(milliseconds: 500));

    return true;
  }
}