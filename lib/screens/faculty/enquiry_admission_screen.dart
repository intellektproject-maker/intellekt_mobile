import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/api/api_client.dart';
import '../../core/constants/colors.dart';

/// Completes an enquiry-to-student admission. The enquiry is reserved first;
/// the backend marks it Admitted only when the student record is created.
class EnquiryAdmissionScreen extends StatefulWidget {
  final Map<String, dynamic> enquiry;
  final String admissionToken;
  final String adminId;

  const EnquiryAdmissionScreen({
    super.key,
    required this.enquiry,
    required this.admissionToken,
    required this.adminId,
  });

  @override
  State<EnquiryAdmissionScreen> createState() => _EnquiryAdmissionScreenState();
}

class _EnquiryAdmissionScreenState extends State<EnquiryAdmissionScreen> with WidgetsBindingObserver {
  final _api = ApiClient();
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _fields = {};
  bool _loading = true, _saving = false, _cancelled = false;
  String? _error;
  bool get _testBatch => (widget.enquiry['batch'] ?? 'Regular Batch').toString().toLowerCase() == 'test batch';
  List<Map<String, dynamic>> _subjects = [];
  List<Map<String, dynamic>> _series = [];
  List<int> _selectedSubjectIds = [];
  String? _subjectChoice, _seriesId;
  String? _testWritingDay;
  String _board = '', _batch = 'Regular Batch';
  String? _lastRollNumber;
  Timer? _draftTimer;
  bool _draftReady = false;
  bool _draftRequestInFlight = false;

  static const _fieldNames = [
    'roll_no', 'name', 'class', 'board', 'phone', 'email', 'school_name',
    'parent_name', 'secondary_contact', 'password', 'date_of_birth', 'academic_year_from',
    'academic_year_to', 'total_fee', 'fee_paid'
  ];

