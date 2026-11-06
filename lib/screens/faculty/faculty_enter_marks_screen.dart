import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';
import '../../core/constants/colors.dart';

class FacultyEnterMarksScreen extends StatefulWidget {
  final String facultyId;
  const FacultyEnterMarksScreen({super.key, required this.facultyId});

  @override
  State<FacultyEnterMarksScreen> createState() => _FacultyEnterMarksScreenState();
}

class _FacultyEnterMarksScreenState extends State<FacultyEnterMarksScreen> {
  final _api = ApiClient();
  final _totalController = TextEditingController();
  List<Map<String, dynamic>> _tests = [];
  List<Map<String, dynamic>> _students = [];
  Map<String, String> _marks = {};
  Map<String, String> _comments = {};
  final Set<String> _savedRolls = {};
  List<Map<String, dynamic>> _editRequests = [];
  final Map<String, String> _editDrafts = {};
  String _busyRoll = '';
  bool _overallBusy = false;
  String? _testCode;
  Map<String, dynamic>? _test;
  bool _loadingTests = true;
  bool _loadingStudents = false;
  bool _saving = false;
  String? _error;

  String get _facultyId => widget.facultyId.trim().toUpperCase();
  String _value(dynamic value) => (value ?? '').toString();
  Map<String, dynamic>? _requestFor(String roll) {
    for (final request in _editRequests) {
      if (_value(request['record_type']) == 'marks' && _value(request['roll_no']) != '*' &&
          _value(request['roll_no']).trim().toUpperCase() == roll.trim().toUpperCase() &&
          _value(request['test_code']).trim().toUpperCase() == (_testCode ?? '').trim().toUpperCase()) return request;
    }
    return null;
  }
  Map<String, dynamic>? get _overallRequest {
    for (final request in _editRequests) {
      if (_value(request['record_type']) == 'marks' && _value(request['roll_no']) == '*' &&
          _value(request['test_code']).trim().toUpperCase() == (_testCode ?? '').trim().toUpperCase()) return request;
    }
    return null;
  }
  bool get _overallApproved => _overallRequest?['status'] == 'Approved';

  @override
  void initState() { super.initState(); _loadTests(); }
  @override
  void dispose() { _totalController.dispose(); super.dispose(); }

  Future<void> _loadTests() async {
    setState(() { _loadingTests = true; _error = null; });
    try {
      final response = await _api.get('/tests');
      _tests = response.data is List ? (response.data as List).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList() : [];
    } catch (e) { _error = e.toString().replaceFirst('Exception: ', ''); }
    finally { if (mounted) setState(() => _loadingTests = false); }
  }

