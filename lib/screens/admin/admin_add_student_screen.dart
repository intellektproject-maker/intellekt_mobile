import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_client.dart';
import '../../core/constants/colors.dart';
import '../../providers/auth_provider.dart';
import '../../routes/app_routes.dart';

class AdminAddStudentScreen extends StatefulWidget {
  final Map<String, dynamic> args;
  const AdminAddStudentScreen({super.key, required this.args});

  @override
  State<AdminAddStudentScreen> createState() => _AdminAddStudentScreenState();
}

class _AdminAddStudentScreenState extends State<AdminAddStudentScreen> {
  final _api = ApiClient();
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _fields = {};
  final Set<int> _subjectIds = {};
  List<Map<String, dynamic>> _subjects = [];
  List<Map<String, dynamic>> _series = [];
  bool _loadingOptions = true;
  bool _saving = false;
  bool _finished = false;
  String? _error;
  String? _seriesId;
  String _subjectsText = '';
  String _mode = 'Online';

  Map<String, dynamic> get _enquiry =>
      widget.args['enquiry'] is Map
          ? Map<String, dynamic>.from(widget.args['enquiry'] as Map)
          : <String, dynamic>{};
  String get _batch => (widget.args['batch'] ?? _enquiry['batch'] ?? 'Regular Batch').toString();
  String get _token => (widget.args['admissionToken'] ?? '').toString();
  String get _enquiryId => (_enquiry['id'] ?? '').toString();
  bool get _isTestBatch => _batch == 'Test Batch';

  @override
  void initState() {
    super.initState();
    final e = _enquiry;
    final classBoard = (e['class_board'] ?? '').toString();
    final separator = classBoard.lastIndexOf('-');
    final board = separator >= 0 ? classBoard.substring(0, separator).trim() : '';
    final className = separator >= 0 ? classBoard.substring(separator + 1).trim() : '';
    final subjectNames = (e['subjects'] ?? '').toString();
    _subjectsText = subjectNames;
    final values = <String, String>{
      'roll_no': '',
      'name': (e['student_name'] ?? '').toString(),
      'class': className,
      'board': board,
      'phone': (e['mobile_number'] ?? '').toString().replaceAll(RegExp(r'\D'), ''),
      'email': '',
      'school_name': (e['school_name'] ?? '').toString(),
      'date_of_birth': e['date_of_birth'] == null ? '' : e['date_of_birth'].toString().substring(0, 10),
      'academic_year_from': (e['academic_year_from'] ?? '').toString(),
      'academic_year_to': (e['academic_year_to'] ?? '').toString(),
      'parent_name': (e['parent_name'] ?? '').toString(),
      'secondary_contact': (e['secondary_contact'] ?? '').toString().replaceAll(RegExp(r'\D'), ''),
      'reference': (e['reference'] ?? '').toString(),
      'password': '',
      'total_fee': '0',
      'fee_paid': '0',
      'next_due': '',
    };
    for (final entry in values.entries) {
      _fields[entry.key] = TextEditingController(text: entry.value);
    }
    _loadOptions();
  }

  @override
  void dispose() {
    for (final controller in _fields.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadOptions() async {
    try {
      if (_isTestBatch) {
        final adminId = (widget.args['adminId'] ?? '').toString().trim().toUpperCase();
        final response = await _api.get('/test-batch/series', queryParameters: {'adminId': adminId});
        final data = response.data;
        final list = data is Map ? data['series'] : null;
        if (list is List) {
          _series = list.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
        }
        if (_series.isNotEmpty) _seriesId = _series.first['id']?.toString();
      } else {
        final response = await _api.get('/subjects');
        if (response.data is List) {
          _subjects = (response.data as List).whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e)).toList();
          final wanted = _subjectsText.toLowerCase();
          for (final subject in _subjects) {
            final name = (subject['subject_name'] ?? '').toString().toLowerCase();
            if (name.isNotEmpty && wanted.contains(name)) {
              final id = int.tryParse(subject['subject_id'].toString());
              if (id != null) _subjectIds.add(id);
            }
          }
        }
      }
    } catch (error) {
      _error = error.toString().replaceFirst('Exception: ', '');
    } finally {
      if (mounted) setState(() => _loadingOptions = false);
    }
  }

  String? _value(String key) => _fields[key]?.text.trim();

