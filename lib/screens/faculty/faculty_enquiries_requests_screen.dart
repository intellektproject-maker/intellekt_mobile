import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';
import '../../core/constants/colors.dart';

class FacultyEnquiriesRequestsScreen extends StatefulWidget {
  const FacultyEnquiriesRequestsScreen({super.key});

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
