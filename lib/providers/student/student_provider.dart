import 'package:flutter/material.dart';

import '../../services/student/student_service.dart';

class StudentProvider extends ChangeNotifier {
  Map<String, dynamic>? _student;
  bool _isLoading = false;
  String? _error;

  Map<String, dynamic>? get student => _student;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadStudent(String rollNo) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _student = await StudentService.getStudent(rollNo);
    } catch (error) {
      _student = null;
      _error = error.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}