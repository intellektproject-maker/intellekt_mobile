import 'package:flutter/material.dart';

import '../../services/student/marks_service.dart';

class MarksProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _marks = [];
  bool _isLoading = false;
  String? _error;

  List<Map<String, dynamic>> get marks => _marks;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadMarks(String rollNo) async {
    final studentId = rollNo.trim().toUpperCase();

    if (studentId.isEmpty) {
      _marks = [];
      _error = 'Student ID is missing.';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _marks = await MarksService.getMarks(studentId);
    } catch (error) {
      _marks = [];
      _error = error.toString().replaceFirst(
        'Exception: ',
        '',
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  double get mathsAverage {
    return _calculateSubjectAverage(
      subjectId: 1,
      acceptedNames: const [
        'maths',
        'mathematics',
      ],
    );
  }

  double get physicsAverage {
    return _calculateSubjectAverage(
      subjectId: 2,
      acceptedNames: const [
        'physics',
      ],
    );
  }

  double _calculateSubjectAverage({
    required int subjectId,
    required List<String> acceptedNames,
  }) {
    final subjectMarks = _marks.where((mark) {
      final recordSubjectId = int.tryParse(
        mark['subject_id']?.toString() ?? '',
      );

      final subjectName = mark['subject_name']
          ?.toString()
          .trim()
          .toLowerCase();

      return recordSubjectId == subjectId ||
          acceptedNames.contains(subjectName);
    }).toList();

    if (subjectMarks.isEmpty) {
      return 0;
    }

    double percentageTotal = 0;

    for (final mark in subjectMarks) {
      final obtainedValue =
          mark['marks_obtained']?.toString().trim() ?? '';

      final totalMarks = double.tryParse(
        mark['total_marks']?.toString() ?? '',
      );

      final obtainedMarks =
      obtainedValue.toUpperCase() == 'A'
          ? 0.0
          : double.tryParse(obtainedValue);

      if (obtainedMarks == null ||
          totalMarks == null ||
          totalMarks <= 0) {
        continue;
      }

      percentageTotal +=
          (obtainedMarks / totalMarks) * 100;
    }

    return percentageTotal / subjectMarks.length;
  }

  String get dashboardValue {
    return 'M: ${mathsAverage.toStringAsFixed(1)}% | '
        'P: ${physicsAverage.toStringAsFixed(1)}%';
  }
}