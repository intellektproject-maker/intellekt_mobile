import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../core/api/api_client.dart';
import '../../core/constants/colors.dart';
import '../../widgets/academic_year_range_filter.dart';
import '../../widgets/marks_entry_input_formatter.dart';

/// Mobile Test Batch actions for admins IG001 / IG002 and faculty IG003 onward.
/// All records are loaded from and saved to the dedicated Test Batch API.
class TestBatchAdminActionsScreen extends StatefulWidget {
  final String adminId;
  final int initialTabIndex;
  const TestBatchAdminActionsScreen({
    super.key,
    required this.adminId,
    this.initialTabIndex = 0,
  });

  @override
  State<TestBatchAdminActionsScreen> createState() => _TestBatchAdminActionsScreenState();
}

class _TestBatchAdminActionsScreenState extends State<TestBatchAdminActionsScreen>
    with SingleTickerProviderStateMixin {
  final ApiClient _api = ApiClient();

  bool _canAccessTestBatch(String rawId) {
    final id = rawId.trim().toUpperCase();
    if (id == 'IG001' || id == 'IG002') return true;
    if (!id.startsWith('IG') || id.length <= 4) return false;
    final sequence = int.tryParse(id.substring(2));
    return sequence != null && sequence >= 3;
  }
  late final TabController _tabs;
  bool _isAuthorized = false;

  @override
  void initState() {
    super.initState();
    _isAuthorized = _canAccessTestBatch(widget.adminId);
    final safeInitialIndex = widget.initialTabIndex < 0
        ? 0
        : widget.initialTabIndex > 2
            ? 2
            : widget.initialTabIndex;
    _tabs = TabController(
      length: 3,
      vsync: this,
      initialIndex: safeInitialIndex,
    );
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAuthorized) {
      return Scaffold(
        appBar: AppBar(title: const Text('Test Batch Administration')),
        body: const Center(child: Text('Access denied. This screen is for IG001, IG002, and faculty IG003 onward.')),
      );
    }
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Test Batch Administration'),
        foregroundColor: AppColors.primary,
        backgroundColor: AppColors.surface,
        bottom: TabBar(
          controller: _tabs,
          isScrollable: false,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          indicatorSize: TabBarIndicatorSize.tab,
          indicatorWeight: 3,
          dividerColor: Colors.transparent,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500),
          tabs: [
            const Tab(icon: Icon(Icons.post_add_outlined), text: 'Post Test'),
            const Tab(icon: Icon(Icons.edit_note_outlined), text: 'Enter Marks'),
            const Tab(icon: Icon(Icons.fact_check_outlined), text: 'Attendance'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _PostTestTab(api: _api, adminId: widget.adminId),
          _EnterMarksTab(api: _api, adminId: widget.adminId),
          _AttendanceTab(api: _api, adminId: widget.adminId),
        ],
      ),
    );
  }
}

class _PostTestTab extends StatefulWidget {
  final ApiClient api;
  final String adminId;
  const _PostTestTab({required this.api, required this.adminId});

  @override
  State<_PostTestTab> createState() => _PostTestTabState();
}

class _PostTestTabState extends State<_PostTestTab> {
  final _formKey = GlobalKey<FormState>();
  final _code = TextEditingController();
  final _subject = TextEditingController();
  final _marks = TextEditingController();
  final _duration = TextEditingController(text: '90');
  final _portion = TextEditingController();
  final _chapter = TextEditingController();
  List<Map<String, dynamic>> _series = [];
  String? _seriesId;
  DateTime? _openDate, _closeDate, _writingCloseDate;
  bool _loading = true, _saving = false;
  String? _error, _message;

  @override
  void initState() { super.initState(); _loadSeries(); }

  @override
  void dispose() {
    for (final c in [_code, _subject, _marks, _duration, _portion, _chapter]) {
      c.dispose();
    }
    super.dispose();
  }

  String _date(DateTime? value) => value == null ? '' : '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
  String _dateLabel(DateTime? value) => value == null ? 'Choose date' : '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';

