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

      try {
        _marks = await TestBatchService.getMarks(rollNo);
      } catch (error) {
        debugPrint('Could not load Test Batch marks: $error');
        _marks = [];
      }

      try {
        final attendanceData = await TestBatchService.getAttendance(rollNo);
        final rawAttendance = attendanceData['attendance'];
        _attendance = rawAttendance is List
            ? rawAttendance
                .map((item) => Map<String, dynamic>.from(item as Map))
                .toList()
            : [];
        _attendancePercentage = double.tryParse(
              attendanceData['attendancePercentage']?.toString() ?? '0',
            ) ??
            0;
      } catch (error) {
        debugPrint('Could not load Test Batch attendance: $error');
        _attendance = [];
        _attendancePercentage = 0;
      }
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
