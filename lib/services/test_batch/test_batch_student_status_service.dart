import '../../core/api/api_client.dart';

class TestBatchStudentStatusService {
  final ApiClient _api = ApiClient();

  String _normalizeBoard(dynamic value) =>
      (value?.toString() ?? '').trim().toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');

  List<Map<String, dynamic>> _list(dynamic value) {
    if (value is! List) return <Map<String, dynamic>>[];
    return value.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<List<Map<String, dynamic>>> _tests({
    required String adminId,
    String? seriesId,
  }) async {
    final response = await _api.get(
      '/test-batch/tests',
      queryParameters: {
        'adminId': adminId.trim().toUpperCase(),
        if (seriesId != null && seriesId.isNotEmpty) 'seriesId': seriesId,
      },
    );
    final data = response.data;
    return _list(data is Map ? data['tests'] : data);
  }

  Future<List<Map<String, dynamic>>> _students({
    required String adminId,
    String? className,
    String? seriesId,
  }) async {
    final response = await _api.get(
      '/test-batch/students',
      queryParameters: {
        'adminId': adminId.trim().toUpperCase(),
        if (className != null && className.isNotEmpty) 'class': className,
        if (seriesId != null && seriesId.isNotEmpty) 'seriesId': seriesId,
      },
    );
    final data = response.data;
    return _list(data is Map ? data['students'] : data);
  }

  Future<List<Map<String, dynamic>>> _registeredStudents(
    String adminId,
    String testCode,
  ) async {
    final response = await _api.get(
      '/test-batch/tests/' + Uri.encodeComponent(testCode) + '/registered-students',
      queryParameters: {'adminId': adminId.trim().toUpperCase()},
    );
    final data = response.data;
    return _list(data is Map ? data['students'] : data);
  }

  Future<List<Map<String, dynamic>>> _attendance({
    required String adminId,
    required String from,
    required String to,
  }) async {
    final response = await _api.get(
      '/test-batch/attendance-report',
      queryParameters: {
        'adminId': adminId.trim().toUpperCase(),
        'from': from,
        'to': to,
      },
    );
    final data = response.data;
    return _list(data is Map ? data['attendance'] : data);
  }

  Future<Map<String, dynamic>> fetch({
    required String adminId,
    String? category,
    String? className,
    String? board,
    String? seriesId,
    String? testCode,
  }) async {
    try {
      final seriesResponse = await _api.get(
        '/test-batch/series',
        queryParameters: {'adminId': adminId.trim().toUpperCase()},
      );
      final seriesData = seriesResponse.data;
      final series = _list(seriesData is Map ? seriesData['series'] : seriesData);

      final tests = await _tests(adminId: adminId, seriesId: seriesId);
      final classes = tests
          .map((e) => e['class']?.toString().trim() ?? '')
          .where((e) => e.isNotEmpty)
          .toSet()
          .toList()
        ..sort();
      final boards = tests
          .map((e) => e['board']?.toString().trim() ?? '')
          .where((e) => e.isNotEmpty)
          .toSet()
          .toList()
        ..sort();

      final normalizedBoard = _normalizeBoard(board);
      final filteredTests = tests.where((test) {
        final testClass = test['class']?.toString().trim() ?? '';
        final testBoard = _normalizeBoard(test['board']);
        return (className == null || className.isEmpty || testClass == className) &&
            (normalizedBoard.isEmpty || testBoard == normalizedBoard) &&
            (seriesId == null || seriesId.isEmpty ||
                test['test_series_id']?.toString() == seriesId);
      }).toList()
        ..sort((a, b) => (a['test_code']?.toString() ?? '')
            .compareTo(b['test_code']?.toString() ?? ''));

      final filters = <String, dynamic>{
        'classes': classes,
        'boards': boards,
        'series': series,
        'tests': filteredTests,
      };

      if (category == null || category.isEmpty || testCode == null || testCode.isEmpty) {
        return {'filters': filters, 'students': <Map<String, dynamic>>[]};
      }

      final selectedTest = filteredTests.firstWhere(
        (test) => (test['test_code']?.toString().toUpperCase() ?? '') == testCode.toUpperCase(),
        orElse: () => <String, dynamic>{},
      );
      if (selectedTest.isEmpty) {
        return {'filters': filters, 'students': <Map<String, dynamic>>[]};
      }

      final allStudents = await _students(
        adminId: adminId,
        className: className,
        seriesId: seriesId,
      );

      final subject = selectedTest['subject_name']?.toString().trim().toLowerCase() ?? '';
      final eligibleStudents = allStudents.where((student) {
        final studentBoard = _normalizeBoard(student['board']);
        final studentClass = student['class']?.toString().trim() ?? '';
        final subjects = student['subjects']?.toString().trim().toLowerCase() ?? '';
        final subjectEligible =
            (subject.contains('math') && (subjects == 'mathematics' || subjects == 'both')) ||
            (subject.contains('physics') && (subjects == 'physics' || subjects == 'both'));
        return studentClass == className &&
            studentBoard == normalizedBoard &&
            subjectEligible;
      }).toList();

      final registered = await _registeredStudents(adminId, testCode);
      final registeredByRoll = <String, Map<String, dynamic>>{
        for (final item in registered)
          (item['roll_no']?.toString().trim().toUpperCase() ?? ''): item,
      };

      final registeredDates = registered
          .map((item) => item['registered_writing_date']?.toString().split('T').first ?? '')
          .where((date) => date.isNotEmpty)
          .toList();

      List<Map<String, dynamic>> attendance = <Map<String, dynamic>>[];
      if (registeredDates.isNotEmpty) {
        registeredDates.sort();
        attendance = await _attendance(
          adminId: adminId,
          from: registeredDates.first,
          to: registeredDates.last,
        );
      }

      final attendanceByRoll = <String, Map<String, dynamic>>{};
      for (final item in attendance) {
        final roll = item['roll_no']?.toString().trim().toUpperCase() ?? '';
        if (roll.isNotEmpty) attendanceByRoll[roll] = item;
      }

      final results = <Map<String, dynamic>>[];
      for (final student in eligibleStudents) {
        final roll = student['roll_no']?.toString().trim().toUpperCase() ?? '';
        final registration = registeredByRoll[roll];
        final attendanceRow = attendanceByRoll[roll];
        final attendanceStatus = attendanceRow?['status']?.toString().trim().toLowerCase();

        String resolvedCategory;
        if (attendanceStatus == 'present') {
          resolvedCategory = 'Completed';
        } else if (attendanceStatus == 'absent') {
          resolvedCategory = 'Lapsed';
        } else if (registration != null) {
          resolvedCategory = 'Registered';
        } else {
          resolvedCategory = 'Yet to Register';
        }

        if (resolvedCategory != category) continue;

        final merged = <String, dynamic>{...student};
        merged['test_code'] = selectedTest['test_code'];
        merged['subject_name'] = selectedTest['subject_name'];
        merged['test_series_name'] = student['test_series_name'] ?? selectedTest['test_series_name'];
        merged['registered_writing_date'] = registration?['registered_writing_date'];
        merged['slot_start'] = registration?['registered_slot_start'];
        merged['slot_end'] = registration?['registered_slot_end'];
        merged['attendance_status'] = attendanceRow?['status'];
        results.add(merged);
      }

      return {'filters': filters, 'students': results};
    } catch (error) {
      final message = error.toString().replaceFirst('Exception: ', '').trim();
      throw Exception(message.isEmpty ? 'Failed to load Test Batch student status.' : message);
    }
  }
}
