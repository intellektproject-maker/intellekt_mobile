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
  final _total = TextEditingController();
  final _codeInput = TextEditingController();
  List<Map<String, dynamic>> _students = [], _requests = [];
  Map<String, String> _marks = {}, _comments = {}, _errors = {};
  Map<String, bool> _saved = {};
  String? _code;
  Map<String, dynamic>? _test;
  String _editingRoll = '', _editDraft = '', _busyRoll = '';
  bool _loadingStudents = false, _validatingCode = false, _saving = false, _overallBusy = false;
  String? _error;
  String _selectedClass = '', _selectedBoard = '';

  String get _facultyId => widget.facultyId.trim().toUpperCase();
  num get _totalMarks => num.tryParse(_total.text.trim()) ?? num.tryParse((_test?['total_marks'] ?? '').toString()) ?? 0;
  bool get _hasSaved => _saved.values.any((v) => v);
  List<Map<String, dynamic>> get _newStudents => _students.where((s) => !(_saved[(s['roll_no'] ?? '').toString().trim()] ?? false)).toList();
  String _str(dynamic value) => (value ?? '').toString();
  String _err(Object e) => e.toString().replaceFirst('Exception: ', '');

  @override
  void initState() { super.initState(); }
  @override
  void dispose() { _total.dispose(); _codeInput.dispose(); super.dispose(); }

  void _show(String message) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<bool> _confirm(String message) async {
    return await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Confirm'),
      content: Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Continue')),
      ],
    )) == true;
  }

  void _reset() {
    _students = []; _requests = []; _marks = {}; _comments = {}; _saved = {}; _errors = {};
    _editingRoll = ''; _editDraft = '';
  }

  Future<void> _validateTestCode() async {
    final code = _codeInput.text.trim();
    if (code.isEmpty) { _show('Enter the test code.'); return; }
    setState(() { _validatingCode = true; _error = null; _test = null; _code = null; _reset(); });
    try {
      final res = await _api.get('/regular-test-code/' + Uri.encodeComponent(code));
      if (res.data is! Map) throw Exception('Invalid test-code response.');
      final parsed = Map<String, dynamic>.from(res.data);
      if (!mounted) return;
      setState(() {
        _test = parsed;
        _code = _str(parsed['canonicalCode']).isEmpty ? code.toUpperCase() : _str(parsed['canonicalCode']);
        _selectedClass = _str(parsed['className']);
        _selectedBoard = _str(parsed['board']);
        _total.text = _str(parsed['totalMarks']);
      });
      if (parsed['duplicate'] == true) {
        _show('This test code already exists. Existing marks will be loaded so you can complete or review this attempt.');
      } else {
        _show('Test code verified. You can load the students.');
      }
    } catch (e) {
      if (mounted) setState(() { _test = null; _code = null; _error = _err(e); });
    } finally {
      if (mounted) setState(() => _validatingCode = false);
    }
  }

  Future<void> _loadRequests() async {
    if (_code == null) return;
    try {
      final res = await _api.get('/record-edit-requests/mine', queryParameters: {'facultyId': _facultyId});
      if (mounted) setState(() => _requests = res.data is List
          ? (res.data as List).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
          : []);
    } catch (_) {}
  }

  Map<String, dynamic>? _requestFor(String roll) {
    for (final r in _requests) {
      if (_str(r['record_type']) == 'marks' && _str(r['roll_no']) != '*' &&
          _str(r['roll_no']).trim().toUpperCase() == roll.trim().toUpperCase() &&
          _str(r['test_code']).trim().toUpperCase() == _str(_code).trim().toUpperCase()) return r;
    }
    return null;
  }

  Map<String, dynamic>? get _overallRequest {
    for (final r in _requests) {
      if (_str(r['record_type']) == 'marks' && _str(r['roll_no']) == '*' &&
          _str(r['test_code']).trim().toUpperCase() == _str(_code).trim().toUpperCase() &&
          ['Pending', 'Approved'].contains(r['status'])) return r;
    }
    return null;
  }
  bool get _overallApproved => _overallRequest?['status'] == 'Approved';

  Future<void> _loadStudents() async {
    final t = _test;
    final code = _str(_code).trim();
    final cls = _selectedClass.trim();
    final board = _selectedBoard.trim();
    final subjectId = _str(t?['subjectId']).trim();
    if (t == null || code.isEmpty || cls.isEmpty || board.isEmpty || subjectId.isEmpty || _totalMarks <= 0) {
      _show('Verify a valid test code before loading students.'); return;
    }
    setState(() { _loadingStudents = true; _reset(); _error = null; });
    try {
      final query = {'className': cls, 'board': board, 'testCode': code, 'subjectId': subjectId};
      final results = await Future.wait([
        _api.get('/enter-marks-students', queryParameters: query),
        _api.get('/marks', queryParameters: query),
      ]);
      if (results[0].data is! List) throw Exception('Unexpected students response.');
      final students = (results[0].data as List).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
      final marks = <String, String>{}, comments = <String, String>{};
      final saved = <String, bool>{};
      final existing = results[1].data is List ? results[1].data as List : [];
      for (final item in existing.whereType<Map>()) {
        final roll = _str(item['roll_no']).trim();
        if (roll.isNotEmpty) {
          marks[roll] = _str(item['marks_obtained']);
          comments[roll] = _str(item['comments']);
          saved[roll] = true;
        }
      }
      if (!mounted) return;
      setState(() { _students = students; _marks = marks; _comments = comments; _saved = saved; });
      await _loadRequests();
      if (students.isEmpty) _show('No students found for this test, class and board.');
    } catch (e) { if (mounted) setState(() => _error = _err(e)); }
    finally { if (mounted) setState(() => _loadingStudents = false); }
  }

  String _comment(String value) {
    if (value.toUpperCase() == 'A') return 'Absent';
    final n = num.tryParse(value);
    if (n == null || _totalMarks <= 0) return '';
    final p = n / _totalMarks * 100;
    if (p >= 90) return 'Excellent';
    if (p >= 75) return 'Very Good';
    if (p >= 60) return 'Good';
    if (p >= 40) return 'Average';
    return 'Needs Improvement';
  }

  void _changeMark(String roll, String raw) {
    final value = raw.trim().toUpperCase();
    if (value.isEmpty) {
      setState(() { _marks[roll] = ''; _comments[roll] = ''; _errors[roll] = 'Required'; }); return;
    }
    if (value == 'A') {
      setState(() { _marks[roll] = 'A'; _comments[roll] = 'Absent'; _errors[roll] = ''; }); return;
    }
    final n = num.tryParse(value);
    if (n == null || n % 1 != 0 || n < 0 || n > _totalMarks) {
      setState(() => _errors[roll] = 'Enter 0-' + _totalMarks.toString() + ' or A'); return;
    }
    setState(() { _marks[roll] = n.toString(); _comments[roll] = _comment(value); _errors[roll] = ''; });
  }

  Future<void> _requestEdit(Map<String, dynamic> student) async {
    final roll = _str(student['roll_no']).trim();
    final request = _requestFor(roll);
    if (_overallApproved || request?['status'] == 'Approved') {
      setState(() { _editingRoll = roll; _editDraft = _marks[roll] ?? ''; }); return;
    }
    if (request?['status'] == 'Pending') { _show('Your edit request is already pending with the admin.'); return; }
    if (!await _confirm('Request admin approval to edit marks for ' + _str(student['name'] ?? roll) + '?')) return;
    setState(() => _busyRoll = roll);
    try {
      final res = await _api.post('/record-edit-requests', data: {
        'facultyId': _facultyId, 'recordType': 'marks', 'roll_no': roll,
        'test_code': _code, 'requested_value': _marks[roll] ?? '',
      });
      if (!mounted) return;
      _show(res.data is Map ? _str(res.data['message']).isNotEmpty ? _str(res.data['message']) : 'Edit request sent to admin.' : 'Edit request sent to admin.');
      await _loadRequests();
    } catch (e) { _show(_err(e)); }
    finally { if (mounted) setState(() => _busyRoll = ''); }
  }

  Future<void> _requestOverall() async {
    if (_students.isEmpty || !_hasSaved || _code == null) { _show('Load existing marks first.'); return; }
    if (_overallRequest != null) {
      _show(_overallApproved ? 'Overall edit is approved.' : 'An overall edit request is already pending.'); return;
    }
    if (!await _confirm('Request approval to edit all saved marks for ' + _str(_code) + '?')) return;
    setState(() => _overallBusy = true);
    try {
      await _api.post('/record-edit-requests', data: {
        'facultyId': _facultyId, 'recordType': 'marks', 'roll_no': '*',
        'test_code': _code, 'requested_value': 'BULK_EDIT',
      });
      _show('Overall edit request sent to admin.');
      await _loadRequests();
    } catch (e) { _show(_err(e)); }
    finally { if (mounted) setState(() => _overallBusy = false); }
  }

  Future<void> _saveApprovedEdit(Map<String, dynamic> student) async {
    final roll = _str(student['roll_no']).trim();
    final value = _editDraft.trim().toUpperCase();
    final permission = _overallApproved ? _overallRequest : _requestFor(roll);
    final n = num.tryParse(value);
    if (permission == null || permission['status'] != 'Approved') { _show('Admin approval is required.'); return; }
    if (value != 'A' && (n == null || n % 1 != 0 || n < 0 || n > _totalMarks)) { _show('Enter valid marks or A for absent.'); return; }
    setState(() => _busyRoll = roll);
    try {
      await _api.post('/record-edit-requests/' + _str(permission['id']) + '/apply', data: {
        'facultyId': _facultyId, 'newValue': value,
        if (_str(permission['roll_no']) == '*') 'roll_no': roll,
      });
      if (!mounted) return;
      setState(() { _editingRoll = ''; _editDraft = ''; });
      _show('Approved marks edit applied successfully.');
      await _loadStudents();
    } catch (e) { _show(_err(e)); }
    finally { if (mounted) setState(() => _busyRoll = ''); }
  }

  Future<void> _finishOverall() async {
    final request = _overallRequest;
    if (!_overallApproved || request == null) return;
    if (_editingRoll.isNotEmpty) { _show('Save or cancel the current edit first.'); return; }
    if (!await _confirm('Finish overall editing? Further changes will need new admin approval.')) return;
    setState(() => _overallBusy = true);
    try {
      await _api.post('/record-edit-requests/' + _str(request['id']) + '/finish', data: {'facultyId': _facultyId});
      _show('Overall edit session completed.');
      await _loadRequests();
    } catch (e) { _show(_err(e)); }
    finally { if (mounted) setState(() => _overallBusy = false); }
  }

  Future<void> _saveNewMarks() async {
    final students = _newStudents;
    if (students.isEmpty) { _show('There are no new marks to save.'); return; }
    final errors = <String, String>{};
    for (final s in students) {
      final roll = _str(s['roll_no']).trim(), value = (_marks[_str(s['roll_no']).trim()] ?? '').trim().toUpperCase();
      final n = num.tryParse(value);
      if (value.isEmpty) errors[roll] = 'Required';
      else if (value != 'A' && (n == null || n % 1 != 0 || n < 0 || n > _totalMarks)) errors[roll] = 'Invalid marks';
      else if ((_errors[roll] ?? '').isNotEmpty) errors[roll] = _errors[roll]!;
    }
    if (errors.isNotEmpty) { setState(() => _errors = errors); _show('Correct the highlighted marks first.'); return; }
    setState(() => _saving = true);
    try {
      final records = students.map((s) {
        final roll = _str(s['roll_no']).trim(), value = (_marks[_str(s['roll_no']).trim()] ?? '').trim().toUpperCase();
        return {
          'roll_no': roll, 'student_name': s['name'] ?? s['student_name'] ?? '',
          'marks': value == 'A' ? 'A' : num.parse(value), 'comments': _comments[roll] ?? '',
          'test_code': _str(_code).trim().toUpperCase(), 'total_marks': _totalMarks,
          'subject_id': _test?['subjectId'], 'chapter': _test?['chapter'],
          'class_name': _test?['className'], 'board': _test?['board'],
        };
      }).toList();
      await _api.post('/marks', data: {'records': records, 'facultyId': _facultyId});
      _show('New student marks saved successfully.');
      await _loadStudents();
    } catch (e) { _show('Could not save marks: ' + _err(e)); }
    finally { if (mounted) setState(() => _saving = false); }
  }

  Widget _filter(String label, String value, List<String> options, ValueChanged<String?> onChanged) {
    return DropdownButtonFormField<String>(
      value: value.isEmpty ? '' : value, isExpanded: true,
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
      items: [const DropdownMenuItem(value: '', child: Text('All')), ...options.map((v) => DropdownMenuItem(value: v, child: Text(v, overflow: TextOverflow.ellipsis)))],
      onChanged: onChanged,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Enter Marks'), foregroundColor: AppColors.primary, backgroundColor: AppColors.surface),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Card(color: AppColors.surface, elevation: 0, child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Text('Manual test entry', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.primary)),
          const SizedBox(height: 8),
          const Text('Enter the test code printed on the answer sheet. The app will identify the board, class, subject, maximum marks and chapter.'),
          const SizedBox(height: 12),
          TextField(
            controller: _codeInput,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(labelText: 'Test code', hintText: 'Example: S12M50C11', border: OutlineInputBorder()),
            onChanged: (_) => setState(() { _test = null; _code = null; _reset(); }),
            onSubmitted: (_) => _validateTestCode(),
          ),
          const SizedBox(height: 10),
          FilledButton.icon(
            onPressed: _validatingCode ? null : _validateTestCode,
            icon: const Icon(Icons.verified_outlined),
            label: Text(_validatingCode ? 'Verifying...' : 'Verify test code'),
          ),
          if (_test != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(10)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Subject: ' + _str(_test!['subjectName'])),
                Text('Maximum marks: ' + _str(_test!['totalMarks'])),
                Text('Chapter: ' + _str(_test!['chapter'])),
                if (_test!['attempt'] != null) Text('Attempt: Test ' + _str(_test!['attempt'])),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _selectedClass,
                  decoration: const InputDecoration(labelText: 'Select class', border: OutlineInputBorder()),
                  items: ['7', '8', '9', '10', '11', '12'].map((v) => DropdownMenuItem(value: v, child: Text('Class $v'))).toList(),
                  onChanged: (v) => setState(() { _selectedClass = v ?? ''; _reset(); }),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: _selectedBoard,
                  decoration: const InputDecoration(labelText: 'Select board', border: OutlineInputBorder()),
                  items: ['State Board', 'CBSE', 'ISC'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
                  onChanged: (v) => setState(() { _selectedBoard = v ?? ''; _reset(); }),
                ),
                if (_test!['duplicate'] == true) Padding(padding: const EdgeInsets.only(top: 6), child: Text(
                  _test!['hasMarks'] == true ? 'Existing marks found for this code.' : 'This code is already present in posted tests.',
                  style: const TextStyle(color: Colors.deepOrange, fontWeight: FontWeight.w700),
                )),
              ]),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(onPressed: _loadingStudents ? null : _loadStudents, icon: const Icon(Icons.people_outline), label: Text(_loadingStudents ? 'Loading students...' : 'Load students')),
          ],
        ]))),
        if (_error != null) Card(color: Colors.red.shade50, child: ListTile(leading: const Icon(Icons.error_outline, color: Colors.red), title: const Text('Could not load data'), subtitle: Text(_error!))),
        if (_loadingStudents) const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator())),
        if (!_loadingStudents && _students.isEmpty) const Card(child: ListTile(title: Text('Verify a test code and load its students to enter marks.'))),
        if (_students.isNotEmpty) ...[
          if (_hasSaved) Card(color: Colors.amber.shade50, child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const Text('Previously saved marks are locked. Request admin approval before editing.', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(_overallRequest?['status'] == 'Pending' ? 'Overall request: Pending' : _overallApproved ? 'Overall request: Approved' : 'You can request permission to edit all saved marks for this test.'),
            const SizedBox(height: 8),
            Wrap(spacing: 8, children: [
              FilledButton.icon(
                onPressed: _overallBusy || _overallRequest?['status'] == 'Pending' || _overallApproved ? null : _requestOverall,
                icon: const Icon(Icons.edit_note),
                label: Text(_overallBusy ? 'Sending...' : _overallRequest?['status'] == 'Pending' ? 'Overall request pending' : _overallApproved ? 'Overall edit approved' : 'Request overall edit'),
              ),
              if (_overallApproved) OutlinedButton(onPressed: _overallBusy ? null : _finishOverall, child: const Text('Finish overall edit')),
            ]),
          ]))),
          ..._students.map((student) {
            final roll = _str(student['roll_no']).trim();
            final name = _str(student['name'] ?? student['student_name'] ?? 'Student');
            final saved = _saved[roll] ?? false;
            final request = _requestFor(roll);
            final pending = request?['status'] == 'Pending';
            final approved = request?['status'] == 'Approved' || _overallApproved;
            final editing = saved && approved && _editingRoll == roll;
            return Card(color: AppColors.surface, elevation: 0, margin: const EdgeInsets.only(bottom: 9), child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16))),
                Chip(label: Text(saved ? (pending ? 'Request Pending' : approved ? 'Edit Approved' : 'Saved • Locked') : 'New'), visualDensity: VisualDensity.compact, backgroundColor: saved ? (pending ? Colors.orange.shade50 : Colors.green.shade50) : Colors.blue.shade50),
              ]),
              Text('Roll No: ' + roll),
              const SizedBox(height: 10),
              if (saved && !editing)
                Text('Marks: ' + (_marks[roll] ?? '-') + ' / ' + _totalMarks.toString(), style: const TextStyle(fontWeight: FontWeight.w700))
              else if (saved && editing)
                TextFormField(
                  key: ValueKey('approved-edit-' + roll),
                  initialValue: _editDraft,
                  keyboardType: TextInputType.text,
                  decoration: const InputDecoration(labelText: 'Corrected marks (or A if absent)', border: OutlineInputBorder()),
                  onChanged: (v) => setState(() => _editDraft = v),
                )
              else
                TextFormField(key: ValueKey('new-' + roll), initialValue: _marks[roll] ?? '', keyboardType: TextInputType.text,
                  decoration: InputDecoration(labelText: 'Marks (or A if absent)', border: const OutlineInputBorder(), errorText: (_errors[roll] ?? '').isEmpty ? null : _errors[roll]),
                  onChanged: (v) => _changeMark(roll, v)),
              if ((_comments[roll] ?? '').isNotEmpty) Padding(padding: const EdgeInsets.only(top: 6), child: Text('Comment: ' + _comments[roll]!)),
              if (saved && pending) const Padding(padding: EdgeInsets.only(top: 6), child: Text('Your edit request is waiting for admin approval.', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.w600))),
              if (saved) Padding(padding: const EdgeInsets.only(top: 8), child: Wrap(spacing: 8, children: [
                if (!approved) OutlinedButton.icon(
                  onPressed: _busyRoll == roll || pending ? null : () => _requestEdit(student),
                  icon: const Icon(Icons.lock_open),
                  label: Text(_busyRoll == roll ? 'Sending...' : pending ? 'Request pending' : 'Request edit'),
                ),
                if (editing) FilledButton(onPressed: _busyRoll == roll ? null : () => _saveApprovedEdit(student), child: Text(_busyRoll == roll ? 'Saving...' : 'Save approved edit')),
                if (editing) TextButton(onPressed: () => setState(() { _editingRoll = ''; _editDraft = ''; }), child: const Text('Cancel')),
                if (approved && !editing) OutlinedButton.icon(onPressed: () => _requestEdit(student), icon: const Icon(Icons.edit), label: const Text('Edit approved mark')),
              ])),
              if (!saved) const Padding(padding: EdgeInsets.only(top: 6), child: Text('Enter new mark', style: TextStyle(color: AppColors.textSecondary, fontSize: 12))),
            ])));
          }),
          if (_newStudents.isNotEmpty) FilledButton.icon(onPressed: _saving ? null : _saveNewMarks,
            icon: _saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.save_outlined),
            label: Text(_saving ? 'Saving marks...' : 'Save new marks (' + _newStudents.length.toString() + ')')),
          if (_newStudents.isEmpty) const Padding(padding: EdgeInsets.all(12), child: Text('All new marks have been entered. Saved marks can only be edited after admin approval.')),
        ],
      ]),
    );
  }
}
