import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../core/api/api_client.dart';
import '../../core/constants/colors.dart';
import '../../widgets/marks_entry_input_formatter.dart';

class FacultyEnterMarksScreen extends StatefulWidget {
  final String facultyId;
  const FacultyEnterMarksScreen({super.key, required this.facultyId});

  @override
  State<FacultyEnterMarksScreen> createState() => _FacultyEnterMarksScreenState();
}

class _RegularMarkStudent {
  final String rollNo;
  final String name;
  final TextEditingController marks = TextEditingController();

  _RegularMarkStudent({required this.rollNo, required this.name});

  void dispose() => marks.dispose();
}

class _FacultyEnterMarksScreenState extends State<FacultyEnterMarksScreen> {
  final ApiClient _api = ApiClient();
  final TextEditingController _testCode = TextEditingController();
  final TextEditingController _chapter = TextEditingController();
  final TextEditingController _portions = TextEditingController();
  List<_RegularMarkStudent> _students = [];
  Map<String, dynamic>? _test;
  DateTime _testDate = DateTime.now();
  bool _hasExistingMarks = false, _editingExisting = false;
  Map<String, Map<String, dynamic>> _approvedEditRequests = {};
  bool get _isAdmin => const {'IG001','IG002'}.contains(widget.facultyId.trim().toUpperCase());
  bool _loading = false;
  bool _saving = false;
  String? _error;
  String? _message;

  @override
  void dispose() {
    _testCode.dispose();
    _chapter.dispose();
    _portions.dispose();
    for (final student in _students) {
      student.dispose();
    }
    super.dispose();
  }

