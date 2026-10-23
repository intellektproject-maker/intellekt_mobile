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
  String? _testCode;
  Map<String, dynamic>? _test;
  bool _loadingTests = true;
  bool _loadingStudents = false;
  bool _saving = false;
  String? _error;

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
    setState(() { _loadingStudents = true; _students = []; _marks = {}; _comments = {}; _error = null; });
    try {
      final response = await _api.get('/enter-marks-students', queryParameters: {'className': cls, 'board': board, 'testCode': code});
      if (response.data is! List) throw Exception('Unexpected students response.');
      final students = (response.data as List).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
      final marksResponse = await _api.get('/marks', queryParameters: {'testCode': code, 'className': cls, 'board': board});
      final existing = marksResponse.data is List ? (marksResponse.data as List).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList() : [];
      final marks = <String, String>{};
      final comments = <String, String>{};
      for (final row in existing) {
        final roll = (row['roll_no'] ?? '').toString();
        if (roll.isNotEmpty) {
          marks[roll] = row['marks_obtained']?.toString() ?? '';
          comments[roll] = (row['comments'] ?? '').toString();
        }
      }
      if (mounted) setState(() { _students = students; _marks = marks; _comments = comments; });
    } catch (e) {
      if (mounted) setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally { if (mounted) setState(() => _loadingStudents = false); }
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
      final records = _students.map((s) {
        final roll = (s['roll_no'] ?? '').toString();
        final value = _marks[roll]!.trim().toUpperCase();
        return {'roll_no': roll, 'student_name': s['name'] ?? s['student_name'] ?? '', 'marks': value == 'A' ? 'A' : num.parse(value), 'comments': _comments[roll] ?? '', 'test_code': _testCode!.toUpperCase().trim(), 'total_marks': total};
      }).toList();
      await _api.post('/marks', data: {'records': records, 'facultyId': widget.facultyId});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Marks saved successfully.')));
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
              setState(() { _testCode = v; _test = found.isEmpty ? null : found.first; _students = []; _marks = {}; _comments = {}; _totalController.text = found.isEmpty ? '' : (found.first['total_marks'] ?? '').toString(); });
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
        ..._students.map((s) {
          final roll = (s['roll_no'] ?? '').toString();
          final name = (s['name'] ?? s['student_name'] ?? 'Student').toString();
          return Card(color: AppColors.surface, elevation: 0, margin: const EdgeInsets.only(bottom: 8), child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, style: const TextStyle(fontWeight: FontWeight.w800)),
            Text('Roll No: $roll'),
            const SizedBox(height: 8),
            TextFormField(
              key: ValueKey('mark-$roll'),
              initialValue: _marks[roll] ?? '',
              keyboardType: TextInputType.text,
              decoration: const InputDecoration(labelText: 'Marks (or A if absent)', border: OutlineInputBorder()),
              onChanged: (v) { final total = num.tryParse(_totalController.text) ?? 0; setState(() { _marks[roll] = v.trim(); _comments[roll] = _commentFor(v.trim(), total); }); },
            ),
            if ((_comments[roll] ?? '').isNotEmpty) Padding(padding: const EdgeInsets.only(top: 6), child: Text('Comment: ${_comments[roll]}', style: const TextStyle(color: AppColors.textSecondary))),
          ])));
        }),
        if (_students.isNotEmpty) FilledButton.icon(onPressed: _saving ? null : _save, icon: _saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.save_outlined), label: Text(_saving ? 'Saving marks...' : 'Save marks')),
      ]),
    );
  }
}
