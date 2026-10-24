import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';
import '../../core/constants/colors.dart';

class FacultyManageMarksScreen extends StatefulWidget {
  final String facultyId;
  const FacultyManageMarksScreen({super.key, required this.facultyId});

  @override
  State<FacultyManageMarksScreen> createState() => _FacultyManageMarksScreenState();
}

class _FacultyManageMarksScreenState extends State<FacultyManageMarksScreen> {
  final _api = ApiClient();
  final _name = TextEditingController();
  final _editController = TextEditingController();
  List<Map<String, dynamic>> _classes = [];
  List<Map<String, dynamic>> _tests = [];
  List<Map<String, dynamic>> _marks = [];
  List<Map<String, dynamic>> _approved = [];
  String? _board;
  String? _className;
  String? _testCode;
  bool _loading = false;
  bool _loadingFilters = true;
  String? _error;
  int? _editingIndex;
  int? _editingRequestId;

  List<String> get _boards => _classes.map((e) => (e['board'] ?? '').toString().trim()).where((e) => e.isNotEmpty).toSet().toList()..sort();
  List<String> get _classOptions => _classes.where((e) => _board == null || (e['board'] ?? '').toString().trim() == _board).map((e) => (e['class'] ?? e['class_name'] ?? '').toString().trim()).where((e) => e.isNotEmpty).toSet().toList()..sort();
  List<Map<String, dynamic>> get _filteredTests => _tests.where((t) =>
    _board != null && _className != null &&
    (t['board'] ?? '').toString().trim().toUpperCase() == _board!.toUpperCase() &&
    (t['class'] ?? t['class_name'] ?? '').toString().trim() == _className
  ).toList();

  @override
  void initState() { super.initState(); _loadFilters(); }
  @override
  void dispose() { _name.dispose(); _editController.dispose(); super.dispose(); }

  Future<void> _loadFilters() async {
    setState(() { _loadingFilters = true; _error = null; });
    try {
      final results = await Future.wait([_api.get('/classes'), _api.get('/tests')]);
      _classes = results[0].data is List ? (results[0].data as List).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList() : [];
      _tests = results[1].data is List ? (results[1].data as List).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList() : [];
      try {
        final approvedResponse = await _api.get('/record-edit-requests/approved', queryParameters: {'facultyId': widget.facultyId});
        _approved = approvedResponse.data is List ? (approvedResponse.data as List).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList() : [];
      } catch (e) {
        debugPrint('Approved edit requests unavailable: $e');
      }
    } catch (e) { _error = e.toString().replaceFirst('Exception: ', ''); }
    finally { if (mounted) setState(() => _loadingFilters = false); }
  }