  Future<void> _cancelAdmission() async {
    if (_finished || _enquiryId.isEmpty || _token.isEmpty) return;
    try {
      await _api.post('/enquiries/$_enquiryId/admission/cancel',
          data: {'admission_token': _token});
      _finished = true;
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not release admission session: ${error.toString().replaceFirst('Exception: ', '')}')),
        );
      }
    }
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    if (!_isTestBatch && _subjectIds.isEmpty) {
      setState(() => _error = 'Select at least one subject.');
      return;
    }
    if (_isTestBatch && _seriesId == null) {
      setState(() => _error = 'Select a Test Series.');
      return;
    }
    setState(() { _saving = true; _error = null; });
    final adminId = AuthProvider().user?.id.trim().toUpperCase() ?? '';
    try {
      final common = <String, dynamic>{
        'enquiry_id': _enquiryId,
        'admission_token': _token,
        'roll_no': _value('roll_no'),
        'name': _value('name'),
        'class': _value('class'),
        'board': _value('board'),
        'phone': _value('phone'),
        'email': _value('email'),
        'school_name': _value('school_name'),
        'password': _value('password'),
        'date_of_birth': _value('date_of_birth')?.isEmpty == true ? null : _value('date_of_birth'),
        'academic_year_from': _value('academic_year_from')?.isEmpty == true ? null : _value('academic_year_from'),
        'academic_year_to': _value('academic_year_to')?.isEmpty == true ? null : _value('academic_year_to'),
        'parent_name': _value('parent_name'),
        'secondary_contact': _value('secondary_contact'),
        'reference': _value('reference'),
      };
      if (_isTestBatch) {
        common.addAll({
          'mode_of_education': _mode,
          'test_series_id': int.tryParse(_seriesId ?? ''),
          'subjects': _subjectsText.isNotEmpty ? _subjectsText : 'Both',
        });
        await _api.post('/test-batch/students',
            queryParameters: {'adminId': adminId}, data: common);
      } else {
        common.addAll({
          'batch': 'Regular Batch',
          'subject_ids': _subjectIds.toList(),
          'total_fee': _value('total_fee') ?? '0',
          'fee_paid': _value('fee_paid') ?? '0',
          'next_due': _value('next_due')?.isEmpty == true ? null : _value('next_due'),
        });
        await _api.post('/students', data: common);
      }
      _finished = true;
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Admission completed'),
          content: const Text('New student added successfully!'),
          actions: [FilledButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Continue'),
          )],
        ),
      );
      if (mounted) context.go(AppRoutes.adminEnquiries);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _field(String key, String label, {bool required = false, TextInputType? keyboardType, String? hint}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: _fields[key],
        keyboardType: keyboardType,
        decoration: InputDecoration(labelText: label, hintText: hint),
        validator: (value) => required && (value == null || value.trim().isEmpty) ? 'Required' : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final labels = <String, String>{
      'roll_no': 'Roll number',
      'name': 'Student name',
      'class': 'Class',
      'board': 'Board',
      'phone': 'Phone',
      'email': 'Email',
      'school_name': 'School name',
      'date_of_birth': 'Date of birth (YYYY-MM-DD)',
      'academic_year_from': 'Academic year from',
      'academic_year_to': 'Academic year to',
      'parent_name': 'Parent name',
      'secondary_contact': 'Secondary contact',
      'reference': 'Reference',
      'password': 'Initial password (optional)',
    };
    final requiredKeys = _isTestBatch
        ? {'roll_no', 'name', 'class'}
        : {'roll_no', 'name', 'class', 'board', 'phone', 'email', 'school_name'};
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_isTestBatch ? 'Add Test Batch Student' : 'Add Regular Student'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.primary,
        leading: IconButton(
          tooltip: 'Cancel admission',
          onPressed: _saving ? null : () async {
            await _cancelAdmission();
            if (context.mounted) context.go(AppRoutes.adminEnquiries);
          },
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: _loadingOptions
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    elevation: 0,
                    color: AppColors.surface,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(_isTestBatch ? 'Test Batch admission' : 'Regular Batch admission',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.primary)),
                        const SizedBox(height: 6),
                        Text('Prefilled from enquiry ${_enquiry['enq_id'] ?? _enquiryId}. Review and edit the fields before saving.',
                            style: const TextStyle(color: AppColors.textSecondary)),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...labels.entries.map((entry) => _field(
                    entry.key, entry.value,
                    required: requiredKeys.contains(entry.key),
                    keyboardType: {'phone', 'secondary_contact'}.contains(entry.key) ? TextInputType.phone : null,
                  )),
                  if (_isTestBatch) ...[
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _seriesId,
                      decoration: const InputDecoration(labelText: 'Test Series'),
                      items: _series.map((series) => DropdownMenuItem(
                        value: series['id'].toString(),
                        child: Text(series['name'].toString()),
                      )).toList(),
                      onChanged: (value) => setState(() => _seriesId = value),
                      validator: (value) => value == null ? 'Select a Test Series' : null,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _mode,
                      decoration: const InputDecoration(labelText: 'Mode of education'),
                      items: const [
                        DropdownMenuItem(value: 'Online', child: Text('Online')),
                        DropdownMenuItem(value: 'Offline', child: Text('Offline')),
                      ],
                      onChanged: (value) => setState(() => _mode = value ?? 'Online'),
                    ),
                    const SizedBox(height: 12),
                    const Text('Subjects', style: TextStyle(fontWeight: FontWeight.w700)),
                    ...['Mathematics', 'Physics', 'Both'].map((subject) => RadioListTile<String>(
                      contentPadding: EdgeInsets.zero,
                      title: Text(subject),
                      value: subject,
                      groupValue: _subjectsText,
                      onChanged: (value) => setState(() => _subjectsText = value ?? ''),
                    )),
                  ] else ...[
                    const Text('Subjects', style: TextStyle(fontWeight: FontWeight.w700)),
                    ..._subjects.map((subject) {
                      final id = int.tryParse(subject['subject_id'].toString());
                      if (id == null) return const SizedBox.shrink();
                      return CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text((subject['subject_name'] ?? 'Subject').toString()),
                        value: _subjectIds.contains(id),
                        onChanged: (checked) => setState(() {
                          if (checked == true) { _subjectIds.add(id); } else { _subjectIds.remove(id); }
                        }),
                      );
                    }),
                    _field('total_fee', 'Total fee', keyboardType: TextInputType.number),
                    _field('fee_paid', 'Fee paid', keyboardType: TextInputType.number),
                    _field('next_due', 'Next due date (YYYY-MM-DD)'),
                  ],
                  if (_error != null) Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(_error!, style: const TextStyle(color: AppColors.error)),
                  ),
                  FilledButton(
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Save Student'),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }
}
