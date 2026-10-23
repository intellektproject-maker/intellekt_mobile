import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';
import '../../core/constants/colors.dart';

class FacultyPostTestScreen extends StatefulWidget {
  final String facultyId;
  const FacultyPostTestScreen({super.key, required this.facultyId});

  @override
  State<FacultyPostTestScreen> createState() => _FacultyPostTestScreenState();
}

class _FacultyPostTestScreenState extends State<FacultyPostTestScreen> {
  final _api = ApiClient();
  final _formKey = GlobalKey<FormState>();
  final _code = TextEditingController();
  final _marks = TextEditingController();
  final _portion = TextEditingController();
  final _duration = TextEditingController(text: '60');
  List<Map<String, dynamic>> _classes = [];
  List<Map<String, dynamic>> _tests = [];
  String _subject = '1';
  String _class = '';
  String _board = '';
  DateTime? _testDate;
  DateTime? _registrationEnd;
  DateTime? _writingTill;
  String? _editingCode;
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _code.dispose(); _marks.dispose(); _portion.dispose(); _duration.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final results = await Future.wait([_api.get('/classes'), _api.get('/posted-tests')]);
      _classes = results[0].data is List
          ? (results[0].data as List).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
          : [];
      _tests = results[1].data is List
          ? (results[1].data as List).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
          : [];
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _dateText(DateTime? d) => d == null ? 'Select date' : '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  String _dateValue(DateTime d) => d.toIso8601String().split('T').first;

  Future<void> _pickDate(String field) async {
    final now = DateTime.now();
    final current = field == 'test' ? _testDate : field == 'registration' ? _registrationEnd : _writingTill;
    final picked = await showDatePicker(context: context, initialDate: current ?? now, firstDate: DateTime(now.year, now.month, now.day), lastDate: DateTime(now.year + 5));
    if (picked == null || !mounted) return;
    setState(() {
      if (field == 'test') _testDate = picked;
      if (field == 'registration') _registrationEnd = picked;
      if (field == 'writing') _writingTill = picked;
    });
  }

  void _edit(Map<String, dynamic> test) {
    setState(() {
      _editingCode = (test['test_code'] ?? '').toString();
      _code.text = _editingCode!;
      _marks.text = (test['total_marks'] ?? '').toString();
      _portion.text = (test['portion'] ?? '').toString();
      _duration.text = (test['duration_minutes'] ?? 60).toString();
      _subject = (test['subject_id'] ?? 1).toString();
      _class = (test['class'] ?? test['class_name'] ?? '').toString();
      _board = (test['board'] ?? '').toString();
      _testDate = DateTime.tryParse((test['test_date'] ?? '').toString());
      _registrationEnd = DateTime.tryParse((test['registration_end_date'] ?? '').toString());
      _writingTill = DateTime.tryParse((test['writing_allowed_till'] ?? '').toString());
    });
  }