  Future<void> _loadSeries() async {
    try {
      final response = await widget.api.get('/test-batch/series', queryParameters: {'adminId': widget.adminId});
      final data = response.data;
      final raw = data is Map ? data['series'] : null;
      if (mounted) setState(() {
        _series = raw is List ? raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList() : [];
        _seriesId ??= _series.isEmpty ? null : _series.first['id']?.toString();
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() { _error = _messageOfError(e); _loading = false; });
    }
  }

  Future<DateTime?> _pick(DateTime? initial, {DateTime? first}) => showDatePicker(
    context: context,
    initialDate: initial ?? first ?? DateTime.now(),
    firstDate: first ?? DateTime(2020),
    lastDate: DateTime(2100),
  );

  String? _required(String? value) => value == null || value.trim().isEmpty ? 'Required' : null;

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_seriesId == null || _openDate == null || _closeDate == null || _writingCloseDate == null) {
      setState(() => _error = 'Choose a test series and all three dates.');
      return;
    }
    if (_closeDate!.isBefore(_openDate!) || !_writingCloseDate!.isAfter(_closeDate!)) {
      setState(() => _error = 'Application close must be on/after open and before Writing Close date.');
      return;
    }
    final marks = int.tryParse(_marks.text.trim());
    final duration = int.tryParse(_duration.text.trim());
    if (marks == null || marks <= 0 || duration == null || duration <= 0) {
      setState(() => _error = 'Total marks and duration must be positive numbers.');
      return;
    }
    setState(() { _saving = true; _error = null; _message = null; });
    try {
      final code = _code.text.trim().toUpperCase();
      final response = await widget.api.post('/test-batch/tests', data: {
        'adminId': widget.adminId,
        'test_code': code,
        'test_series_id': int.parse(_seriesId!),
        'subject_name': _subject.text.trim(),
        'duration_minutes': duration,
        'total_marks': marks,
        'portion': _portion.text.trim(),
        'chapter': _chapter.text.trim(),
        'application_open_date': _date(_openDate),
        'application_close_date': _date(_closeDate),
        'writing_close_date': _date(_writingCloseDate),
        'status': 'Scheduled',
      });
      if (!mounted) return;
      setState(() => _message = (response.data is Map ? response.data['message'] : null)?.toString() ?? 'Test posted successfully.');
      _formKey.currentState!.reset();
      _code.clear(); _subject.clear(); _marks.clear(); _portion.clear(); _chapter.clear();
      setState(() { _openDate = null; _closeDate = null; _writingCloseDate = null; _duration.text = '90'; });
    } catch (e) {
      if (mounted) setState(() => _error = _messageOfError(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      Card(child: Padding(padding: const EdgeInsets.all(16), child: Form(
        key: _formKey,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Text('Post a Test Batch test', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: AppColors.primary)),
          const SizedBox(height: 12),
          if (_loading) const LinearProgressIndicator(),
          DropdownButtonFormField<String>(
            value: _seriesId,
            decoration: const InputDecoration(labelText: 'Test Series', border: OutlineInputBorder()),
            items: _series.map((s) => DropdownMenuItem(value: s['id'].toString(), child: Text(s['name']?.toString() ?? 'Series'))).toList(),
            onChanged: (v) => setState(() => _seriesId = v),
            validator: (v) => v == null ? 'Select a test series' : null,
          ),
          const SizedBox(height: 10),
          TextFormField(controller: _code, textCapitalization: TextCapitalization.characters, decoration: const InputDecoration(labelText: 'Unique test code', border: OutlineInputBorder()), validator: _required, onChanged: (v) {
            final m = RegExp(r'^([SCI])(\d{2})([MP])(106|140|\d{2})(?!\d)').firstMatch(v.trim().toUpperCase());
            if (m != null) {
              _subject.text = m.group(3) == 'M' ? 'Mathematics' : 'Physics';
              _marks.text = m.group(4)!;
              _duration.text = [35, 40, 50].contains(int.tryParse(m.group(4)!)) ? '90' : '180';
            }
          }),
          const SizedBox(height: 10),
          TextFormField(controller: _subject, decoration: const InputDecoration(labelText: 'Subject', border: OutlineInputBorder()), validator: _required),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: TextFormField(controller: _marks, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Total marks', border: OutlineInputBorder()), validator: _required)),
            const SizedBox(width: 10),
            Expanded(child: TextFormField(controller: _duration, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Duration (minutes)', border: OutlineInputBorder()), validator: _required)),
          ]),
          const SizedBox(height: 10),
          _dateButton('Apply for Test - Open Date', _openDate, () async { final d = await _pick(_openDate); if (d != null) setState(() => _openDate = d); }),
          _dateButton('Apply for Test - Close Date', _closeDate, () async { final d = await _pick(_closeDate); if (d != null) setState(() => _closeDate = d); }),
          _dateButton('Writing Close date', _writingCloseDate, () async { final d = await _pick(_writingCloseDate); if (d != null) setState(() => _writingCloseDate = d); }),
          const SizedBox(height: 8),
          const SizedBox(height: 10),
          TextFormField(controller: _portion, decoration: const InputDecoration(labelText: 'Portion', border: OutlineInputBorder())),
          const SizedBox(height: 10),
          TextFormField(controller: _chapter, decoration: const InputDecoration(labelText: 'Chapter (optional)', border: OutlineInputBorder())),
          if (_error != null) _notice(_error!, true),
          if (_message != null) _notice(_message!, false),
          const SizedBox(height: 12),
          FilledButton.icon(onPressed: _saving || _loading ? null : _save, icon: _saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.publish_outlined), label: Text(_saving ? 'Posting...' : 'Post Test')),
        ]),
      ))),
    ],
  );

  Widget _dateButton(String label, DateTime? date, VoidCallback onTap) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: OutlinedButton.icon(onPressed: onTap, icon: const Icon(Icons.calendar_month_outlined), label: Align(alignment: Alignment.centerLeft, child: Text('$label: ${_dateLabel(date)}'))),
  );
}

class _EnterMarksTab extends StatefulWidget {
  final ApiClient api;
  final String adminId;
  const _EnterMarksTab({required this.api, required this.adminId});

  @override
  State<_EnterMarksTab> createState() => _EnterMarksTabState();
}

class _TestBatchMarkStudent {
  final String rollNo;
  final String name;
  final TextEditingController marks = TextEditingController();
  bool hasSavedMark = false;

  _TestBatchMarkStudent({required this.rollNo, required this.name});

  void dispose() => marks.dispose();
}

