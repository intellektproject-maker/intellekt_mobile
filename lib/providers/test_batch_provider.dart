import 'package:flutter/foundation.dart';

import '../services/student/test_batch_service.dart';

class TestBatchProvider extends ChangeNotifier {
  Map<String, dynamic>? _student;
  List<Map<String, dynamic>> _marks = [];
  List<Map<String, dynamic>> _attendance = [];
  bool _isLoading = false;
  String? _error;
  double _attendancePercentage = 0;

  Map<String, dynamic>? get student => _student;
  List<Map<String, dynamic>> get marks => List.unmodifiable(_marks);
  List<Map<String, dynamic>> get attendance => List.unmodifiable(_attendance);
  bool get isLoading => _isLoading;
  String? get error => _error;
  double get attendancePercentage => _attendancePercentage;

  String get registeredSubjects =>
      (_student?['subjects'] ?? '').toString().trim().toLowerCase();

  bool get isMathematicsRegistered {
    final subjects = registeredSubjects;
    return subjects == 'both' || subjects == 'mathematics';
  }

  bool get isPhysicsRegistered {
    final subjects = registeredSubjects;
    return subjects == 'both' || subjects == 'physics';
  }

  Future<void> load(String rollNo) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final studentData = await TestBatchService.getStudent(rollNo);
      final rawStudent = studentData['student'];
      _student = rawStudent is Map
          ? Map<String, dynamic>.from(rawStudent)
          : null;

      if (_student == null) {
        throw Exception('Test Batch student profile was not returned.');
      }

      notifyListeners();

      // The Test Batch student endpoint already returns the student's
      // marks and attendance. Keep the app on that single source of truth.
      final rawMarks = studentData['marks'];
      _marks = rawMarks is List
          ? rawMarks
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList()
          : [];

      final rawAttendance = studentData['attendance'];
      _attendance = rawAttendance is List
          ? rawAttendance
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList()
          : [];

      _attendancePercentage = double.tryParse(
            studentData['attendancePercentage']?.toString() ?? '0',
          ) ??
          0;
    } catch (error) {
      _student = null;
      _marks = [];
      _attendance = [];
      _attendancePercentage = 0;
      _error = error.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