  Map<String, dynamic>? _approvedFor(Map<String, dynamic> row) {
    final roll = (row['roll_no'] ?? '').toString().toUpperCase();
    final code = (row['test_code'] ?? '').toString().toUpperCase();
    for (final request in _approved) {
      if ((request['record_type'] ?? '') == 'marks' &&
          (request['roll_no'] ?? '').toString().toUpperCase() == roll &&
          (request['test_code'] ?? '').toString().toUpperCase() == code &&
          (request['status'] ?? '') == 'Approved') return request;
    }
    return null;
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; _marks = []; _editingIndex = null; });
    try {
      final response = await _api.get('/marks', queryParameters: {
        if (_name.text.trim().isNotEmpty) 'name': _name.text.trim(),
        if (_className != null) 'className': _className,
        if (_board != null) 'board': _board,
        if (_testCode != null) 'testCode': _testCode,
      });
      if (response.data is! List) throw Exception('Unexpected response from server.');
      _marks = (response.data as List).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (e) { _error = e.toString().replaceFirst('Exception: ', ''); }
    finally { if (mounted) setState(() => _loading = false); }
  }

  Future<void> _requestOrApply(Map<String, dynamic> row) async {
    final value = _editController.text.trim();
    final total = num.tryParse((row['total_marks'] ?? '').toString());
    final isAbsent = value.toUpperCase() == 'A';
    final parsed = num.tryParse(value);
    if (value.isEmpty || (!isAbsent && (parsed == null || parsed < 0 || (total != null && parsed > total)))) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter valid marks within the total, or A for absent.')));
      return;
    }
    try {
      if (_editingRequestId != null) {
        await _api.post('/record-edit-requests/$_editingRequestId/apply', data: {'facultyId': widget.facultyId, 'newValue': value});
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Approved edit applied successfully.')));
        await _loadFilters();
      } else {
        await _api.post('/record-edit-requests', data: {
          'facultyId': widget.facultyId, 'recordType': 'marks',
          'roll_no': row['roll_no'], 'test_code': row['test_code'],
          'requested_value': isAbsent ? 'A' : parsed.toString(),
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Edit request sent to IG001 and IG002 for approval.')));
      }
      if (!mounted) return;
      setState(() { _editingIndex = null; _editingRequestId = null; });
      await _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Request failed: ${e.toString().replaceFirst('Exception: ', '')}')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Manage Marks'), foregroundColor: AppColors.primary, backgroundColor: AppColors.surface, actions: [IconButton(onPressed: _loadFilters, icon: const Icon(Icons.refresh))]),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Card(color: AppColors.surface, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade200)), child: Padding(
          padding: const EdgeInsets.all(16), child: Column(children: [
            TextField(controller: _name, textInputAction: TextInputAction.search, onSubmitted: (_) => _load(), decoration: const InputDecoration(labelText: 'Search by student name (optional)', prefixIcon: Icon(Icons.person_outline), border: OutlineInputBorder())),
            const SizedBox(height: 10),
            if (_loadingFilters) const LinearProgressIndicator(),
            DropdownButtonFormField<String>(value: _boards.contains(_board) ? _board : null, isExpanded: true, decoration: const InputDecoration(labelText: 'Board', border: OutlineInputBorder()), items: _boards.map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(), onChanged: (v) => setState(() { _board = v; _className = null; _testCode = null; })),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(value: _classOptions.contains(_className) ? _className : null, isExpanded: true, decoration: const InputDecoration(labelText: 'Class', border: OutlineInputBorder()), items: _classOptions.map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(), onChanged: (v) => setState(() { _className = v; _testCode = null; })),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(value: _filteredTests.any((t) => (t['test_code'] ?? '').toString() == _testCode) ? _testCode : null, isExpanded: true, decoration: const InputDecoration(labelText: 'Test Code (select Board and Class first)', border: OutlineInputBorder()), items: _filteredTests.map((t) { final code = (t['test_code'] ?? '').toString(); return DropdownMenuItem(value: code, child: Text(code)); }).toList(), onChanged: _board == null || _className == null ? null : (v) => setState(() => _testCode = v)),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: FilledButton.icon(onPressed: _loading ? null : _load, icon: const Icon(Icons.search), label: const Text('Search marks'))),
              const SizedBox(width: 8),
              OutlinedButton(onPressed: () { _name.clear(); setState(() { _board = null; _className = null; _testCode = null; _marks = []; _error = null; }); }, child: const Text('Clear')),
            ]),
          ]),
        )),
        const SizedBox(height: 14),
        if (_error != null) Card(color: Colors.red.shade50, child: ListTile(leading: const Icon(Icons.error_outline, color: Colors.red), title: const Text('Could not load marks'), subtitle: Text(_error!))),
        if (_loading) const Padding(padding: EdgeInsets.all(28), child: Center(child: CircularProgressIndicator())),
        if (!_loading && _error == null && _marks.isEmpty) const Card(child: ListTile(title: Text('Search by name or select a board, class and test code.'))),
        ..._marks.asMap().entries.map((entry) {
          final i = entry.key; final row = entry.value;
          final name = (row['name'] ?? row['student_name'] ?? 'Student').toString();
          final roll = (row['roll_no'] ?? '-').toString();
          final code = (row['test_code'] ?? '-').toString();
          final marks = (row['marks_obtained'] ?? '-').toString();
          final total = (row['total_marks'] ?? '-').toString();
          final approval = _approvedFor(row);
          return Card(color: AppColors.surface, elevation: 0, margin: const EdgeInsets.only(bottom: 9), child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            const SizedBox(height: 4),
            Text('Roll: $roll • ${row['board'] ?? '-'}-${row['class'] ?? '-'} • Test: $code'),
            const SizedBox(height: 8),
            if (_editingIndex == i) Row(children: [
              Expanded(child: TextField(controller: _editController, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(labelText: 'Marks / $total', border: const OutlineInputBorder()))),
              IconButton(onPressed: () => _requestOrApply(row), icon: const Icon(Icons.check_circle_outline, color: Colors.green), tooltip: approval == null ? 'Submit request' : 'Apply approved edit'),
              IconButton(onPressed: () => setState(() { _editingIndex = null; _editingRequestId = null; }), icon: const Icon(Icons.close)),
            ]) else Row(children: [
              Expanded(child: Text('Marks: $marks / $total', style: const TextStyle(fontWeight: FontWeight.w600))),
              TextButton.icon(onPressed: () { setState(() { _editingIndex = i; _editingRequestId = approval == null ? null : int.tryParse(approval['id'].toString()); _editController.text = marks == '-' ? '' : marks; }); }, icon: const Icon(Icons.edit_outlined), label: Text(approval == null ? 'Request Edit' : 'Edit Approved')),
            ]),
            if (approval != null) const Text('Admin approved this edit. Submit the final value to apply it.', style: TextStyle(color: Colors.green, fontSize: 12)),
          ])));
        }),
      ]),
    );
  }
}
