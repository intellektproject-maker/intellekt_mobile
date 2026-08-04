import '../../../data/mock/mock_enter_marks_data.dart';
import '../../../data/mock/mock_test_codes.dart';
import '../../../models/mark_entry.dart';
import '../../../models/test_code.dart';

class EnterMarksService {
  /// Load students
  Future<List<MarkEntry>> getStudents() async {
    await Future.delayed(const Duration(milliseconds: 600));

    return mockMarkEntries;
  }

  /// Load test codes based on filters
  Future<List<TestCode>> getTestCodes({
    required String className,
    required String board,
    required String subject,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));

    final result = mockTestCodes.where((e) {
      return e.className == className &&
          e.board == board &&
          e.subject == subject;
    }).toList();

    print("Found ${result.length} test codes");

    return result;
  }

  /// Save marks
  Future<bool> saveMarks(List<MarkEntry> students) async {
    await Future.delayed(const Duration(seconds: 1));

    return true;
  }
}