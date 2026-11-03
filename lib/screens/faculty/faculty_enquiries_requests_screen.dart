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
  List<Map<String, dynamic>> _enquiries = [];
  List<Map<String, dynamic>> _requests = [];
  bool _loadingEnquiries = true;
  bool _loadingRequests = true;
  String? _enquiryError;
  String? _requestError;

  @override
  void initState() { super.initState(); _tabs = TabController(length: 2, vsync: this); _loadEnquiries(); _loadRequests(); }
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
    final status = (enquiry['status'] ?? 'Pending').toString();
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
    final reasonController = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject enquiry'),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Enter the reason for rejecting ${enquiry['student_name'] ?? 'this enquiry'}.'),
          const SizedBox(height: 12),
          TextField(controller: reasonController, autofocus: true, maxLines: 3, decoration: const InputDecoration(labelText: 'Rejection reason', hintText: 'Enter reason', border: OutlineInputBorder())),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(onPressed: () { final value = reasonController.text.trim(); if (value.isEmpty) return; Navigator.pop(ctx, value); }, child: const Text('Reject')),
        ],
      ),
    );
    reasonController.dispose();
    if (reason == null || reason.trim().isEmpty || !mounted) return;
    try {
      await _api.put('/enquiries/${Uri.encodeComponent(id.toString())}', data: {'status': 'Rejected', 'comment': reason.trim(), 'reason': reason.trim()});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enquiry rejected.')));
      await _loadEnquiries();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not reject enquiry: ${e.toString().replaceFirst('Exception: ', '')}')));
    }
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
        return Card(color: AppColors.surface, elevation: 0, child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 5),
          Text('Enquiry: ${item['enq_id'] ?? '-'} • Class/Board: ${item['class_board'] ?? '-'}'),
          Text('Subjects: ${item['subjects'] ?? '-'}'),
          Text('Parent: ${item['parent_name'] ?? '-'} • Phone: ${item['mobile_number'] ?? '-'}'),
          Text('Status: ${item['status'] ?? 'Pending'}'),
          if ((item['comment'] ?? item['reason'] ?? '').toString().isNotEmpty) Text('Note: ${item['comment'] ?? item['reason']}'),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (!{'Admitted', 'Rejected'}.contains((item['status'] ?? 'Pending').toString()))
                FilledButton.icon(
                  onPressed: () => _startAdmission(item),
                  icon: const Icon(Icons.person_add_alt_1),
                  label: Text((item['status'] ?? 'Pending').toString() == 'Admission In Progress' ? 'Continue Admission' : 'Accept & Enrol'),
                ),
              if (!{'Admitted', 'Rejected'}.contains((item['status'] ?? 'Pending').toString()))
                OutlinedButton.icon(
                  onPressed: () => _rejectEnquiry(item),
                  icon: const Icon(Icons.block, color: Colors.red),
                  label: const Text('Reject', style: TextStyle(color: Colors.red)),
                ),
              OutlinedButton.icon(
                onPressed: () => _deleteEnquiry(item),
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                label: const Text('Delete', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ])));
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
      bottom: TabBar(controller: _tabs, labelColor: AppColors.primary, tabs: const [Tab(text: 'Enquiries'), Tab(text: 'Requests')]),
      actions: [IconButton(onPressed: () { if (_tabs.index == 0) { _loadEnquiries(); } else { _loadRequests(); } }, icon: const Icon(Icons.refresh))],
    ),
    body: TabBarView(controller: _tabs, children: [
      _state(loading: _loadingEnquiries, error: _enquiryError, retry: _loadEnquiries, empty: 'No enquiries found.', items: _enquiries, requests: false),
      _state(loading: _loadingRequests, error: _requestError, retry: _loadRequests, empty: 'No answer-sheet requests found.', items: _requests, requests: true),
    ]),
  );
}