  TextEditingController _field(String key) => _fields.putIfAbsent(key, () => TextEditingController());

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    for (final key in _fieldNames) {
      _field(key).addListener(_scheduleDraftSave);
    }
    _batch = _testBatch ? 'Test Batch' : 'Regular Batch';
    _prefill();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _draftTimer?.cancel();
    for (final controller in _fields.values) { controller.dispose(); }
    super.dispose();
  }

  String _cleanPhone(dynamic value) => (value ?? '').toString().replaceAll(RegExp(r'\D'), '').substringSafe(10);
  String _date(dynamic value) => value == null ? '' : value.toString().split('T').first;
  String? _required(String? value) => value == null || value.trim().isEmpty ? 'Required' : null;
  String get _enquiryId => widget.enquiry['id'].toString();

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _draftTimer?.cancel();
      _persistDraft();
    }
  }

  Map<String, dynamic> _draftSnapshot() => {
    'fields': {
      for (final key in _fieldNames)
        if (key != 'password') key: _field(key).text,
    },
    'selected_subject_ids': _selectedSubjectIds,
    'subject_choice': _subjectChoice,
    'series_id': _seriesId,
    'test_writing_day': _testWritingDay,
  };

  void _scheduleDraftSave() {
    if (!_draftReady || _saving || !mounted) return;
    _draftTimer?.cancel();
    _draftTimer = Timer(const Duration(milliseconds: 650), _persistDraft);
  }

  Future<void> _persistDraft() async {
    if (!_draftReady || _saving || _draftRequestInFlight) return;
    _draftTimer?.cancel();
    _draftRequestInFlight = true;
    try {
      await _api.put(
        '/enquiries/${Uri.encodeComponent(_enquiryId)}/admission/draft',
        data: {'draft_data': _draftSnapshot()},
      );
    } catch (_) {
      // Keep the form usable during temporary network loss. The next edit or
      // app resume will retry the latest snapshot.
    } finally {
      _draftRequestInFlight = false;
    }
  }

  Future<void> _loadSavedDraft() async {
    try {
      final response = await _api.get(
        '/enquiries/${Uri.encodeComponent(_enquiryId)}/admission/draft',
      );
      final data = response.data;
      final draft = data is Map ? data['draft_data'] : null;
      if (draft is! Map) return;
      final fields = draft['fields'];
      if (fields is Map) {
        for (final key in _fieldNames) {
          if (key == 'password') continue;
          final value = fields[key];
          if (value != null) _field(key).text = value.toString();
        }
      }
      final ids = draft['selected_subject_ids'];
      if (ids is List) {
        _selectedSubjectIds = ids.map((v) => int.tryParse(v.toString()))
            .whereType<int>().toList();
      }
      _subjectChoice = draft['subject_choice']?.toString();
      _seriesId = draft['series_id']?.toString();
      _testWritingDay = draft['test_writing_day']?.toString();
    } catch (_) {
      // A failed draft fetch should not prevent a fresh admission form opening.
    }
  }



  Future<void> _prefill() async {
    try {
      final id = widget.enquiry['id'];
      final response = await _api.get('/enquiries/${Uri.encodeComponent(id.toString())}');
      final enquiry = response.data is Map ? Map<String, dynamic>.from(response.data) : widget.enquiry;
      final combined = (enquiry['class_board'] ?? '').toString();
      final split = combined.lastIndexOf('-');
      _board = split >= 0 ? combined.substring(0, split).trim() : '';
      _field('board').text = _board;
      _field('class').text = split >= 0 ? combined.substring(split + 1).trim() : '';
      _field('name').text = (enquiry['student_name'] ?? '').toString();
      _field('phone').text = _cleanPhone(enquiry['mobile_number']);
      _field('school_name').text = (enquiry['school_name'] ?? '').toString();
      _field('parent_name').text = (enquiry['parent_name'] ?? '').toString();
      _field('secondary_contact').text = _cleanPhone(enquiry['secondary_contact']);
      _field('date_of_birth').text = _date(enquiry['date_of_birth']);
      _field('academic_year_from').text = (enquiry['academic_year_from'] ?? '').toString();
      _field('academic_year_to').text = (enquiry['academic_year_to'] ?? '').toString();

      if (_testBatch) {
        final seriesResponse = await _api.get('/test-batch/series', queryParameters: {'adminId': widget.adminId});
        final data = seriesResponse.data;
        _series = data is Map && data['series'] is List
            ? (data['series'] as List).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
            : [];
        _seriesId = _series.isEmpty ? null : _series.first['id']?.toString();
        final wanted = (enquiry['subjects'] ?? '').toString().toLowerCase();
        _subjectChoice = wanted.contains('both') ? 'Both' : wanted.contains('phys') ? 'Physics' : wanted.contains('math') ? 'Mathematics' : null;
        final next = await _api.get('/test-batch/students/next-roll', queryParameters: {'adminId': widget.adminId});
        _field('roll_no').text = (next.data is Map ? next.data['roll_no'] : null)?.toString() ?? 'IAT001';
      } else {
        final lastRollResponse = await _api.get('/students/last-roll-number');
        final lastRollData = lastRollResponse.data;
        // The endpoint may return either an object or a list. In particular,
        // an empty list means there are no regular students yet; never render
        // the Dart list representation ("[]") in the admission form.
        dynamic lastRollValue;
        if (lastRollData is Map) {
          lastRollValue = lastRollData['last_roll_no'] ??
              lastRollData['last_roll_number'] ??
              lastRollData['lastRollNumber'] ??
              lastRollData['lastRollNo'] ??
              lastRollData['roll_no'];
        } else if (lastRollData is List) {
          if (lastRollData.isNotEmpty) {
            final first = lastRollData.first;
            if (first is Map) {
              lastRollValue = first['last_roll_no'] ??
                  first['last_roll_number'] ??
                  first['lastRollNumber'] ??
                  first['lastRollNo'] ??
                  first['roll_no'];
            } else {
              lastRollValue = first;
            }
          }
        } else {
          lastRollValue = lastRollData;
        }
        final parsedLastRoll = lastRollValue?.toString().trim();
        _lastRollNumber = parsedLastRoll == null || parsedLastRoll.isEmpty
            ? null
            : parsedLastRoll;
        final subjectsResponse = await _api.get('/subjects');
        _subjects = subjectsResponse.data is List
            ? (subjectsResponse.data as List).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
            : [];
        final wanted = (enquiry['subjects'] ?? '').toString().toLowerCase();
        _selectedSubjectIds = _subjects.where((s) {
          final name = (s['subject_name'] ?? '').toString().toLowerCase();
          return (wanted.contains('both') && (name.contains('math') || name.contains('phys'))) ||
              (wanted.contains('math') && name.contains('math')) ||
              (wanted.contains('phys') && name.contains('phys'));
        }).map((s) => int.tryParse(s['subject_id'].toString())).whereType<int>().toList();
        final selectedName = _selectedSubjectIds.isEmpty
            ? ''
            : _subjects.firstWhere((s) => s['subject_id'].toString() == _selectedSubjectIds.first.toString())['subject_name'].toString().toLowerCase();
        _subjectChoice = _selectedSubjectIds.length > 1
            ? 'Both'
            : selectedName.contains('math')
                ? 'Mathematics'
                : selectedName.contains('phys')
                    ? 'Physics'
                    : null;
      }
      await _loadSavedDraft();
      _draftReady = true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _restoreEnquiry() async {
    if (_cancelled) return;
    _cancelled = true;
    try {
      await _api.post('/enquiries/${Uri.encodeComponent(widget.enquiry['id'].toString())}/admission/cancel',
          data: {'admission_token': widget.admissionToken});
    } catch (_) {}
  }

  Future<void> _close() async {
    _draftTimer?.cancel();
    await _persistDraft();
    await _restoreEnquiry();
    if (mounted) Navigator.of(context).pop(false);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_testBatch && (_seriesId == null || _subjectChoice == null)) {
      setState(() => _error = 'Select a test series and at least one subject.');
      return;
    }
    if (!_testBatch && _selectedSubjectIds.isEmpty) {
      setState(() => _error = 'Select at least one subject.');
      return;
    }
    if (!_testBatch && _testWritingDay == null) {
      setState(() => _error = 'Select a test writing day.');
      return;
    }
    final phone = _field('phone').text.trim();
    final secondary = _field('secondary_contact').text.trim();
    if (!RegExp(r'^\d{10}$').hasMatch(phone)) {
      setState(() => _error = 'Phone number must contain exactly 10 digits.');
      return;
    }
    if (!_testBatch && (!RegExp(r'^\d{10}$').hasMatch(secondary) || secondary == phone)) {
      setState(() => _error = 'Enter a different 10-digit secondary contact number.');
      return;
    }
    if (!_testBatch && _field('date_of_birth').text.trim().isEmpty) {
      setState(() => _error = 'Date of birth is required.');
      return;
    }
    setState(() { _saving = true; _error = null; });
    try {
      final id = widget.enquiry['id'].toString();
      final base = {
        'name': _field('name').text.trim(),
        'class': _field('class').text.trim(),
        'board': _field('board').text.trim(),
        'phone': phone,
        'email': _field('email').text.trim(),
        'school_name': _field('school_name').text.trim(),
        'parent_name': _field('parent_name').text.trim(),
        'secondary_contact': secondary,
        'date_of_birth': _field('date_of_birth').text.trim().isEmpty ? _date(widget.enquiry['date_of_birth']) : _field('date_of_birth').text.trim(),
        'academic_year_from': _field('academic_year_from').text.trim(),
        'academic_year_to': _field('academic_year_to').text.trim(),
        'password': _field('password').text.trim().isEmpty ? _field('roll_no').text.trim() : _field('password').text.trim(),
        'enquiry_id': id,
        'admission_token': widget.admissionToken,
      };
      if (_testBatch) {
        await _api.post('/test-batch/students', data: {
          ...base,
          'adminId': widget.adminId,
          'roll_no': _field('roll_no').text.trim().toUpperCase(),
          'reference': (widget.enquiry['reference'] ?? '').toString(),
          'test_series_id': int.parse(_seriesId!),
          'subjects': _subjectChoice,
        });
      } else {
        await _api.post('/students', data: {
          ...base,
          'roll_no': _field('roll_no').text.trim(),
          'batch': 'Regular Batch',
          'reference': '',
          'subject_ids': _selectedSubjectIds,
          'test_writing_day': _testWritingDay,
          'total_fee': num.tryParse(_field('total_fee').text) ?? 0,
          'fee_paid': num.tryParse(_field('fee_paid').text) ?? 0,
          'next_due': null,
        });
      }
      _cancelled = true;
      _draftTimer?.cancel();
      try { await _api.delete('/enquiries/${Uri.encodeComponent(id)}/admission/draft'); } catch (_) {}
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Student enrolled successfully.')));
      Navigator.of(context).pop(true);
    } catch (e) {
      await _restoreEnquiry();
      if (mounted) setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _input(String key, String label, {bool required = false, TextInputType? keyboard, bool obscure = false}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextFormField(
          controller: _field(key),
          keyboardType: keyboard,
          obscureText: obscure,
          onChanged: (_) => _scheduleDraftSave(),
          decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
          validator: required ? _required : null,
        ),
      );

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: false,
    onPopInvokedWithResult: (didPop, result) { if (!didPop) _close(); },
    child: Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_testBatch ? 'Enrol Test Batch Student' : 'Enrol Regular Student'),
        foregroundColor: AppColors.primary,
        backgroundColor: AppColors.surface,
        leading: IconButton(icon: const Icon(Icons.close), onPressed: _saving ? null : _close),
      ),
      body: _loading ? const Center(child: CircularProgressIndicator()) : Form(
        key: _formKey,
        child: ListView(padding: const EdgeInsets.all(16), children: [
          Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Enquiry ${widget.enquiry['enq_id'] ?? widget.enquiry['id']}', style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.primary)),
            const SizedBox(height: 4),
            Text('Batch: $_batch • Class: $_board-${_field('class').text}'),
            const SizedBox(height: 14),
            if (!_testBatch) ...[
              Text(
                'Last roll number in database: ${_lastRollNumber ?? 'No regular students yet'}',
                style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.primary),
              ),
              const SizedBox(height: 6),
              const Text('Enter the next roll number below.'),
              const SizedBox(height: 8),
            ],
            _input('roll_no', _testBatch ? 'Test Batch Roll Number (IAT...)' : 'Student Roll Number', required: true),
            _input('name', 'Student Name', required: true),
            _input('class', 'Class', required: true, keyboard: TextInputType.number),
            _input('board', 'Board', required: !_testBatch),
            _input('phone', 'Phone Number', required: true, keyboard: TextInputType.phone),
            _input('email', 'Email', required: !_testBatch, keyboard: TextInputType.emailAddress),
            _input('school_name', 'School Name', required: !_testBatch),
            _input('parent_name', 'Parent Name'),
            _input('secondary_contact', 'Secondary Contact', required: !_testBatch, keyboard: TextInputType.phone),
            if (!_testBatch) _input('date_of_birth', 'Date of Birth (YYYY-MM-DD)', required: true),
            _input('password', 'Password (leave blank to use roll number)', obscure: true),
            _input('academic_year_from', 'Academic Year From', keyboard: TextInputType.number),
            _input('academic_year_to', 'Academic Year To', keyboard: TextInputType.number),
            if (_testBatch) ...[
              DropdownButtonFormField<String>(
                value: _seriesId,
                decoration: const InputDecoration(labelText: 'Test Series', border: OutlineInputBorder()),
                items: _series.map((s) => DropdownMenuItem(value: s['id'].toString(), child: Text(s['name']?.toString() ?? 'Series'))).toList(),
                onChanged: (v) { setState(() => _seriesId = v); _scheduleDraftSave(); },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _subjectChoice,
                decoration: const InputDecoration(labelText: 'Subjects', border: OutlineInputBorder()),
                items: const ['Mathematics', 'Physics', 'Both'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                onChanged: (v) { setState(() => _subjectChoice = v); _scheduleDraftSave(); },
              ),
            ] else ...[
              DropdownButtonFormField<String>(
                value: _testWritingDay,
                decoration: const InputDecoration(labelText: 'Test Writing Day', border: OutlineInputBorder()),
                items: const ['Sunday', 'Monday', 'Tuesday']
                    .map((day) => DropdownMenuItem(value: day, child: Text(day)))
                    .toList(),
                onChanged: (value) { setState(() => _testWritingDay = value); _scheduleDraftSave(); },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _subjectChoice,
                decoration: const InputDecoration(labelText: 'Subjects', border: OutlineInputBorder()),
                items: const ['Mathematics', 'Physics', 'Both'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                onChanged: (v) {
                  final selected = v == 'Both' ? ['math', 'phys'] : [v?.toLowerCase() ?? ''];
                  setState(() {
                    _subjectChoice = v;
                    _selectedSubjectIds = _subjects.where((s) => selected.any((q) => (s['subject_name'] ?? '').toString().toLowerCase().contains(q))).map((s) => int.tryParse(s['subject_id'].toString())).whereType<int>().toList();
                  });
                  _scheduleDraftSave();
                },
              ),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _input('total_fee', 'Total Fee', keyboard: TextInputType.number)),
                const SizedBox(width: 10),
                Expanded(child: _input('fee_paid', 'Fee Paid', keyboard: TextInputType.number)),
              ]),
            ],
            if (_error != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(_error!, style: const TextStyle(color: Colors.red))),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.person_add_alt_1),
              label: Text(_saving ? 'Enrolling...' : 'Complete Enrolment'),
            ),
          ]))),
        ]),
      ),
    ),
  );
}

extension _SafeSubstring on String {
  String substringSafe(int max) => length > max ? substring(0, max) : this;
}
