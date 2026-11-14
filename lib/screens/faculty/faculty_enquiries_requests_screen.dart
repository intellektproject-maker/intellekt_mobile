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
  static const int _pageSize = 5;
  int _enquiriesPage = 0;
  int _pendingPage = 0;
  int _requestsPage = 0;

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

  Future<Map<String, int>> _currentClassBoardStudentCounts(Map<String, dynamic> enquiry) async {
    final combined = (enquiry['class_board'] ?? '').toString();
    final split = combined.lastIndexOf('-');
    if (split < 0) throw Exception('Could not identify the class and board from this enquiry.');
    final board = combined.substring(0, split).trim();
    final className = combined.substring(split + 1).trim();
    if (board.isEmpty || className.isEmpty) throw Exception('Class or board is missing from this enquiry.');

    final batch = (enquiry['batch'] ?? 'Regular Batch').toString().trim();
    final response = await _api.get('/student-count', queryParameters: {
      'class': className,
      'board': board,
      'batch': batch,
    });
    if (response.data is! Map) {
      throw Exception('Unexpected student-count response.');
    }

    final data = Map<String, dynamic>.from(response.data as Map);
    final subjectCounts = data['subject_counts'] is Map
        ? Map<String, dynamic>.from(data['subject_counts'] as Map)
        : <String, dynamic>{};

    return {
      'total': (data['count'] as num?)?.toInt() ?? 0,
      'mathematics': (subjectCounts['mathematics'] as num?)?.toInt() ?? 0,
      'physics': (subjectCounts['physics'] as num?)?.toInt() ?? 0,
      'both': (subjectCounts['both'] as num?)?.toInt() ?? 0,
    };
  }

  Future<String?> _promptPendingReason() {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _PendingReasonDialog(),
    );
  }

  Widget _subjectCountRow(String label, int count) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      children: [
        Expanded(child: Text(label, style: const TextStyle(fontSize: 14))),
        Text(
          count.toString(),
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.primary),
        ),
      ],
    ),
  );

  Future<void> _startAdmission(Map<String, dynamic> enquiry) async {
    final status = (enquiry['status'] ?? 'New').toString();
    if (status == 'Admitted') {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('This enquiry is already enrolled.')));
      return;
    }

    try {
      final counts = await _currentClassBoardStudentCounts(enquiry);
      if (!mounted) return;
      final combined = (enquiry['class_board'] ?? '').toString();
      final split = combined.lastIndexOf('-');
      final board = split >= 0 ? combined.substring(0, split).trim() : '-';
      final className = split >= 0 ? combined.substring(split + 1).trim() : '-';
      final decision = await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Text('Current Student Count'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Batch: ${enquiry['batch'] ?? 'Regular Batch'}'),
              Text('Board: $board'),
              Text('Class: $className'),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text('${counts['mathematics']! + counts['physics']!}', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: AppColors.primary)),
                    const Text('Total subject enrollments'),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _subjectCountRow('Mathematics Enrolled', counts['mathematics']!),
              _subjectCountRow('Physics Enrolled', counts['physics']!),
              const SizedBox(height: 8),
              const Text('Proceed to the student admission form or move this enquiry to Pending.'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, 'pending'),
              child: const Text('Pending'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, 'proceed'),
              child: const Text('Proceed'),
            ),
          ],
        ),
      );
      if (!mounted || decision == null) return;

      final id = enquiry['id'];
      if (id == null) throw Exception('Enquiry ID is missing.');
      if (decision == 'pending') {
        final reason = await _promptPendingReason();
        if (reason == null || !mounted) return;
        await _api.put('/enquiries/${Uri.encodeComponent(id.toString())}', data: {
          'status': 'Pending',
          'comment': '',
          'reason': reason,
        });
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enquiry moved to Pending.')));
        await _loadEnquiries();
        return;
      }

      final token = 'admission-${DateTime.now().microsecondsSinceEpoch}-${Random.secure().nextInt(1 << 32)}';
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
        SnackBar(content: Text('Could not continue admission: ${e.toString().replaceFirst('Exception: ', '')}')),
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
    final reason = await _promptPendingReason();
    if (reason == null || !mounted) return;
    try {
      await _api.put('/enquiries/${Uri.encodeComponent(id.toString())}', data: {
        'status': 'Pending',
        'comment': '',
        'reason': reason,
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
                if ((enquiry['status'] ?? '').toString() == 'Pending') _detail('Pending Reason', (enquiry['reason'] ?? enquiry['comment'] ?? '-').toString()),
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
                if ((enquiry['status'] ?? '').toString() != 'Pending')
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
    final ist = date.toUtc().add(const Duration(hours: 5, minutes: 30));
    return '${ist.day.toString().padLeft(2, '0')}/${ist.month.toString().padLeft(2, '0')}/${ist.year} ${ist.hour.toString().padLeft(2, '0')}:${ist.minute.toString().padLeft(2, '0')} IST';
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

  Widget _state({required bool loading, required String? error, required Future<void> Function() retry, required String empty, required List<Map<String, dynamic>> items, required bool requests, required int page, required ValueChanged<int> onPageChanged}) {
    if (loading) return const Center(child: CircularProgressIndicator());
    if (error != null) return Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.cloud_off_outlined, size: 40), const SizedBox(height: 8), Text(error, textAlign: TextAlign.center), const SizedBox(height: 12), OutlinedButton(onPressed: retry, child: const Text('Retry'))])));
    if (items.isEmpty) return Center(child: Text(empty));
    final pageCount = max(1, (items.length / _pageSize).ceil());
    final safePage = page.clamp(0, pageCount - 1);
    final pageItems = items.skip(safePage * _pageSize).take(_pageSize).toList();
    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: retry,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              itemCount: pageItems.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final item = pageItems[i];
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
                  if ((item['status'] ?? '').toString() == 'Pending' && (item['reason'] ?? '').toString().trim().isNotEmpty) Padding(padding: const EdgeInsets.only(top: 8), child: Container(width: double.infinity, padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(8)), child: Text('Pending reason: ${item['reason']}', style: TextStyle(color: Colors.brown.shade800, fontWeight: FontWeight.w600)))),
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
            ),
          ),
        ),
        Container(
          width: double.infinity,
          color: AppColors.background,
          padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
          child: SafeArea(
            top: false,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: safePage > 0 ? () => onPageChanged(safePage - 1) : null,
                  child: const Text('Previous'),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.primary.withOpacity(0.35)),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: DropdownButton<int>(
                    value: safePage + 1,
                    underline: const SizedBox.shrink(),
                    isDense: true,
                    items: List.generate(
                      pageCount,
                      (index) => DropdownMenuItem<int>(
                        value: index + 1,
                        child: Text('${index + 1}'),
                      ),
                    ),
                    onChanged: (value) {
                      if (value != null) onPageChanged(value - 1);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: safePage < pageCount - 1
                      ? () => onPageChanged(safePage + 1)
                      : null,
                  child: const Text('Next'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
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
        page: _enquiriesPage,
        onPageChanged: (value) => setState(() => _enquiriesPage = value),
      ),
      _state(
        loading: _loadingEnquiries,
        error: _enquiryError,
        retry: _loadEnquiries,
        empty: 'No enquiries marked as pending.',
        items: _enquiries.where((e) => (e['status'] ?? '').toString() == 'Pending').toList(),
        requests: false,
        page: _pendingPage,
        onPageChanged: (value) => setState(() => _pendingPage = value),
      ),
      _state(loading: _loadingRequests, error: _requestError, retry: _loadRequests, empty: 'No answer-sheet requests found.', items: _requests, requests: true, page: _requestsPage, onPageChanged: (value) => setState(() => _requestsPage = value)),
    ]),
  );
}


class _PendingReasonDialog extends StatefulWidget {
  const _PendingReasonDialog({super.key});

  @override
  State<_PendingReasonDialog> createState() => _PendingReasonDialogState();
}

class _PendingReasonDialogState extends State<_PendingReasonDialog> {
  final TextEditingController _controller = TextEditingController();
  String? _validationError;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Reason for Pending'),
    content: TextField(
      controller: _controller,
      autofocus: true,
      maxLines: 3,
      decoration: InputDecoration(
        labelText: 'Reason',
        hintText: 'Enter why this enquiry is being kept pending',
        border: const OutlineInputBorder(),
        errorText: _validationError,
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: () {
          final value = _controller.text.trim();
          if (value.isEmpty) {
            setState(() => _validationError = 'Reason is required');
            return;
          }
          Navigator.of(context).pop(value);
        },
        child: const Text('Save'),
      ),
    ],
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
