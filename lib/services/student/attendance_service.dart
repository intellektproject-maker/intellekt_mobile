import '../../data/mock/mock_attendance_data.dart';

class AttendanceService {
  AttendanceService._();

  static Future<List<Map<String, dynamic>>> getAttendance(
      String rollNo,
      ) async {
    // Simulates API loading time.
    await Future.delayed(
      const Duration(milliseconds: 500),
    );

    return mockAttendanceData
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }
}