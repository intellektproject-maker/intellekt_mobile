import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';
import '../../core/constants/colors.dart';

class FacultyManageAttendanceScreen extends StatefulWidget {
  final String facultyId;
  const FacultyManageAttendanceScreen({super.key, required this.facultyId});

  @override
  State<FacultyManageAttendanceScreen> createState() => _FacultyManageAttendanceScreenState();
}

class _FacultyManageAttendanceScreenState extends State<FacultyManageAttendanceScreen> {
  final _api = ApiClient();
  List<Map<String, dynamic>> _classes = [];
  List<Map<String, dynamic>> _rows = [];
  String? _classBoard;
  String _subject = '';
  DateTime _from = DateTime.now().subtract(const Duration(days: 7));
  DateTime _to = DateTime.now();
  bool _loadingClasses = true;
  bool _loading = false;
  String? _error;

  @override
  void initState() { super.initState(); _loadClasses(); }

  Future<void> _loadClasses() async {
    try {
      final res = await _api.get('/classes');
      _classes = res.data is List ? (res.data as List).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList() : [];
    } catch (e) { _error = e.toString().replaceFirst('Exception: ', ''); }
    finally { if (mounted) setState(() => _loadingClasses = false); }
  }

  String _date(DateTime d) => d.toIso8601String().split('T').first;
  Future<void> _pickDate(bool from) async {
    final now = DateTime.now();
    final picked = await showDatePicker(context: context, initialDate: from ? _from : _to, firstDate: DateTime(now.year - 5), lastDate: now);
    if (picked != null && mounted) setState(() { if (from) { _from = picked; } else { _to = picked; } });
  }

  Future<void> _search({bool todayOnly = false}) async {
    if (_classBoard == null) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select a class.'))); return; }
    if (!todayOnly && _from.isAfter(_to)) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('From date must be before To date.'))); return; }
    setState(() { _loading = true; _error = null; _rows = []; });
    try {
      final params = <String, dynamic>{
        'mode': todayOnly ? 'markedToday' : 'report',
        'class': _classBoard,
        if (todayOnly) 'subject': int.parse(_subject),
        if (!todayOnly) 'from': _date(_from),
        if (!todayOnly) 'to': _date(_to),
        if (!todayOnly && _subject.isNotEmpty) 'subject': int.parse(_subject),
      };
      final res = await _api.get('/attendance', queryParameters: params);
      if (res.data is! List) throw Exception('Unexpected attendance response.');
      _rows = (res.data as List).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (e) { _error = e.toString().replaceFirst('Exception: ', ''); }
    finally { if (mounted) setState(() => _loading = false); }
  }

  Future<void> _edit(Map<String, dynamic> row) async {
    final current = (row['status'] ?? 'Present').toString();
    final selected = await showDialog<String>(context: context, builder: (ctx) => SimpleDialog(
      title: Text('Update attendance: ${row['name'] ?? row['student_name'] ?? row['roll_no'] ?? ''}'),
      children: ['Present', 'Absent'].map((s) => SimpleDialogOption(onPressed: () => Navigator.pop(ctx, s), child: Row(children: [Icon(s == 'Present' ? Icons.check_circle_outline : Icons.cancel_outlined), const SizedBox(width: 10), Text(s), if (s == current) const Spacer(), if (s == current) const Icon(Icons.check, size: 16)]))).toList(),
    ));
    if (selected == null || selected == current) return;
    final dateText = (row['attendance_date'] ?? '').toString().split('T').first;
    try {
      final facultyId = widget.facultyId.trim().toUpperCase();
      if (facultyId == 'IG001' || facultyId == 'IG002') {
        await _api.put('/attendance', data: {
          'records': [{'roll_no': row['roll_no'], 'status': selected}],
          'subject': row['subject_id'],
          'facultyId': facultyId,
          'date': dateText,
        });
        if (!mounted) return;
        setState(() {
          final i = _rows.indexWhere((r) => (r['roll_no'] ?? '') == (row['roll_no'] ?? '') && (r['attendance_date'] ?? '') == (row['attendance_date'] ?? '') && (r['subject_id'] ?? '') == (row['subject_id'] ?? ''));
          if (i >= 0) _rows[i]['status'] = selected;
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Attendance updated.')));
      } else {
        await _api.post('/record-edit-requests', data: {
          'facultyId': facultyId,
          'recordType': 'attendance',
          'roll_no': (row['roll_no'] ?? '').toString(),
          'subject_id': row['subject_id'],
          'attendance_date': dateText,
          'requested_value': selected,
        });
        if (!mounted) return;
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
      appBar: AppBar(title: const Text('Manage Attendance'), foregroundColor: AppColors.primary, backgroundColor: AppColors.surface, actions: [IconButton(onPressed: () => _search(), icon: const Icon(Icons.refresh))]),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Card(color: AppColors.surface, elevation: 0, child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          if (_loadingClasses) const LinearProgressIndicator(),
          DropdownButtonFormField<String>(value: _classBoard, isExpanded: true, decoration: const InputDecoration(labelText: 'Class / Board', border: OutlineInputBorder()), items: _classes.map((c) { final b = (c['board'] ?? '').toString(); final cl = (c['class'] ?? c['class_name'] ?? '').toString(); return DropdownMenuItem(value: '$b-$cl', child: Text('$b-$cl')); }).toList(), onChanged: (v) => setState(() => _classBoard = v)),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(value: _subject, decoration: const InputDecoration(labelText: 'Subject (optional for report)', border: OutlineInputBorder()), items: const [DropdownMenuItem(value: '', child: Text('All subjects')), DropdownMenuItem(value: '1', child: Text('Maths')), DropdownMenuItem(value: '2', child: Text('Physics'))], onChanged: (v) => setState(() => _subject = v ?? '')),
          const SizedBox(height: 8),
          Row(children: [Expanded(child: OutlinedButton(onPressed: () => _pickDate(true), child: Text('From: ${_date(_from)}'))), const SizedBox(width: 8), Expanded(child: OutlinedButton(onPressed: () => _pickDate(false), child: Text('To: ${_date(_to)}')))]),
          FilledButton.icon(onPressed: _loading ? null : () => _search(), icon: const Icon(Icons.search), label: const Text('View attendance report')),
          OutlinedButton.icon(onPressed: _loading || _subject.isEmpty ? null : () => _search(todayOnly: true), icon: const Icon(Icons.today_outlined), label: const Text('View attendance marked today')),
        ]))),
        if (_error != null) Card(color: Colors.red.shade50, child: ListTile(title: const Text('Could not load attendance'), subtitle: Text(_error!))),
        if (_loading) const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator())),
        if (!_loading && _rows.isEmpty) const Card(child: ListTile(title: Text('No attendance records loaded.'))),
        ..._rows.map((r) => Card(color: AppColors.surface, elevation: 0, margin: const EdgeInsets.only(bottom: 8), child: ListTile(
          title: Text((r['name'] ?? r['student_name'] ?? 'Student').toString(), style: const TextStyle(fontWeight: FontWeight.w700)),
          subtitle: Text('Roll: ${r['roll_no'] ?? '-'} • ${r['attendance_date'] ?? '-'}\nSubject: ${r['subject_name'] ?? r['subject_id'] ?? '-'}'),
          isThreeLine: true,
          trailing: TextButton(onPressed: () => _edit(r), child: Text((r['status'] ?? '-').toString())),
        ))),
      ]),
    );
  }
}
