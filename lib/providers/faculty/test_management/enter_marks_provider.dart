import 'package:flutter/material.dart';

import '../../../models/mark_entry.dart';
import '../../../models/test_code.dart';
import '../../../services/faculty/test_management/enter_marks_service.dart';

class EnterMarksProvider extends ChangeNotifier {
  final EnterMarksService _service = EnterMarksService();

  bool isLoading = false;
  bool isSaving = false;

  List<MarkEntry> students = [];
  List<TestCode> testCodes = [];
  List<TestCode> filteredTestCodes = [];

  TestCode? selectedTestCode;

  String selectedClass = "XI";
  String selectedBoard = "State Board";
  String selectedSubject = "Mathematics";

  String searchQuery = "";
  String totalMarks = "";

  Future<void> initialize() async {
    await loadStudents();
    await loadTestCodes(
      className: selectedClass,
      board: selectedBoard,
      subject: selectedSubject,
    );
  }

  Future<void> loadStudents() async {
    isLoading = true;
    notifyListeners();

    students = await _service.getStudents();

    isLoading = false;
    notifyListeners();
  }

  Future<void> loadTestCodes({
    required String className,
    required String board,
    required String subject,
  }) async {
    selectedClass = className;
    selectedBoard = board;
    selectedSubject = subject;

    testCodes = await _service.getTestCodes(
      className: className,
      board: board,
      subject: subject,
    );

    _filterTestCodes();
    notifyListeners();
  }

  void updateSearch(String value) {
    searchQuery = value;
    _filterTestCodes();
    notifyListeners();
  }

  void _filterTestCodes() {
    if (searchQuery.trim().isEmpty) {
      filteredTestCodes = List.from(testCodes);
      return;
    }

    filteredTestCodes = testCodes.where((test) {
      return test.code
          .toLowerCase()
          .contains(searchQuery.toLowerCase());
    }).toList();
  }

  void selectTestCode(TestCode code) {
    selectedTestCode = code;
    notifyListeners();
  }

  void updateTotalMarks(String value) {
    totalMarks = value;
    notifyListeners();
  }

  void updateMarks(int index, int marks) {
    students[index].marks = marks;
    notifyListeners();
  }

  Future<void> saveMarks() async {
    isSaving = true;
    notifyListeners();

    await _service.saveMarks(students);

    isSaving = false;
    notifyListeners();
  }

  void clearSelection() {
    selectedTestCode = null;
    totalMarks = "";
    searchQuery = "";
    notifyListeners();
  }
}