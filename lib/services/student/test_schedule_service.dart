import '../../data/mock/mock_test_schedule_data.dart';
import '../../data/mock/mock_test_slots_data.dart';
import '../../models/test.dart';

class TestScheduleService {
  TestScheduleService._();

  static Future<List<Test>> getTests(String rollNo) async {
    await Future.delayed(const Duration(milliseconds: 500));

    return mockTestScheduleData
        .map(Test.fromJson)
        .where(_isActiveTest)
        .toList();
  }

  static Future<List<Map<String, dynamic>>> getSlots({
    required String testCode,
    required DateTime writingDate,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final slots = mockTestSlotsData[testCode];

    if (slots == null) {
      return [];
    }

    return List<Map<String, dynamic>>.from(slots);
  }

  static bool _isActiveTest(Test test) {
    final writingAllowedTill = test.writingAllowedTill;

    if (writingAllowedTill == null) {
      return false;
    }

    final now = DateTime.now();

    final today = DateTime(now.year, now.month, now.day);

    final writingTill = DateTime(
      writingAllowedTill.year,
      writingAllowedTill.month,
      writingAllowedTill.day,
    );

    return !writingTill.isBefore(today);
  }
}
