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
    String testCode, {
    String? category,
    String? className,
    String? board,
    String? seriesId,
  }) async {
    final response = await _api.get(
      '/test-batch/tests/' + Uri.encodeComponent(testCode) + '/registered-students',
      queryParameters: {
        'adminId': adminId.trim().toUpperCase(),
        if (category != null && category.isNotEmpty) 'category': category,
        if (className != null && className.isNotEmpty) 'class': className.trim(),
        if (board != null && board.isNotEmpty) 'board': board.trim(),
        if (seriesId != null && seriesId.isNotEmpty) 'seriesId': seriesId,
      },
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

  String _testBoard(String code) {
    final match = RegExp(r'^([SCI])\d{2}').firstMatch(code.trim().toUpperCase());
    if (match == null) return '';
    switch (match.group(1)) {
      case 'S':
        return 'stateboard';
      case 'C':
        return 'cbse';
      case 'I':
        return 'isc';
      default:
        return '';
    }
  }

  String _testClass(String code) {
    final match = RegExp(r'^[SCI](\d{2})').firstMatch(code.trim().toUpperCase());
    return match?.group(1) ?? '';
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

      final normalizedBoard = _normalizeBoard(board);

      // Build Class and Board choices from the test catalogue first. This
      // keeps the filter controls populated even when the student endpoint
      // returns no rows for the current partial selection.
      final tests = await _tests(adminId: adminId, seriesId: seriesId);

      final classes = tests
          .map((e) => _testClass(e['test_code']?.toString() ?? ''))
          .where((e) => e.isNotEmpty)
          .toSet()
          .toList()
        ..sort();

      final boards = tests
          .map((e) => _testBoard(e['test_code']?.toString() ?? ''))
          .where((e) => e.isNotEmpty)
          .map((e) => e == 'stateboard'
              ? 'State Board'
              : e == 'cbse'
                  ? 'CBSE'
                  : e == 'isc'
                      ? 'ISC'
                      : e)
          .toSet()
          .toList()
        ..sort();

      final allStudents = await _students(
        adminId: adminId,
        className: className,
        seriesId: seriesId,
      );
      final filteredTests = tests.where((test) {
        final code = test['test_code']?.toString().trim() ?? '';
        final testClass = _testClass(code);
        final testBoard = _testBoard(code);
        final normalizedTestClass = testClass.trim();
        return (className == null || className.isEmpty ||
                normalizedTestClass == className.trim()) &&
            (normalizedBoard.isEmpty || testBoard == normalizedBoard) &&
            (seriesId == null || seriesId.isEmpty ||
                test['test_series_id']?.toString() == seriesId);
      }).toList()
        ..sort((a, b) => (a['test_code']?.toString() ?? '')
            .compareTo(b['test_code']?.toString() ?? ''));

      // Test codes must be unique even if the API returns duplicate rows.
      final uniqueTestsByCode = <String, Map<String, dynamic>>{};
      for (final test in filteredTests) {
        final code = test['test_code']?.toString().trim() ?? '';
        if (code.isEmpty) continue;
        uniqueTestsByCode.putIfAbsent(code.toUpperCase(), () => test);
      }
      final uniqueFilteredTests = uniqueTestsByCode.values.toList();

      final filters = <String, dynamic>{
        'classes': classes,
        'boards': boards,
        'series': series,
        'tests': uniqueFilteredTests,
      };

      // With no Test Code selected, show all students matching the
      // selected status and any filters already chosen.
      if (category != null &&
          category.isNotEmpty &&
          (testCode == null || testCode.isEmpty)) {
        final resultStudents = allStudents.where((student) {
          final studentBoard = _normalizeBoard(student['board']);
          final studentClass = student['class']?.toString().trim() ?? '';
          return (className == null ||
                  className.isEmpty ||
                  studentClass == className) &&
              (normalizedBoard.isEmpty || studentBoard == normalizedBoard);
        }).toList();

        final registrationsByTest = <String, List<Map<String, dynamic>>>{};
        for (final test in uniqueFilteredTests) {
          final code = test['test_code']?.toString().trim() ?? '';
          if (code.isEmpty) continue;
          registrationsByTest[code.toUpperCase()] =
              await _registeredStudents(adminId, code, category: category, className: className, board: board, seriesId: seriesId);
        }

        final allRegistrationDates = <String>[];
        for (final rows in registrationsByTest.values) {
          for (final row in rows) {
            final date =
                row['registered_writing_date']?.toString().split('T').first ??
                    '';
            if (date.isNotEmpty) allRegistrationDates.add(date);
          }
        }

        List<Map<String, dynamic>> allAttendance = <Map<String, dynamic>>[];
        if (allRegistrationDates.isNotEmpty) {
          allRegistrationDates.sort();
          allAttendance = await _attendance(
            adminId: adminId,
            from: allRegistrationDates.first,
            to: allRegistrationDates.last,
          );
        }

        final attendanceByRollDate = <String, String>{};
        for (final row in allAttendance) {
          final roll =
              row['roll_no']?.toString().trim().toUpperCase() ?? '';
          final date =
              row['attendance_date']?.toString().split('T').first ?? '';
          if (roll.isNotEmpty && date.isNotEmpty) {
            attendanceByRollDate['$roll|$date'] =
                row['status']?.toString().trim().toLowerCase() ?? '';
          }
        }

        final results = <Map<String, dynamic>>[];
        for (final test in uniqueFilteredTests) {
          final code = test['test_code']?.toString().trim() ?? '';
          if (code.isEmpty) continue;
          final subject =
              test['subject_name']?.toString().trim().toLowerCase() ?? '';

          final registeredByRoll = <String, Map<String, dynamic>>{
            for (final row in (registrationsByTest[code.toUpperCase()] ?? []))
              (row['roll_no']?.toString().trim().toUpperCase() ?? ''): row,
          };

          for (final student in resultStudents) {
            final roll =
                student['roll_no']?.toString().trim().toUpperCase() ?? '';
            final subjects =
                student['subjects']?.toString().trim().toLowerCase() ?? '';

            final subjectEligible =
                (subject.contains('math') &&
                        (subjects == 'mathematics' || subjects == 'both')) ||
                    (subject.contains('physics') &&
                        (subjects == 'physics' || subjects == 'both'));
            if (!subjectEligible) continue;

            final registration = registeredByRoll[roll];
            if (registration == null) continue;

            final writingDate =
                registration['registered_writing_date']?.toString().split('T').first ??
                    '';
            final attendanceStatus =
                attendanceByRollDate['$roll|$writingDate'] ?? '';

            final resolvedCategory = attendanceStatus == 'present'
                ? 'Completed'
                : attendanceStatus == 'absent'
                    ? 'Lapsed'
                    : 'Registered';

            if (resolvedCategory != category) continue;

            final merged = <String, dynamic>{...student};
            merged['test_code'] = test['test_code'];
            merged['subject_name'] = test['subject_name'];
            merged['test_series_name'] =
                student['test_series_name'] ?? test['test_series_name'];
            merged['registered_writing_date'] =
                registration['registered_writing_date'];
            merged['slot_start'] = registration['registered_slot_start'];
            merged['slot_end'] = registration['registered_slot_end'];
            merged['attendance_status'] = attendanceStatus;
            results.add(merged);
          }
        }

        return {'filters': filters, 'students': results};
      }

      if (category == null || category.isEmpty) {
        return {'filters': filters, 'students': <Map<String, dynamic>>[]};
      }

      final selectedTestCode = testCode!;
      final selectedTest = uniqueFilteredTests.firstWhere(
        (test) =>
            (test['test_code']?.toString().trim().toUpperCase() ?? '') ==
            selectedTestCode.trim().toUpperCase(),
        orElse: () => <String, dynamic>{},
      );
      if (selectedTest.isEmpty) {
        return {'filters': filters, 'students': <Map<String, dynamic>>[]};
      }

      // If a class/board filter is selected, reload without the narrower class
      // only when needed so the result set can still be filtered consistently.
      final resultStudents = allStudents.where((student) {
        final studentBoard = _normalizeBoard(student['board']);
        final studentClass = student['class']?.toString().trim() ?? '';
        return (className == null || className.isEmpty || studentClass == className) &&
            (normalizedBoard.isEmpty || studentBoard == normalizedBoard);
      }).toList();

      final subject =
          selectedTest['subject_name']?.toString().trim().toLowerCase() ?? '';
      final eligibleStudents = resultStudents.where((student) {
        final subjects =
            student['subjects']?.toString().trim().toLowerCase() ?? '';
        final subjectEligible =
            (subject.contains('math') &&
                    (subjects == 'mathematics' || subjects == 'both')) ||
                (subject.contains('physics') &&
                    (subjects == 'physics' || subjects == 'both'));
        return subjectEligible;
      }).toList();

      final registered = await _registeredStudents(adminId, selectedTestCode, category: category, className: className, board: board, seriesId: seriesId);
      final registeredByRoll = <String, Map<String, dynamic>>{
        for (final item in registered)
          (item['roll_no']?.toString().trim().toUpperCase() ?? ''): item,
      };

      final registeredDates = registered
          .map((item) =>
              item['registered_writing_date']?.toString().split('T').first ?? '')
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

      // Attendance must be matched by both student and writing date.
      // A student may register for multiple tests on different dates, so
      // indexing by roll number alone can assign the wrong attendance status.
      final attendanceByRollDate = <String, Map<String, dynamic>>{};
      for (final item in attendance) {
        final roll = item['roll_no']?.toString().trim().toUpperCase() ?? '';
        final date = item['attendance_date']?.toString().split('T').first ?? '';
        if (roll.isNotEmpty && date.isNotEmpty) {
          attendanceByRollDate['$roll|$date'] = item;
        }
      }

      final results = <Map<String, dynamic>>[];
      for (final student in eligibleStudents) {
        final roll = student['roll_no']?.toString().trim().toUpperCase() ?? '';
        final registration = registeredByRoll[roll];
        final writingDate = registration?['registered_writing_date']
                ?.toString()
                .split('T')
                .first ??
            '';
        final attendanceRow = writingDate.isEmpty
            ? null
            : attendanceByRollDate['$roll|$writingDate'];
        final attendanceStatus =
            attendanceRow?['status']?.toString().trim().toLowerCase();

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
        merged['test_series_name'] =
            student['test_series_name'] ?? selectedTest['test_series_name'];
        merged['registered_writing_date'] =
            registration?['registered_writing_date'];
        merged['slot_start'] = registration?['registered_slot_start'];
        merged['slot_end'] = registration?['registered_slot_end'];
        merged['attendance_status'] = attendanceRow?['status'];
        results.add(merged);
      }

      return {'filters': filters, 'students': results};
    } catch (error) {
      final message = error.toString().replaceFirst('Exception: ', '').trim();
      throw Exception(message.isEmpty
          ? 'Failed to load Test Batch student status.'
          : message);
    }
  }
}
