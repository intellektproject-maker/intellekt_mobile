import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../core/api/api_client.dart';
import '../../core/constants/colors.dart';

class ManageStudentsScreen extends StatefulWidget {
  final String userId;

  const ManageStudentsScreen({super.key, required this.userId});

  @override
  State<ManageStudentsScreen> createState() => _ManageStudentsScreenState();
}

class _ManageStudentsScreenState extends State<ManageStudentsScreen> {
  final ApiClient _api = ApiClient();
  final TextEditingController _search = TextEditingController();

  List<Map<String, dynamic>> _students = [];
  List<Map<String, dynamic>> _subjects = [];
  bool _loading = true;
  String? _error;
  String _classFilter = '';
  String _boardFilter = '';
  int _page = 1;

  static const int _pageSize = 10;

  String _text(dynamic value) => (value ?? '').toString().trim();
  String _errorText(Object error) =>
      error.toString().replaceFirst('Exception: ', '').trim();

  bool _isRegularStudent(Map<String, dynamic> student) {
    final batch = _text(student['batch']).toLowerCase();
    return batch.isEmpty || batch == 'regular batch';
  }

  List<Map<String, dynamic>> get _visibleStudents {
    final query = _search.text.trim().toLowerCase();
    return _students.where((student) {
      final matchesSearch = query.isEmpty ||
          [
            student['roll_no'],
            student['name'],
            student['phone'],
            student['email'],
            student['school_name'],
          ].any((value) => _text(value).toLowerCase().contains(query));
      final matchesClass =
          _classFilter.isEmpty || _text(student['class']) == _classFilter;
      final matchesBoard =
          _boardFilter.isEmpty || _text(student['board']) == _boardFilter;
      return _isRegularStudent(student) &&
          matchesSearch &&
          matchesClass &&
          matchesBoard;
    }).toList();
  }

  List<String> get _classes => _students
      .where(_isRegularStudent)
      .map((student) => _text(student['class']))
      .where((value) => value.isNotEmpty)
      .toSet()
      .toList()
    ..sort();

  List<String> get _boards => _students
      .where(_isRegularStudent)
      .map((student) => _text(student['board']))
      .where((value) => value.isNotEmpty)
      .toSet()
      .toList()
    ..sort();

  int get _totalPages =>
      (_visibleStudents.length / _pageSize).ceil().clamp(1, 999999).toInt();