  Future<void> _loadStudents() async {
    final test = _test;
    if (test == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select a test first.')));
      return;
    }
    final code = (_testCode ?? '').trim();
    final cls = (test['class'] ?? test['class_name'] ?? '').toString();
    final board = (test['board'] ?? '').toString();
    final total = num.tryParse(_totalController.text.trim().isNotEmpty ? _totalController.text.trim() : (test['total_marks'] ?? '').toString());
    if (cls.isEmpty || board.isEmpty || total == null || total <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('The selected test is missing class, board or valid total marks.')));
      return;
    }
    _totalController.text = total.toString();
    setState(() { _loadingStudents = true; _students = []; _marks = {}; _comments = {}; _savedRolls.clear(); _editRequests = []; _editDrafts.clear(); _error = null; });
    try {
      final response = await _api.get('/enter-marks-students', queryParameters: {'className': cls, 'board': board, 'testCode': code});
      if (response.data is! List) throw Exception('Unexpected students response.');
      final students = (response.data as List).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
      final marksResponse = await _api.get('/marks', queryParameters: {'testCode': code, 'className': cls, 'board': board});
      final existing = marksResponse.data is List ? (marksResponse.data as List).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList() : [];
      final marks = <String, String>{};
      final comments = <String, String>{};
      final savedRolls = <String>{};
      for (final row in existing) {
        final roll = (row['roll_no'] ?? '').toString();
        if (roll.isNotEmpty) {
          marks[roll] = row['marks_obtained']?.toString() ?? '';
          comments[roll] = (row['comments'] ?? '').toString();
          savedRolls.add(roll);
        }
      }
      if (mounted) setState(() { _students = students; _marks = marks; _comments = comments; _savedRolls..clear()..addAll(savedRolls); });
      await _loadEditRequests();
    } catch (e) {
      if (mounted) setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally { if (mounted) setState(() => _loadingStudents = false); }
  }

  Future<void> _loadEditRequests() async {
    try {
      final response = await _api.get('/record-edit-requests/mine', queryParameters: {'facultyId': _facultyId});
      if (!mounted) return;
      setState(() => _editRequests = response.data is List
          ? (response.data as List).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
          : []);
    } catch (_) {}
  }

  Future<bool> _confirmEdit(String message) async => await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(title: const Text('Request edit permission'), content: Text(message),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Send request'))]),
  ) == true;

  Future<void> _requestStudentEdit(Map<String, dynamic> student) async {
    final roll = _value(student['roll_no']).trim();
    final request = _requestFor(roll);
    if (_overallApproved || request?['status'] == 'Approved') {
      setState(() => _editDrafts[roll] = _marks[roll] ?? '');
      return;
    }
    if (request?['status'] == 'Pending') { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Your edit request is already pending with the admin.'))); return; }
    if (!await _confirmEdit('Request approval to edit marks for ${student['name'] ?? roll}?')) return;
    setState(() => _busyRoll = roll);
    try {
      final response = await _api.post('/record-edit-requests', data: {
        'facultyId': _facultyId, 'recordType': 'marks', 'roll_no': roll,
        'test_code': _testCode, 'requested_value': _marks[roll] ?? '',
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(response.data is Map ? _value(response.data['message']).isEmpty ? 'Edit request sent to admin.' : _value(response.data['message']) : 'Edit request sent to admin.')));
      await _loadEditRequests();
    } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')))); }
    finally { if (mounted) setState(() => _busyRoll = ''); }
  }

  Future<void> _requestOverallEdit() async {
    if (_savedRolls.isEmpty || _testCode == null) return;
    if (_overallRequest?['status'] == 'Pending') { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Overall edit request is already pending.'))); return; }
    if (_overallApproved) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Overall edit is approved.'))); return; }
    if (!await _confirmEdit('Request approval to edit all saved marks for test ${_testCode!}?')) return;
    setState(() => _overallBusy = true);
    try {
      final response = await _api.post('/record-edit-requests', data: {
        'facultyId': _facultyId, 'recordType': 'marks', 'roll_no': '*',
        'test_code': _testCode, 'requested_value': 'Edit permission requested',
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(response.data is Map ? _value(response.data['message']) : 'Overall edit request sent to admin.')));
      await _loadEditRequests();
    } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')))); }
    finally { if (mounted) setState(() => _overallBusy = false); }
  }

  Future<void> _applyApprovedMark(Map<String, dynamic> student) async {
    final roll = _value(student['roll_no']).trim();
    final request = _overallApproved ? _overallRequest : _requestFor(roll);
    final value = (_editDrafts[roll] ?? _marks[roll] ?? '').trim().toUpperCase();
    final total = num.tryParse(_totalController.text.trim()) ?? 0;
    final number = num.tryParse(value);
    if (request == null || request['status'] != 'Approved') return;
    if (value != 'A' && (number == null || number < 0 || number > total)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter valid marks within the total, or A for absent.'))); return;
    }
    setState(() => _busyRoll = roll);
    try {
      await _api.post('/record-edit-requests/${request['id']}/apply', data: {
        'facultyId': _facultyId, 'newValue': value,
        if (_value(request['roll_no']) == '*') 'roll_no': roll,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Approved marks edit saved.')));
      _editDrafts.remove(roll);
      await _loadStudents();
    } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')))); }
    finally { if (mounted) setState(() => _busyRoll = ''); }
  }

  Future<void> _finishOverallEdit() async {
    final request = _overallRequest;
    if (request == null || !_overallApproved) return;
    final confirm = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Finish overall edit'), content: const Text('Finish this approved overall editing session?'),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Finish'))],
    ));
    if (confirm != true) return;
    setState(() => _overallBusy = true);
    try {
      await _api.post('/record-edit-requests/${request['id']}/finish', data: {'facultyId': _facultyId});
      await _loadEditRequests();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Overall edit session completed.')));
    } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')))); }
    finally { if (mounted) setState(() => _overallBusy = false); }
  }

  String _commentFor(String value, num total) {
    if (value.toUpperCase() == 'A') return 'Absent';
    final n = num.tryParse(value);
    if (n == null || total <= 0) return '';
    final p = n / total * 100;
    if (p >= 90) return 'Excellent';
    if (p >= 75) return 'Very Good';
    if (p >= 60) return 'Good';
    if (p >= 40) return 'Average';
    return 'Needs Improvement';
  }

  Future<void> _save() async {
    final total = num.tryParse(_totalController.text.trim());
    if (_students.isEmpty || total == null || total <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Load students and confirm total marks first.')));
      return;
    }
    for (final student in _students) {
      final roll = (student['roll_no'] ?? '').toString();
      final value = (_marks[roll] ?? '').trim();
      final n = num.tryParse(value);
      if (value.isEmpty || (value.toUpperCase() != 'A' && (n == null || n < 0 || n > total))) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Enter valid marks or A (absent) for ${student['name'] ?? roll}.')));
        return;
      }
    }
    setState(() => _saving = true);
    try {
      final records = _students.where((s) => !_savedRolls.contains((s['roll_no'] ?? '').toString())).map((s) {
        final roll = (s['roll_no'] ?? '').toString();
        final value = _marks[roll]!.trim().toUpperCase();
        return {'roll_no': roll, 'student_name': s['name'] ?? s['student_name'] ?? '', 'marks': value == 'A' ? 'A' : num.parse(value), 'comments': _comments[roll] ?? '', 'test_code': _testCode!.toUpperCase().trim(), 'total_marks': total};
      }).toList();
      await _api.post('/marks', data: {'records': records, 'facultyId': widget.facultyId});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('New student marks saved successfully.')));
      await _loadStudents();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not save marks: ${e.toString().replaceFirst('Exception: ', '')}')));
    } finally { if (mounted) setState(() => _saving = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Enter Marks'), foregroundColor: AppColors.primary, backgroundColor: AppColors.surface, actions: [IconButton(onPressed: _loadTests, icon: const Icon(Icons.refresh))]),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Card(color: AppColors.surface, elevation: 0, child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('Select test', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.primary)),
          const SizedBox(height: 12),
          if (_loadingTests) const LinearProgressIndicator(),
          DropdownButtonFormField<String>(
            value: _testCode,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Test code', border: OutlineInputBorder()),
            items: _tests.map((t) { final code = (t['test_code'] ?? '').toString(); return DropdownMenuItem(value: code, child: Text('$code • ${t['board'] ?? ''}-${t['class'] ?? t['class_name'] ?? ''}')); }).toList(),
            onChanged: (v) {
              final found = _tests.where((t) => (t['test_code'] ?? '').toString() == v).toList();
              setState(() { _testCode = v; _test = found.isEmpty ? null : found.first; _students = []; _marks = {}; _comments = {}; _savedRolls.clear(); _editRequests = []; _editDrafts.clear(); _totalController.text = found.isEmpty ? '' : (found.first['total_marks'] ?? '').toString(); });
            },
          ),
          const SizedBox(height: 12),
          TextField(controller: _totalController, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Total marks', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          FilledButton.icon(onPressed: _loadingStudents || _loadingTests ? null : _loadStudents, icon: const Icon(Icons.people_outline), label: Text(_loadingStudents ? 'Loading students...' : 'Load students')),
        ]))),
        if (_error != null) Card(color: Colors.red.shade50, child: ListTile(leading: const Icon(Icons.error_outline, color: Colors.red), title: const Text('Request failed'), subtitle: Text(_error!))),
        if (_loadingStudents) const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator())),
        if (!_loadingStudents && _students.isEmpty) const Card(child: ListTile(title: Text('Choose a test and load its students to enter marks.'))),
        if (_students.isNotEmpty && _savedRolls.isNotEmpty) Card(color: Colors.amber.shade50, child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Text('Previously saved marks are locked. Request admin approval before editing.', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(_overallRequest?['status'] == 'Pending' ? 'Overall request: Pending' : _overallApproved ? 'Overall request: Approved' : 'Request permission to edit every saved mark for this test.'),
          const SizedBox(height: 8),
          Wrap(spacing: 8, children: [
            FilledButton(onPressed: _overallBusy || _overallRequest?['status'] == 'Pending' || _overallApproved ? null : _requestOverallEdit,
              child: Text(_overallBusy ? 'Sending...' : _overallRequest?['status'] == 'Pending' ? 'Overall request pending' : _overallApproved ? 'Overall edit approved' : 'Request overall edit')),
            if (_overallApproved) OutlinedButton(onPressed: _overallBusy ? null : _finishOverallEdit, child: const Text('Finish overall edit')),
          ]),
        ]))),
        ..._students.map((s) {
          final roll = (s['roll_no'] ?? '').toString();
          final name = (s['name'] ?? s['student_name'] ?? 'Student').toString();
          return Card(color: AppColors.surface, elevation: 0, margin: const EdgeInsets.only(bottom: 8), child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, style: const TextStyle(fontWeight: FontWeight.w800)),
            Text('Roll No: $roll'),
            const SizedBox(height: 8),
            if (_savedRolls.contains(roll)) ...[
              Text('Marks: ${_marks[roll] ?? '-'} / ${_totalController.text}', style: const TextStyle(fontWeight: FontWeight.w700)),
              if (_requestFor(roll)?['status'] == 'Pending') const Text('Edit request: Pending', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.w700)),
              if (_requestFor(roll)?['status'] == 'Approved' || _overallApproved) ...[
                TextFormField(key: ValueKey('approved-mark-$roll'), initialValue: _editDrafts[roll] ?? _marks[roll] ?? '', keyboardType: TextInputType.text,
                  decoration: const InputDecoration(labelText: 'New marks (or A if absent)', border: OutlineInputBorder()),
                  onChanged: (v) => _editDrafts[roll] = v),
                const SizedBox(height: 6),
                FilledButton(onPressed: _busyRoll == roll ? null : () => _applyApprovedMark(s), child: Text(_busyRoll == roll ? 'Saving...' : 'Save approved edit')),
              ] else OutlinedButton.icon(onPressed: _busyRoll == roll ? null : () => _requestStudentEdit(s), icon: const Icon(Icons.lock_open),
                label: Text(_busyRoll == roll ? 'Sending...' : 'Request edit')),
            ] else TextFormField(
              key: ValueKey('mark-$roll'), initialValue: _marks[roll] ?? '', keyboardType: TextInputType.text,
              decoration: const InputDecoration(labelText: 'Marks (or A if absent)', border: OutlineInputBorder()),
              onChanged: (v) { final total = num.tryParse(_totalController.text) ?? 0; setState(() { _marks[roll] = v.trim(); _comments[roll] = _commentFor(v.trim(), total); }); },
            ),
            if ((_comments[roll] ?? '').isNotEmpty) Padding(padding: const EdgeInsets.only(top: 6), child: Text('Comment: ${_comments[roll]}', style: const TextStyle(color: AppColors.textSecondary))),
          ])));
        }),
        if (_students.any((s) => !_savedRolls.contains((s['roll_no'] ?? '').toString()))) FilledButton.icon(onPressed: _saving ? null : _save, icon: _saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.save_outlined), label: Text(_saving ? 'Saving marks...' : 'Save marks')),
      ]),
    );
  }
}
