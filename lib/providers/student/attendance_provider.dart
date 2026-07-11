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
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _attendance =
      await AttendanceService.getAttendance(rollNo);
    } catch (error) {
      _attendance = [];
      _error = error.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}