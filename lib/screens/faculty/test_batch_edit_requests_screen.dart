import 'package:flutter/material.dart';

import '../../core/api/api_client.dart';
import '../../core/constants/colors.dart';

/// Test Batch edit workflow shared by Admin (review) and Faculty (request).
/// This screen uses the same API contract as the web dashboard.
class TestBatchEditRequestsScreen extends StatefulWidget {
  final String userId;
  const TestBatchEditRequestsScreen({super.key, required this.userId});

  @override
  State<TestBatchEditRequestsScreen> createState() =>
      _TestBatchEditRequestsScreenState();
}

class _TestBatchEditRequestsScreenState
    extends State<TestBatchEditRequestsScreen> {
  final ApiClient _api = ApiClient();
  final _formKey = GlobalKey<FormState>();
  final _roll = TextEditingController();
  final _testCode = TextEditingController();
  final _subject = TextEditingController();
  final _date = TextEditingController();
  final _original = TextEditingController();
  final _requested = TextEditingController();
  final _note = TextEditingController();
  String _type = 'marks';
  bool _loading = true;
  bool _saving = false;
  String? _error;
  List<Map<String, dynamic>> _requests = [];

  String get _id => widget.userId.trim().toUpperCase();
  bool get _isAdmin => _id == 'IG001' || _id == 'IG002';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final controller in [
      _roll, _testCode, _subject, _date, _original, _requested, _note,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  String _errorText(Object error) =>
      error.toString().replaceFirst('Exception: ', '').trim();

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final response = await _api.get(
        _isAdmin
            ? '/test-batch/record-edit-requests'
            : '/test-batch/record-edit-requests/mine',
        queryParameters: _isAdmin ? {'adminId': _id} : {'facultyId': _id},
      );
      final data = response.data;
      final rows = data is List
          ? data
          : data is Map && data['requests'] is List
              ? data['requests'] as List
              : <dynamic>[];
      if (!mounted) return;
      setState(() {
        _requests = rows.whereType<Map>()
            .map((row) => Map<String, dynamic>.from(row)).toList();
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() { _error = _errorText(error); _loading = false; });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _saving = true; _error = null; });
    try {
      await _api.post('/test-batch/record-edit-requests', data: {
        'facultyId': _id,
        'recordType': _type,
        'roll_no': _roll.text.trim().toUpperCase(),
        if (_type == 'marks') ...{
          'test_code': _testCode.text.trim().toUpperCase(),
          'subject_name': _subject.text.trim(),
        },
        if (_type == 'attendance') 'attendance_date': _date.text.trim(),
        'original_value': _original.text.trim(),
        'requested_value': _requested.text.trim(),
      });
      _roll.clear(); _testCode.clear(); _subject.clear(); _date.clear();
      _original.clear(); _requested.clear();
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Edit request sent to Admin.')),
        );
      }
    } catch (error) {
      if (mounted) setState(() => _error = _errorText(error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _review(Map<String, dynamic> request, String decision) async {
    final id = request['id'];
    if (id == null) return;
    setState(() { _saving = true; _error = null; });
    try {
      await _api.put(
        '/test-batch/record-edit-requests/$id/review',
        data: {
          'adminId': _id,
          'decision': decision,
          'note': _note.text.trim(),
        },
      );
      _note.clear();
      await _load();
    } catch (error) {
      if (mounted) setState(() => _error = _errorText(error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _applyApproved(Map<String, dynamic> request) async {
    final id = request['id'];
    if (id == null) return;
    setState(() { _saving = true; _error = null; });
    try {
      await _api.post('/test-batch/record-edit-requests/$id/apply', data: {
        'facultyId': _id,
      });
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Approved change applied successfully.')),
        );
      }
    } catch (error) {
      if (mounted) setState(() => _error = _errorText(error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'Required' : null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_isAdmin ? 'Review Edit Requests' : 'My Edit Requests'),
        foregroundColor: AppColors.primary,
        backgroundColor: AppColors.surface,
        actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh))],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (!_isAdmin) _requestForm(),
            if (_error != null)
              Card(child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              )),
            Text(
              _isAdmin ? 'Faculty requests' : 'Request history',
              style: const TextStyle(
                color: AppColors.primary, fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            if (_loading) const Center(child: CircularProgressIndicator()),
            if (!_loading && _requests.isEmpty)
              const Card(child: ListTile(title: Text('No edit requests found.'))),
            ..._requests.map(_requestCard),
          ],
        ),
      ),
    );
  }

  Widget _requestForm() => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Request permission to edit',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800,
                color: AppColors.primary)),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _type,
              decoration: const InputDecoration(
                labelText: 'Record type', border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: 'marks', child: Text('Marks')),
                DropdownMenuItem(value: 'attendance', child: Text('Attendance')),
              ],
              onChanged: (value) => setState(() => _type = value ?? 'marks'),
            ),
            const SizedBox(height: 10),
            TextFormField(controller: _roll, validator: _required,
              decoration: const InputDecoration(labelText: 'Student roll number',
                border: OutlineInputBorder())),
            if (_type == 'marks') ...[
              const SizedBox(height: 10),
              TextFormField(controller: _testCode, validator: _required,
                decoration: const InputDecoration(labelText: 'Test code',
                  border: OutlineInputBorder())),
              const SizedBox(height: 10),
              TextFormField(controller: _subject,
                decoration: const InputDecoration(labelText: 'Subject (optional)',
                  border: OutlineInputBorder())),
            ] else ...[
              const SizedBox(height: 10),
              TextFormField(controller: _date, validator: (v) {
                if (v == null || !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(v.trim())) {
                  return 'Use YYYY-MM-DD';
                }
                return null;
              }, decoration: const InputDecoration(labelText: 'Attendance date (YYYY-MM-DD)',
                border: OutlineInputBorder())),
            ],
            const SizedBox(height: 10),
            TextFormField(controller: _original, validator: _required,
              decoration: const InputDecoration(labelText: 'Current value',
                border: OutlineInputBorder())),
            const SizedBox(height: 10),
            TextFormField(controller: _requested, validator: _required,
              decoration: InputDecoration(
                labelText: _type == 'marks' ? 'Requested marks (or A)' : 'Requested status (Present/Absent)',
                border: const OutlineInputBorder())),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _saving ? null : _submit,
              child: Text(_saving ? 'Sending...' : 'Send edit request'),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _requestCard(Map<String, dynamic> request) {
    final status = (request['status'] ?? 'Pending').toString();
    final isPending = status.toLowerCase() == 'pending';
    final type = (request['record_type'] ?? '').toString();
    final record = type == 'marks'
        ? 'Test ${request['test_code'] ?? '-'} · ${request['subject_name'] ?? '-'}'
        : 'Attendance · ${request['attendance_date'] ?? '-'}';
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(child: Text(
                '${request['student_name'] ?? request['roll_no'] ?? 'Student'} (${request['roll_no'] ?? '-'})',
                style: const TextStyle(fontWeight: FontWeight.w800))),
              Chip(label: Text(status)),
            ]),
            Text(record),
            Text('Faculty: ${request['requested_by_name'] ?? request['requested_by'] ?? '-'}'),
            Text('Change: ${request['original_value'] ?? '-'} → ${request['requested_value'] ?? '-'}'),
            if (!_isAdmin && status.toLowerCase() == 'approved') ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _saving ? null : () => _applyApproved(request),
                  child: const Text('Apply approved change'),
                ),
              ),
            ],
            if (_isAdmin && isPending) ...[
              const SizedBox(height: 10),
              TextField(controller: _note,
                decoration: const InputDecoration(labelText: 'Review note (optional)',
                  border: OutlineInputBorder())),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(child: OutlinedButton(
                  onPressed: _saving ? null : () => _review(request, 'decline'),
                  child: const Text('Reject'))),
                const SizedBox(width: 10),
                Expanded(child: FilledButton(
                  onPressed: _saving ? null : () => _review(request, 'approve'),
                  child: const Text('Approve'))),
              ]),
            ],
          ],
        ),
      ),
    );
  }
}
