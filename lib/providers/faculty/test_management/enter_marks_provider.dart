import 'package:flutter/material.dart';

import '../../../models/mark_entry.dart';
import '../../../models/test_code.dart';
import '../../../services/faculty/test_management/enter_marks_service.dart';

class EnterMarksProvider extends ChangeNotifier {
  final EnterMarksService _service = EnterMarksService();

  bool isLoading = false;
  bool isSaving = false;
  bool studentsLoaded = false;

  List<MarkEntry> students = [];
  List<TestCode> testCodes = [];
  List<TestCode> filteredTestCodes = [];

  TestCode? selectedTestCode;

  String selectedClass = "XI";
  String selectedBoard = "State Board";
  String selectedSubject = "Mathematics";

  String searchQuery = "";
  String totalMarks = "";

  /// Initial page load
  Future<void> initialize() async {
    await loadTestCodes(
      className: selectedClass,
      board: selectedBoard,
      subject: selectedSubject,
    );
  }

  /// Load students only when the button is pressed
  Future<void> loadStudents() async {
    if (selectedTestCode == null) return;

    isLoading = true;
    notifyListeners();

    students = await _service.getStudents();

    studentsLoaded = true;

    isLoading = false;
    notifyListeners();
  }

  /// Load test codes according to filters
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

    selectedTestCode = null;
    studentsLoaded = false;
    students.clear();

    notifyListeners();
  }

  /// Search test code
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

  /// Select a test code
  void selectTestCode(TestCode code) {
    selectedTestCode = code;

    studentsLoaded = false;
    students.clear();

    notifyListeners();
  }

  /// Total marks
  void updateTotalMarks(String value) {
    totalMarks = value;
    notifyListeners();
  }

  /// Update marks
  void updateMarks(int index, int marks) {
    students[index].marks = marks;
    notifyListeners();
  }

  /// Save marks
  Future<void> saveMarks() async {
    if (!studentsLoaded) return;

    isSaving = true;
    notifyListeners();

    await _service.saveMarks(students);

    isSaving = false;
    notifyListeners();
  }

  /// Reset everything
  void clearSelection() {
    selectedTestCode = null;
    studentsLoaded = false;
    students.clear();

    totalMarks = "";
    searchQuery = "";

    _filterTestCodes();

    notifyListeners();
  }
}