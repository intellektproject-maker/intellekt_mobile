import 'package:flutter/material.dart';

import '../../core/constants/colors.dart';
import '../../services/test_batch/test_batch_student_status_service.dart';

class TestBatchStudentStatusScreen extends StatefulWidget {
  final String adminId;
  const TestBatchStudentStatusScreen({super.key, required this.adminId});

  @override
  State<TestBatchStudentStatusScreen> createState() => _TestBatchStudentStatusScreenState();
}

class _TestBatchStudentStatusScreenState extends State<TestBatchStudentStatusScreen> {
  final TestBatchStudentStatusService _service = TestBatchStudentStatusService();

  static const _categories = ['Registered', 'Completed', 'Lapsed'];
  String? _category, _className, _board, _seriesId, _testCode;
  List<String> _classes = [], _boards = [];
  List<Map<String, dynamic>> _series = [], _tests = [], _students = [];
  bool _loading = true, _studentsLoading = false;
  String? _error;

  @override
  void initState() { super.initState(); _loadFilters(); }

  Future<void> _loadFilters() async {
    setState(() { _loading = true; _error = null; });
    try {
      final result = await _service.fetch(
        adminId: widget.adminId, category: _category, className: _className,
        board: _board, seriesId: _seriesId,
      );
      if (!mounted) return;
      _applyFilters(result['filters']);
      setState(() => _loading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString().replaceFirst('Exception: ', ''); _loading = false; });
    }
  }

  void _applyFilters(dynamic raw) {
    if (raw is! Map) return;
    final classes = raw['classes'];
    final boards = raw['boards'];
    final series = raw['series'];
    final tests = raw['tests'];
    _classes = classes is List ? classes.map((e) => e.toString()).where((e) => e.isNotEmpty).toList() : [];
    _boards = boards is List ? boards.map((e) => e.toString()).where((e) => e.isNotEmpty).toList() : [];
    _series = series is List ? series.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList() : [];
    _tests = tests is List ? tests.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList() : [];
  }

  Future<void> _selectCategory(String value) async {
    setState(() { _category = value; _testCode = null; _students = []; });
    await _loadFilters();
  }

  Future<void> _changeClass(String? value) async {
    setState(() { _className = value; _testCode = null; _students = []; });
    await _loadFilters();
  }

  Future<void> _changeBoard(String? value) async {
    setState(() { _board = value; _testCode = null; _students = []; });
    await _loadFilters();
  }

  Future<void> _changeSeries(String? value) async {
    setState(() { _seriesId = value; _testCode = null; _students = []; });
    await _loadFilters();
  }

  Future<void> _loadStudents(String? value) async {
    setState(() { _testCode = value; _students = []; });
    if (value == null || _category == null || _className == null || _board == null || _seriesId == null) return;

    setState(() { _studentsLoading = true; _error = null; });
    try {
      final result = await _service.fetch(
        adminId: widget.adminId, category: _category, className: _className,
        board: _board, seriesId: _seriesId, testCode: value,
      );
      if (!mounted) return;
      _applyFilters(result['filters']);
      setState(() {
        _students = List<Map<String, dynamic>>.from(result['students'] ?? []);
        _studentsLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString().replaceFirst('Exception: ', ''); _studentsLoading = false; });
    }
  }

  String _value(Map<String, dynamic> item, String key) {
    final value = item[key]?.toString().trim() ?? '';
    return value.isEmpty ? '-' : value;
  }

  Color get _statusColor {
    if (_category == 'Completed') return Colors.green;
    if (_category == 'Lapsed') return Colors.red;
    if (_category == 'Registered') return Colors.blue;
    return Colors.orange.shade800;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.primary,
        elevation: 0,
        title: const Text('Test Batch Student Status',
          style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800)),
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _loadFilters,
        child: _loading && _category == null
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
                children: [
                  const Text('Registration Status',
                    style: TextStyle(color: AppColors.primary, fontSize: 21, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 12),
                  ..._categories.map(_categoryCard),
                  if (_category != null) ...[
                    const SizedBox(height: 14),
                    _filterCard(),
                  ],
                  if (_category != null && _className != null && _board != null &&
                      _seriesId != null && _testCode != null) ...[
                    const SizedBox(height: 18),
                    _results(),
                  ],
                ],
              ),
      ),
    );
  }

  Widget _categoryCard(String category) {
    final selected = _category == category;
    final icon = category == 'Yet to Register'
        ? Icons.app_registration_outlined
        : category == 'Registered'
            ? Icons.event_available_outlined
            : category == 'Completed'
                ? Icons.task_alt_outlined
                : Icons.event_busy_outlined;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: selected ? AppColors.primary.withValues(alpha: 0.06) : AppColors.surface,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: selected ? AppColors.primary : AppColors.border),
        boxShadow: const [BoxShadow(blurRadius: 7, offset: Offset(0, 3), color: Color(0x14000000))],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: () => _selectCategory(category),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          child: Row(children: [
            Container(width: 46, height: 46,
              decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(13)),
              child: Icon(icon, color: AppColors.primary)),
            const SizedBox(width: 14),
            Expanded(child: Text(category,
              style: const TextStyle(color: AppColors.primary, fontSize: 15, fontWeight: FontWeight.w800))),
            Icon(selected ? Icons.keyboard_arrow_up_rounded : Icons.chevron_right_rounded,
              color: AppColors.primary, size: 30),
          ]),
        ),
      ),
    );
  }

  Widget _filterCard() {
    final seriesById = <String, Map<String, dynamic>>{};
    for (final item in _series) {
      final id = item['id']?.toString().trim() ?? '';
      if (id.isNotEmpty) seriesById.putIfAbsent(id, () => item);
    }

    final testsByCode = <String, Map<String, dynamic>>{};
    for (final item in _tests) {
      final code = item['test_code']?.toString().trim() ?? '';
      if (code.isNotEmpty) {
        testsByCode.putIfAbsent(code.toUpperCase(), () => item);
      }
    }

    final seriesIds = seriesById.keys.toList();
    final testCodes = testsByCode.keys.toList();
    final selectedTestCode = _testCode?.trim().toUpperCase();
    final safeTestCode =
        selectedTestCode != null && testCodes.contains(selectedTestCode)
            ? selectedTestCode
            : null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _category!,
            style: TextStyle(
              color: _statusColor,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          _dropdown('Select Class', _className, _classes, _changeClass),
          const SizedBox(height: 12),
          _dropdown('Select Board', _board, _boards, _changeBoard),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: seriesIds.contains(_seriesId) ? _seriesId : null,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Select Test Series',
              border: OutlineInputBorder(),
            ),
            items: seriesById.values.map((e) {
              final id = e['id']?.toString().trim() ?? '';
              return DropdownMenuItem(
                value: id,
                child: Text(e['name']?.toString() ?? id),
              );
            }).toList(),
            onChanged: _changeSeries,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: safeTestCode,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Select Test Code',
              border: OutlineInputBorder(),
            ),
            items: testsByCode.values.map((e) {
              final code = e['test_code']?.toString().trim() ?? '';
              final subject = e['subject_name']?.toString().trim() ?? '';
              return DropdownMenuItem(
                value: code.toUpperCase(),
                child: Text(
                  subject.isEmpty ? code : '$code — $subject',
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
            onChanged: _loadStudents,
          ),
        ],
      ),
    );
  }

  Widget _dropdown(
    String label,
    String? value,
    List<String> values,
    ValueChanged<String?> onChanged,
  ) {
    return DropdownButtonFormField<String>(
      initialValue: values.contains(value) ? value : null,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      items: values
          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget _results() {
    if (_studentsLoading) {
      return const Padding(padding: EdgeInsets.all(30),
        child: Center(child: CircularProgressIndicator(color: AppColors.primary)));
    }
    if (_error != null) {
      return Container(padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(15)),
        child: Text(_error!, textAlign: TextAlign.center));
    }
    if (_students.isEmpty) {
      return Container(padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(15), border: Border.all(color: AppColors.border)),
        child: const Column(children: [
          Icon(Icons.person_search_outlined, size: 44, color: AppColors.primary),
          SizedBox(height: 10),
          Text('No students found for the selected filters.', textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.w700)),
        ]));
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Students (' + _students.length.toString() + ')',
        style: const TextStyle(color: AppColors.primary, fontSize: 20, fontWeight: FontWeight.w800)),
      const SizedBox(height: 10),
      ..._students.map(_studentCard),
    ]);
  }

  Widget _studentCard(Map<String, dynamic> student) {
    final statusLabel = _category == 'Completed'
        ? 'Present'
        : _category == 'Lapsed'
            ? 'Absent'
            : _category ?? '-';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            blurRadius: 6,
            offset: Offset(0, 2),
            color: Color(0x12000000),
          ),
        ],
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 2),
        childrenPadding: const EdgeInsets.fromLTRB(13, 0, 13, 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(13),
        ),
        collapsedShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(13),
        ),
        iconColor: AppColors.primary,
        collapsedIconColor: AppColors.primary,
        title: Text(
          _value(student, 'name'),
          style: const TextStyle(
            color: AppColors.primary,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _statusColor.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                statusLabel,
                style: TextStyle(
                  color: _statusColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.keyboard_arrow_down_rounded),
          ],
        ),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Roll No: ' + _value(student, 'roll_no'),
                    style: const TextStyle(fontSize: 13)),
                Text('Class: ' + _value(student, 'class'),
                    style: const TextStyle(fontSize: 13)),
                Text('Board: ' + _value(student, 'board'),
                    style: const TextStyle(fontSize: 13)),
                Text('Test Series: ' + _value(student, 'test_series_name'),
                    style: const TextStyle(fontSize: 13)),
                Text('Test Code: ' + _value(student, 'test_code'),
                    style: const TextStyle(fontSize: 13)),
                Text('Subject: ' + _value(student, 'subject_name'),
                    style: const TextStyle(fontSize: 13)),
                if (_category == 'Registered') ...[
                  const SizedBox(height: 2),
                  Text(
                    'Writing Date: ' + _value(student, 'registered_writing_date'),
                    style: const TextStyle(fontSize: 13),
                  ),
                  Text(
                    'Slot: ' +
                        _value(student, 'slot_start') +
                        ' - ' +
                        _value(student, 'slot_end'),
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