class _EnterMarksTabState extends State<_EnterMarksTab> {
  List<String> _subjects = [];
  List<Map<String, dynamic>> _tests = [];
  List<_TestBatchMarkStudent> _students = [];
  String? _subject;
  String? _testCode;
  String? _classFilter, _boardFilter;
  Map<String, dynamic>? _test;
  bool _hasExistingMarks = false, _editingExisting = false;
  Map<String, Map<String, dynamic>> _approvedEditRequests = {};
  bool get _isAdmin => const {'IG001','IG002'}.contains(widget.adminId.trim().toUpperCase());
  List<Map<String, dynamic>> get _filteredTests => _tests.where((test) =>
    (_classFilter == null || (test['class'] ?? '').toString() == _classFilter) &&
    (_boardFilter == null || (test['board'] ?? '').toString().toUpperCase() == _boardFilter)).toList();
  List<String> get _classOptions => _tests.map((test) => (test['class'] ?? '').toString()).where((v) => v.isNotEmpty).toSet().toList()..sort();
  List<String> get _boardOptions => _tests.map((test) => (test['board'] ?? '').toString().toUpperCase()).where((v) => v.isNotEmpty).toSet().toList()..sort();
  bool _loading = true;
  bool _saving = false;
  String? _error;
  String? _message;

  @override
  void initState() {
    super.initState();
    _loadSubjects();
  }

  @override
  void dispose() {
    for (final student in _students) { student.dispose(); }
    super.dispose();
  }

