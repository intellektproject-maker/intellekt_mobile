import '../../data/mock/mock_marks_data.dart';

class MarksService {
  MarksService._();

  static Future<List<Map<String, dynamic>>> getMarks(
      String rollNo,
      ) async {
    await Future.delayed(
      const Duration(milliseconds: 500),
    );

    return List<Map<String, dynamic>>.from(mockMarksData);
  }
}