import 'package:dio/dio.dart';

import '../core/api/api_client.dart';
import '../models/faculty_model.dart';
import '../models/faculty_task_model.dart';

class FacultyTaskRepository {
  final Dio _dio = ApiClient().dio;

  List<FacultyTaskModel> _parseList(dynamic data) {
    if (data is! List) return <FacultyTaskModel>[];

    return data.whereType<Map>().map<FacultyTaskModel>((item) {
      return FacultyTaskModel.fromJson(Map<String, dynamic>.from(item));
    }).toList(growable: false);
  }

  List<Map<String, dynamic>> _parseNotificationList(dynamic data) {
    if (data is! List) return <Map<String, dynamic>>[];

    return data.whereType<Map>().map<Map<String, dynamic>>((item) {
      return Map<String, dynamic>.from(item);
    }).toList(growable: false);
  }

  List<FacultyModel> _parseFacultyList(dynamic data) {
    if (data is! List) return <FacultyModel>[];

    return data.whereType<Map>().map<FacultyModel>((item) {
      return FacultyModel.fromJson(Map<String, dynamic>.from(item));
    }).toList(growable: false);
  }

  List<String> _parseTestCodes(dynamic data) {
    if (data is! List) return <String>[];

    return data
        .whereType<Map>()
        .map<String>((item) => item['test_code']?.toString() ?? '')
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList(growable: false);
  }

  String _errorMessage(DioException e, String fallback) {
    final data = e.response?.data;
    if (data is Map) {
      final value = data['error'] ?? data['message'] ?? data['details'];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString();
      }
    }
    return fallback;
  }

  Future<List<FacultyTaskModel>> getMyTasks(String facultyId) async {
    try {
      final response = await _dio.get('/faculty-tasks/${facultyId.trim().toUpperCase()}');
      return _parseList(response.data);
    } on DioException catch (e) {
      throw Exception(_errorMessage(e, 'Unable to load faculty tasks.'));
    }
  }

  Future<List<FacultyTaskModel>> getAllTasks(String loginFacultyId) async {
    try {
      final response = await _dio.get('/faculty-tasks-all', queryParameters: {'loginFacultyId': loginFacultyId.trim().toUpperCase()});
      return _parseList(response.data);
    } on DioException catch (e) {
      throw Exception(_errorMessage(e, 'Unable to load all faculty tasks.'));
    }
  }

  Future<List<FacultyTaskModel>> getDailyTasks(String loginFacultyId) async {
    try {
      final response = await _dio.get('/faculty-daily-tasks-all', queryParameters: {'loginFacultyId': loginFacultyId.trim().toUpperCase()});
      return _parseList(response.data);
    } on DioException catch (e) {
      throw Exception(_errorMessage(e, 'Unable to load daily faculty tasks.'));
    }
  }

  Future<void> updateTaskStatus(int taskId, bool completed) async {
    try {
      await _dio.put('/faculty-tasks/$taskId', data: {'is_completed': completed});
    } on DioException catch (e) {
      throw Exception(_errorMessage(e, 'Unable to update task.'));
    }
  }

  Future<void> deleteTask(int taskId, String loginFacultyId) async {
    try {
      await _dio.delete('/faculty-tasks/$taskId', queryParameters: {'loginFacultyId': loginFacultyId.trim().toUpperCase()});
    } on DioException catch (e) {
      throw Exception(_errorMessage(e, 'Unable to delete task.'));
    }
  }

  Future<void> reassignTask({required int taskId, required String facultyId, required String facultyName}) async {
    try {
      await _dio.put('/faculty-tasks/$taskId', data: {'faculty_id': facultyId.trim().toUpperCase(), 'faculty_name': facultyName});
    } on DioException catch (e) {
      throw Exception(_errorMessage(e, 'Unable to reassign task.'));
    }
  }

  Future<void> assignTask({required String loginFacultyId, required String facultyId, required String facultyName, required String className, required String subjectName, required String totalTestNote, required String otherTasks, required String? dueDate, required String priority, required String taskType}) async {
    try {
      await _dio.post('/faculty-tasks', data: {
        'loginFacultyId': loginFacultyId.trim().toUpperCase(),
        'faculty_id': facultyId.trim().toUpperCase(),
        'faculty_name': facultyName,
        'class_name': className,
        'subject_name': subjectName,
        'total_test_note': totalTestNote,
        'other_tasks': otherTasks,
        'due_date': taskType == 'Daily' ? null : dueDate,
        'priority': taskType == 'Daily' ? 'High' : priority,
        'task_type': taskType,
      });
    } on DioException catch (e) {
      throw Exception(_errorMessage(e, 'Failed to assign task.'));
    }
  }

  Future<List<FacultyModel>> getFacultyList() async {
    try {
      final response = await _dio.get('/faculty');
      return _parseFacultyList(response.data);
    } on DioException catch (e) {
      throw Exception(_errorMessage(e, 'Unable to load faculty list.'));
    }
  }

  Future<List<String>> getClassOptions() async {
    try {
      final response = await _dio.get('/classes');
      if (response.data is! List) return <String>['Others'];
      final values = <String>{};
      for (final item in response.data.whereType<Map>()) {
        final map = Map<String, dynamic>.from(item);
        final board = map['board']?.toString() ?? '';
        final cls = (map['class'] ?? map['class_name'])?.toString() ?? '';
        if (board.isNotEmpty && cls.isNotEmpty) values.add('$board-$cls');
      }
      return [...values, 'Others'];
    } on DioException {
      return <String>['Others'];
    }
  }

  Future<List<String>> getTestCodes() async {
    try {
      final response = await _dio.get('/tests');
      return _parseTestCodes(response.data);
    } on DioException {
      return <String>[];
    }
  }

  Future<List<Map<String, dynamic>>> getFacultyNotifications(String facultyId) async {
    try {
      final response = await _dio.get('/faculty-notifications/${facultyId.trim().toUpperCase()}');
      return _parseNotificationList(response.data);
    } on DioException {
      return <Map<String, dynamic>>[];
    }
  }

  Future<void> markNotificationRead({required String facultyId, required String moduleName}) async {
    try {
      await _dio.put('/faculty-notifications/mark-read/${facultyId.trim().toUpperCase()}/$moduleName');
    } on DioException {
      // Legacy compatibility endpoint.
    }
  }

  Future<void> markSingleNotificationRead({required String facultyId, required int notificationId}) async {
    try {
      await _dio.put('/faculty-notifications/read/${facultyId.trim().toUpperCase()}/$notificationId');
    } on DioException catch (e) {
      throw Exception(_errorMessage(e, 'Unable to mark notification as read.'));
    }
  }
}
