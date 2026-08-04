import 'package:flutter/material.dart';

import '../../services/student/attendance_service.dart';

class AttendanceProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _attendance = [];
  bool _isLoading = false;
  String? _error;

  List<Map<String, dynamic>> get attendance => _attendance;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadAttendance(String rollNo) async {
    final studentId = rollNo.trim().toUpperCase();

    if (studentId.isEmpty) {
      _attendance = [];
      _error = 'Student ID is missing.';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _attendance =
      await AttendanceService.getAttendance(studentId);
    } catch (error) {
      _attendance = [];
      _error = error.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  double get attendancePercentage {
    final validRecords = _attendance.where((record) {
      final status =
      record['status']?.toString().trim().toLowerCase();

      return status == 'present' || status == 'absent';
    }).toList();

    if (validRecords.isEmpty) {
      return 0;
    }

    final presentCount = validRecords.where((record) {
      final status =
      record['status']?.toString().trim().toLowerCase();

      return status == 'present';
    }).length;

    return (presentCount / validRecords.length) * 100;
  }
}