  String _friendlyError(Object error, {bool saving = false}) {
    if (error is DioException) {
      final status = error.response?.statusCode;
      final data = error.response?.data;
      final detail = data is Map ? (data['error'] ?? data['message'])?.toString().toLowerCase() ?? '' : '';
      if (detail.contains('pending') || detail.contains('approved') || detail.contains('edit request')) {
        return 'An edit request for this student is already pending or approved.';
      }
      if (detail.contains('already submitted') || detail.contains('finalized')) {
        return 'Marks have already been submitted for this test.';
      }
      if (status == 409) return 'This record cannot be changed right now. Refresh and try again.';
      if (detail.contains('no registered students') || status == 404) {
        return 'No registered students were found for this test.';
      }
      if (status == 403) return 'You do not have permission to enter Test Batch marks.';
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.sendTimeout ||
          error.type == DioExceptionType.connectionError) {
        return 'Could not connect. Please check your connection and try again.';
      }
    }
    return saving
        ? 'Could not save marks. Your entries are still here; please try again.'
        : 'Could not load Test Batch tests. Please try again.';
  }

  void _clearStudents() {
    for (final student in _students) { student.dispose(); }
    _students = [];
    _test = null;
    _hasExistingMarks = false;
    _editingExisting = false;
    _approvedEditRequests = {};
  }

  Future<void> _requestMarkEdit(_TestBatchMarkStudent student) async {
    // Let the dialog's TextFormField own its controller. Disposing an external
    // controller immediately after showDialog returns can happen while the
    // dialog route is still completing its reverse animation, causing a
    // Flutter inherited-element/dependent assertion on some devices.
    var requestedText = student.marks.text;
    final requested = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Request marks edit - ${student.rollNo}'),
        content: TextFormField(
          initialValue: student.marks.text,
          autofocus: true,
          textCapitalization: TextCapitalization.characters,
          inputFormatters: [MarksEntryInputFormatter()],
          onChanged: (value) => requestedText = value,
          decoration: const InputDecoration(labelText: 'Requested marks (number or A)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(dialogContext, requestedText.trim().toUpperCase()), child: const Text('Request edit')),
        ],
      ),
    );
    if (requested == null || requested.isEmpty || _testCode == null) return;
    final maxMarks = int.tryParse((_test?['total_marks'] ?? '').toString()) ?? 100000;
    final number = int.tryParse(requested);
    if (requested != 'A' && (number == null || number < 0 || number > maxMarks)) {
      if (mounted) setState(() => _error = 'Enter marks from 0 to $maxMarks, or A for absent.');
      return;
    }
    try {
      await widget.api.post('/test-batch/record-edit-requests', data: {
        'facultyId': widget.adminId, 'recordType': 'marks', 'roll_no': student.rollNo,
        'test_code': _testCode, 'subject_name': _test?['subject_name'] ?? _subject, 'requested_value': requested,
      });
      if (mounted) setState(() { _error = null; _message = 'Edit request sent to the admin. Apply it after approval.'; });
    } catch (error) {
      if (mounted) setState(() => _error = _friendlyError(error, saving: true));
    }
  }

  Future<void> _applyApprovedMarkEdit(_TestBatchMarkStudent student) async {
    final request = _approvedEditRequests[student.rollNo.trim().toUpperCase()];
    if (request == null) return;
    final value = (request['requested_value'] ?? '').toString().trim().toUpperCase();
    try {
      await widget.api.post('/test-batch/record-edit-requests/${request['id']}/apply',
        data: {'facultyId': widget.adminId, 'newValue': value});
      if (!mounted) return;
      setState(() { student.marks.text = value; _approvedEditRequests.remove(student.rollNo.trim().toUpperCase()); _message = 'Approved marks edit applied for ${student.rollNo}.'; _error = null; });
    } catch (error) {
      if (mounted) setState(() => _error = _friendlyError(error, saving: true));
    }
  }

  void _resetTestSelection() {
    _clearStudents();
    setState(() { _testCode = null; _error = null; _message = null; });
  }

  Future<void> _loadSubjects() async {
    setState(() { _loading = true; _error = null; });
    try {
      final response = await widget.api.get(
        '/test-batch/mark-entry/subjects',
        queryParameters: {'adminId': widget.adminId},
      );
      final raw = response.data is Map ? response.data['subjects'] : null;
      final sourceSubjects = raw is List
          ? raw.map((item) => item is Map ? (item['subject_name'] ?? item['subject'] ?? '').toString() : item.toString()).toList()
          : <String>[];
      final normalized = sourceSubjects.map((value) => value.toLowerCase()).toSet();
      final subjects = <String>[
        if (normalized.any((value) => value.contains('math'))) 'Mathematics',
        if (normalized.any((value) => value.contains('phys'))) 'Physics',
      ];
      if (!mounted) return;
      setState(() { _subjects = subjects; _loading = false; });
    } catch (error) {
      if (mounted) setState(() { _error = _friendlyError(error); _loading = false; });
    }
  }

  Future<void> _selectSubject(String? subject) async {
    if (subject == null) return;
    _clearStudents();
    setState(() {
      _subject = subject;
      _testCode = null;
      _classFilter = null;
      _boardFilter = null;
      _tests = [];
      _error = null;
      _message = null;
      _loading = true;
    });
    try {
      final response = await widget.api.get(
        '/test-batch/mark-entry/tests',
        queryParameters: {'adminId': widget.adminId, 'subject': subject},
      );
      final raw = response.data is Map ? response.data['tests'] : null;
      final tests = raw is List
          ? raw.whereType<Map>().map((item) => Map<String, dynamic>.from(item)).toList()
          : <Map<String, dynamic>>[];
      if (mounted) setState(() { _tests = tests; _loading = false; });
    } catch (error) {
      if (mounted) setState(() { _error = _friendlyError(error); _loading = false; });
    }
  }

  Future<void> _selectTest(String? code) async {
    if (code == null) return;
    _clearStudents();
    setState(() {
      _testCode = code;
      _error = null;
      _message = null;
      _loading = true;
    });
    try {
      final response = await widget.api.get(
        '/test-batch/tests/${Uri.encodeComponent(code)}/mark-entry',
        queryParameters: {'adminId': widget.adminId},
      );
      final data = response.data;
      final test = data is Map && data['test'] is Map
          ? Map<String, dynamic>.from(data['test'] as Map)
          : <String, dynamic>{};
      final raw = data is Map ? data['students'] : null;
      final students = raw is List
          ? raw.whereType<Map>().map((row) => _TestBatchMarkStudent(
                rollNo: (row['roll_no'] ?? '').toString(),
                name: (row['name'] ?? '').toString(),
              )).toList()
          : <_TestBatchMarkStudent>[];
      final marksRaw = data is Map ? data['marks'] : null;
      final marksByRoll = <String, Map<String, dynamic>>{};
      if (marksRaw is List) {
        for (final row in marksRaw.whereType<Map>()) {
          marksByRoll[(row['roll_no'] ?? '').toString().trim().toUpperCase()] = Map<String, dynamic>.from(row);
        }
      }
      for (final student in students) {
        final saved = marksByRoll[student.rollNo.trim().toUpperCase()];
        if (saved != null) {
          student.marks.text = (saved['marks_obtained'] ?? '').toString();
          student.hasSavedMark = student.marks.text.trim().isNotEmpty;
        }
      }
      if (students.isEmpty) throw DioException(
        requestOptions: RequestOptions(path: '/test-batch/mark-entry'),
        response: Response(
          requestOptions: RequestOptions(path: '/test-batch/mark-entry'),
          statusCode: 404,
          data: {'error': 'No registered students'},
        ),
      );
      if (!mounted) {
        for (final student in students) { student.dispose(); }
        return;
      }
      final approved = <String, Map<String, dynamic>>{};
      if (!_isAdmin && marksByRoll.isNotEmpty) {
        try {
          final approvedResponse = await widget.api.get('/test-batch/record-edit-requests/approved', queryParameters: {'facultyId': widget.adminId});
          final rows = approvedResponse.data is List ? (approvedResponse.data as List).whereType<Map>() : const <Map>[];
          for (final row in rows) {
            if ((row['record_type'] ?? '').toString() == 'marks' && (row['status'] ?? '').toString() == 'Approved' &&
                (row['test_code'] ?? '').toString().trim().toUpperCase() == code &&
                (row['roll_no'] ?? '').toString().trim() != '*') {
              approved[(row['roll_no'] ?? '').toString().trim().toUpperCase()] = Map<String, dynamic>.from(row);
            }
          }
        } catch (_) {}
      }
      _clearStudents();
      setState(() { _students = students; _test = test; _hasExistingMarks = marksByRoll.isNotEmpty;
        _editingExisting = marksByRoll.isEmpty; _approvedEditRequests = approved; _loading = false; });
    } catch (error) {
      if (mounted) setState(() { _error = _friendlyError(error); _loading = false; });
    }
  }

  Future<bool> _confirmAbsent(List<_TestBatchMarkStudent> absent) async {
    if (absent.isEmpty) return true;
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Absent students'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: absent.map((s) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text('${s.name} — Roll No: ${s.rollNo}'),
            )).toList(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Continue')),
        ],
      ),
    ) ?? false;
  }

  Future<bool> _confirmSubmit() async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Submit marks'),
        content: const Text('Are you sure you want to submit these marks?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Submit')),
        ],
      ),
    ) ?? false;
  }

  Future<void> _saveMarks() async {
    if (_students.isEmpty || _testCode == null || _test == null || _saving) return;

    // Submit only marks entered in this save. Previously saved marks for faculty
    // stay read-only; blank students can be completed and submitted later.
    final entered = _students.where((s) => s.marks.text.trim().isNotEmpty &&
        (_isAdmin && _editingExisting || !s.hasSavedMark)).toList();
    if (entered.isEmpty) {
      setState(() => _error = 'Enter marks for at least one student before saving.');
      return;
    }

    final invalid = entered.where((s) {
      final value = s.marks.text.trim().toUpperCase();
      if (value == 'A') return false;
      final number = int.tryParse(value);
      return number == null || number < 0 || number > 100000;
    }).toList();
    if (invalid.isNotEmpty) {
      setState(() => _error = 'Enter a whole number from 0 to 100000, or A for absent.');
      return;
    }

    final maxMarks = int.tryParse((_test?['total_marks'] ?? '').toString());
    if (maxMarks != null) {
      final overMax = entered.where((s) {
        final value = s.marks.text.trim().toUpperCase();
        return value != 'A' && (int.tryParse(value) ?? 0) > maxMarks;
      }).toList();
      if (overMax.isNotEmpty) {
        setState(() => _error = 'Marks cannot exceed the maximum of $maxMarks for this test.');
        return;
      }
    }

    final absent = entered.where((s) => s.marks.text.trim().toUpperCase() == 'A').toList();
    if (!await _confirmAbsent(absent)) return;
    if (!await _confirmSubmit()) return;

    setState(() { _saving = true; _error = null; _message = null; });
    try {
      final records = entered.map((s) => {
        'roll_no': s.rollNo,
        'marks': s.marks.text.trim().toUpperCase(),
      }).toList();
      await widget.api.post(
        '/test-batch/tests/${Uri.encodeComponent(_testCode!)}/marks/submit',
        data: {'adminId': widget.adminId, 'records': records},
      );
      if (!mounted) return;
      setState(() {
        for (final student in entered) {
          student.hasSavedMark = true;
        }
        _hasExistingMarks = true;
        _editingExisting = false;
        _message = 'Marks saved for ${entered.length} student(s). You can enter the remaining marks later.';
        _error = null;
      });
    } catch (error) {
      if (mounted) setState(() => _error = _friendlyError(error, saving: true));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _notice(String text, {required bool error}) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: error ? Colors.red.shade50 : Colors.green.shade50,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: error ? Colors.red.shade200 : Colors.green.shade200),
    ),
    child: Text(text, style: TextStyle(color: error ? Colors.red.shade800 : Colors.green.shade800)),
  );

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      if (_error != null) _notice(_error!, error: true),
      if (_message != null) _notice(_message!, error: false),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const Text('Test Batch – Enter Marks', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.primary)),
            const SizedBox(height: 12),
            const Text('Subject', style: TextStyle(fontWeight: FontWeight.w600)),
            Wrap(spacing: 8, children: _subjects.map((subject) => Row(mainAxisSize: MainAxisSize.min, children: [
              Radio<String>(value: subject, groupValue: _subject, onChanged: _loading ? null : _selectSubject),
              Text(subject),
            ])).toList()),
            if (_subject != null && _classOptions.isNotEmpty) ...[
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _classFilter ?? 'All',
                decoration: const InputDecoration(labelText: 'Class', border: OutlineInputBorder()),
                items: ['All', ..._classOptions].map((value) => DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                )).toList(),
                onChanged: _loading ? null : (value) {
                  _resetTestSelection();
                  setState(() => _classFilter = value == null || value == 'All' ? null : value);
                },
              ),
            ],
            if (_subject != null && _boardOptions.isNotEmpty) ...[
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _boardFilter ?? 'All',
                decoration: const InputDecoration(labelText: 'Board', border: OutlineInputBorder()),
                items: ['All', ..._boardOptions].map((value) => DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                )).toList(),
                onChanged: _loading ? null : (value) {
                  _resetTestSelection();
                  setState(() => _boardFilter = value == null || value == 'All' ? null : value);
                },
              ),
            ],
            const SizedBox(height: 12),
            Autocomplete<String>(
              optionsBuilder: (value) {
                final query = value.text.trim().toUpperCase();
                return _filteredTests.map((test) => (test['test_code'] ?? '').toString())
                  .where((code) => query.isEmpty || code.toUpperCase().contains(query));
              },
              onSelected: _selectTest,
              fieldViewBuilder: (context, controller, focusNode, onSubmitted) => TextField(
                controller: controller, focusNode: focusNode, enabled: !_loading && _subject != null,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(labelText: 'Test code', hintText: 'Type test code', border: OutlineInputBorder()),
                onSubmitted: (_) => onSubmitted(),
              ),
            ),
            if (_loading) const Padding(
              padding: EdgeInsets.only(top: 12),
              child: LinearProgressIndicator(),
            ),
          ]),
        ),
      ),
      if (_test != null) ...[
        const SizedBox(height: 12),
        if (_hasExistingMarks && _isAdmin)
          Align(alignment: Alignment.centerRight, child: TextButton.icon(
            onPressed: _saving ? null : () => setState(() => _editingExisting = !_editingExisting),
            icon: Icon(_editingExisting ? Icons.lock_outline : Icons.edit_outlined),
            label: Text(_editingExisting ? 'Finish editing' : 'Edit saved marks'),
          )),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                Text('Test Series: ${_test?['test_series_name'] ?? '-'}'),
                Text('Class: ${_test?['class'] ?? '-'}'),
                Text('Board: ${_test?['board'] ?? '-'}'),
                Text('Subject: ${_test?['subject_name'] ?? _subject ?? '-'}'),
                Text('Maximum marks: ${_test?['total_marks'] ?? '-'}'),
                Text('Test date: ${_test?['test_date'] ?? _test?['writing_close_date'] ?? '-'}'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Row(children: [
            Expanded(child: Text('Student', style: TextStyle(fontWeight: FontWeight.w700))),
            SizedBox(width: 120, child: Text('Marks (A if absent)', style: TextStyle(fontWeight: FontWeight.w700))),
          ]),
        ),
        ..._students.map((student) => Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(student.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(student.rollNo, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ])),
              if (_hasExistingMarks && !_isAdmin && student.hasSavedMark)
                Column(mainAxisSize: MainAxisSize.min, children: [
                  TextButton(onPressed: _saving ? null : () => _requestMarkEdit(student), child: const Text('Request Edit')),
                  if (_approvedEditRequests.containsKey(student.rollNo.trim().toUpperCase()))
                    TextButton(onPressed: _saving ? null : () => _applyApprovedMarkEdit(student), child: const Text('Apply Approved')),
                ]),
              SizedBox(
                width: 120,
                child: TextField(
                  controller: student.marks,
                  readOnly: _hasExistingMarks && (!_isAdmin || !_editingExisting) && student.hasSavedMark,
                  keyboardType: TextInputType.text,
                  textCapitalization: TextCapitalization.characters,
                  inputFormatters: [MarksEntryInputFormatter()],
                  decoration: const InputDecoration(
                    hintText: '0 / A',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  ),
                ),
              ),
            ]),
          ),
        )),
        const SizedBox(height: 8),
        if (!_hasExistingMarks || (_isAdmin && (_editingExisting || _students.any((s) => !s.hasSavedMark))) || (!_isAdmin && _students.any((s) => !s.hasSavedMark)))
          ElevatedButton(onPressed: _saving ? null : _saveMarks,
            child: _saving ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : Text(_hasExistingMarks ? 'Save Changes' : 'Save Marks')),
      ],
    ],
  );
}

