import 'package:dio/dio.dart';

import '../models/faculty_model.dart';
import '../models/faculty_task_model.dart';

class FacultyProfileService {
  static const String baseUrl =
      'https://responsible-wonder-production.up.railway.app';

  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
      },
    ),
  );

  // Get one faculty member
  Future<FacultyModel> getFaculty(String facultyId) async {
    final response = await _dio.get('/faculty/$facultyId');

    return FacultyModel.fromJson(
      Map<String, dynamic>.from(response.data),
    );
  }

  // Get all faculty
  Future<List<FacultyModel>> getAllFaculty() async {
    final response = await _dio.get('/faculty');

    final List<dynamic> data = response.data;

    return data
        .map(
          (item) => FacultyModel.fromJson(
        Map<String, dynamic>.from(item),
      ),
    )
        .toList();
  }

  // Get classes
  Future<List<String>> getClasses() async {
    final response = await _dio.get('/classes');

    final List<dynamic> data = response.data;

    final classes = data
        .map((item) {
      final board = item['board']?.toString() ?? '';

      final className =
          item['class']?.toString() ??
              item['class_name']?.toString() ??
              '';

      if (board.isEmpty || className.isEmpty) {
        return null;
      }

      return '$board-$className';
    })
        .whereType<String>()
        .toSet()
        .toList();

    classes.add('Others');

    return classes;
  }

  // Get test codes
  Future<List<String>> getTestCodes() async {
    final response = await _dio.get('/tests');

    final List<dynamic> data = response.data;

    return data
        .map(
          (item) => item['test_code']?.toString() ?? '',
    )
        .where((code) => code.isNotEmpty)
        .toList();
  }

  // Get my tasks
  Future<List<FacultyTaskModel>> getMyTasks(
      String facultyId,
      ) async {
    final response = await _dio.get(
      '/faculty-tasks/$facultyId',
    );

    return _convertTaskList(response.data);
  }

  // Get all faculty tasks
  Future<List<FacultyTaskModel>> getAllFacultyTasks(
      String loginFacultyId,
      ) async {
    final response = await _dio.get(
      '/faculty-tasks-all',
      queryParameters: {
        'loginFacultyId': loginFacultyId,
      },
    );

    return _convertTaskList(response.data);
  }

  // Get all daily tasks
  Future<List<FacultyTaskModel>> getDailyTasks(
      String loginFacultyId,
      ) async {
    final response = await _dio.get(
      '/faculty-daily-tasks-all',
      queryParameters: {
        'loginFacultyId': loginFacultyId,
      },
    );

    return _convertTaskList(response.data);
  }

  // Assign task
  Future<String> assignTask({
    required String loginFacultyId,
    required String facultyId,
    required String facultyName,
    required String className,
    required String subjectName,
    required String totalTestNote,
    required String otherTasks,
    required String? dueDate,
    required String priority,
    required String taskType,
  }) async {
    final response = await _dio.post(
      '/faculty-tasks',
      data: {
        'loginFacultyId': loginFacultyId,
        'faculty_id': facultyId,
        'faculty_name': facultyName,
        'class_name': className,
        'subject_name': subjectName,
        'total_test_note': totalTestNote,
        'other_tasks': otherTasks,
        'due_date': taskType == 'Daily' ? null : dueDate,
        'priority': taskType == 'Daily' ? 'High' : priority,
        'task_type': taskType,
      },
    );

    return response.data['message']?.toString() ??
        'Task assigned successfully';
  }

  // Update task completion
  Future<void> updateTaskCompletion({
    required int taskId,
    required bool isCompleted,
  }) async {
    await _dio.put(
      '/faculty-tasks/$taskId',
      data: {
        'is_completed': isCompleted,
      },
    );
  }

  // Delete task
  Future<void> deleteTask({
    required int taskId,
    required String loginFacultyId,
  }) async {
    await _dio.delete(
      '/faculty-tasks/$taskId',
      queryParameters: {
        'loginFacultyId': loginFacultyId,
      },
    );
  }

  // Reassign task
  Future<void> reassignTask({
    required int taskId,
    required String facultyId,
    required String facultyName,
  }) async {
    await _dio.put(
      '/faculty-tasks/$taskId',
      data: {
        'faculty_id': facultyId,
        'faculty_name': facultyName,
      },
    );
  }

  // Get faculty notifications
  Future<List<Map<String, dynamic>>> getNotifications(
      String facultyId,
      ) async {
    final response = await _dio.get(
      '/faculty-notifications/$facultyId',
    );

    final List<dynamic> data = response.data;

    return data
        .map(
          (item) => Map<String, dynamic>.from(item),
    )
        .toList();
  }

  // Mark notification as read
  Future<void> markNotificationRead({
    required String facultyId,
    required String moduleName,
  }) async {
    await _dio.put(
      '/faculty-notifications/mark-read/'
          '$facultyId/$moduleName',
    );
  }

  // Convert JSON task list into Dart models
  List<FacultyTaskModel> _convertTaskList(
      dynamic responseData,
      ) {
    final List<dynamic> data = responseData;

    return data
        .map(
          (item) => FacultyTaskModel.fromJson(
        Map<String, dynamic>.from(item),
      ),
    )
        .toList();
  }
}