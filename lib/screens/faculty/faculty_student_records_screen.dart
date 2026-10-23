import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';
import '../../core/constants/colors.dart';

class FacultyStudentRecordsScreen extends StatefulWidget {
  const FacultyStudentRecordsScreen({super.key});

  @override
  State<FacultyStudentRecordsScreen> createState() => _FacultyStudentRecordsScreenState();
}

class _FacultyStudentRecordsScreenState extends State<FacultyStudentRecordsScreen> {
  final _api = ApiClient();
  final _search = TextEditingController();
  List<Map<String, dynamic>> _classes = [];
  List<Map<String, dynamic>> _students = [];
  String? _classKey;
  bool _loadingClasses = true;
  bool _loadingStudents = false;
  String? _error;

  @override
  void initState() { super.initState(); _loadClasses(); }
  @override
  void dispose() { _search.dispose(); super.dispose(); }

  Future<void> _loadClasses() async {
    try {
      final res = await _api.get('/classes');
      _classes = res.data is List ? (res.data as List).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList() : [];
    } catch (e) { _error = e.toString().replaceFirst('Exception: ', ''); }
    finally { if (mounted) setState(() => _loadingClasses = false); }
  }

  Future<void> _loadStudents() async {
    if (_classKey == null) return;
    final parts = _classKey!.split('||');
    final board = parts.first;
    final cls = parts.length > 1 ? parts[1] : '';
    setState(() { _loadingStudents = true; _error = null; });
    try {
      final res = await _api.get('/student-records', queryParameters: {'className': cls, 'board': board});
      if (res.data is! List) throw Exception('Unexpected student records response.');
      _students = (res.data as List).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (e) { _error = e.toString().replaceFirst('Exception: ', ''); }
    finally { if (mounted) setState(() => _loadingStudents = false); }
  }

  Future<void> _showRecord(Map<String, dynamic> student) async {
    final roll = (student['roll_no'] ?? '').toString();
    if (roll.isEmpty) return;
    showDialog<void>(context: context, barrierDismissible: false, builder: (ctx) => const Center(child: CircularProgressIndicator()));
    try {
      final res = await _api.get('/student-record-report/${Uri.encodeComponent(roll)}');
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      final data = res.data is Map ? Map<String, dynamic>.from(res.data as Map) : <String, dynamic>{};
      final person = data['student'] is Map ? Map<String, dynamic>.from(data['student'] as Map) : student;
      final attendance = data['attendance'] is Map ? Map<String, dynamic>.from(data['attendance'] as Map) : <String, dynamic>{};
      final marks = data['marks'] is List ? (data['marks'] as List).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList() : <Map<String, dynamic>>[];
      await showModalBottomSheet<void>(context: context, isScrollControlled: true, showDragHandle: true, builder: (ctx) => DraggableScrollableSheet(
        expand: false, initialChildSize: .8, maxChildSize: .95, builder: (ctx, scroll) => ListView(controller: scroll, padding: const EdgeInsets.all(20), children: [
          Text((person['name'] ?? person['student_name'] ?? 'Student Record').toString(), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.primary)),
          const SizedBox(height: 6),
          Text('Roll No: ${person['roll_no'] ?? roll} • Class: ${person['board'] ?? ''}-${person['class'] ?? ''}'),
          const SizedBox(height: 18),
          const Text('Attendance', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          Card(color: AppColors.surface, child: Padding(padding: const EdgeInsets.all(14), child: Text('Present: ${attendance['present_days'] ?? 0}   •   Absent: ${attendance['absent_days'] ?? 0}'))),
          const SizedBox(height: 12),
          const Text('Marks', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          if (marks.isEmpty) const Card(child: ListTile(title: Text('No marks records found.'))),
          ...marks.map((m) => Card(color: AppColors.surface, elevation: 0, child: ListTile(
            title: Text((m['test_code'] ?? 'Test').toString(), style: const TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Text((m['subject_name'] ?? '').toString()),
            trailing: Text('${m['marks_obtained'] ?? '-'} / ${m['total_marks'] ?? '-'}', style: const TextStyle(fontWeight: FontWeight.w800)),
          ))),
        ]),
      ));
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not load student record: ${e.toString().replaceFirst('Exception: ', '')}')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final query = _search.text.trim().toLowerCase();
    final visible = _students.where((s) => '${s['name'] ?? s['student_name'] ?? ''} ${s['roll_no'] ?? ''}'.toLowerCase().contains(query)).toList();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Student Records'), foregroundColor: AppColors.primary, backgroundColor: AppColors.surface, actions: [IconButton(onPressed: _loadStudents, icon: const Icon(Icons.refresh))]),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Card(color: AppColors.surface, elevation: 0, child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
          if (_loadingClasses) const LinearProgressIndicator(),
          DropdownButtonFormField<String>(value: _classKey, isExpanded: true, decoration: const InputDecoration(labelText: 'Select class', border: OutlineInputBorder()), items: _classes.map((c) { final b = (c['board'] ?? '').toString(); final cl = (c['class'] ?? c['class_name'] ?? '').toString(); return DropdownMenuItem(value: '$b||$cl', child: Text('$b-$cl')); }).toList(), onChanged: (v) { setState(() { _classKey = v; _students = []; }); if (v != null) _loadStudents(); }),
          const SizedBox(height: 12),
          TextField(controller: _search, onChanged: (_) => setState(() {}), decoration: const InputDecoration(labelText: 'Search by name or roll number', prefixIcon: Icon(Icons.search), border: OutlineInputBorder())),
        ]))),
        if (_error != null) Card(color: Colors.red.shade50, child: ListTile(title: const Text('Could not load records'), subtitle: Text(_error!))),
        if (_loadingStudents) const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator())),
        if (!_loadingStudents && _students.isEmpty) const Card(child: ListTile(title: Text('Select a class to view student records.'))),
        ...visible.map((s) => Card(color: AppColors.surface, elevation: 0, child: ListTile(
          title: Text((s['name'] ?? s['student_name'] ?? 'Student').toString(), style: const TextStyle(fontWeight: FontWeight.w800)),
          subtitle: Text('Roll No: ${s['roll_no'] ?? '-'} • Phone: ${s['phone'] ?? '-'}'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _showRecord(s),
        ))),
      ]),
    );
  }
}
