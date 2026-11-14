import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';
import '../../core/constants/colors.dart';
import '../../widgets/academic_year_range_filter.dart';

class FacultyEnterAttendanceScreen extends StatefulWidget {
  final String facultyId;
  const FacultyEnterAttendanceScreen({super.key, required this.facultyId});

  @override
  State<FacultyEnterAttendanceScreen> createState() => _FacultyEnterAttendanceScreenState();
}

class _FacultyEnterAttendanceScreenState extends State<FacultyEnterAttendanceScreen> {
  final _api = ApiClient();
  List<Map<String, dynamic>> _classes = [];
  List<Map<String, dynamic>> _students = [];
  String? _classKey;
  String _subject = '1';
  DateTime _date = DateTime.now();
  Map<String, String> _attendance = {};
  final Map<String, String> _savedAttendance = {};
  List<Map<String, dynamic>> _editRequests = [];
  final Map<String, String> _editDrafts = {};
  String _busyRoll = '';
  String _academicYearFrom = '', _academicYearTo = '';
  List<Map<String, dynamic>> get _visibleStudents => filterStudentsByAcademicYear(_students, fromYear: _academicYearFrom, toYear: _academicYearTo);

  String get _facultyId => widget.facultyId.trim().toUpperCase();
  String get _dateKey => _date.toIso8601String().split('T').first;
  String get _selectedBoard => (_classKey ?? '').split('||').first;
  String get _selectedClass => (_classKey ?? '').split('||').length > 1 ? (_classKey ?? '').split('||')[1] : '';
  String _value(dynamic value) => (value ?? '').toString();

  void _show(String message) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Map<String, dynamic>? _requestFor(String roll) {
    for (final request in _editRequests) {
      if (_value(request['record_type']) == 'attendance' &&
          _value(request['roll_no']) != '*' &&
          _value(request['roll_no']).trim().toUpperCase() == roll.trim().toUpperCase() &&
          _value(request['attendance_date']).split('T').first == _dateKey &&
          _value(request['subject_id']) == _subject) return request;
    }
    return null;
  }
  Map<String, dynamic>? get _overallAttendanceRequest {
    for (final request in _editRequests) {
      if (_value(request['record_type']) == 'attendance' &&
          _value(request['roll_no']) == '*' &&
          _value(request['attendance_date']).split('T').first == _dateKey &&
          _value(request['subject_id']) == _subject &&
          _value(request['class_name']).toUpperCase() == _selectedClass.toUpperCase() &&
          _value(request['board']).toUpperCase() == _selectedBoard.toUpperCase() &&
          ['Pending', 'Approved'].contains(request['status'])) return request;
    }
    return null;
  }
  bool get _overallAttendanceApproved => _overallAttendanceRequest?['status'] == 'Approved';

  bool _loadingClasses = true;
  bool _loadingStudents = false;
  bool _saving = false;
  String? _error;

  @override
  void initState() { super.initState(); _loadClasses(); }

  Future<void> _loadClasses() async {
    setState(() { _loadingClasses = true; _error = null; });
    try {
      final response = await _api.get('/classes');
      _classes = response.data is List ? (response.data as List).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList() : [];
    } catch (e) { _error = e.toString().replaceFirst('Exception: ', ''); }
    finally { if (mounted) setState(() => _loadingClasses = false); }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final picked = await showDatePicker(context: context, initialDate: _date.isAfter(today) ? today : _date, firstDate: DateTime(now.year - 1), lastDate: today);
    if (picked != null && mounted) setState(() { _date = picked; _students = []; _attendance = {}; _savedAttendance.clear(); _editRequests = []; _editDrafts.clear(); });
  }

