import 'package:flutter/material.dart';

import '../../core/api/api_client.dart';
import '../../core/constants/colors.dart';

/// Admin-only Test Batch student management. Uses isolated /test-batch APIs.
class TestBatchStudentsScreen extends StatefulWidget {
  final String adminId;
  const TestBatchStudentsScreen({super.key, required this.adminId});

  @override
  State<TestBatchStudentsScreen> createState() => _TestBatchStudentsScreenState();
}

class _TestBatchStudentsScreenState extends State<TestBatchStudentsScreen> {
  final ApiClient _api = ApiClient();
  final _search = TextEditingController();
  final _name = TextEditingController();
  final _roll = TextEditingController();
  final _className = TextEditingController();
  final _board = TextEditingController();
  final _subjects = TextEditingController();
  final _password = TextEditingController();
  List<Map<String, dynamic>> _students = [];
  List<Map<String, dynamic>> _series = [];
  String? _seriesId;
  String? _editingRoll;
  bool _loading = true;
  bool _saving = false;
  String? _error;
  int _page = 0;
  static const int _pageSize = 10;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose(); _name.dispose(); _roll.dispose(); _className.dispose();
    _board.dispose(); _subjects.dispose(); _password.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final results = await Future.wait([
        _api.get('/test-batch/series', queryParameters: {'adminId': widget.adminId}),
        _api.get('/test-batch/students', queryParameters: {
          'adminId': widget.adminId,
          if (_search.text.trim().isNotEmpty) 'search': _search.text.trim(),
        }),
      ]);
      final seriesData = results[0].data;
      final studentsData = results[1].data;
      if (!mounted) return;
      setState(() {
        final rawSeries = seriesData is Map ? seriesData['series'] : null;
        _series = rawSeries is List
            ? rawSeries.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
            : [];
        final rawStudents = studentsData is Map ? studentsData['students'] : null;
        _students = rawStudents is List
            ? rawStudents.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
            : [];
        _seriesId ??= _series.isEmpty ? null : _series.first['id']?.toString();
        _page = 0;
        _loading = false;
      });
    } catch (error) {
      if (mounted) setState(() {
        _error = error.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  void _clearForm() {
    _editingRoll = null;
    _name.clear(); _roll.clear(); _className.clear(); _board.clear();
    _subjects.clear(); _password.clear();
    _seriesId = _series.isEmpty ? null : _series.first['id']?.toString();
  }

  void _edit(Map<String, dynamic> student) {
    setState(() {
      _editingRoll = student['roll_no']?.toString();
      _roll.text = _editingRoll ?? '';
      _name.text = student['name']?.toString() ?? '';
      _className.text = student['class']?.toString() ?? '';
      _board.text = student['board']?.toString() ?? '';
      _subjects.text = student['subjects']?.toString() ?? '';
      _seriesId = student['test_series_id']?.toString();
      _password.clear();
    });
    _showForm();
  }

  Future<void> _showForm() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) => StatefulBuilder(builder: (context, setSheetState) =>
        Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 16),
          child: SingleChildScrollView(child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(_editingRoll == null ? 'Add Test Batch Student' : 'Edit Test Batch Student',
                style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: AppColors.primary)),
              const SizedBox(height: 12),
              TextField(controller: _roll, enabled: _editingRoll == null,
                decoration: const InputDecoration(labelText: 'Roll number (IAT001)', border: OutlineInputBorder())),
              const SizedBox(height: 10),
              TextField(controller: _name, decoration: const InputDecoration(labelText: 'Student name', border: OutlineInputBorder())),
              const SizedBox(height: 10),
              TextField(controller: _className, decoration: const InputDecoration(labelText: 'Class', border: OutlineInputBorder())),
              const SizedBox(height: 10),
              TextField(controller: _board, decoration: const InputDecoration(labelText: 'Board', border: OutlineInputBorder())),
              const SizedBox(height: 10),
              TextField(controller: _subjects, decoration: const InputDecoration(labelText: 'Subjects (Mathematics / Physics / Both)', border: OutlineInputBorder())),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _series.any((s) => s['id'].toString() == _seriesId) ? _seriesId : null,
                decoration: const InputDecoration(labelText: 'Test Series', border: OutlineInputBorder()),
                items: _series.map((s) => DropdownMenuItem(
                  value: s['id'].toString(), child: Text(s['name']?.toString() ?? 'Series'))).toList(),
                onChanged: (v) => setSheetState(() => _seriesId = v),
              ),
              const SizedBox(height: 10),
              TextField(controller: _password, obscureText: true,
                decoration: const InputDecoration(labelText: 'Password (optional)', border: OutlineInputBorder())),
              const SizedBox(height: 14),
              FilledButton(
                onPressed: _saving ? null : () async {
                  if (_roll.text.trim().isEmpty || _name.text.trim().isEmpty ||
                      _className.text.trim().isEmpty || _seriesId == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Roll, name, class and test series are required.')));
                    return;
                  }
                  setSheetState(() {});
                  await _save();
                  if (mounted && _error == null) Navigator.of(sheetContext).pop();
                },
                child: Text(_saving ? 'Saving...' : 'Save Student'),
              ),
            ],
          )),
        )),
    );
  }

  Future<void> _save() async {
    setState(() { _saving = true; _error = null; });
    try {
      final payload = <String, dynamic>{
        'adminId': widget.adminId,
        'roll_no': _roll.text.trim().toUpperCase(),
        'name': _name.text.trim(),
        'class': _className.text.trim(),
        'board': _board.text.trim(),
        'subjects': _subjects.text.trim(),
        'test_series_id': int.parse(_seriesId!),
        if (_password.text.isNotEmpty) 'password': _password.text,
      };
      if (_editingRoll == null) {
        await _api.post('/test-batch/students', data: payload);
      } else {
        await _api.put('/test-batch/students/${Uri.encodeComponent(_editingRoll!)}', data: payload);
      }
      _clearForm();
      await _load();
    } catch (error) {
      if (mounted) setState(() => _error = error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete(String roll) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Test Batch student?'),
        content: Text('Delete $roll? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _api.delete('/test-batch/students/${Uri.encodeComponent(roll)}',
        data: {'adminId': widget.adminId});
      await _load();
    } catch (error) {
      if (mounted) setState(() => _error = error.toString().replaceFirst('Exception: ', ''));
    }
  }

  @override
  Widget build(BuildContext context) {
    final start = _page * _pageSize;
    final pageRows = _students.skip(start).take(_pageSize).toList();
    final pages = (_students.length / _pageSize).ceil().clamp(1, 999999);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Test Batch Students'),
        foregroundColor: AppColors.primary,
        backgroundColor: AppColors.surface,
        actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh))],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () { _clearForm(); _showForm(); },
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Add Student'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
        children: [
          TextField(controller: _search, onSubmitted: (_) => _load(),
            decoration: InputDecoration(
              labelText: 'Search name or roll number',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(onPressed: _load, icon: const Icon(Icons.search)),
            )),
          if (_error != null) Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text(_error!, style: const TextStyle(color: Colors.red))),
          if (_loading) const Padding(
            padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator())),
          if (!_loading && _students.isEmpty)
            const Card(child: ListTile(title: Text('No Test Batch students found.'))),
          ...pageRows.map((student) => Card(
            child: ListTile(
              title: Text(student['name']?.toString() ?? '-',
                style: const TextStyle(fontWeight: FontWeight.w800)),
              subtitle: Text('Roll: ${student['roll_no'] ?? '-'} · Class: ${student['class'] ?? '-'}\nBoard: ${student['board'] ?? '-'} · ${student['test_series_name'] ?? '-'}'),
              isThreeLine: true,
              trailing: PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') _edit(student);
                  if (value == 'delete') _delete(student['roll_no'].toString());
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'edit', child: Text('Edit')),
                  PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              ),
            ),
          )),
          if (_students.isNotEmpty) Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Page ${_page + 1} of $pages'),
              Row(children: [
                IconButton(onPressed: _page > 0 ? () => setState(() => _page--) : null,
                  icon: const Icon(Icons.chevron_left)),
                IconButton(onPressed: _page + 1 < pages ? () => setState(() => _page++) : null,
                  icon: const Icon(Icons.chevron_right)),
              ]),
            ],
          ),
        ],
      ),
    );
  }
}
