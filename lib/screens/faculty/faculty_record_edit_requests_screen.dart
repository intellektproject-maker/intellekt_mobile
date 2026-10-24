import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';
import '../../core/constants/colors.dart';

class FacultyRecordEditRequestsScreen extends StatefulWidget {
  final String adminId;
  const FacultyRecordEditRequestsScreen({super.key, required this.adminId});

  @override
  State<FacultyRecordEditRequestsScreen> createState() => _FacultyRecordEditRequestsScreenState();
}

class _FacultyRecordEditRequestsScreenState extends State<FacultyRecordEditRequestsScreen> {
  final _api = ApiClient();
  List<Map<String, dynamic>> _requests = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final response = await _api.get('/record-edit-requests', queryParameters: {'adminId': widget.adminId});
      if (response.data is! List) throw Exception('Unexpected requests response.');
      _requests = (response.data as List).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _review(Map<String, dynamic> request, String decision) async {
    final noteController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(decision == 'approve' ? 'Approve edit request?' : 'Decline edit request?'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('${request['requested_by_name'] ?? request['requested_by']} requested to change ${request['student_name'] ?? request['roll_no']} from ${request['original_value']} to ${request['requested_value']}.'),
          const SizedBox(height: 12),
          TextField(controller: noteController, decoration: const InputDecoration(labelText: 'Admin note (optional)', border: OutlineInputBorder())),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(decision == 'approve' ? 'Approve' : 'Decline')),
        ],
      ),
    );
    if (confirmed != true) { noteController.dispose(); return; }
    try {
      await _api.put('/record-edit-requests/${request['id']}/review', data: {
        'adminId': widget.adminId, 'decision': decision, 'note': noteController.text.trim(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Request ${decision}d.')));
      await _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Review failed: ${e.toString().replaceFirst('Exception: ', '')}')));
    } finally { noteController.dispose(); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Record Edit Requests'),
        foregroundColor: AppColors.primary,
        backgroundColor: AppColors.surface,
        actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh))],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Padding(padding: const EdgeInsets.all(20), child: Text(_error!, textAlign: TextAlign.center)))
              : _requests.isEmpty
                  ? const Center(child: Text('No record edit requests yet.'))
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _requests.length,
                        itemBuilder: (context, index) {
                          final r = _requests[index];
                          final pending = (r['status'] ?? '') == 'Pending';
                          final type = (r['record_type'] ?? '').toString();
                          return Card(
                            color: AppColors.surface,
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Row(children: [
                                  Expanded(child: Text('${r['student_name'] ?? 'Student'} (${r['roll_no'] ?? '-'})', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800))),
                                  Chip(label: Text((r['status'] ?? 'Pending').toString())),
                                ]),
                                const SizedBox(height: 5),
                                Text('Type: ${type == 'marks' ? 'Marks' : 'Attendance'} • ${type == 'marks' ? 'Test ${r['test_code'] ?? '-'}' : 'Subject ${r['subject_id'] ?? '-'} • ${r['attendance_date'] ?? '-'}'}'),
                                Text('Requested by: ${r['requested_by_name'] ?? r['requested_by'] ?? '-'}'),
                                const SizedBox(height: 8),
                                Text('Current value: ${r['original_value']}'),
                                Text('Requested value: ${r['requested_value']}', style: const TextStyle(fontWeight: FontWeight.w700)),
                                if ((r['review_note'] ?? '').toString().isNotEmpty) Text('Note: ${r['review_note']}'),
                                if (pending) ...[
                                  const SizedBox(height: 10),
                                  Row(children: [
                                    Expanded(child: OutlinedButton.icon(onPressed: () => _review(r, 'decline'), icon: const Icon(Icons.close), label: const Text('Decline'))),
                                    const SizedBox(width: 10),
                                    Expanded(child: FilledButton.icon(onPressed: () => _review(r, 'approve'), icon: const Icon(Icons.check), label: const Text('Approve'))),
                                  ]),
                                ],
                              ]),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