class _AttendanceTab extends StatefulWidget {
  final ApiClient api;
  final String adminId;
  const _AttendanceTab({required this.api, required this.adminId});
  @override
  State<_AttendanceTab> createState() => _AttendanceTabState();
}

class _AttendanceTabState extends State<_AttendanceTab> {
  DateTime _date = DateTime.now();
  List<Map<String, dynamic>> _students = [];
  String _academicYearFrom = '', _academicYearTo = '';
  List<Map<String, dynamic>> get _visibleStudents => filterStudentsByAcademicYear(_students, fromYear: _academicYearFrom, toYear: _academicYearTo);
  final Map<String, String?> _status = {};
  final Map<String, Map<String, dynamic>> _approvedAttendanceEdits = {};
  final Map<String, Map<String, dynamic>> _pendingAttendanceEdits = {};
  Map<String, dynamic>? _overallAttendanceRequest;
  bool _loading = false, _saving = false;
  bool get _isFaculty => !const {'IG001', 'IG002'}.contains(widget.adminId.trim().toUpperCase());

  Widget _attendanceRadioOption(String roll, String status, bool enabled) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Radio<String>(
          value: status,
          groupValue: const {'Present', 'Absent'}.contains(_status[roll])
              ? _status[roll]
              : null,
          visualDensity: VisualDensity.compact,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          onChanged: enabled
              ? (value) {
                  if (value != null) setState(() => _status[roll] = value);
                }
              : null,
        ),
        Text(status),
      ],
    );
  }

  bool _attendanceRequestMatchesSelectedDate(Map<String, dynamic> request) {
    final date = (request['attendance_date'] ?? '').toString();
    return date.startsWith(_dateString);
  }

  Future<void> _loadApprovedAttendanceEdits() async {
    if (!_isFaculty) return;
    try {
      final response = await widget.api.get('/test-batch/record-edit-requests/approved', queryParameters: {'facultyId': widget.adminId});
      final rows = response.data is List ? (response.data as List).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList() : <Map<String, dynamic>>[];
      final mineResponse = await widget.api.get('/test-batch/record-edit-requests/mine', queryParameters: {'facultyId': widget.adminId});
      final mineRows = mineResponse.data is List ? (mineResponse.data as List).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList() : <Map<String, dynamic>>[];
      if (!mounted) return;
      setState(() {
        _approvedAttendanceEdits
          ..clear()
          ..addEntries(rows.where((row) => row['record_type'] == 'attendance' && row['roll_no'] != '*' && _attendanceRequestMatchesSelectedDate(row))
              .map((row) => MapEntry(row['roll_no'].toString().trim().toUpperCase(), row)));
        _pendingAttendanceEdits
          ..clear()
          ..addEntries(mineRows.where((row) => row['record_type'] == 'attendance' &&
              row['roll_no'] != '*' && row['status'] == 'Pending' && _attendanceRequestMatchesSelectedDate(row))
              .map((row) => MapEntry(row['roll_no'].toString().trim().toUpperCase(), row)));
        Map<String, dynamic>? overallRequest;
        for (final row in rows) {
          if (row['record_type'] == 'attendance' && row['roll_no'] == '*' &&
              _attendanceRequestMatchesSelectedDate(row)) {
            overallRequest = row;
            break;
          }
        }
        if (overallRequest == null) {
          for (final row in mineRows) {
            if (row['record_type'] == 'attendance' && row['roll_no'] == '*' &&
                row['status'] == 'Pending' && _attendanceRequestMatchesSelectedDate(row)) {
              overallRequest = row;
              break;
            }
          }
        }
        _overallAttendanceRequest = overallRequest;
      });
    } catch (_) {}
  }

  String? _savedAttendanceStatus(Map<String, dynamic> student) {
    final value = (student['status'] ?? student['attendance_status'])?.toString();
    return const {'Present', 'Absent'}.contains(value) ? value : null;
  }

  Future<void> _requestAttendanceEdit(String roll, String current) async {
    final value = await showDialog<String>(context: context, builder: (dialogContext) => AlertDialog(
      title: Text('Request attendance edit - $roll'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('Current status: $current'),
        ListTile(title: const Text('Present'), onTap: () => Navigator.pop(dialogContext, 'Present')),
        ListTile(title: const Text('Absent'), onTap: () => Navigator.pop(dialogContext, 'Absent')),
      ]),
      actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel'))],
    ));
    if (value == null) return;
    try {
      final response = await widget.api.post('/test-batch/record-edit-requests', data: {'facultyId': widget.adminId, 'recordType': 'attendance', 'roll_no': roll, 'attendance_date': _dateString, 'requested_value': value});
      final request = response.data is Map && response.data['request'] is Map
          ? Map<String, dynamic>.from(response.data['request'] as Map)
          : <String, dynamic>{'status': 'Pending'};
      if (mounted) setState(() {
        _pendingAttendanceEdits[roll.trim().toUpperCase()] = request;
        _message = 'Attendance edit request sent. This record is locked until admin review.';
      });
    } catch (e) { if (mounted) setState(() => _error = _messageOfError(e)); }
  }

  Future<void> _requestOverallAttendanceEdit() async {
    if (!_isFaculty || _saving || _students.where((s) => _savedAttendanceStatus(s) != null).isEmpty) return;
    try {
      final response = await widget.api.post('/test-batch/record-edit-requests', data: {
        'facultyId': widget.adminId,
        'recordType': 'attendance',
        'roll_no': '*',
        'attendance_date': _dateString,
        'requested_value': 'EDIT_PERMISSION',
      });
      final request = response.data is Map && response.data['request'] is Map
          ? Map<String, dynamic>.from(response.data['request'] as Map)
          : <String, dynamic>{'status': 'Pending', 'roll_no': '*', 'attendance_date': _dateString};
      if (mounted) setState(() {
        _overallAttendanceRequest = request;
        _message = 'Overall attendance edit request sent. Saved attendance is locked until admin review.';
      });
    } catch (e) {
      if (mounted) setState(() => _error = _messageOfError(e));
    }
  }

  Future<void> _applyOverallAttendanceEdit() async {
    final request = _overallAttendanceRequest;
    if (!_isFaculty || request == null || request['status'] != 'Approved' || _saving) return;
    final records = _students.where((s) => _savedAttendanceStatus(s) != null).map((s) {
      final roll = (s['roll_no'] ?? '').toString();
      return {'roll_no': roll, 'status': _status[roll]};
    }).toList();
    if (records.isEmpty || records.any((row) => !const {'Present', 'Absent'}.contains(row['status']))) {
      setState(() => _error = 'Please select Present or Absent for every saved student before saving overall attendance.');
      return;
    }
    setState(() { _saving = true; _error = null; _message = null; });
    try {
      await widget.api.post('/test-batch/record-edit-requests/${request['id']}/apply', data: {
        'facultyId': widget.adminId,
        'records': records,
      });
      if (mounted) setState(() {
        _overallAttendanceRequest = null;
        _message = 'Overall attendance saved for ${records.length} students.';
      });
      await _load();
    } catch (e) {
      if (mounted) setState(() => _error = _messageOfError(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _applyApprovedAttendanceEdit(String roll) async {
    final request = _approvedAttendanceEdits[roll];
    if (request == null) return;
    try {
      await widget.api.post('/test-batch/record-edit-requests/${request['id']}/apply', data: {'facultyId': widget.adminId});
      if (mounted) { setState(() { _approvedAttendanceEdits.remove(roll); _pendingAttendanceEdits.remove(roll); _message = 'Approved attendance edit applied for $roll.'; }); await _load(); }
    } catch (e) { if (mounted) setState(() => _error = _messageOfError(e)); }
  }
  String? _error, _message;

  String get _dateString => '${_date.year.toString().padLeft(4, '0')}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}';

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; _message = null; });
    try {
      final response = await widget.api.get('/test-batch/attendance', queryParameters: {'adminId': widget.adminId, 'date': _dateString});
      final data = response.data;
      final rows = data is Map && data['attendance'] is List ? (data['attendance'] as List).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList() : <Map<String, dynamic>>[];
      await _loadApprovedAttendanceEdits();
      if (mounted) setState(() {
        _students = rows;
        _status.clear();
        for (final s in rows) {
          final savedStatus = _savedAttendanceStatus(s);
          _status[(s['roll_no'] ?? '').toString()] =
              const {'Present', 'Absent'}.contains(savedStatus) ? savedStatus : null;
        }
      });
    } catch (e) { if (mounted) setState(() => _error = _messageOfError(e)); }
    finally { if (mounted) setState(() => _loading = false); }
  }

  Future<void> _save() async {
    if (_visibleStudents.isEmpty) { setState(() => _error = 'No registered Test Batch students found for this writing date and academic year.'); return; }
    setState(() { _saving = true; _error = null; _message = null; });
    try {
      final unmarked = _visibleStudents.where((s) =>
          _status[(s['roll_no'] ?? '').toString()] == null).toList();
      if (unmarked.isNotEmpty) {
        setState(() => _error =
            'Select Present or Absent for every student before saving attendance.');
        return;
      }
      final records = _visibleStudents.where((s) {
        final saved = s['status']?.toString();
        final roll = (s['roll_no'] ?? '').toString();
        return !_isFaculty || _savedAttendanceStatus(s) == null || _status[roll] == _savedAttendanceStatus(s);
      }).map((s) => {
        'roll_no': s['roll_no'],
        'status': _status[(s['roll_no'] ?? '').toString()],
      }).toList();
      if (records.isEmpty) { setState(() => _message = 'No new attendance entries to save. Use Request Edit for saved records.'); return; }
      await widget.api.post('/test-batch/attendance', data: {'adminId': widget.adminId, 'attendanceDate': _dateString, 'records': records});
      if (mounted) setState(() => _message = 'Attendance saved for ${records.length} student(s).');
      await _load();
    } catch (e) { if (mounted) setState(() => _error = _messageOfError(e)); }
    finally { if (mounted) setState(() => _saving = false); }
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(context: context, initialDate: _date, firstDate: DateTime(2020), lastDate: DateTime(2100));
    if (d != null && mounted) setState(() { _date = d; _students = []; _status.clear(); });
  }

  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(16), children: [
    Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const Text('Test Batch attendance', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: AppColors.primary)),
      OutlinedButton.icon(onPressed: _pickDate, icon: const Icon(Icons.calendar_month_outlined), label: Text('Writing date: $_dateString')),
      FilledButton.icon(onPressed: _loading ? null : _load, icon: const Icon(Icons.people_outline), label: Text(_loading ? 'Loading...' : 'Load registered students')),
      if (_isFaculty && _students.any((s) => _savedAttendanceStatus(s) != null)) ...[
        const SizedBox(height: 8),
        if (_overallAttendanceRequest?['status'] == 'Pending')
          const OutlinedButton(onPressed: null, child: Text('Overall Edit Request Pending'))
        else if (_overallAttendanceRequest?['status'] == 'Approved')
          FilledButton.icon(onPressed: _saving ? null : _applyOverallAttendanceEdit, icon: const Icon(Icons.save_outlined), label: Text(_saving ? 'Saving overall...' : 'Save Overall Attendance'))
        else
          OutlinedButton.icon(onPressed: _saving ? null : _requestOverallAttendanceEdit, icon: const Icon(Icons.edit_note), label: const Text('Request Overall Edit')),
      ],
    ]))),
    if (_error != null) _notice(_error!, true),
    if (_message != null) _notice(_message!, false),
    if (_loading) const Center(child: Padding(padding: EdgeInsets.all(18), child: CircularProgressIndicator())),
    if (_students.isNotEmpty) AcademicYearRangeFilter(
      students: _students,
      fromYear: _academicYearFrom,
      toYear: _academicYearTo,
      onFromChanged: (value) => setState(() => _academicYearFrom = value ?? ''),
      onToChanged: (value) => setState(() => _academicYearTo = value ?? ''),
    ),
    if (!_loading && _visibleStudents.isEmpty) const Card(child: ListTile(title: Text('Load students registered for a test on this date.'))),
    ..._visibleStudents.map((s) {
      final roll = (s['roll_no'] ?? '').toString();
      final savedStatus = _savedAttendanceStatus(s);
      final hasPendingRequest = _pendingAttendanceEdits.containsKey(roll.trim().toUpperCase());
      final overallApproved = _overallAttendanceRequest?['status'] == 'Approved';
      final canMark = !hasPendingRequest && (!(_isFaculty && savedStatus != null) || overallApproved);
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text((s['name'] ?? 'Student').toString()),
                subtitle: Text('Roll: $roll\nTests: ${s['test_codes'] ?? '-'}'),
                isThreeLine: true,
                trailing: (_isFaculty && savedStatus != null)
                    ? PopupMenuButton<String>(
                        tooltip: 'Edit attendance',
                        onSelected: (action) {
                          if (action == 'request') _requestAttendanceEdit(roll, savedStatus);
                          if (action == 'apply') _applyApprovedAttendanceEdit(roll);
                        },
                        itemBuilder: (_) => [
                          if (hasPendingRequest)
                            const PopupMenuItem(enabled: false, child: Text('Request Pending'))
                          else if (_approvedAttendanceEdits.containsKey(roll.trim().toUpperCase()))
                            const PopupMenuItem(value: 'apply', child: Text('Apply Approved Edit'))
                          else
                            const PopupMenuItem(value: 'request', child: Text('Request Edit')),
                        ],
                      )
                    : null,
              ),
              Opacity(
                opacity: canMark ? 1 : 0.48,
                child: IgnorePointer(
                  ignoring: !canMark,
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 4,
                    children: [
                      _attendanceRadioOption(roll, 'Present', canMark),
                      _attendanceRadioOption(roll, 'Absent', canMark),
                    ],
                  ),
                ),
              ),
              if (hasPendingRequest)
                const Padding(
                  padding: EdgeInsets.only(top: 6),
                  child: Text('Attendance edit request pending admin approval. This record is locked.',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ),
            ],
          ),
        ),
      );
    }),
    if (_students.isNotEmpty) FilledButton.icon(onPressed: _saving ? null : _save, icon: _saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.save_outlined), label: Text(_saving ? 'Saving...' : 'Save attendance')),
  ]);
}

String _messageOfError(Object error) {
  final text = error.toString().replaceFirst('Exception: ', '').trim();
  return text.isEmpty ? 'The request failed. Please try again.' : text;
}

Widget _notice(String text, bool error) => Container(
  margin: const EdgeInsets.symmetric(vertical: 8),
  padding: const EdgeInsets.all(12),
  decoration: BoxDecoration(
    color: error ? Colors.red.shade50 : Colors.green.shade50,
    borderRadius: BorderRadius.circular(10),
    border: Border.all(color: error ? Colors.red.shade200 : Colors.green.shade200),
  ),
  child: Text(text, style: TextStyle(color: error ? Colors.red.shade800 : Colors.green.shade800)),
);
