import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';
import '../../core/constants/colors.dart';

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
  bool _loadingClasses = true;
  bool _loadingStudents = false;
  bool _saving = false;
  String? _error;

  String get _facultyId => widget.facultyId.trim().toUpperCase();
  String get _dateKey => _date.toIso8601String().split('T').first;
  String _value(dynamic value) => (value ?? '').toString();
  Map<String, dynamic>? _requestFor(String roll) {
    for (final request in _editRequests) {
      if (_value(request['record_type']) == 'attendance' && _value(request['roll_no']).trim().toUpperCase() == roll.trim().toUpperCase() && _value(request['attendance_date']).split('T').first == _dateKey && _value(request['subject_id']) == _subject) return request;
    }
    return null;
  }

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
      final dateKey = _dateKey;
      final report = await _api.get('/attendance', queryParameters: {'mode': 'report', 'class': '$board-$cls', 'from': dateKey, 'to': dateKey, 'subject': _subject});
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
      setState(() => _editRequests = response.data is List ? (response.data as List).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList() : []);
    } catch (_) {}
  }

  Future<void> _requestAttendanceEdit(Map<String, dynamic> student) async {
    final roll = _value(student['roll_no']).trim();
    final request = _requestFor(roll);
    if (request?['status'] == 'Pending') { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Your edit request is already pending with the admin.'))); return; }
    if (request?['status'] == 'Approved') { setState(() => _editDrafts[roll] = _savedAttendance[roll] ?? 'Present'); return; }
    final confirm = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(title: const Text('Request edit permission'), content: Text('Request admin approval to edit attendance for $roll on $_dateKey?'), actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Send request'))]));
    if (confirm != true) return;
    setState(() => _busyRoll = roll);
    try {
      final current = _savedAttendance[roll] ?? 'Present';
      final response = await _api.post('/record-edit-requests', data: {'facultyId': _facultyId, 'recordType': 'attendance', 'roll_no': roll, 'subject_id': int.parse(_subject), 'attendance_date': _dateKey, 'requested_value': current == 'Present' ? 'Absent' : 'Present'});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(response.data is Map && _value(response.data['message']).isNotEmpty ? _value(response.data['message']) : 'Edit request sent to admin.')));
      await _loadEditRequests();
    } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')))); }
    finally { if (mounted) setState(() => _busyRoll = ''); }
  }

  Future<void> _applyApprovedAttendanceEdit(Map<String, dynamic> student) async {
    final roll = _value(student['roll_no']).trim();
    final request = _requestFor(roll);
    final value = _editDrafts[roll] ?? _savedAttendance[roll] ?? '';
    if (request == null || request['status'] != 'Approved' || !['Present', 'Absent'].contains(value)) return;
    setState(() => _busyRoll = roll);
    try {
      await _api.post('/record-edit-requests/${request['id']}/apply', data: {'facultyId': _facultyId, 'newValue': value});
      if (!mounted) return;
      setState(() { _savedAttendance[roll] = value; _editDrafts.remove(roll); });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Approved attendance edit saved.')));
      await _loadEditRequests();
    } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')))); }
    finally { if (mounted) setState(() => _busyRoll = ''); }
  }

  Future<void> _save({bool overwrite = false}) async {
    if (_students.isEmpty) return;
    setState(() => _saving = true);
    try {
      final newStudents = _students.where((s) => !_savedAttendance.containsKey((s['roll_no'] ?? '').toString())).toList();
      if (newStudents.isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('All attendance records are already saved. Request admin approval to edit them.'))); return; }
      final records = newStudents.map((s) => {'roll_no': s['roll_no'], 'status': _attendance[(s['roll_no'] ?? '').toString()] ?? 'Present'}).toList();
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
        if (_students.isNotEmpty && _savedAttendance.isNotEmpty) Card(color: Colors.amber.shade50, child: const Padding(padding: EdgeInsets.all(14), child: Text('Previously saved attendance is locked. Request admin approval before making corrections.'))),
        if (_students.isNotEmpty) Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Row(children: [
          Expanded(child: Text('${_students.length} students', style: const TextStyle(fontWeight: FontWeight.w800))),
          TextButton(onPressed: () => setState(() { for (final s in _students) { _attendance[(s['roll_no'] ?? '').toString()] = 'Present'; } }), child: const Text('Mark all present')),
        ])),
        ..._students.map((s) {
          final roll = (s['roll_no'] ?? '').toString();
          final name = (s['name'] ?? s['student_name'] ?? 'Student').toString();
          final saved = _savedAttendance.containsKey(roll);
          final request = _requestFor(roll);
          final approved = request?['status'] == 'Approved';
          final pending = request?['status'] == 'Pending';
          return Card(color: AppColors.surface, elevation: 0, margin: const EdgeInsets.only(bottom: 8), child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
            Text('Roll No: $roll'),
            const SizedBox(height: 8),
            if (saved) Text('Saved attendance: ${_savedAttendance[roll]}', style: const TextStyle(fontWeight: FontWeight.w700)) else DropdownButton<String>(
              value: _attendance[roll] ?? 'Present',
              items: const [DropdownMenuItem(value: 'Present', child: Text('Present')), DropdownMenuItem(value: 'Absent', child: Text('Absent'))],
              onChanged: (v) => setState(() => _attendance[roll] = v ?? 'Present'),
            ),
            if (saved && pending) const Padding(padding: EdgeInsets.only(top: 6), child: Text('Edit request: Pending', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.w700))),
            if (saved && approved) ...[
              DropdownButton<String>(value: _editDrafts[roll] ?? _savedAttendance[roll], items: const [DropdownMenuItem(value: 'Present', child: Text('Present')), DropdownMenuItem(value: 'Absent', child: Text('Absent'))], onChanged: (v) => setState(() => _editDrafts[roll] = v ?? _savedAttendance[roll] ?? 'Present')),
              FilledButton(onPressed: _busyRoll == roll ? null : () => _applyApprovedAttendanceEdit(s), child: Text(_busyRoll == roll ? 'Saving...' : 'Save approved edit')),
            ] else if (saved) OutlinedButton.icon(onPressed: _busyRoll == roll ? null : () => _requestAttendanceEdit(s), icon: const Icon(Icons.lock_open), label: Text(_busyRoll == roll ? 'Sending...' : 'Request edit')),
          ])));
        }),
        if (_students.any((s) => !_savedAttendance.containsKey((s['roll_no'] ?? '').toString()))) FilledButton.icon(onPressed: _saving ? null : () => _save(), icon: _saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.save_outlined), label: Text(_saving ? 'Saving...' : 'Save attendance')),
      ]),
    );
  }
}
