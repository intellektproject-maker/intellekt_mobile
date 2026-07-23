import 'package:flutter/material.dart';

import '../../../models/mark_entry.dart';
import '../../../services/faculty/test_management/manage_marks_service.dart';

class ManageMarksProvider extends ChangeNotifier {
  final ManageMarksService _service = ManageMarksService();

  bool isLoading = false;
  bool isSaving = false;

  List<MarkEntry> students = [];

  String studentName = '';
  String className = '';
  String testCode = '';

  Future<void> searchMarks() async {
    isLoading = true;
    notifyListeners();

    students = await _service.getMarks(
      studentName: studentName,
      className: className,
      testCode: testCode,
    );

    isLoading = false;
    notifyListeners();
  }

  void updateStudentName(String value) {
    studentName = value;
  }

  void updateClass(String value) {
    className = value;
    notifyListeners();
  }

  void updateTestCode(String value) {
    testCode = value;
    notifyListeners();
  }

  void updateMarks(int index, int marks) {
    students[index].marks = marks;
    notifyListeners();
  }

  Future<bool> saveMarks() async {
    isSaving = true;
    notifyListeners();

    for (final student in students) {
      await _service.updateMarks(student);
    }

    isSaving = false;
    notifyListeners();

    return true;
  }

  void clearFilters() {
    studentName = '';
    className = '';
    testCode = '';
    students.clear();

    notifyListeners();
  }
}