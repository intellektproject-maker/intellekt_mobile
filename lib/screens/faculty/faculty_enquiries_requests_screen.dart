import 'dart:math';
import 'package:flutter/material.dart';
import 'enquiry_admission_screen.dart';
import '../../core/api/api_client.dart';
import '../../core/constants/colors.dart';

class FacultyEnquiriesRequestsScreen extends StatefulWidget {
  final String adminId;
  const FacultyEnquiriesRequestsScreen({super.key, required this.adminId});

  @override
  State<FacultyEnquiriesRequestsScreen> createState() => _FacultyEnquiriesRequestsScreenState();
}

class _FacultyEnquiriesRequestsScreenState extends State<FacultyEnquiriesRequestsScreen> with SingleTickerProviderStateMixin {
  final _api = ApiClient();
  late final TabController _tabs;
  int _selectedTab = 0;
  List<Map<String, dynamic>> _enquiries = [];
  List<Map<String, dynamic>> _requests = [];
  bool _loadingEnquiries = true;
  bool _loadingRequests = true;
  String? _enquiryError;
  String? _requestError;

  @override
  void initState() { super.initState(); _tabs = TabController(length: 3, vsync: this); _loadEnquiries(); _loadRequests(); }
  @override
  void dispose() { _tabs.dispose(); super.dispose(); }

