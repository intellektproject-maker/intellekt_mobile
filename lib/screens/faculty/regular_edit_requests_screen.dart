import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';
import '../../core/constants/colors.dart';

class RegularEditRequestsScreen extends StatefulWidget {
  final String userId;
  const RegularEditRequestsScreen({super.key, required this.userId});

  @override
  State<RegularEditRequestsScreen> createState() => _RegularEditRequestsScreenState();
}

class _RegularEditRequestsScreenState extends State<RegularEditRequestsScreen> {
  final ApiClient _api = ApiClient();
  final _roll = TextEditingController();
  final _testCode = TextEditingController();
  final _subjectId = TextEditingController(text: '1');
  final _attendanceDate = TextEditingController();
  String _recordType = 'marks';
  String _attendanceValue = 'Present';
  List<Map<String, dynamic>> _requests = [];
  bool _loading = true;
  bool _saving = false;
  String? _error;

  String get _id => widget.userId.trim().toUpperCase();
  bool get _isAdmin => _id == 'IG001' || _id == 'IG002';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _roll.dispose();
    _testCode.dispose();
    _subjectId.dispose();
    _attendanceDate.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final response = await _api.get(
        _isAdmin ? '/record-edit-requests' : '/record-edit-requests/approved',
        queryParameters: _isAdmin ? {'adminId': _id} : {'facultyId': _id},
      );
      _requests = response.data is List
          ? (response.data as List).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
          : [];
      _requests = _requests.where((r) => r['status'] != 'Applied').toList();
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submitRequest() async {
    if (_roll.text.trim().isEmpty ||
        (_recordType == 'marks' && _testCode.text.trim().isEmpty) ||
        (_recordType == 'attendance' &&
            (_attendanceDate.text.trim().isEmpty || int.tryParse(_subjectId.text) == null))) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fill in the student roll number and all record details.')));
      return;
    }
    setState(() => _saving = true);
    try {
      await _api.post('/record-edit-requests', data: {
        'facultyId': _id,
        'recordType': _recordType,
        'roll_no': _roll.text.trim(),
        if (_recordType == 'marks') 'test_code': _testCode.text.trim(),
        if (_recordType == 'attendance') 'subject_id': int.parse(_subjectId.text),
        if (_recordType == 'attendance') 'attendance_date': _attendanceDate.text.trim(),
        // The backend records this as a permission request; the actual new value
        // is entered only after an administrator approves it.
        'requested_value': _recordType == 'marks' ? '0' : _attendanceValue,
      });
      if (!mounted) return;
      _roll.clear();
      _testCode.clear();
      _attendanceDate.clear();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Edit permission request sent to IG001 and IG002.')));
      await _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _review(Map<String, dynamic> request, String decision) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(decision == 'approve' ? 'Approve edit request?' : 'Reject edit request?'),
        content: Text('Request #${request['id']} for ${request['student_name'] ?? request['roll_no']}'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(decision == 'approve' ? 'Approve' : 'Reject')),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _api.put('/record-edit-requests/${request['id']}/review', data: {'adminId': _id, 'decision': decision});
      await _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
    }
  }

  Future<void> _apply(Map<String, dynamic> request) async {
    final controller = TextEditingController();
    final type = (request['record_type'] ?? '').toString();
    final value = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Apply approved edit'),
        content: TextField(
          controller: controller,
          keyboardType: type == 'marks' ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
          decoration: InputDecoration(
            labelText: type == 'marks' ? 'New marks (or A for absent)' : 'New attendance status',
            hintText: type == 'marks' ? 'Enter marks or A' : 'Present or Absent',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, controller.text.trim()), child: const Text('Apply')),
        ],
      ),
    );
    controller.dispose();
    if (value == null || value.isEmpty) return;
    try {
      await _api.post('/record-edit-requests/${request['id']}/apply', data: {'facultyId': _id, 'newValue': value});
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Approved edit applied successfully.')));
      await _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Edit Requests'),
        foregroundColor: AppColors.primary,
        backgroundColor: AppColors.surface,
        actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh))],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (!_isAdmin)
            Card(
              color: AppColors.surface,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('Request permission to edit a record', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.primary)),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _recordType,
                      decoration: const InputDecoration(labelText: 'Record type', border: OutlineInputBorder()),
                      items: const [
                        DropdownMenuItem(value: 'marks', child: Text('Marks')),
                        DropdownMenuItem(value: 'attendance', child: Text('Attendance')),
                      ],
                      onChanged: (v) => setState(() => _recordType = v ?? 'marks'),
                    ),
                    const SizedBox(height: 10),
                    TextField(controller: _roll, decoration: const InputDecoration(labelText: 'Student roll number', border: OutlineInputBorder())),
                    if (_recordType == 'marks') ...[
                      const SizedBox(height: 10),
                      TextField(controller: _testCode, decoration: const InputDecoration(labelText: 'Test code', border: OutlineInputBorder())),
                    ] else ...[
                      const SizedBox(height: 10),
                      TextField(controller: _subjectId, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Subject ID (1 Maths, 2 Physics)', border: OutlineInputBorder())),
                      const SizedBox(height: 10),
                      TextField(controller: _attendanceDate, readOnly: true, decoration: const InputDecoration(labelText: 'Attendance date (YYYY-MM-DD)', border: OutlineInputBorder(), suffixIcon: Icon(Icons.calendar_today)), onTap: () async {
                        final now = DateTime.now();
                        final picked = await showDatePicker(context: context, initialDate: now, firstDate: DateTime(now.year - 5), lastDate: DateTime(now.year + 1));
                        if (picked != null && mounted) setState(() => _attendanceDate.text = picked.toIso8601String().split('T').first);
                      }),
                    ],
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: _saving ? null : _submitRequest,
                      icon: const Icon(Icons.send_outlined),
                      label: Text(_saving ? 'Sending...' : 'Send approval request'),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),
          Text(_isAdmin ? 'Requests awaiting review' : 'Approved requests', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.primary)),
          const SizedBox(height: 8),
          if (_error != null) Card(color: Colors.red.shade50, child: ListTile(title: const Text('Could not load requests'), subtitle: Text(_error!))),
          if (_loading) const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator())),
          if (!_loading && _requests.isEmpty) Card(color: AppColors.surface, child: ListTile(title: Text(_isAdmin ? 'No edit requests found.' : 'No approved requests available.'), subtitle: const Text('Pull down or tap refresh to check again.'))),
          ..._requests.map((r) {
            final status = (r['status'] ?? 'Pending').toString();
            final type = (r['record_type'] ?? 'marks').toString();
            final student = (r['student_name'] ?? r['roll_no'] ?? '-').toString();
            final record = type == 'attendance' ? 'Attendance • ${r['attendance_date'] ?? '-'}' : 'Marks • ${r['test_code'] ?? '-'}';
            return Card(
              color: AppColors.surface,
              margin: const EdgeInsets.only(bottom: 10),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(student, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text('Request #${r['id']} • $record'),
                  const SizedBox(height: 6),
                  Text('Faculty: ${r['requested_by_name'] ?? r['requested_by'] ?? '-'}'),
                  const SizedBox(height: 6),
                  Chip(label: Text(status)),
                  if (_isAdmin && status == 'Pending') Row(children: [
                    Expanded(child: FilledButton(onPressed: () => _review(r, 'approve'), child: const Text('Approve'))),
                    const SizedBox(width: 8),
                    Expanded(child: OutlinedButton(onPressed: () => _review(r, 'decline'), child: const Text('Reject'))),
                  ]),
                  if (!_isAdmin && status == 'Approved') SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: () => _apply(r), icon: const Icon(Icons.check_circle_outline), label: const Text('Apply approved edit'))),
                ]),
              ),
            );
          }),
        ],
      ),
    );
  }
}
