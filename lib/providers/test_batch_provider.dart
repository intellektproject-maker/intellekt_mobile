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
      final marksData = await TestBatchService.getMarks(rollNo);
      final attendanceData = await TestBatchService.getAttendance(rollNo);
      final rawStudent = studentData['student'];
      _student = rawStudent is Map ? Map<String, dynamic>.from(rawStudent) : null;
      _marks = marksData;
      final rawAttendance = attendanceData['attendance'];
      _attendance = rawAttendance is List
          ? rawAttendance.map((item) => Map<String, dynamic>.from(item as Map)).toList()
          : [];
      _attendancePercentage = double.tryParse(
            attendanceData['attendancePercentage']?.toString() ?? '0',
          ) ?? 0;
    } catch (error) {
      _error = error.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
