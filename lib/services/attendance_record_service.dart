import '../models/student_model.dart';
import '../models/attendance_record_model.dart';
import '../repositories/mock/mock_attendance_record_repository.dart';

class AttendanceRecordService {
  AttendanceRecordService._();

  static final AttendanceRecordService instance =
  AttendanceRecordService._();

  final MockAttendanceRecordRepository _repository =
      MockAttendanceRecordRepository.instance;

  /// Load students
  Future<List<StudentModel>> loadStudents({
    required String className,
    required String subject,
  }) {
    return _repository.loadStudents(
      className: className,
      subject: subject,
    );
  }

  /// Save attendance
  Future<void> saveAttendance({
    required List<AttendanceRecordModel> records,
  }) {
    return _repository.saveAttendance(
      records: records,
    );
  }

  /// Today's attendance
  Future<List<AttendanceRecordModel>> getTodayAttendance() {
    return _repository.getTodayAttendance();
  }

  /// Attendance report
  Future<List<AttendanceRecordModel>> getAttendanceReport({
    String? className,
    String? subject,
    String? keyword,
    DateTime? from,
    DateTime? to,
  }) {
    return _repository.getAttendanceReport(
      className: className,
      subject: subject,
      keyword: keyword,
      from: from,
      to: to,
    );
  }

  /// Update attendance
  Future<void> updateAttendance({
    required String rollNo,
    required bool present,
  }) {
    return _repository.updateAttendance(
      rollNo: rollNo,
      present: present,
    );
  }

  /// Refresh today's records
  Future<List<AttendanceRecordModel>> refreshTodayAttendance() {
    return _repository.refreshTodayAttendance();
  }
}