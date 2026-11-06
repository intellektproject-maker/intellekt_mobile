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
  final _codeController = TextEditingController();
  List<Map<String, dynamic>> _classes = [], _students = [], _requests = [];
  Map<String, String> _marks = {}, _comments = {}, _errors = {};
  Map<String, bool> _saved = {};
  String? _code;
  Map<String, dynamic>? _test;
  String _classFilter = '', _boardFilter = '';
  String _editingRoll = '', _editDraft = '', _busyRoll = '';
  bool _loadingClasses = true, _loadingStudents = false, _saving = false, _overallBusy = false;
  String? _error;

  String get _facultyId => widget.facultyId.trim().toUpperCase();
  num get _totalMarks => num.tryParse(_total.text.trim()) ?? 0;
  bool get _hasSaved => _saved.values.any((v) => v);
  List<Map<String, dynamic>> get _newStudents => _students.where((s) => !(_saved[(s['roll_no'] ?? '').toString().trim()] ?? false)).toList();
  String _str(dynamic value) => (value ?? '').toString();
  String _err(Object e) => e.toString().replaceFirst('Exception: ', '');

  @override
  void initState() { super.initState(); _loadClasses(); }
  @override
  void dispose() { _total.dispose(); _codeController.dispose(); super.dispose(); }

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

  List<String> _unique(String Function(Map<String, dynamic>) getter) {
    final values = _classes.map(getter).where((v) => v.trim().isNotEmpty).toSet().toList()..sort();
    return values;
  }

  void _reset() {
    _students = []; _requests = []; _marks = {}; _comments = {}; _saved = {}; _errors = {};
    _editingRoll = ''; _editDraft = '';
  }

  Future<void> _loadClasses() async {
    setState(() { _loadingClasses = true; _error = null; });
    try {
      final res = await _api.get('/classes');
      _classes = res.data is List
          ? (res.data as List).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
          : [];
      if (_classes.isEmpty) _error = 'No class and board options were returned by the server.';
    } catch (e) { _error = _err(e); }
    finally { if (mounted) setState(() => _loadingClasses = false); }
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
    final code = _codeController.text.trim().toUpperCase();
    final cls = _classFilter.trim();
    final board = _boardFilter.trim();
    if (code.isEmpty || cls.isEmpty || board.isEmpty || _totalMarks <= 0) {
      _show('Enter a test code, choose a class and board, and enter valid total marks.');
      return;
    }
    setState(() {
      _code = code;
      _test = {'test_code': code, 'class': cls, 'board': board, 'total_marks': _totalMarks};
      _loadingStudents = true;
      _reset();
      _error = null;
    });
    try {
      final query = {'className': cls, 'board': board};
      final results = await Future.wait([
        _api.get('/enter-marks-students', queryParameters: {...query, 'testCode': code}),
        _api.get('/marks', queryParameters: {...query, 'testCode': code}),
      ]);
      if (results[0].data is! List) throw Exception('Unexpected students response.');
      final students = (results[0].data as List)
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
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
      if (students.isEmpty) _show('No students found for the selected class and board.');
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
      value: options.contains(value) ? value : null,
      isExpanded: true,
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
      items: options.map((v) => DropdownMenuItem(value: v, child: Text(v, overflow: TextOverflow.ellipsis))).toList(),
      onChanged: onChanged,
    );
  }

  @override
  Widget build(BuildContext context) {
    final classes = _classes
        .where((c) => _boardFilter.isEmpty || _str(c['board']) == _boardFilter)
        .map((c) => _str(c['class'] ?? c['class_name']))
        .where((v) => v.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    final boards = _classes
        .where((c) => _classFilter.isEmpty ||
            _str(c['class'] ?? c['class_name']) == _classFilter)
        .map((c) => _str(c['board']))
        .where((v) => v.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Enter Marks'), foregroundColor: AppColors.primary, backgroundColor: AppColors.surface,
        actions: [IconButton(onPressed: _loadingClasses ? null : _loadClasses, icon: const Icon(Icons.refresh))]),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Card(color: AppColors.surface, elevation: 0, child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Text('Enter marks details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.primary)),
          const SizedBox(height: 12),
          TextField(
            controller: _codeController,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(labelText: 'Enter test code', border: OutlineInputBorder(), prefixIcon: Icon(Icons.tag)),
            onChanged: (_) => setState(() { _code = null; _reset(); }),
          ),
          const SizedBox(height: 10),
          if (_loadingClasses) const LinearProgressIndicator(),
          _filter('Choose board', _boardFilter, boards, (v) => setState(() {
            _boardFilter = v ?? '';
            if (!_classes.any((c) =>
                _str(c['board']) == _boardFilter &&
                _str(c['class'] ?? c['class_name']) == _classFilter)) {
              _classFilter = '';
            }
            _code = null; _test = null; _reset();
          })),
          const SizedBox(height: 10),
          _filter('Choose class', _classFilter, classes, (v) => setState(() {
            _classFilter = v ?? '';
            _code = null; _test = null; _reset();
          })),
          const SizedBox(height: 10),
          TextField(
            controller: _total,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Total marks', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(onPressed: _loadingStudents || _loadingClasses ? null : _loadStudents, icon: const Icon(Icons.people_outline), label: Text(_loadingStudents ? 'Loading students...' : 'Load students')),
        ]))),
        if (_error != null) Card(color: Colors.red.shade50, child: ListTile(leading: const Icon(Icons.error_outline, color: Colors.red), title: const Text('Could not load data'), subtitle: Text(_error!))),
        if (_loadingStudents) const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator())),
        if (!_loadingStudents && _students.isEmpty) const Card(child: ListTile(title: Text('Enter a test code, choose a class and board, then load students to enter marks.'))),
        if (_students.isNotEmpty) ...[
          if (_hasSaved) Card(color: Colors.amber.shade50, child: const Padding(padding: EdgeInsets.all(14), child: Text('Previously saved marks are locked. Contact an admin if a correction is required.'))),
          ..._students.map((student) {
            final roll = _str(student['roll_no']).trim();
            final name = _str(student['name'] ?? student['student_name'] ?? 'Student');
            final saved = _saved[roll] ?? false;
            final editing = false;
            return Card(color: AppColors.surface, elevation: 0, margin: const EdgeInsets.only(bottom: 9), child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16))),
                Chip(label: Text(saved ? 'Saved • Locked' : 'New'), visualDensity: VisualDensity.compact, backgroundColor: saved ? Colors.green.shade50 : Colors.blue.shade50),
              ]),
              Text('Roll No: ' + roll),
              const SizedBox(height: 10),
              if (saved)
                Text('Marks: ' + (_marks[roll] ?? '-') + ' / ' + _totalMarks.toString(), style: const TextStyle(fontWeight: FontWeight.w700))
              else
                TextFormField(key: ValueKey('new-' + roll), initialValue: _marks[roll] ?? '', keyboardType: TextInputType.text,
                  decoration: InputDecoration(labelText: 'Marks (or A if absent)', border: const OutlineInputBorder(), errorText: (_errors[roll] ?? '').isEmpty ? null : _errors[roll]),
                  onChanged: (v) => _changeMark(roll, v)),
              if ((_comments[roll] ?? '').isNotEmpty) Padding(padding: const EdgeInsets.only(top: 6), child: Text('Comment: ' + (editing ? _comment(_editDraft) : _comments[roll]!))),
              if (!saved) const Padding(padding: EdgeInsets.only(top: 6), child: Text('Enter new mark', style: TextStyle(color: AppColors.textSecondary, fontSize: 12))),
            ])));
          }),
          if (_newStudents.isNotEmpty) FilledButton.icon(onPressed: _saving ? null : _saveNewMarks,
            icon: _saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.save_outlined),
            label: Text(_saving ? 'Saving marks...' : 'Save new marks (' + _newStudents.length.toString() + ')')),
          if (_newStudents.isEmpty) const Padding(padding: EdgeInsets.all(12), child: Text('All marks for this test have been entered. Saved marks are read-only in the faculty app.')),
        ],
      ]),
    );
  }
}
