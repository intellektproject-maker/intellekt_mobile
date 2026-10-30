import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/api/api_client.dart';
import '../../core/constants/colors.dart';

class FacultyManageMarksScreen extends StatefulWidget {
  const FacultyManageMarksScreen({super.key});

  @override
  State<FacultyManageMarksScreen> createState() => _FacultyManageMarksScreenState();
}

class _FacultyManageMarksScreenState extends State<FacultyManageMarksScreen> {
  final _api = ApiClient();
  final _name = TextEditingController();
  final _className = TextEditingController();
  final _board = TextEditingController();
  final _testCode = TextEditingController();
  final _editController = TextEditingController();
  List<Map<String, dynamic>> _marks = [];
  bool _loading = false;
  String? _error;
  int? _editingIndex;

  @override
  void dispose() { _name.dispose(); _className.dispose(); _board.dispose(); _testCode.dispose(); _editController.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final response = await _api.get('/marks', queryParameters: {
        if (_name.text.trim().isNotEmpty) 'name': _name.text.trim(),
        if (_className.text.trim().isNotEmpty) 'className': _className.text.trim(),
        if (_board.text.trim().isNotEmpty) 'board': _board.text.trim(),
        if (_testCode.text.trim().isNotEmpty) 'testCode': _testCode.text.trim(),
      });
      if (response.data is! List) throw Exception('Unexpected response from server.');
      _marks = (response.data as List).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally { if (mounted) setState(() => _loading = false); }
  }

  Future<void> _update(Map<String, dynamic> row) async {
    final value = num.tryParse(_editController.text.trim());
    final total = num.tryParse((row['total_marks'] ?? '').toString());
    if (value == null || value < 0 || (total != null && value > total)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter valid marks within the total marks.')));
      return;
    }
    final confirmed = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Update marks?'),
      content: Text('Save ${value.toString()} marks for ${row['name'] ?? row['student_name'] ?? row['roll_no']}?'),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save'))],
    ));
    if (confirmed != true) return;
    try {
      final facultyId = (Provider.of<AuthProvider>(context, listen: false).user?.id ?? '').trim().toUpperCase();
      if (facultyId == 'IG001' || facultyId == 'IG002') {
        await _api.put('/marks/${Uri.encodeComponent((row['roll_no'] ?? '').toString())}/${Uri.encodeComponent((row['test_code'] ?? '').toString())}', data: {'marks': value});
        if (!mounted) return;
        setState(() => _editingIndex = null);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Marks updated successfully.')));
        await _load();
      } else {
        await _api.post('/record-edit-requests', data: {'facultyId': facultyId, 'recordType': 'marks', 'roll_no': (row['roll_no'] ?? '').toString(), 'test_code': (row['test_code'] ?? '').toString(), 'requested_value': value.toString()});
        if (!mounted) return;
        setState(() => _editingIndex = null);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Edit permission request sent to IG001 and IG002.')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Update failed: ${e.toString().replaceFirst('Exception: ', '')}')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Manage Marks'), foregroundColor: AppColors.primary, backgroundColor: AppColors.surface, actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh))]),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Card(color: AppColors.surface, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade200)), child: Padding(
          padding: const EdgeInsets.all(16), child: Column(children: [
            TextField(controller: _name, decoration: const InputDecoration(labelText: 'Student name', prefixIcon: Icon(Icons.person_outline), border: OutlineInputBorder())),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: TextField(controller: _board, decoration: const InputDecoration(labelText: 'Board', border: OutlineInputBorder()))),
              const SizedBox(width: 10),
              Expanded(child: TextField(controller: _className, decoration: const InputDecoration(labelText: 'Class', border: OutlineInputBorder()))),
            ]),
            const SizedBox(height: 10),
            TextField(controller: _testCode, decoration: const InputDecoration(labelText: 'Test code', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: FilledButton.icon(onPressed: _loading ? null : _load, icon: const Icon(Icons.search), label: const Text('Search marks'))),
              const SizedBox(width: 8),
              OutlinedButton(onPressed: () { _name.clear(); _board.clear(); _className.clear(); _testCode.clear(); setState(() { _marks = []; _error = null; }); }, child: const Text('Clear')),
            ]),
          ]),
        )),
        const SizedBox(height: 14),
        if (_error != null) Card(color: Colors.red.shade50, child: ListTile(leading: const Icon(Icons.error_outline, color: Colors.red), title: const Text('Could not load marks'), subtitle: Text(_error!))),
        if (_loading) const Padding(padding: EdgeInsets.all(28), child: Center(child: CircularProgressIndicator())),
        if (!_loading && _error == null && _marks.isEmpty) const Card(child: ListTile(title: Text('Search to view marks records.'))),
        ..._marks.asMap().entries.map((entry) {
          final i = entry.key; final row = entry.value;
          final name = (row['name'] ?? row['student_name'] ?? 'Student').toString();
          final roll = (row['roll_no'] ?? '-').toString();
          final code = (row['test_code'] ?? '-').toString();
          final marks = (row['marks_obtained'] ?? '-').toString();
          final total = (row['total_marks'] ?? '-').toString();
          return Card(color: AppColors.surface, elevation: 0, margin: const EdgeInsets.only(bottom: 9), child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            const SizedBox(height: 4),
            Text('Roll: $roll • Test: $code'),
            const SizedBox(height: 8),
            if (_editingIndex == i) Row(children: [
              Expanded(child: TextField(controller: _editController, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(labelText: 'Marks / $total', border: const OutlineInputBorder()))),
              IconButton(onPressed: () => _update(row), icon: const Icon(Icons.check_circle_outline, color: Colors.green), tooltip: 'Save'),
              IconButton(onPressed: () => setState(() => _editingIndex = null), icon: const Icon(Icons.close)),
            ]) else Row(children: [
              Expanded(child: Text('Marks: $marks / $total', style: const TextStyle(fontWeight: FontWeight.w600))),
              TextButton.icon(onPressed: () { setState(() { _editingIndex = i; _editController.text = marks == '-' ? '' : marks; }); }, icon: const Icon(Icons.edit_outlined), label: const Text('Edit')),
            ]),
          ])));
        }),
      ]),
    );
  }
}