  void _reset() {
    _formKey.currentState?.reset();
    setState(() {
      _editingCode = null; _code.clear(); _marks.clear(); _portion.clear(); _duration.text = '60';
      _subject = '1'; _class = ''; _board = ''; _testDate = null; _registrationEnd = null; _writingTill = null;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_testDate == null || _registrationEnd == null || _writingTill == null || _class.isEmpty || _board.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select class, test date, registration deadline and writing deadline.')));
      return;
    }
    if (_registrationEnd!.isAfter(_testDate!) || _registrationEnd!.isAtSameMomentAs(_testDate!) || _writingTill!.isBefore(_testDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Registration must end before the test; writing deadline must be on or after the test.')));
      return;
    }
    setState(() => _saving = true);
    try {
      final payload = {
        'test_code': _code.text.trim().toUpperCase(),
        'subject_id': int.parse(_subject),
        'test_date': _dateValue(_testDate!),
        'total_marks': num.parse(_marks.text),
        'portion': _portion.text.trim(),
        'created_by': widget.facultyId,
        'class_name': _class,
        'board': _board,
        'duration_minutes': int.parse(_duration.text),
        'registration_end_date': _dateValue(_registrationEnd!),
        'writing_allowed_till': _dateValue(_writingTill!),
      };
      if (_editingCode == null) {
        await _api.post('/post-test', data: payload);
      } else {
        await _api.put('/posted-tests/${Uri.encodeComponent(_editingCode!)}', data: payload);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_editingCode == null ? 'Test posted successfully.' : 'Test updated successfully.')));
      _reset();
      await _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not save test: ${e.toString().replaceFirst('Exception: ', '')}')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete(String code) async {
    final yes = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Delete test?'), content: Text('Delete $code?'),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete'))],
    ));
    if (yes != true) return;
    try {
      await _api.delete('/posted-tests/${Uri.encodeComponent(code)}');
      if (mounted) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Test deleted.'))); if (_editingCode == code) _reset(); await _load(); }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not delete test: $e')));
    }
  }

  Widget _dateButton(String label, String field, DateTime? date) => OutlinedButton.icon(
    onPressed: () => _pickDate(field), icon: const Icon(Icons.calendar_month_outlined), label: Text('$label: ${_dateText(date)}'),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Post Test'), foregroundColor: AppColors.primary, backgroundColor: AppColors.surface, actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh))]),
      body: _loading ? const Center(child: CircularProgressIndicator()) : RefreshIndicator(
        onRefresh: _load,
        child: ListView(padding: const EdgeInsets.all(16), children: [
          if (_error != null) Card(color: Colors.red.shade50, child: ListTile(title: const Text('Unable to load test data'), subtitle: Text(_error!))),
          Card(color: AppColors.surface, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade200)), child: Padding(
            padding: const EdgeInsets.all(16),
            child: Form(key: _formKey, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Text(_editingCode == null ? 'Create a test' : 'Edit test', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.primary)),
              const SizedBox(height: 14),
              TextFormField(controller: _code, enabled: _editingCode == null, textCapitalization: TextCapitalization.characters, decoration: const InputDecoration(labelText: 'Test code', border: OutlineInputBorder()), validator: (v) => v == null || v.trim().isEmpty ? 'Enter test code' : null),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(value: _subject, decoration: const InputDecoration(labelText: 'Subject', border: OutlineInputBorder()), items: const [DropdownMenuItem(value: '1', child: Text('Maths')), DropdownMenuItem(value: '2', child: Text('Physics'))], onChanged: (v) => setState(() => _subject = v ?? '1')),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(value: _class.isEmpty ? null : '$_class||$_board', decoration: const InputDecoration(labelText: 'Class / Board', border: OutlineInputBorder()), items: _classes.map((c) { final cl = (c['class'] ?? c['class_name'] ?? '').toString(); final br = (c['board'] ?? '').toString(); return DropdownMenuItem(value: '$cl||$br', child: Text('$br - $cl')); }).toList(), onChanged: (v) { final p = (v ?? '||').split('||'); setState(() { _class = p.first; _board = p.length > 1 ? p[1] : ''; }); }),
              const SizedBox(height: 12),
              TextFormField(controller: _marks, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Total marks', border: OutlineInputBorder()), validator: (v) => num.tryParse(v ?? '') == null || num.parse(v!) <= 0 ? 'Enter a positive total' : null),
              const SizedBox(height: 12),
              TextFormField(controller: _duration, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Duration (minutes)', border: OutlineInputBorder()), validator: (v) => int.tryParse(v ?? '') == null || int.parse(v!) <= 0 ? 'Enter duration' : null),
              const SizedBox(height: 12),
              TextFormField(controller: _portion, decoration: const InputDecoration(labelText: 'Portion / syllabus (optional)', border: OutlineInputBorder())),
              const SizedBox(height: 8),
              _dateButton('Test date', 'test', _testDate),
              _dateButton('Registration closes', 'registration', _registrationEnd),
              _dateButton('Writing allowed till', 'writing', _writingTill),
              const SizedBox(height: 12),
              FilledButton.icon(onPressed: _saving ? null : _save, icon: _saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.save_outlined), label: Text(_saving ? 'Saving...' : _editingCode == null ? 'Post test' : 'Update test')),
              if (_editingCode != null) TextButton(onPressed: _reset, child: const Text('Cancel editing')),
            ])),
          )),
          const SizedBox(height: 20),
          Text('Posted tests (${_tests.length})', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.primary)),
          const SizedBox(height: 8),
          if (_tests.isEmpty) const Card(child: ListTile(title: Text('No posted tests found.'))),
          ..._tests.map((t) {
            final code = (t['test_code'] ?? '').toString();
            return Card(color: AppColors.surface, elevation: 0, child: ListTile(
              title: Text(code, style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text('${t['board'] ?? ''}-${t['class'] ?? t['class_name'] ?? ''} • ${t['total_marks'] ?? '-'} marks\nDate: ${t['test_date'] ?? '-'}'),
              isThreeLine: true,
              trailing: PopupMenuButton<String>(onSelected: (v) => v == 'edit' ? _edit(t) : _delete(code), itemBuilder: (_) => const [PopupMenuItem(value: 'edit', child: Text('Edit')), PopupMenuItem(value: 'delete', child: Text('Delete'))]),
            );
          }),
        ]),
      ),
    );
  }
}