  String _friendlyError(Object error, {bool saving = false}) {
    if (error is DioException) {
      final status = error.response?.statusCode;
      final data = error.response?.data;
      final detail = data is Map ? (data['error'] ?? data['message'])?.toString().toLowerCase() ?? '' : '';
      if (detail.contains('pending') || detail.contains('approved') || detail.contains('edit request')) {
        return 'An edit request for this student is already pending or approved.';
      }
      if (detail.contains('already taken') || detail.contains('duplicate')) {
        return 'This test code is already taken. Please enter a different test code.';
      }
      if (status == 409) return 'This record cannot be changed right now. Refresh and try again.';
      if (detail.contains('invalid test code') || detail.contains('test code format')) {
        return 'The test code is invalid. Please check it and try again.';
      }
      if (detail.contains('no students') || status == 404) {
        return 'No eligible students were found for this test code.';
      }
      if (status == 403) return 'You do not have permission to enter marks.';
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.sendTimeout ||
          error.type == DioExceptionType.connectionError) {
        return 'Could not connect. Please check your connection and try again.';
      }
    }
    return saving
        ? 'Could not save marks. Your entries are still here; please try again.'
        : 'Could not load students. Please check the test code and try again.';
  }

  String get _testDateString => '${_testDate.year.toString().padLeft(4, '0')}-${_testDate.month.toString().padLeft(2, '0')}-${_testDate.day.toString().padLeft(2, '0')}';

  Future<void> _pickTestDate() async {
    final picked = await showDatePicker(context: context, initialDate: _testDate, firstDate: DateTime(2020), lastDate: DateTime(2100));
    if (picked != null && mounted) setState(() => _testDate = picked);
  }

  Future<void> _requestMarkEdit(_RegularMarkStudent student) async {
    final controller = TextEditingController(text: student.marks.text);
    final requested = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Request marks edit - ${student.rollNo}'),
        content: TextField(controller: controller, autofocus: true, textCapitalization: TextCapitalization.characters,
          inputFormatters: [MarksEntryInputFormatter()],
          decoration: const InputDecoration(labelText: 'Requested marks (number or A)')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(dialogContext, controller.text.trim().toUpperCase()), child: const Text('Request edit')),
        ],
      ),
    );
    controller.dispose();
    if (requested == null || requested.isEmpty) return;
    final maxMarks = int.tryParse((_test?['total_marks'] ?? '').toString()) ?? 100000;
    final number = int.tryParse(requested);
    if (requested != 'A' && (number == null || number < 0 || number > maxMarks)) {
      if (mounted) setState(() => _error = 'Enter marks from 0 to $maxMarks, or A for absent.');
      return;
    }
    try {
      await _api.post('/record-edit-requests', data: {'facultyId': widget.facultyId, 'recordType': 'marks',
        'roll_no': student.rollNo, 'test_code': _testCode.text.trim().toUpperCase(), 'requested_value': requested});
      if (mounted) setState(() { _error = null; _message = 'Edit request sent to the admin. Apply it after approval.'; });
    } catch (error) {
      if (mounted) setState(() => _error = _friendlyError(error, saving: true));
    }
  }

  Future<void> _applyApprovedMarkEdit(_RegularMarkStudent student) async {
    final request = _approvedEditRequests[student.rollNo.trim().toUpperCase()];
    if (request == null) return;
    final value = (request['requested_value'] ?? '').toString().trim().toUpperCase();
    try {
      await _api.post('/record-edit-requests/${request['id']}/apply', data: {'facultyId': widget.facultyId, 'newValue': value});
      if (!mounted) return;
      setState(() { student.marks.text = value; _approvedEditRequests.remove(student.rollNo.trim().toUpperCase()); _message = 'Approved marks edit applied for ${student.rollNo}.'; _error = null; });
    } catch (error) {
      if (mounted) setState(() => _error = _friendlyError(error, saving: true));
    }
  }

  void _changeTestCode() {
    for (final student in _students) { student.dispose(); }
    setState(() { _students = []; _test = null; _chapter.clear(); _portions.clear(); _hasExistingMarks = false; _editingExisting = false; _approvedEditRequests = {}; _error = null; _message = null; });
  }

  Future<void> _loadStudents() async {
    final code = _testCode.text.trim().toUpperCase().replaceAll(RegExp(r'\s+'), '');
    if (code.isEmpty) {
      setState(() { _error = 'Enter a test code to continue.'; _message = null; });
      return;
    }
    setState(() { _loading = true; _error = null; _message = null; });
    try {
      final response = await _api.get(
        '/regular-mark-entry/${Uri.encodeComponent(code)}',
        queryParameters: {'facultyId': widget.facultyId},
      );
      final data = response.data;
      final test = data is Map && data['test'] is Map
          ? Map<String, dynamic>.from(data['test'] as Map)
          : <String, dynamic>{};
      final raw = data is Map ? data['students'] : null;
      final loaded = raw is List
          ? raw.whereType<Map>().map((row) => _RegularMarkStudent(
                rollNo: (row['roll_no'] ?? '').toString(),
                name: (row['name'] ?? '').toString(),
              )).toList()
          : <_RegularMarkStudent>[];
      final marksRaw = data is Map ? data['marks'] : null;
      final marksByRoll = <String, Map<String, dynamic>>{};
      if (marksRaw is List) {
        for (final row in marksRaw.whereType<Map>()) {
          marksByRoll[(row['roll_no'] ?? '').toString().trim().toUpperCase()] = Map<String, dynamic>.from(row);
        }
      }
      for (final student in loaded) {
        final saved = marksByRoll[student.rollNo.trim().toUpperCase()];
        if (saved != null) student.marks.text = (saved['marks_obtained'] ?? '').toString();
      }
      final savedDate = DateTime.tryParse((test['test_date'] ?? '').toString());
      if (savedDate != null) _testDate = savedDate;
      if (loaded.isEmpty) throw DioException(
        requestOptions: RequestOptions(path: '/regular-mark-entry'),
        response: Response(
          requestOptions: RequestOptions(path: '/regular-mark-entry'),
          statusCode: 404,
          data: {'error': 'No students'},
        ),
      );
      if (!mounted) {
        for (final student in loaded) { student.dispose(); }
        return;
      }
      for (final student in _students) { student.dispose(); }
      final approved = <String, Map<String, dynamic>>{};
      if (!_isAdmin && marksByRoll.isNotEmpty) {
        try {
          final approvedResponse = await _api.get('/record-edit-requests/approved', queryParameters: {'facultyId': widget.facultyId});
          final rows = approvedResponse.data is List ? (approvedResponse.data as List).whereType<Map>() : const <Map>[];
          for (final row in rows) {
            if ((row['record_type'] ?? '').toString() == 'marks' && (row['status'] ?? '').toString() == 'Approved' &&
                (row['test_code'] ?? '').toString().trim().toUpperCase() == code &&
                (row['roll_no'] ?? '').toString().trim() != '*') {
              approved[(row['roll_no'] ?? '').toString().trim().toUpperCase()] = Map<String, dynamic>.from(row);
            }
          }
        } catch (_) {}
      }
      setState(() {
        _students = loaded; _test = test; _chapter.clear(); _portions.clear(); _hasExistingMarks = marksByRoll.isNotEmpty;
        _editingExisting = marksByRoll.isEmpty; _approvedEditRequests = approved; _testCode.text = code;
      });
    } catch (error) {
      if (mounted) setState(() => _error = _friendlyError(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<bool> _showMissing(List<_RegularMarkStudent> missing) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Marks missing'),
        content: Text('Enter marks for all students before saving:\\n\\n${missing.map((s) => '${s.name} (${s.rollNo})').join('\\n')}'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Return to marks')),
        ],
      ),
    ) ?? false;
  }

  Future<bool> _confirmAbsent(List<_RegularMarkStudent> absent) async {
    if (absent.isEmpty) return true;
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Absent students'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: absent.map((s) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text('${s.name} — Roll No: ${s.rollNo}'),
            )).toList(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Continue')),
        ],
      ),
    ) ?? false;
  }

  Future<bool> _confirmSubmit() async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Submit marks'),
        content: const Text('Are you sure you want to submit these marks?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Submit')),
        ],
      ),
    ) ?? false;
  }

  Future<void> _saveMarks() async {
    if (_students.isEmpty || _test == null || _saving) return;
    final chapterValue = _chapter.text.trim();
    if (!RegExp(r'^(?:[1-9]\d*|combined)$', caseSensitive: false).hasMatch(chapterValue)) {
      setState(() => _error = 'Chapter must be a number or combined.');
      return;
    }
    if (_portions.text.trim().isEmpty) {
      setState(() => _error = 'Enter the portions for this test.');
      return;
    }
    final missing = _students.where((s) => s.marks.text.trim().isEmpty).toList();
    if (missing.isNotEmpty) {
      await _showMissing(missing);
      return;
    }

    final invalid = _students.where((s) {
      final value = s.marks.text.trim().toUpperCase();
      if (value == 'A') return false;
      final number = int.tryParse(value);
      return number == null || number < 0 || number > 100000;
    }).toList();
    if (invalid.isNotEmpty) {
      setState(() => _error = 'Enter a whole number from 0 to 100000, or A for absent.');
      return;
    }

    final maxMarks = int.tryParse((_test?['total_marks'] ?? '').toString());
    if (maxMarks != null) {
      final overMax = _students.where((s) {
        final value = s.marks.text.trim().toUpperCase();
        return value != 'A' && (int.tryParse(value) ?? 0) > maxMarks;
      }).toList();
      if (overMax.isNotEmpty) {
        setState(() => _error = 'Marks cannot exceed the maximum of $maxMarks for this test.');
        return;
      }
    }

    final absent = _students.where((s) => s.marks.text.trim().toUpperCase() == 'A').toList();
    if (!await _confirmAbsent(absent)) return;
    if (!await _confirmSubmit()) return;

    setState(() { _saving = true; _error = null; _message = null; });
    try {
      final records = _students.map((s) => {
        'roll_no': s.rollNo,
        'marks': s.marks.text.trim().toUpperCase(),
      }).toList();
      await _api.post('/regular-mark-entry/submit', data: {
        'facultyId': widget.facultyId,
        'testCode': _testCode.text.trim().toUpperCase(),
        'testDate': _testDateString,
        'chapter': chapterValue,
        'portion': _portions.text.trim(),
        'records': records,
      });
      if (!mounted) return;
      setState(() { _hasExistingMarks = true; _editingExisting = false; _message = 'Marks saved successfully.'; _error = null; });
    } catch (error) {
      if (mounted) setState(() => _error = _friendlyError(error, saving: true));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _notice(String text, {required bool error}) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: error ? Colors.red.shade50 : Colors.green.shade50,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: error ? Colors.red.shade200 : Colors.green.shade200),
    ),
    child: Text(text, style: TextStyle(color: error ? Colors.red.shade800 : Colors.green.shade800)),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Regular Batch – Enter Marks'),
        foregroundColor: AppColors.primary,
        backgroundColor: AppColors.surface,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_error != null) _notice(_error!, error: true),
          if (_message != null) _notice(_message!, error: false),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                const Text('Enter test code', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.primary)),
                const SizedBox(height: 12),
                OutlinedButton.icon(onPressed: _loading ? null : _pickTestDate, icon: const Icon(Icons.calendar_month_outlined), label: Text('Test date: $_testDateString')),
                const SizedBox(height: 8),
                TextField(
                  controller: _testCode,
                  readOnly: _students.isNotEmpty,
                  textCapitalization: TextCapitalization.characters,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _loadStudents(),
                  decoration: const InputDecoration(
                    labelText: 'Test code',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                if (_students.isEmpty)
                  ElevatedButton(
                    onPressed: _loading ? null : _loadStudents,
                    child: _loading ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Load students'),
                  )
                else
                  OutlinedButton(
                    onPressed: _saving ? null : _changeTestCode,
                    child: const Text('Change test code'),
                  ),
              ]),
            ),
          ),
          if (_test != null) ...[
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  children: [
                    Text('Board: ${_test?['board'] ?? '-'}'),
                    Text('Class: ${_test?['class'] ?? '-'}'),
                    Text('Subject: ${_test?['subject'] ?? '-'}'),
                    Text('Maximum marks: ${_test?['total_marks'] ?? '-'}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _chapter,
              decoration: const InputDecoration(
                labelText: 'Chapter',
                hintText: 'Enter chapter number or combined',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _portions,
              decoration: const InputDecoration(
                labelText: 'Portions',
                hintText: 'Enter portions covered in this test',
                border: OutlineInputBorder(),
              ),
            ),
            if (_hasExistingMarks && _isAdmin)
              Align(alignment: Alignment.centerRight, child: TextButton.icon(
                onPressed: _saving ? null : () => setState(() => _editingExisting = !_editingExisting),
                icon: Icon(_editingExisting ? Icons.lock_outline : Icons.edit_outlined),
                label: Text(_editingExisting ? 'Finish editing' : 'Edit saved marks'),
              )),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Row(children: [
                Expanded(child: Text('Student', style: TextStyle(fontWeight: FontWeight.w700))),
                SizedBox(width: 120, child: Text('Marks (A if absent)', style: TextStyle(fontWeight: FontWeight.w700))),
              ]),
            ),
            ..._students.map((student) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(student.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                    Text(student.rollNo, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  ])),
                  if (_hasExistingMarks && !_isAdmin)
                    Column(mainAxisSize: MainAxisSize.min, children: [
                      TextButton(onPressed: _saving ? null : () => _requestMarkEdit(student), child: const Text('Request Edit')),
                      if (_approvedEditRequests.containsKey(student.rollNo.trim().toUpperCase()))
                        TextButton(onPressed: _saving ? null : () => _applyApprovedMarkEdit(student), child: const Text('Apply Approved')),
                    ]),
                  SizedBox(
                    width: 120,
                    child: TextField(
                      controller: student.marks,
                      readOnly: _hasExistingMarks && (!_isAdmin || !_editingExisting),
                      keyboardType: TextInputType.text,
                      textCapitalization: TextCapitalization.characters,
                      inputFormatters: [MarksEntryInputFormatter()],
                      decoration: const InputDecoration(
                        hintText: '0 / A',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      ),
                    ),
                  ),
                ]),
              ),
            )),
            const SizedBox(height: 8),
            if (!_hasExistingMarks || (_isAdmin && _editingExisting))
              ElevatedButton(onPressed: _saving ? null : _saveMarks,
                child: _saving ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(_hasExistingMarks ? 'Save Changes' : 'Save Marks')),
          ],
        ],
      ),
    );
  }
}