  Future<void> _loadStudents() async {
    if (_classKey == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select a class first.')));
      return;
    }
    final selected = _classes.firstWhere((c) => '${c['board'] ?? ''}||${c['class'] ?? c['class_name'] ?? ''}' == _classKey);
    final board = (selected['board'] ?? '').toString();
    final cls = (selected['class'] ?? selected['class_name'] ?? '').toString();
    setState(() { _loadingStudents = true; _students = []; _attendance = {}; _savedAttendance.clear(); _editRequests = []; _editDrafts.clear(); _error = null; });
    try {
      final response = await _api.get('/students', queryParameters: {'class': cls, 'board': board, 'subject_id': int.parse(_subject)});
      if (response.data is! List) throw Exception('Unexpected students response.');
      _students = (response.data as List).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
      _attendance = {for (final s in _students) (s['roll_no'] ?? '').toString(): 'Present'};
      final report = await _api.get('/attendance', queryParameters: {
        'mode': 'report', 'class': board + '-' + cls, 'from': _dateKey, 'to': _dateKey, 'subject': _subject,
      });
      if (report.data is List) {
        for (final item in (report.data as List).whereType<Map>()) {
          final row = Map<String, dynamic>.from(item);
          final roll = _value(row['roll_no']).trim();
          if (roll.isNotEmpty) _savedAttendance[roll] = _value(row['status']);
        }
      }
      await _loadEditRequests();
    } catch (e) { _error = e.toString().replaceFirst('Exception: ', ''); }
    finally { if (mounted) setState(() => _loadingStudents = false); }
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

  Future<void> _requestAttendanceEdit(Map<String, dynamic> student) async {
    final roll = _value(student['roll_no']).trim();
    final request = _requestFor(roll) ?? _overallAttendanceRequest;
    if (request?['status'] == 'Pending') {
      _show('Your edit request is already pending with the admin.');
      return;
    }
    if (request?['status'] == 'Approved') {
      setState(() => _editDrafts[roll] = _savedAttendance[roll] ?? 'Present');
      return;
    }
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Request edit permission'),
        content: Text('Request admin approval to edit attendance for ' + roll + ' on ' + _dateKey + '?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Send request')),
        ],
      ),
    );
    if (confirm != true) return;
    setState(() => _busyRoll = roll);
    try {
      final current = _savedAttendance[roll] ?? 'Present';
      final response = await _api.post('/record-edit-requests', data: {
        'facultyId': _facultyId, 'recordType': 'attendance', 'roll_no': roll,
        'subject_id': int.parse(_subject), 'attendance_date': _dateKey,
        'requested_value': current == 'Present' ? 'Absent' : 'Present',
      });
      if (!mounted) return;
      _show(response.data is Map && _value(response.data['message']).isNotEmpty
          ? _value(response.data['message']) : 'Edit request sent to admin.');
      await _loadEditRequests();
    } catch (e) {
      _show('Could not send edit request: ' + e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _busyRoll = '');
    }
  }

  Future<void> _applyApprovedAttendanceEdit(Map<String, dynamic> student) async {
    final roll = _value(student['roll_no']).trim();
    final request = _requestFor(roll) ?? _overallAttendanceRequest;
    final value = _editDrafts[roll] ?? _savedAttendance[roll] ?? '';
    if (request == null || request['status'] != 'Approved' || !['Present', 'Absent'].contains(value)) return;
    setState(() => _busyRoll = roll);
    try {
      await _api.post('/record-edit-requests/' + _value(request['id']) + '/apply', data: {
        'facultyId': _facultyId, 'newValue': value,
        if (_value(request['roll_no']) == '*') 'roll_no': roll,
      });
      if (!mounted) return;
      setState(() { _savedAttendance[roll] = value; _editDrafts.remove(roll); });
      _show('Approved attendance edit saved.');
      await _loadEditRequests();
    } catch (e) {
      _show('Could not save attendance edit: ' + e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _busyRoll = '');
    }
  }

  Future<void> _requestOverallAttendanceEdit() async {
    if (_savedAttendance.isEmpty) { _show('Load existing attendance first.'); return; }
    final existing = _overallAttendanceRequest;
    if (existing != null) {
      _show(existing['status'] == 'Approved' ? 'Overall attendance edit is approved.' : 'An overall attendance edit request is already pending.');
      return;
    }
    final confirm = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Request overall edit access'),
      content: Text('Request admin approval to edit all saved attendance for the selected class, subject and date ($_dateKey)?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Send request')),
      ],
    ));
    if (confirm != true) return;
    setState(() => _busyRoll = '*');
    try {
      final response = await _api.post('/record-edit-requests', data: {
        'facultyId': _facultyId, 'recordType': 'attendance', 'roll_no': '*',
        'subject_id': int.parse(_subject), 'attendance_date': _dateKey,
        'class_name': _selectedClass, 'board': _selectedBoard,
        'requested_value': 'BULK_EDIT',
      });
      _show(response.data is Map && _value(response.data['message']).isNotEmpty
          ? _value(response.data['message']) : 'Overall attendance edit request sent.');
      await _loadEditRequests();
    } catch (e) { _show('Could not send overall request: ' + e.toString().replaceFirst('Exception: ', '')); }
    finally { if (mounted) setState(() => _busyRoll = ''); }
  }

  Future<void> _finishOverallAttendanceEdit() async {
    final request = _overallAttendanceRequest;
    if (!_overallAttendanceApproved || request == null) return;
    final confirm = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Finish overall edit?'),
      content: const Text('This will close the overall attendance edit permission. Further changes will need new admin approval.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Finish')),
      ],
    ));
    if (confirm != true) return;
    setState(() => _busyRoll = '*');
    try {
      await _api.post('/record-edit-requests/' + _value(request['id']) + '/finish', data: {'facultyId': _facultyId});
      _show('Overall attendance edit session completed.');
      await _loadEditRequests();
    } catch (e) { _show(e.toString().replaceFirst('Exception: ', '')); }
    finally { if (mounted) setState(() => _busyRoll = ''); }
  }

  Future<void> _save({bool overwrite = false}) async {
    if (_students.isEmpty) return;
    setState(() => _saving = true);
    try {
      final records = _visibleStudents.where((s) => !_savedAttendance.containsKey((s['roll_no'] ?? '').toString())).map((s) => {'roll_no': s['roll_no'], 'status': _attendance[(s['roll_no'] ?? '').toString()] ?? 'Present'}).toList();
      if (records.isEmpty) { _show('There are no new attendance records to save.'); return; }
      await _api.post('/attendance', data: {
        'records': records,
        'subject': int.parse(_subject),
        'facultyId': widget.facultyId,
        'date': _date.toIso8601String().split('T').first,
        'overwrite': overwrite,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Attendance saved successfully.')));
      await _loadStudents();
    } catch (e) {
      final message = e.toString().replaceFirst('Exception: ', '');
      if (mounted && message.toLowerCase().contains('duplicate')) {
        final confirm = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
          title: const Text('Attendance already exists'),
          content: const Text('Overwrite the attendance already recorded for this class, subject and date?'),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Overwrite'))],
        ));
        if (confirm == true) { await _save(overwrite: true); return; }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not save attendance: $message')));
      }
    } finally { if (mounted) setState(() => _saving = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Enter Attendance'), foregroundColor: AppColors.primary, backgroundColor: AppColors.surface, actions: [IconButton(onPressed: _loadClasses, icon: const Icon(Icons.refresh))]),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Card(color: AppColors.surface, elevation: 0, child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          if (_loadingClasses) const LinearProgressIndicator(),
          DropdownButtonFormField<String>(
            value: _classKey,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Class / Board', border: OutlineInputBorder()),
            items: _classes.map((c) {
              final board = (c['board'] ?? '').toString();
              final cls = (c['class'] ?? c['class_name'] ?? '').toString();
              return DropdownMenuItem(value: '$board||$cls', child: Text('$board - $cls'));
            }).toList(),
            onChanged: (v) => setState(() { _classKey = v; _students = []; _attendance = {}; _savedAttendance.clear(); _editRequests = []; _editDrafts.clear(); }),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _subject,
            decoration: const InputDecoration(labelText: 'Subject', border: OutlineInputBorder()),
            items: const [DropdownMenuItem(value: '1', child: Text('Maths')), DropdownMenuItem(value: '2', child: Text('Physics'))],
            onChanged: (v) => setState(() { _subject = v ?? '1'; _students = []; _attendance = {}; _savedAttendance.clear(); _editRequests = []; _editDrafts.clear(); }),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(onPressed: _pickDate, icon: const Icon(Icons.calendar_month_outlined), label: Text('Attendance date: ${_date.day.toString().padLeft(2, '0')}/${_date.month.toString().padLeft(2, '0')}/${_date.year}')),
          FilledButton.icon(onPressed: _loadingStudents || _loadingClasses ? null : _loadStudents, icon: const Icon(Icons.people_outline), label: Text(_loadingStudents ? 'Loading students...' : 'Load students')),
        ]))),
        if (_error != null) Card(color: Colors.red.shade50, child: ListTile(leading: const Icon(Icons.error_outline, color: Colors.red), title: const Text('Request failed'), subtitle: Text(_error!))),
        if (_loadingStudents) const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator())),
        if (!_loadingStudents && _students.isEmpty) const Card(child: ListTile(title: Text('Select class, subject and date, then load students.'))),
        if (_savedAttendance.isNotEmpty) Card(
          color: Colors.amber.shade50,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              const Text('Existing attendance is locked until admin approval.', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text(_overallAttendanceRequest?['status'] == 'Pending'
                  ? 'Overall edit request: Pending'
                  : _overallAttendanceApproved
                      ? 'Overall edit request: Approved'
                      : 'Request permission to edit all saved attendance for this date and subject.'),
              const SizedBox(height: 8),
              Wrap(spacing: 8, children: [
                OutlinedButton.icon(
                  onPressed: _busyRoll == '*' || _overallAttendanceRequest != null ? null : _requestOverallAttendanceEdit,
                  icon: const Icon(Icons.edit_note),
                  label: Text(_busyRoll == '*' ? 'Sending...' : _overallAttendanceRequest?['status'] == 'Pending' ? 'Request pending' : _overallAttendanceApproved ? 'Approved' : 'Request overall edit'),
                ),
                if (_overallAttendanceApproved) FilledButton(
                  onPressed: _busyRoll == '*' ? null : _finishOverallAttendanceEdit,
                  child: const Text('Finish overall edit'),
                ),
              ]),
            ]),
          ),
        ),
        if (_visibleStudents.isNotEmpty) Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Row(children: [
          Expanded(child: Text('${_visibleStudents.length} students', style: const TextStyle(fontWeight: FontWeight.w800))),
          TextButton(onPressed: () => setState(() { for (final s in _visibleStudents) { _attendance[(s['roll_no'] ?? '').toString()] = 'Present'; } }), child: const Text('Mark all present')),
        ])),
        if (_students.isNotEmpty) AcademicYearRangeFilter(
          students: _students,
          fromYear: _academicYearFrom,
          toYear: _academicYearTo,
          onFromChanged: (value) => setState(() => _academicYearFrom = value ?? ''),
          onToChanged: (value) => setState(() => _academicYearTo = value ?? ''),
        ),
        ..._visibleStudents.map((s) {
          final roll = (s['roll_no'] ?? '').toString();
          final name = (s['name'] ?? s['student_name'] ?? 'Student').toString();
          final saved = _savedAttendance.containsKey(roll);
          final request = _requestFor(roll);
          final pending = request?['status'] == 'Pending' || _overallAttendanceRequest?['status'] == 'Pending';
          final approved = request?['status'] == 'Approved' || _overallAttendanceApproved;
          return Card(color: AppColors.surface, elevation: 0, margin: const EdgeInsets.only(bottom: 8), child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(name, style: const TextStyle(fontWeight: FontWeight.w700))),
                if (saved) Chip(
                  label: Text(pending ? 'Request Pending' : approved ? 'Edit Approved' : 'Saved • Locked'),
                  visualDensity: VisualDensity.compact,
                  backgroundColor: pending ? Colors.orange.shade50 : Colors.green.shade50,
                ),
              ]),
              Text('Roll No: $roll'),
              const SizedBox(height: 8),
              if (saved && approved)
                DropdownButton<String>(
                  value: _editDrafts[roll] ?? _savedAttendance[roll],
                  items: const [DropdownMenuItem(value: 'Present', child: Text('Present')), DropdownMenuItem(value: 'Absent', child: Text('Absent'))],
                  onChanged: (v) => setState(() => _editDrafts[roll] = v ?? _savedAttendance[roll] ?? 'Present'),
                )
              else if (saved)
                Text('Saved attendance: ' + (_savedAttendance[roll] ?? ''), style: const TextStyle(fontWeight: FontWeight.w700))
              else
                DropdownButton<String>(
                  value: _attendance[roll] ?? 'Present',
                  items: const [DropdownMenuItem(value: 'Present', child: Text('Present')), DropdownMenuItem(value: 'Absent', child: Text('Absent'))],
                  onChanged: (v) => setState(() => _attendance[roll] = v ?? 'Present'),
                ),
              if (saved && pending) const Padding(padding: EdgeInsets.only(top: 6), child: Text('Your edit request is waiting for admin approval.', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.w600))),
              if (saved) Padding(padding: const EdgeInsets.only(top: 8), child: Wrap(spacing: 8, children: [
                if (!approved) OutlinedButton.icon(
                  onPressed: _busyRoll == roll || pending ? null : () => _requestAttendanceEdit(s),
                  icon: const Icon(Icons.lock_open),
                  label: Text(_busyRoll == roll ? 'Sending...' : pending ? 'Request pending' : 'Request edit'),
                ),
                if (approved) FilledButton(
                  onPressed: _busyRoll == roll ? null : () => _applyApprovedAttendanceEdit(s),
                  child: Text(_busyRoll == roll ? 'Saving...' : 'Save approved edit'),
                ),
              ])),
            ]),
          ));
        }),
        if (_students.any((s) => !_savedAttendance.containsKey((s['roll_no'] ?? '').toString())))
          FilledButton.icon(onPressed: _saving ? null : () => _save(), icon: _saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.save_outlined), label: Text(_saving ? 'Saving...' : 'Save new attendance')),
      ]),
    );
  }
}
