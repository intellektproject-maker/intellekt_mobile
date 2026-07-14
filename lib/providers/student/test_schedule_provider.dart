import 'package:flutter/foundation.dart';

import '../../models/test.dart';
import '../../services/student/test_schedule_service.dart';

class TestScheduleProvider extends ChangeNotifier {
  List<Test> _tests = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Test> get tests => _tests;

  bool get isLoading => _isLoading;

  String? get errorMessage => _errorMessage;

  bool get hasError => _errorMessage != null;

  bool get hasTests => _tests.isNotEmpty;

  Future<void> loadTests(String rollNo) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _tests = await TestScheduleService.getTests(rollNo);
    } catch (error) {
      _tests = [];
      _errorMessage = 'Failed to load test schedule';

      debugPrint('Error loading test schedule: $error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshTests(String rollNo) async {
    await loadTests(rollNo);
  }

  Future<List<Map<String, dynamic>>> loadSlots({
    required String testCode,
    required DateTime writingDate,
  }) async {
    return TestScheduleService.getSlots(
      testCode: testCode,
      writingDate: writingDate,
    );
  }

  void registerTest({
    required Test test,
    required DateTime writingDate,
    String? registeredSlotLabel,
  }) {
    _tests = _tests.map((currentTest) {
      if (currentTest.testId == test.testId) {
        return currentTest.copyWith(
          isRegistered: true,
          writingDate: writingDate,
          registeredSlotLabel: registeredSlotLabel ?? 'Flexible timing',
        );
      }

      return currentTest;
    }).toList();

    notifyListeners();
  }

  void clear() {
    _tests = [];
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
  }
}
