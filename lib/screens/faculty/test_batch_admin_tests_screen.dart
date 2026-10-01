import 'package:flutter/material.dart';

import '../../core/constants/colors.dart';
import '../../services/test_batch/test_batch_admin_test_service.dart';

class TestBatchAdminTestsScreen extends StatefulWidget {
  final String adminId;
  const TestBatchAdminTestsScreen({super.key, required this.adminId});

  @override
  State<TestBatchAdminTestsScreen> createState() => _TestBatchAdminTestsScreenState();
}

class _TestBatchAdminTestsScreenState extends State<TestBatchAdminTestsScreen> {
  final TestBatchAdminTestService _service = TestBatchAdminTestService();
  List<Map<String, dynamic>> _tests = <Map<String, dynamic>>[];
  bool _loading = true;
  String? _error;
  String _filter = 'All';

  @override
  void initState() {
    super.initState();
    _loadTests();
  }

  Future<void> _loadTests() async {
    setState(() { _loading = true; _error = null; });
    try {
      final tests = await _service.getPostedTests(adminId: widget.adminId);
      if (!mounted) return;
      setState(() { _tests = tests; _loading = false; });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _filteredTests {
    if (_filter == 'All') return _tests;
    return _tests.where((test) =>
      (test['status'] ?? '').toString().trim().toLowerCase() ==
      _filter.toLowerCase()).toList();
  }

  String _value(Map<String, dynamic> test, String key) {
    final value = test[key];
    if (value == null || value.toString().trim().isEmpty) return '-';
    return value.toString();
  }

  String _formatDate(String value) {
    if (value == '-') return value;
    final parsed = DateTime.tryParse(value);
    if (parsed == null) return value;
    return parsed.day.toString().padLeft(2, '0') + '/' +
        parsed.month.toString().padLeft(2, '0') + '/' +
        parsed.year.toString();
  }

  String _dateTimeText(Map<String, dynamic> test) {
    final date = _formatDate(_value(test, 'writing_date'));
    final start = _value(test, 'slot_start');
    final end = _value(test, 'slot_end');
    return (start == '-' && end == '-') ? date : date + ' • ' + start + ' - ' + end;
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed': return Colors.green;
      case 'cancelled': return Colors.red;
      case 'scheduled':
      case 'posted': return AppColors.primary;
      default: return Colors.orange.shade800;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.primary,
        elevation: 0,
        title: const Text('Test Batch Posted Tests',
          style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800)),
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _loadTests,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (_error != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 140),
          const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.primary),
          const SizedBox(height: 12),
          const Text('Unable to load posted tests', textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text(_error!, textAlign: TextAlign.center),
          const SizedBox(height: 18),
          Center(child: FilledButton(onPressed: _loadTests, child: const Text('Retry'))),
        ],
      );
    }

    final tests = _filteredTests;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      children: [
        _summaryCard(),
        const SizedBox(height: 14),
        DropdownButtonFormField<String>(
          initialValue: _filter,
          decoration: const InputDecoration(
            labelText: 'Filter by Status',
            border: OutlineInputBorder(),
            filled: true,
            fillColor: AppColors.surface,
          ),
          items: const [
            DropdownMenuItem(value: 'All', child: Text('All')),
            DropdownMenuItem(value: 'Scheduled', child: Text('Scheduled')),
            DropdownMenuItem(value: 'Completed', child: Text('Completed')),
            DropdownMenuItem(value: 'Cancelled', child: Text('Cancelled')),
          ],
          onChanged: (value) { if (value != null) setState(() => _filter = value); },
        ),
        const SizedBox(height: 16),
        if (tests.isEmpty)
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: const Column(children: [
              Icon(Icons.event_busy_outlined, size: 44, color: AppColors.primary),
              SizedBox(height: 12),
              Text('No posted tests found.', textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.w700)),
            ]),
          )
        else
          ...tests.map(_testCard),
      ],
    );
  }

  Widget _summaryCard() {
    final scheduled = _tests.where((test) {
      final status = _value(test, 'status').toLowerCase();
      return status == 'scheduled' || status == 'posted';
    }).length;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(16)),
      child: Row(children: [
        Expanded(child: _summaryItem('Posted Tests', _tests.length.toString())),
        Container(width: 1, height: 44, color: Colors.white24),
        Expanded(child: _summaryItem('Scheduled', scheduled.toString())),
      ]),
    );
  }

  Widget _summaryItem(String label, String value) {
    return Column(children: [
      Text(value, style: const TextStyle(color: Colors.white, fontSize: 25, fontWeight: FontWeight.w800)),
      const SizedBox(height: 4),
      Text(label, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600)),
    ]);
  }

  Widget _testCard(Map<String, dynamic> test) {
    final status = _value(test, 'status');
    final statusColor = _statusColor(status);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: const [BoxShadow(blurRadius: 8, offset: Offset(0, 3), color: Color(0x14000000))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: Text(_value(test, 'test_code'),
            style: const TextStyle(color: AppColors.primary, fontSize: 18, fontWeight: FontWeight.w800))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(20)),
            child: Text(status, style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w800)),
          ),
        ]),
        const SizedBox(height: 10),
        _infoRow('Subject', _value(test, 'subject_name')),
        _infoRow('Class', _value(test, 'class')),
        _infoRow('Board', _value(test, 'board')),
        _infoRow('Test Series', _value(test, 'test_series_name')),
        _infoRow('Total Marks', _value(test, 'total_marks')),
        _infoRow('Duration', _value(test, 'duration_minutes') + ' minutes'),
        _infoRow('Test Date / Slot', _dateTimeText(test)),
        _infoRow('Application Open', _formatDate(_value(test, 'application_open_date'))),
        _infoRow('Application Close', _formatDate(_value(test, 'application_close_date'))),
        _infoRow('Portion', _value(test, 'portion')),
        if (_value(test, 'chapter') != '-') _infoRow('Chapter', _value(test, 'chapter')),
      ]),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Text.rich(TextSpan(children: [
        TextSpan(text: label + ': ', style: const TextStyle(fontWeight: FontWeight.w700)),
        TextSpan(text: value),
      ])),
    );
  }
}