  List<Map<String, dynamic>> get _pageStudents {
    final start = (_page - 1) * _pageSize;
    return _visibleStudents.skip(start).take(_pageSize).toList();
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _message(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final responses = await Future.wait([
        _api.get('/students'),
        _api.get('/subjects'),
      ]);
      final studentData = responses[0].data;
      final subjectData = responses[1].data;
      if (studentData is! List || subjectData is! List) {
        throw Exception('Unexpected student or subject response.');
      }
      final students = studentData
          .whereType<Map>()
          .map((row) {
            final student = Map<String, dynamic>.from(row);
            // The legacy list API includes a password field; never retain or display it in the list.
            student.remove('password');
            return student;
          })
          .where(_isRegularStudent)
          .toList();
      final subjects = subjectData
          .whereType<Map>()
          .map((row) => Map<String, dynamic>.from(row))
          .toList();
      if (!mounted) return;
      setState(() {
        _students = students;
        _subjects = subjects;
        if (_classFilter.isNotEmpty && !_classes.contains(_classFilter)) {
          _classFilter = '';
        }
        if (_boardFilter.isNotEmpty && !_boards.contains(_boardFilter)) {
          _boardFilter = '';
        }
        _page = 1;
      });
    } catch (error) {
      if (mounted) setState(() => _error = _errorText(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openStudentForm({String? rollNo}) async {
    final editing = rollNo != null;
    final controllers = <String, TextEditingController>{
      for (final key in [
        'roll_no',
        'name',
        'class',
        'board',
        'date_of_birth',
        'academic_year_from',
        'academic_year_to',
        'parent_name',
        'secondary_contact',
        'reference',
        'phone',
        'email',
        'school_name',
        'password',
        'total_fee',
        'fee_paid',
        'next_due',
      ])
        key: TextEditingController(),
    };
    final selectedSubjects = <int>{};
    var currentPassword = '';
    var saving = false;
    String? formError;

    void fill(Map<String, dynamic> data) {
      for (final entry in controllers.entries) {
        entry.value.text = _text(data[entry.key]);
      }
      currentPassword = _text(data['password']);
      controllers['date_of_birth']!.text =
          _dateOnly(data['date_of_birth']);
      controllers['next_due']!.text = _dateOnly(data['next_due']);
      final mapped = data['subjects'];
      if (mapped is List) {
        for (final subject in mapped.whereType<Map>()) {
          final id = int.tryParse(_text(subject['subject_id']));
          if (id != null) selectedSubjects.add(id);
        }
      }
    }

    if (editing) {
      try {
        final response = await _api.get(
          '/students/${Uri.encodeComponent(rollNo)}',
        );
        if (response.data is! Map) {
          throw Exception('Invalid student details response.');
        }
        fill(Map<String, dynamic>.from(response.data as Map));
      } catch (error) {
        _message('Could not load student: ${_errorText(error)}');
        for (final controller in controllers.values) {
          controller.dispose();
        }
        return;
      }
    }

    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.background,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            Widget field(
              String key,
              String label, {
              TextInputType keyboard = TextInputType.text,
              bool required = false,
              bool obscure = false,
              String? hint,
              int maxLines = 1,
            }) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: TextFormField(
                  controller: controllers[key],
                  keyboardType: keyboard,
                  obscureText: obscure,
                  maxLines: maxLines,
                  decoration: InputDecoration(
                    labelText: required ? '$label *' : label,
                    hintText: hint,
                    border: const OutlineInputBorder(),
                    filled: true,
                    fillColor: AppColors.surface,
                  ),
                ),
              );
            }

            Future<void> pickDate(String key, String label) async {
              final now = DateTime.now();
              final existing = DateTime.tryParse(controllers[key]!.text);
              final picked = await showDatePicker(
                context: context,
                initialDate: existing ?? DateTime(now.year, now.month, now.day),
                firstDate: DateTime(1950),
                lastDate: DateTime(now.year + 10),
                helpText: label,
              );
              if (picked != null) {
                controllers[key]!.text = _dateOnly(picked.toIso8601String());
                setSheetState(() {});
              }
            }

            Future<void> submit() async {
              final roll = controllers['roll_no']!.text.trim();
              final name = controllers['name']!.text.trim();
              final className = controllers['class']!.text.trim();
              final board = controllers['board']!.text.trim();
              final phone = controllers['phone']!.text.trim();
              final email = controllers['email']!.text.trim();
              final school = controllers['school_name']!.text.trim();
              final password = controllers['password']!.text.trim();

              if ([roll, name, className, board, phone, email, school]
                  .any((value) => value.isEmpty)) {
                setSheetState(() => formError = 'Please complete all required fields.');
                return;
              }
              if (!RegExp(r'^\d{10}$').hasMatch(phone)) {
                setSheetState(() => formError = 'Phone number must be exactly 10 digits.');
                return;
              }
              if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
                setSheetState(() => formError = 'Enter a valid email address.');
                return;
              }
              if (selectedSubjects.isEmpty) {
                setSheetState(() => formError = 'Select at least one subject.');
                return;
              }
              if (password.isNotEmpty && password.length < 4) {
                setSheetState(() => formError = 'Password must contain at least 4 characters.');
                return;
              }

              final totalFee =
                  double.tryParse(controllers['total_fee']!.text.trim()) ?? 0;
              final feePaid =
                  double.tryParse(controllers['fee_paid']!.text.trim()) ?? 0;
              if (totalFee < 0 || feePaid < 0) {
                setSheetState(() => formError = 'Fee values cannot be negative.');
                return;
              }

              final payload = <String, dynamic>{
                'roll_no': roll,
                'name': name,
                'class': className,
                'board': board,
                'date_of_birth':
                    controllers['date_of_birth']!.text.trim().isEmpty
                        ? null
                        : controllers['date_of_birth']!.text.trim(),
                'batch': 'Regular Batch',
                'academic_year_from':
                    controllers['academic_year_from']!.text.trim().isEmpty
                        ? null
                        : controllers['academic_year_from']!.text.trim(),
                'academic_year_to':
                    controllers['academic_year_to']!.text.trim().isEmpty
                        ? null
                        : controllers['academic_year_to']!.text.trim(),
                'parent_name': controllers['parent_name']!.text.trim(),
                'secondary_contact':
                    controllers['secondary_contact']!.text.trim(),
                'reference': controllers['reference']!.text.trim(),
                'phone': phone,
                'email': email,
                'school_name': school,
                'password': password.isNotEmpty
                    ? password
                    : (editing ? currentPassword : roll),
                'subject_ids': selectedSubjects.toList(),
                'total_fee': totalFee,
                'fee_paid': feePaid,
                'next_due': controllers['next_due']!.text.trim().isEmpty
                    ? null
                    : controllers['next_due']!.text.trim(),
              };

              setSheetState(() {
                saving = true;
                formError = null;
              });
              try {
                final response = editing
                    ? await _api.put(
                        '/students/${Uri.encodeComponent(rollNo)}',
                        data: payload,
                      )
                    : await _api.post('/students', data: payload);
                if (!mounted) return;
                Navigator.of(sheetContext).pop();
                _message(
                  editing
                      ? 'Student updated successfully.'
                      : 'Student added successfully.',
                );
                await _loadData();
                if (response.data is Map &&
                    response.data['roll_no'] != null) {
                  debugPrint('Created student ${response.data['roll_no']}');
                }
              } catch (error) {
                setSheetState(() {
                  saving = false;
                  formError = _errorText(error);
                });
              }
            }

            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.viewInsetsOf(context).bottom + 20,
              ),
              child: SizedBox(
                height: MediaQuery.sizeOf(context).height * 0.88,
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            editing ? 'Edit Student' : 'Add Student',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: saving
                              ? null
                              : () => Navigator.of(sheetContext).pop(),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const Divider(),
                    Expanded(
                      child: ListView(
                        children: [
                          field('roll_no', 'Roll Number', required: true),
                          field('name', 'Student Name', required: true),
                          field('class', 'Class', required: true),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: DropdownButtonFormField<String>(
                              value: const ['State Board', 'CBSE', 'ICSE', 'ISC']
                                      .contains(controllers['board']!.text)
                                  ? controllers['board']!.text
                                  : null,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: 'Board *',
                                border: OutlineInputBorder(),
                                filled: true,
                                fillColor: AppColors.surface,
                              ),
                              items: const [
                                DropdownMenuItem(value: 'State Board', child: Text('State Board')),
                                DropdownMenuItem(value: 'CBSE', child: Text('CBSE')),
                                DropdownMenuItem(value: 'ICSE', child: Text('ICSE')),
                                DropdownMenuItem(value: 'ISC', child: Text('ISC')),
                              ],
                              onChanged: (value) {
                                if (value != null) {
                                  controllers['board']!.text = value;
                                  setSheetState(() {});
                                }
                              },
                            ),
                          ),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Date of Birth'),
                            subtitle: Text(
                              controllers['date_of_birth']!.text.isEmpty
                                  ? 'Not selected'
                                  : controllers['date_of_birth']!.text,
                            ),
                            trailing: IconButton(
                              onPressed: () => pickDate('date_of_birth', 'Date of Birth'),
                              icon: const Icon(Icons.calendar_month_outlined),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Batch: Regular Batch',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 12),
                          field('academic_year_from', 'Academic Year From',
                              keyboard: TextInputType.number),
                          field('academic_year_to', 'Academic Year To',
                              keyboard: TextInputType.number),
                          field('parent_name', 'Parent Name'),
                          field('secondary_contact', 'Secondary Contact',
                              keyboard: TextInputType.phone),
                          field('reference', 'Reference'),
                          field('phone', 'Phone Number',
                              keyboard: TextInputType.phone, required: true),
                          field('email', 'Email Address',
                              keyboard: TextInputType.emailAddress, required: true),
                          field('school_name', 'School Name', required: true),
                          field(
                            'password',
                            editing ? 'New Password (optional)' : 'Password (optional)',
                            obscure: true,
                            hint: editing
                                ? 'Leave blank to keep current password'
                                : 'Leave blank to use roll number',
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Enrolled Subjects *',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 6),
                          ..._subjects.map((subject) {
                            final id = int.tryParse(_text(subject['subject_id']));
                            if (id == null) return const SizedBox.shrink();
                            return CheckboxListTile(
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                              value: selectedSubjects.contains(id),
                              title: Text(_text(subject['subject_name'])),
                              activeColor: AppColors.primary,
                              onChanged: (checked) {
                                setSheetState(() {
                                  if (checked == true) {
                                    selectedSubjects.add(id);
                                  } else {
                                    selectedSubjects.remove(id);
                                  }
                                });
                              },
                            );
                          }),
                          const Divider(),
                          field('total_fee', 'Total Fee',
                              keyboard: const TextInputType.numberWithOptions(decimal: true)),
                          field('fee_paid', 'Fee Paid',
                              keyboard: const TextInputType.numberWithOptions(decimal: true)),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Next Fee Due Date'),
                            subtitle: Text(
                              controllers['next_due']!.text.isEmpty
                                  ? 'Not selected'
                                  : controllers['next_due']!.text,
                            ),
                            trailing: IconButton(
                              onPressed: () => pickDate('next_due', 'Next Fee Due Date'),
                              icon: const Icon(Icons.calendar_month_outlined),
                            ),
                          ),
                          if (formError != null)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              child: Text(
                                formError!,
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          const SizedBox(height: 12),
                          FilledButton.icon(
                            onPressed: saving ? null : submit,
                            icon: saving
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.save_outlined),
                            label: Text(saving ? 'Saving...' : 'Save Student'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    for (final controller in controllers.values) {
      controller.dispose();
    }
  }

  String _dateOnly(dynamic value) {
    final raw = _text(value);
    if (raw.isEmpty) return '';
    return raw.length >= 10 ? raw.substring(0, 10) : raw;
  }

  Future<void> _deleteStudent(Map<String, dynamic> student) async {
    final roll = _text(student['roll_no']);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Student'),
        content: Text(
          'Delete $roll permanently? Related marks, attendance, fee and subject records are also removed by the server.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _api.delete('/students/${Uri.encodeComponent(roll)}');
      _message('Student deleted successfully.');
      await _loadData();
    } catch (error) {
      _message('Could not delete student: ${_errorText(error)}');
    }
  }

  Future<void> _exportCsv() async {
    final rows = _visibleStudents;
    if (rows.isEmpty) {
      _message('No students available to export.');
      return;
    }
    final headers = [
      'Roll No',
      'Name',
      'Class',
      'Board',
      'Date of Birth',
      'Batch',
      'Academic Year From',
      'Academic Year To',
      'Parent Name',
      'Phone',
      'Secondary Contact',
      'Reference',
      'Email',
      'School',
    ];
    String cell(dynamic value) =>
        '"${_text(value).replaceAll('"', '""')}"';
    final csv = [
      headers.map(cell).join(','),
      ...rows.map((student) => [
            student['roll_no'],
            student['name'],
            student['class'],
            student['board'],
            student['date_of_birth'],
            student['batch'] ?? 'Regular Batch',
            student['academic_year_from'],
            student['academic_year_to'],
            student['parent_name'],
            student['phone'],
            student['secondary_contact'],
            student['reference'],
            student['email'],
            student['school_name'],
          ].map(cell).join(',')),
    ].join('\r\n');
    final bytes = Uint8List.fromList([0xEF, 0xBB, 0xBF, ...utf8.encode(csv)]);
    try {
      final path = await FilePicker.platform.saveFile(
        dialogTitle: 'Export student list',
        fileName: 'student-list.csv',
        type: FileType.custom,
        allowedExtensions: ['csv'],
        bytes: bytes,
      );
      if (path != null) _message('Excel-compatible student CSV exported.');
    } catch (error) {
      _message('Could not export Excel file: ${_errorText(error)}');
    }
  }

  Future<void> _exportPdf() async {
    final rows = _visibleStudents;
    if (rows.isEmpty) {
      _message('No students available to export.');
      return;
    }
    final document = pw.Document();
    final data = rows.map((student) => [
      _text(student['roll_no']),
      _text(student['name']),
      _text(student['class']),
      _text(student['board']),
      _dateOnly(student['date_of_birth']),
      _text(student['batch']).isEmpty ? 'Regular Batch' : _text(student['batch']),
      _text(student['academic_year_from']),
      _text(student['academic_year_to']),
      _text(student['parent_name']),
      _text(student['phone']),
      _text(student['secondary_contact']),
      _text(student['reference']),
      _text(student['email']),
      _text(student['school_name']),
    ]).toList();
    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(24),
        build: (context) => [
          pw.Text(
            'INTELLEKT ACADEMY',
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromHex('#000351'),
            ),
          ),
          pw.SizedBox(height: 5),
          pw.Text('Regular Student List • Total: ${rows.length}'),
          pw.SizedBox(height: 14),
          pw.TableHelper.fromTextArray(
            headers: const [
              'Roll No',
              'Name',
              'Class',
              'Board',
              'DOB',
              'Batch',
              'Academic From',
              'Academic To',
              'Parent',
              'Phone',
              'Secondary Contact',
              'Reference',
              'Email',
              'School',
            ],
            data: data,
            headerDecoration: pw.BoxDecoration(
              color: PdfColor.fromHex('#000351'),
            ),
            headerStyle: pw.TextStyle(
              color: PdfColors.white,
              fontWeight: pw.FontWeight.bold,
              fontSize: 8,
            ),
            cellStyle: const pw.TextStyle(fontSize: 7),
            cellPadding: const pw.EdgeInsets.all(5),
            border: pw.TableBorder.all(
              color: PdfColor.fromHex('#D9E0EF'),
              width: 0.5,
            ),
          ),
        ],
      ),
    );
    try {
      await Printing.sharePdf(
        bytes: await document.save(),
        filename: 'intellekt-student-list.pdf',
      );
    } catch (error) {
      _message('Could not export PDF: ${_errorText(error)}');
    }
  }

  Future<void> _showExportOptions() async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Wrap(
          children: [
            const ListTile(
              title: Text(
                'Export Filtered Students',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf_outlined, color: Colors.red),
              title: const Text('Export as PDF'),
              onTap: () {
                Navigator.pop(sheetContext);
                _exportPdf();
              },
            ),
            ListTile(
              leading: const Icon(Icons.table_view_outlined, color: Colors.green),
              title: const Text('Export for Excel (CSV)'),
              onTap: () {
                Navigator.pop(sheetContext);
                _exportCsv();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterDropdown(
    String label,
    String value,
    List<String> options,
    ValueChanged<String?> onChanged,
  ) {
    return DropdownButtonFormField<String>(
      value: value.isEmpty ? '' : value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: AppColors.surface,
      ),
      items: [
        const DropdownMenuItem(value: '', child: Text('All')),
        ...options.map(
          (option) => DropdownMenuItem(value: option, child: Text(option)),
        ),
      ],
      onChanged: onChanged,
    );
  }

  @override
  Widget build(BuildContext context) {
    final visible = _visibleStudents;
    final start = visible.isEmpty ? 0 : (_page - 1) * _pageSize + 1;
    final end = (_page * _pageSize).clamp(0, visible.length);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Manage Students'),
        foregroundColor: AppColors.primary,
        backgroundColor: AppColors.surface,
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loading ? null : _loadData,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _loading ? null : () => _openStudentForm(),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Add Student'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          children: [
            Card(
              color: AppColors.surface,
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Regular Student Management',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_students.length} students • Signed in: ${widget.userId}',
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _search,
                      onChanged: (_) => setState(() => _page = 1),
                      decoration: const InputDecoration(
                        labelText: 'Search roll no, name, phone, email or school',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _filterDropdown(
                      'Class',
                      _classFilter,
                      _classes,
                      (value) => setState(() {
                        _classFilter = value ?? '';
                        _page = 1;
                      }),
                    ),
                    const SizedBox(height: 12),
                    _filterDropdown(
                      'Board',
                      _boardFilter,
                      _boards,
                      (value) => setState(() {
                        _boardFilter = value ?? '';
                        _page = 1;
                      }),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton.icon(
                          onPressed: _loading ? null : _loadData,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Refresh'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => setState(() {
                            _search.clear();
                            _classFilter = '';
                            _boardFilter = '';
                            _page = 1;
                          }),
                          icon: const Icon(Icons.filter_alt_off_outlined),
                          label: const Text('Clear Filters'),
                        ),
                        FilledButton.tonalIcon(
                          onPressed: _showExportOptions,
                          icon: const Icon(Icons.file_download_outlined),
                          label: const Text('Export'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (_error != null)
              Card(
                color: Colors.red.shade50,
                child: ListTile(
                  leading: const Icon(Icons.error_outline, color: Colors.red),
                  title: const Text('Could not load students'),
                  subtitle: Text(_error!),
                  trailing: IconButton(
                    onPressed: _loadData,
                    icon: const Icon(Icons.refresh),
                  ),
                ),
              ),
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (visible.isEmpty)
              const Card(
                color: AppColors.surface,
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: Text('No students found.')),
                ),
              )
            else ...[
              const SizedBox(height: 8),
              ..._pageStudents.map((student) {
                final roll = _text(student['roll_no']);
                return Card(
                  color: AppColors.surface,
                  elevation: 0,
                  margin: const EdgeInsets.only(bottom: 10),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                _text(student['name']),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            PopupMenuButton<String>(
                              onSelected: (value) {
                                if (value == 'edit') {
                                  _openStudentForm(rollNo: roll);
                                } else if (value == 'delete') {
                                  _deleteStudent(student);
                                }
                              },
                              itemBuilder: (_) => const [
                                PopupMenuItem(
                                  value: 'edit',
                                  child: Text('Edit'),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Text('Delete'),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Text(
                          'Roll No: $roll',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const Divider(height: 18),
                        _detail('Class', _text(student['class'])),
                        _detail('Board', _text(student['board'])),
                        _detail('Date of Birth', _dateOnly(student['date_of_birth'])),
                        _detail('Batch', _text(student['batch']).isEmpty
                            ? 'Regular Batch'
                            : _text(student['batch'])),
                        _detail('Academic Year From', _text(student['academic_year_from'])),
                        _detail('Academic Year To', _text(student['academic_year_to'])),
                        _detail('Parent Name', _text(student['parent_name'])),
                        _detail('Phone', _text(student['phone'])),
                        _detail('Secondary Contact', _text(student['secondary_contact'])),
                        _detail('Reference', _text(student['reference'])),
                        _detail('Email', _text(student['email'])),
                        _detail('School', _text(student['school_name'])),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Showing $start–$end of ${visible.length}',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _page <= 1
                        ? null
                        : () => setState(() => _page--),
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Text('$_page / $_totalPages'),
                  IconButton(
                    onPressed: _page >= _totalPages
                        ? null
                        : () => setState(() => _page++),
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _detail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            TextSpan(text: value.isEmpty ? '-' : value),
          ],
        ),
      ),
    );
  }
}