  Future<void> _loadEnquiries() async {
    setState(() { _loadingEnquiries = true; _enquiryError = null; });
    try {
      final res = await _api.get('/enquiries');
      if (res.data is! List) throw Exception('Unexpected enquiries response.');
      _enquiries = (res.data as List).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (e) { _enquiryError = e.toString().replaceFirst('Exception: ', ''); }
    finally { if (mounted) setState(() => _loadingEnquiries = false); }
  }

  Future<void> _loadRequests() async {
    setState(() { _loadingRequests = true; _requestError = null; });
    try {
      final res = await _api.get('/answer-sheet-requests');
      if (res.data is! List) throw Exception('Unexpected requests response.');
      _requests = (res.data as List).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (e) { _requestError = e.toString().replaceFirst('Exception: ', ''); }
    finally { if (mounted) setState(() => _loadingRequests = false); }
  }

  Future<void> _startAdmission(Map<String, dynamic> enquiry) async {
    final status = (enquiry['status'] ?? 'New').toString();
    if (status == 'Admitted') {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('This enquiry is already enrolled.')));
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Accept enquiry?'),
        content: Text('Start admission for ${enquiry['student_name'] ?? 'this student'}? You will review and complete the student registration form next.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Accept & Continue')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final token = 'admission-${DateTime.now().microsecondsSinceEpoch}-${Random.secure().nextInt(1 << 32)}';
    try {
      final id = enquiry['id'];
      if (id == null) throw Exception('Enquiry ID is missing.');
      await _api.post('/enquiries/${Uri.encodeComponent(id.toString())}/admission/start',
          data: {'admission_token': token});
      if (!mounted) return;
      final completed = await Navigator.of(context).push<bool>(
        MaterialPageRoute(builder: (_) => EnquiryAdmissionScreen(
          enquiry: enquiry,
          admissionToken: token,
          adminId: widget.adminId,
        )),
      );
      if (!mounted) return;
      if (completed == true) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enquiry converted to an enrolled student.')));
      }
      await _loadEnquiries();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not start admission: ${e.toString().replaceFirst('Exception: ', '')}')),
      );
      await _loadEnquiries();
    }
  }

  Future<void> _rejectEnquiry(Map<String, dynamic> enquiry) async {
    final id = enquiry['id'];
    if (id == null) return;

    // The web dashboard's Reject action deletes the enquiry; it does not
    // update its status through PUT /enquiries/:id.
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject enquiry?'),
        content: Text(
          'Reject and remove the enquiry for ${enquiry['student_name'] ?? 'this student'}? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await _api.delete('/enquiries/${Uri.encodeComponent(id.toString())}');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enquiry rejected and removed.')),
      );
      await _loadEnquiries();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Could not reject enquiry: ${e.toString().replaceFirst('Exception: ', '')}',
            ),
          ),
        );
      }
    }
  }

  Future<void> _markAsPending(Map<String, dynamic> enquiry) async {
    final id = enquiry['id'];
    if (id == null) return;
    try {
      await _api.put('/enquiries/${Uri.encodeComponent(id.toString())}', data: {
        'status': 'Pending',
        'comment': '',
        'reason': '',
      });
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enquiry moved to Pending.')),
      );
      await _loadEnquiries();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not mark as pending: ${e.toString().replaceFirst('Exception: ', '')}')),
      );
    }
  }

  Future<void> _showEnquiryReview(Map<String, dynamic> enquiry) async {
    String value(String key) {
      final v = enquiry[key];
      if (v == null || v.toString().trim().isEmpty) return '-';
      return v.toString();
    }
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(value('student_name'), style: const TextStyle(fontWeight: FontWeight.w800)),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _detail('Enquiry ID', value('enq_id')),
                _detail('Class / Board', value('class_board')),
                _detail('Date of Birth', value('date_of_birth')),
                _detail('Batch', value('batch')),
                _detail('School', value('school_name')),
                _detail('Subjects', value('subjects')),
                _detail('Academic Year', '${value('academic_year_from')} - ${value('academic_year_to')}'),
                _detail('Parent', value('parent_name')),
                _detail('Mobile', value('mobile_number')),
                _detail('Secondary Contact', value('secondary_contact')),
                _detail('Reference', value('reference')),
                _detail('Registered Date', _formatRegisteredDate(enquiry['created_at'])),
              ],
            ),
          ),
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FilledButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                    _startAdmission(enquiry);
                  },
                  child: const Text('Accept & Enrol'),
                ),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                    _rejectEnquiry(enquiry);
                  },
                  child: const Text('Reject'),
                ),
                OutlinedButton(
                  onPressed: () => _markAsPending(enquiry),
                  child: const Text('Mark as Pending'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _detail(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 9),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    ),
  );

  String _formatRegisteredDate(dynamic raw) {
    if (raw == null) return '-';
    final date = DateTime.tryParse(raw.toString());
    if (date == null) return raw.toString();
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _deleteEnquiry(Map<String, dynamic> enquiry) async {
    final id = enquiry['id'];
    if (id == null) return;
    final confirmed = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Delete enquiry?'),
      content: Text('Permanently delete the enquiry for ${enquiry['student_name'] ?? 'this student'}? This cannot be undone.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
        FilledButton(style: FilledButton.styleFrom(backgroundColor: Colors.red), onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
      ],
    ));
    if (confirmed != true) return;
    try {
      await _api.delete('/enquiries/${Uri.encodeComponent(id.toString())}');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enquiry deleted.')));
      await _loadEnquiries();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not delete enquiry: ${e.toString().replaceFirst('Exception: ', '')}')));
    }
  }
  Future<void> _completeRequest(Map<String, dynamic> request) async {
    final id = request['id'];
    if (id == null) return;
    final confirmed = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Mark request completed?'),
      content: Text('Remove the answer-sheet request for ${request['student_name'] ?? request['roll_no'] ?? 'this student'} from the pending list?'),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Complete'))],
    ));
    if (confirmed != true) return;
    try {
      await _api.delete('/answer-sheet-requests/${Uri.encodeComponent(id.toString())}');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Request marked completed.')));
      await _loadRequests();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not complete request: ${e.toString().replaceFirst('Exception: ', '')}')));
    }
  }

  Widget _state({required bool loading, required String? error, required Future<void> Function() retry, required String empty, required List<Map<String, dynamic>> items, required bool requests}) {
    if (loading) return const Center(child: CircularProgressIndicator());
    if (error != null) return Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.cloud_off_outlined, size: 40), const SizedBox(height: 8), Text(error, textAlign: TextAlign.center), const SizedBox(height: 12), OutlinedButton(onPressed: retry, child: const Text('Retry'))])));
    if (items.isEmpty) return Center(child: Text(empty));
    return RefreshIndicator(onRefresh: retry, child: ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final item = items[i];
        if (requests) {
          return Card(color: AppColors.surface, elevation: 0, child: ListTile(
            title: Text((item['student_name'] ?? item['roll_no'] ?? 'Student').toString(), style: const TextStyle(fontWeight: FontWeight.w800)),
            subtitle: Text('Roll: ${item['roll_no'] ?? '-'} • Class: ${item['class_name'] ?? '-'}\nTest: ${item['test_code'] ?? '-'} • Status: ${item['status'] ?? 'Pending'}\nPhone: ${item['requested_phone'] ?? '-'}'),
            isThreeLine: true,
            trailing: IconButton(tooltip: 'Mark completed', onPressed: () => _completeRequest(item), icon: const Icon(Icons.check_circle_outline, color: Colors.green)),
          ));
        }
        final name = (item['student_name'] ?? 'Student').toString();
        return Card(
          color: AppColors.surface,
          elevation: 0,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _showEnquiryReview(item),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                  const SizedBox(height: 5),
                  Text('Enquiry: ${item['enq_id'] ?? '-'} • Class/Board: ${item['class_board'] ?? '-'}'),
                  Text('Subjects: ${item['subjects'] ?? '-'}'),
                  Text('School: ${item['school_name'] ?? '-'}'),
                  Text('Parent: ${item['parent_name'] ?? '-'} • Phone: ${item['mobile_number'] ?? '-'}'),
                  Text('Registered: ${_formatRegisteredDate(item['created_at'])}'),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () => _showEnquiryReview(item),
                      icon: const Icon(Icons.visibility_outlined),
                      label: const Text('Review'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    appBar: AppBar(
      title: const Text('Enquiries & Requests'),
      foregroundColor: AppColors.primary,
      backgroundColor: AppColors.surface,
      bottom: TabBar(
        controller: _tabs,
        labelColor: AppColors.primary,
        onTap: (index) => setState(() => _selectedTab = index),
        tabs: const [Tab(text: 'Enquiries'), Tab(text: 'Pending'), Tab(text: 'Requests')],
      ),
      actions: [IconButton(onPressed: () { if (_tabs.index < 2) { _loadEnquiries(); } else { _loadRequests(); } }, icon: const Icon(Icons.refresh))],
    ),
    body: TabBarView(controller: _tabs, children: [
      _state(
        loading: _loadingEnquiries,
        error: _enquiryError,
        retry: _loadEnquiries,
        empty: 'No new enquiries awaiting review.',
        items: _enquiries.where((e) {
          final status = (e['status'] ?? 'New').toString();
          return status == 'New';
        }).toList(),
        requests: false,
      ),
      _state(
        loading: _loadingEnquiries,
        error: _enquiryError,
        retry: _loadEnquiries,
        empty: 'No enquiries marked as pending.',
        items: _enquiries.where((e) => (e['status'] ?? '').toString() == 'Pending').toList(),
        requests: false,
      ),
      _state(loading: _loadingRequests, error: _requestError, retry: _loadRequests, empty: 'No answer-sheet requests found.', items: _requests, requests: true),
    ]),
  );
}


class _RejectEnquiryDialog extends StatefulWidget {
  final String studentName;
  const _RejectEnquiryDialog({required this.studentName});

  @override
  State<_RejectEnquiryDialog> createState() => _RejectEnquiryDialogState();
}

class _RejectEnquiryDialogState extends State<_RejectEnquiryDialog> {
  final _reasonController = TextEditingController();

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Reject enquiry'),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Enter the reason for rejecting ${widget.studentName}.'),
        const SizedBox(height: 12),
        TextField(
          controller: _reasonController,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Rejection reason',
            hintText: 'Enter reason',
            border: OutlineInputBorder(),
          ),
        ),
      ],
    ),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
      FilledButton(
        onPressed: () {
          final value = _reasonController.text.trim();
          if (value.isNotEmpty) Navigator.pop(context, value);
        },
        child: const Text('Reject'),
      ),
    ],
  );
}
