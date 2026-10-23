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
    if (picked != null && mounted) setState(() => _date = picked);
  }

  Future<void> _loadStudents() async {
    if (_classKey == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select a class first.')));
      return;
    }
    final selected = _classes.firstWhere((c) => '${c['board'] ?? ''}||${c['class'] ?? c['class_name'] ?? ''}' == _classKey);
    final board = (selected['board'] ?? '').toString();
    final cls = (selected['class'] ?? selected['class_name'] ?? '').toString();
    setState(() { _loadingStudents = true; _students = []; _attendance = {}; _error = null; });
    try {
      final response = await _api.get('/students', queryParameters: {'class': cls, 'board': board, 'subject_id': int.parse(_subject)});
      if (response.data is! List) throw Exception('Unexpected students response.');
      _students = (response.data as List).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
      _attendance = {for (final s in _students) (s['roll_no'] ?? '').toString(): 'Present'};
    } catch (e) { _error = e.toString().replaceFirst('Exception: ', ''); }
    finally { if (mounted) setState(() => _loadingStudents = false); }
  }

  Future<void> _save({bool overwrite = false}) async {
    if (_students.isEmpty) return;
    setState(() => _saving = true);
    try {
      final records = _students.map((s) => {'roll_no': s['roll_no'], 'status': _attendance[(s['roll_no'] ?? '').toString()] ?? 'Present'}).toList();
      await _api.post('/attendance', data: {
        'records': records,
        'subject': int.parse(_subject),
        'facultyId': widget.facultyId,
        'date': _date.toIso8601String().split('T').first,
        'overwrite': overwrite,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Attendance saved successfully.')));
      setState(() { _students = []; _attendance = {}; });
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
            onChanged: (v) => setState(() { _classKey = v; _students = []; _attendance = {}; }),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _subject,
            decoration: const InputDecoration(labelText: 'Subject', border: OutlineInputBorder()),
            items: const [DropdownMenuItem(value: '1', child: Text('Maths')), DropdownMenuItem(value: '2', child: Text('Physics'))],
            onChanged: (v) => setState(() { _subject = v ?? '1'; _students = []; _attendance = {}; }),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(onPressed: _pickDate, icon: const Icon(Icons.calendar_month_outlined), label: Text('Attendance date: ${_date.day.toString().padLeft(2, '0')}/${_date.month.toString().padLeft(2, '0')}/${_date.year}')),
          FilledButton.icon(onPressed: _loadingStudents || _loadingClasses ? null : _loadStudents, icon: const Icon(Icons.people_outline), label: Text(_loadingStudents ? 'Loading students...' : 'Load students')),
        ]))),
        if (_error != null) Card(color: Colors.red.shade50, child: ListTile(leading: const Icon(Icons.error_outline, color: Colors.red), title: const Text('Request failed'), subtitle: Text(_error!))),
        if (_loadingStudents) const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator())),
        if (!_loadingStudents && _students.isEmpty) const Card(child: ListTile(title: Text('Select class, subject and date, then load students.'))),
        if (_students.isNotEmpty) Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Row(children: [
          Expanded(child: Text('${_students.length} students', style: const TextStyle(fontWeight: FontWeight.w800))),
          TextButton(onPressed: () => setState(() { for (final s in _students) { _attendance[(s['roll_no'] ?? '').toString()] = 'Present'; } }), child: const Text('Mark all present')),
        ])),
        ..._students.map((s) {
          final roll = (s['roll_no'] ?? '').toString();
          final name = (s['name'] ?? s['student_name'] ?? 'Student').toString();
          return Card(color: AppColors.surface, elevation: 0, margin: const EdgeInsets.only(bottom: 8), child: ListTile(
            title: Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Text('Roll No: $roll'),
            trailing: DropdownButton<String>(
              value: _attendance[roll] ?? 'Present',
              items: const [DropdownMenuItem(value: 'Present', child: Text('Present')), DropdownMenuItem(value: 'Absent', child: Text('Absent'))],
              onChanged: (v) => setState(() => _attendance[roll] = v ?? 'Present'),
            ),
          ));
        }),
        if (_students.isNotEmpty) FilledButton.icon(onPressed: _saving ? null : () => _save(), icon: _saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.save_outlined), label: Text(_saving ? 'Saving...' : 'Save attendance')),
      ]),
    );
  }
}
