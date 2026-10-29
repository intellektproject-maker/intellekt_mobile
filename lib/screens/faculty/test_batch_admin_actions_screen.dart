import 'package:flutter/material.dart';

import '../../core/api/api_client.dart';
import '../../core/constants/colors.dart';

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
          tabs: const [
            Tab(icon: Icon(Icons.post_add_outlined), text: 'Post Test'),
            Tab(icon: Icon(Icons.edit_note_outlined), text: 'Enter Marks'),
            Tab(icon: Icon(Icons.fact_check_outlined), text: 'Attendance'),
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
            final m = RegExp(r'^([SCI])(\d{2})([MP])(\d{2})').firstMatch(v.trim().toUpperCase());
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

class _EnterMarksTabState extends State<_EnterMarksTab> {
  List<Map<String, dynamic>> _tests = [], _students = [];
  String? _selectedClass, _selectedSubject, _testCode, _writingDate;
  final Map<String, String> _marks = {}, _remarks = {};
  bool _loading = false, _saving = false;
  String? _error, _message;

  String _classFor(Map<String, dynamic> test) {
    final explicit = (test['class'] ?? test['class_name'] ?? test['class_level'] ?? '').toString().trim();
    if (explicit.isNotEmpty) return explicit;
    final code = (test['test_code'] ?? '').toString().toUpperCase();
    final match = RegExp(r'^[SCI](\d{2})[MP]').firstMatch(code);
    return match?.group(1) ?? 'Other';
  }

  String _subjectFor(Map<String, dynamic> test) {
    final explicit = (test['subject_name'] ?? test['subject'] ?? '').toString().trim();
    if (explicit.isNotEmpty) return explicit;
    final code = (test['test_code'] ?? '').toString().toUpperCase();
    final match = RegExp(r'^[SCI]\d{2}([MP])').firstMatch(code);
    if (match?.group(1) == 'M') return 'Mathematics';
    if (match?.group(1) == 'P') return 'Physics';
    return 'Other';
  }

  List<String> get _classes => _tests.map(_classFor).toSet().toList()
    ..sort((a, b) => a.compareTo(b));

  List<String> get _subjectsForClass => _tests
    .where((t) => _selectedClass == null || _classFor(t) == _selectedClass)
    .map(_subjectFor).toSet().toList()
    ..sort();

  List<Map<String, dynamic>> get _filteredTests => _tests.where((t) =>
    (_selectedClass == null || _classFor(t) == _selectedClass) &&
    (_selectedSubject == null || _subjectFor(t) == _selectedSubject)
  ).toList();

  @override
  void initState() { super.initState(); _loadTests(); }

  String _messageOf(Object e) => _messageOfError(e);
  Future<void> _loadTests() async {
    setState(() { _loading = true; _error = null; });
    try {
      final r = await widget.api.get('/test-batch/tests', queryParameters: {'adminId': widget.adminId});
      final data = r.data;
      if (mounted) setState(() => _tests = data is Map && data['tests'] is List ? (data['tests'] as List).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList() : []);
    } catch (e) { if (mounted) setState(() => _error = _messageOfError(e)); }
    finally { if (mounted) setState(() => _loading = false); }
  }

  Future<void> _loadStudents() async {
    if (_testCode == null) return;
    setState(() { _loading = true; _students = []; _marks.clear(); _remarks.clear(); _error = null; _message = null; });
    try {
      final registered = await widget.api.get('/test-batch/tests/${Uri.encodeComponent(_testCode!)}/registered-students', queryParameters: {'adminId': widget.adminId});
      final data = registered.data;
      final base = data is Map && data['students'] is List ? (data['students'] as List).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList() : <Map<String, dynamic>>[];
      final entry = await widget.api.get('/test-batch/tests/${Uri.encodeComponent(_testCode!)}/mark-entry', queryParameters: {'adminId': widget.adminId});
      final ed = entry.data;
      final existing = ed is Map && ed['students'] is List ? (ed['students'] as List).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList() : <Map<String, dynamic>>[];
      final byRoll = {for (final s in existing) (s['roll_no'] ?? '').toString().toUpperCase(): s};
      final merged = base.map((s) => {...s, ...(byRoll[(s['roll_no'] ?? '').toString().toUpperCase()] ?? {})}).toList();
      final dateOptions = merged.map((s) => _dateOnly(s['registered_writing_date'] ?? s['writing_date'])).whereType<String>().toSet().toList()..sort();
      if (mounted) setState(() {
        _students = merged;
        _writingDate = dateOptions.isNotEmpty ? dateOptions.first : null;
        for (final s in merged) {
          final roll = (s['roll_no'] ?? '').toString();
          _marks[roll] = s['marks_obtained']?.toString() ?? '';
          _remarks[roll] = s['remarks']?.toString() ?? '';
        }
      });
    } catch (e) { if (mounted) setState(() => _error = _messageOfError(e)); }
    finally { if (mounted) setState(() => _loading = false); }
  }

  List<String> get _availableWritingDates => _students.map((s) => _dateOnly(s['registered_writing_date'] ?? s['writing_date'])).whereType<String>().toSet().toList()..sort();

  String? _dateOnly(dynamic v) {
    final s = v?.toString().trim() ?? '';
    if (s.isEmpty) return null;
    final d = s.split('T').first;
    return RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(d) ? d : null;
  }

  Future<void> _save() async {
    if (_testCode == null || _writingDate == null) { setState(() => _error = 'Choose a test and writing date first.'); return; }
    final test = _tests.firstWhere((t) => t['test_code'] == _testCode, orElse: () => {});
    final total = num.tryParse(test['total_marks']?.toString() ?? '');
    final records = _students.where((s) => (_marks[(s['roll_no'] ?? '').toString()] ?? '').trim().isNotEmpty).map((s) {
      final roll = (s['roll_no'] ?? '').toString();
      return {'roll_no': roll, 'marks_obtained': _marks[roll]!.trim(), 'remarks': _remarks[roll] ?? ''};
    }).toList();
    if (records.isEmpty) { setState(() => _error = 'Enter marks for at least one student who completed the test.'); return; }
    for (final r in records) {
      final raw = r['marks_obtained'].toString();
      final n = num.tryParse(raw);
      if (raw.toUpperCase() != 'A' && (n == null || n < 0 || (total != null && n > total))) {
        setState(() => _error = 'Marks must be between 0 and ${total ?? 'the maximum marks'}, or A for absent.');
        return;
      }
    }
    setState(() { _saving = true; _error = null; _message = null; });
    try {
      await widget.api.post('/test-batch/tests/${Uri.encodeComponent(_testCode!)}/marks', data: {
        'adminId': widget.adminId, 'writing_date': _writingDate, 'records': records,
      });
      if (mounted) setState(() => _message = 'Saved marks for ${records.length} student(s). You can enter remaining marks later.');
      await _loadStudents();
    } catch (e) { if (mounted) setState(() => _error = _messageOfError(e)); }
    finally { if (mounted) setState(() => _saving = false); }
  }

  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(16), children: [
    Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const Text('Enter Test Batch marks', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: AppColors.primary)),
      if (_loading && _tests.isEmpty) const LinearProgressIndicator(),
      DropdownButtonFormField<String>(
        value: _selectedClass,
        isExpanded: true,
        decoration: const InputDecoration(labelText: 'Filter by class', border: OutlineInputBorder()),
        items: _classes.map((value) => DropdownMenuItem(value: value, child: Text(value == 'Other' ? value : 'Class $value'))).toList(),
        onChanged: (v) => setState(() {
          _selectedClass = v;
          _selectedSubject = null;
          _testCode = null;
          _students = [];
          _writingDate = null;
        }),
      ),
      const SizedBox(height: 10),
      DropdownButtonFormField<String>(
        value: _selectedSubject,
        isExpanded: true,
        decoration: const InputDecoration(labelText: 'Filter by subject', border: OutlineInputBorder()),
        items: _subjectsForClass.map((value) => DropdownMenuItem(value: value, child: Text(value))).toList(),
        onChanged: _selectedClass == null ? null : (v) => setState(() {
          _selectedSubject = v;
          _testCode = null;
          _students = [];
          _writingDate = null;
        }),
      ),
      const SizedBox(height: 10),
      DropdownButtonFormField<String>(
        value: _testCode,
        isExpanded: true,
        decoration: const InputDecoration(labelText: 'Select test code', border: OutlineInputBorder()),
        items: _filteredTests.map((t) => DropdownMenuItem(
          value: t['test_code']?.toString(),
          child: Text((t['test_code'] ?? '').toString()),
        )).toList(),
        onChanged: (v) => setState(() { _testCode = v; _students = []; _writingDate = null; }),
      ),
      const SizedBox(height: 10),
      FilledButton.icon(onPressed: _loading || _testCode == null ? null : _loadStudents, icon: const Icon(Icons.people_outline), label: const Text('Load registered students')),
    ]))),
    if (_error != null) _notice(_error!, true),
    if (_message != null) _notice(_message!, false),
    if (_loading && _students.isNotEmpty) const LinearProgressIndicator(),
    if (_students.isNotEmpty) ...[
      const SizedBox(height: 8),
      DropdownButtonFormField<String>(
        value: _writingDate,
        decoration: const InputDecoration(labelText: 'Writing date', border: OutlineInputBorder()),
        items: _availableWritingDates.map((d) => DropdownMenuItem<String>(value: d, child: Text(d))).toList(),
        onChanged: (v) => setState(() => _writingDate = v),
      ),
      const SizedBox(height: 10),
      ..._students.where((s) => _writingDate == null || _dateOnly(s['registered_writing_date'] ?? s['writing_date']) == _writingDate).map((s) {
        final roll = (s['roll_no'] ?? '').toString();
        return Card(child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${s['name'] ?? s['student_name'] ?? roll}', style: const TextStyle(fontWeight: FontWeight.w800)),
          Text('Roll No: $roll'),
          TextFormField(initialValue: _marks[roll] ?? '', decoration: const InputDecoration(labelText: 'Marks (or A if absent)'), keyboardType: TextInputType.text, onChanged: (v) => _marks[roll] = v.trim()),
          TextFormField(initialValue: _remarks[roll] ?? '', decoration: const InputDecoration(labelText: 'Remarks (optional)'), onChanged: (v) => _remarks[roll] = v),
        ])));
      }),
      FilledButton.icon(onPressed: _saving ? null : _save, icon: _saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.save_outlined), label: Text(_saving ? 'Saving...' : 'Save entered marks')),
    ],
  ]);

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
  final Map<String, String?> _status = {};
  bool _loading = false, _saving = false;
  String? _error, _message;

  String get _dateString => '${_date.year.toString().padLeft(4, '0')}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}';

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; _message = null; });
    try {
      final response = await widget.api.get('/test-batch/attendance', queryParameters: {'adminId': widget.adminId, 'date': _dateString});
      final data = response.data;
      final rows = data is Map && data['attendance'] is List ? (data['attendance'] as List).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList() : <Map<String, dynamic>>[];
      if (mounted) setState(() {
        _students = rows;
        _status.clear();
        for (final s in rows) {
          final savedStatus = s['status']?.toString();
          _status[(s['roll_no'] ?? '').toString()] =
              const {'Present', 'Absent'}.contains(savedStatus) ? savedStatus : null;
        }
      });
    } catch (e) { if (mounted) setState(() => _error = _messageOfError(e)); }
    finally { if (mounted) setState(() => _loading = false); }
  }

  Future<void> _save() async {
    if (_students.isEmpty) { setState(() => _error = 'No registered Test Batch students found for this writing date.'); return; }
    setState(() { _saving = true; _error = null; _message = null; });
    try {
      final unmarked = _students.where((s) =>
          _status[(s['roll_no'] ?? '').toString()] == null).toList();
      if (unmarked.isNotEmpty) {
        setState(() => _error =
            'Select Present or Absent for every student before saving attendance.');
        return;
      }
      final records = _students.map((s) => {
        'roll_no': s['roll_no'],
        'status': _status[(s['roll_no'] ?? '').toString()],
      }).toList();
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
    ]))),
    if (_error != null) _notice(_error!, true),
    if (_message != null) _notice(_message!, false),
    if (_loading) const Center(child: Padding(padding: EdgeInsets.all(18), child: CircularProgressIndicator())),
    if (!_loading && _students.isEmpty) const Card(child: ListTile(title: Text('Load students registered for a test on this date.'))),
    ..._students.map((s) {
      final roll = (s['roll_no'] ?? '').toString();
      return Card(child: ListTile(
        title: Text((s['name'] ?? 'Student').toString()),
        subtitle: Text('Roll: $roll\nTests: ${s['test_codes'] ?? '-'}'),
        isThreeLine: true,
        trailing: DropdownButton<String>(
          value: const {'Present', 'Absent'}.contains(_status[roll])
              ? _status[roll]
              : null,
          hint: const Text('Select status'),
          items: const [DropdownMenuItem(value: 'Present', child: Text('Present')), DropdownMenuItem(value: 'Absent', child: Text('Absent'))],
          onChanged: (v) => setState(() => _status[roll] = v ?? 'Present'),
        ),
      ));
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
