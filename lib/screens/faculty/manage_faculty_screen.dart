import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../core/api/api_client.dart';
import '../../core/constants/colors.dart';

class ManageFacultyScreen extends StatefulWidget {
  final String adminId;

  const ManageFacultyScreen({super.key, required this.adminId});

  @override
  State<ManageFacultyScreen> createState() => _ManageFacultyScreenState();
}

class _ManageFacultyScreenState extends State<ManageFacultyScreen> {
  final ApiClient _api = ApiClient();
  final TextEditingController _search = TextEditingController();

  List<Map<String, dynamic>> _faculty = [];
  List<Map<String, dynamic>> _roles = [];
  bool _loading = true;
  String? _error;
  int _page = 1;

  static const int _pageSize = 10;
  static const Set<String> _protectedAdmins = {'IG001', 'IG002'};

  String _value(dynamic value) => (value ?? '').toString().trim();
  String _id(dynamic value) => _value(value).toUpperCase();
  String _errorText(Object error) =>
      error.toString().replaceFirst('Exception: ', '').trim();

  bool _isProtected(String facultyId) =>
      _protectedAdmins.contains(_id(facultyId));

  String _roleName(Map<String, dynamic> faculty) {
    final existing = _value(faculty['role_name']);
    if (existing.isNotEmpty) return existing;
    final role = _roles.where(
      (item) => _value(item['role_id']) == _value(faculty['role_id']),
    );
    return role.isEmpty ? '-' : _value(role.first['role_name']);
  }

  List<Map<String, dynamic>> get _filteredFaculty {
    final query = _search.text.trim().toLowerCase();
    return _faculty.where((faculty) {
      if (query.isEmpty) return true;
      return [
        faculty['faculty_id'],
        faculty['name'],
        _roleName(faculty),
        faculty['phone'],
        faculty['email'],
        faculty['employment_type'],
      ].any((item) => _value(item).toLowerCase().contains(query));
    }).toList();
  }

  int get _totalPages =>
      (_filteredFaculty.length / _pageSize).ceil().clamp(1, 999999).toInt();

  List<Map<String, dynamic>> get _pageFaculty {
    final start = (_page - 1) * _pageSize;
    return _filteredFaculty.skip(start).take(_pageSize).toList();
  }

  String _nextFacultyId() {
    var maximum = 0;
    for (final faculty in _faculty) {
      final match = RegExp(r'^IG(\d+)$', caseSensitive: false)
          .firstMatch(_id(faculty['faculty_id']));
      if (match != null) {
        final number = int.tryParse(match.group(1) ?? '');
        if (number != null && number > maximum) maximum = number;
      }
    }
    return 'IG${(maximum + 1).toString().padLeft(3, '0')}';
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
      final results = await Future.wait([
        _api.get('/faculty'),
        _api.get('/faculty-roles'),
      ]);
      final facultyData = results[0].data;
      final rolesData = results[1].data;
      if (facultyData is! List || rolesData is! List) {
        throw Exception('Unexpected faculty or role response.');
      }

      final faculty = facultyData.whereType<Map>().map((row) {
        final item = Map<String, dynamic>.from(row);
        // The legacy faculty endpoint includes passwords. Never retain them in the list.
        item.remove('password');
        return item;
      }).toList();
      final roles = rolesData
          .whereType<Map>()
          .map((row) => Map<String, dynamic>.from(row))
          .toList();

      if (!mounted) return;
      setState(() {
        _faculty = faculty;
        _roles = roles;
        _page = 1;
      });
    } catch (error) {
      if (mounted) setState(() => _error = _errorText(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openFacultyForm({Map<String, dynamic>? existing}) async {
    final editing = existing != null;
    final originalId = editing ? _id(existing['faculty_id']) : '';
    final generatedId = editing ? originalId : _nextFacultyId();
    final controllers = <String, TextEditingController>{
      'faculty_id': TextEditingController(
        text: generatedId,
      ),
      'name': TextEditingController(text: editing ? _value(existing['name']) : ''),
      'phone': TextEditingController(text: editing ? _value(existing['phone']) : ''),
      'email': TextEditingController(text: editing ? _value(existing['email']) : ''),
      'password': TextEditingController(text: editing ? '' : generatedId),
      'date_of_joining': TextEditingController(
        text: editing ? _dateOnly(existing['date_of_joining']) : '',
      ),
    };
    String roleId = editing ? _value(existing['role_id']) : '';
    String employment = editing ? _value(existing['employment_type']) : '';
    bool saving = false;
    String? formError;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.background,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) {
          InputDecoration decoration(String label, {String? hint}) =>
              InputDecoration(
                labelText: label,
                hintText: hint,
                border: const OutlineInputBorder(),
                filled: true,
                fillColor: AppColors.surface,
              );

          Widget textField(
            String key,
            String label, {
            TextInputType keyboard = TextInputType.text,
            bool obscure = false,
            bool enabled = true,
            String? hint,
          }) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 13),
              child: TextField(
                controller: controllers[key],
                enabled: enabled,
                keyboardType: keyboard,
                obscureText: obscure,
                onChanged: key == 'phone'
                    ? (value) {
                        final digits = value.replaceAll(RegExp(r'\D'), '');
                        if (digits != value) {
                          controllers[key]!.value = TextEditingValue(
                            text: digits.length > 10 ? digits.substring(0, 10) : digits,
                            selection: TextSelection.collapsed(
                              offset: digits.length > 10 ? 10 : digits.length,
                            ),
                          );
                        }
                      }
                    : null,
                decoration: decoration(label, hint: hint),
              ),
            );
          }

          Future<void> chooseJoiningDate() async {
            final now = DateTime.now();
            final current = DateTime.tryParse(controllers['date_of_joining']!.text);
            final date = await showDatePicker(
              context: context,
              initialDate: current ?? now,
              firstDate: DateTime(1950),
              lastDate: DateTime(now.year + 5),
              helpText: 'Date of Joining',
            );
            if (date != null) {
              controllers['date_of_joining']!.text = _dateOnly(date.toIso8601String());
              setSheetState(() {});
            }
          }

          Future<void> submit() async {
            final facultyId = _id(controllers['faculty_id']!.text);
            final name = controllers['name']!.text.trim();
            final phone = controllers['phone']!.text.trim();
            final email = controllers['email']!.text.trim();
            final password = controllers['password']!.text.trim();
            final joining = controllers['date_of_joining']!.text.trim();

            if (facultyId.isEmpty || name.isEmpty || roleId.isEmpty ||
                phone.isEmpty || email.isEmpty || employment.isEmpty ||
                joining.isEmpty || (!editing && password.isEmpty)) {
              setSheetState(() => formError = 'Please complete all required fields.');
              return;
            }
            if (!RegExp(r'^\d{10}$').hasMatch(phone)) {
              setSheetState(() => formError = 'Phone number must contain exactly 10 digits.');
              return;
            }
            if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
              setSheetState(() => formError = 'Enter a valid email address.');
              return;
            }
            if (editing && _isProtected(originalId)) {
              setSheetState(() => formError = 'Protected admin accounts cannot be edited.');
              return;
            }

            final payload = <String, dynamic>{
              'faculty_id': facultyId,
              'name': name,
              'role_id': int.tryParse(roleId),
              'phone': phone,
              'email': email,
              'password': password,
              'employment_type': employment,
              'date_of_joining': joining,
            };

            setSheetState(() {
              saving = true;
              formError = null;
            });
            try {
              if (editing) {
                await _api.put(
                  '/faculty/${Uri.encodeComponent(originalId)}',
                  data: payload,
                );
              } else {
                await _api.post('/faculty', data: payload);
              }
              if (!mounted) return;
              Navigator.of(sheetContext).pop();
              _message(editing
                  ? 'Faculty updated successfully.'
                  : 'Faculty added successfully.');
              await _loadData();
            } catch (error) {
              setSheetState(() {
                saving = false;
                formError = _errorText(error);
              });
            }
          }

          return Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              16,
              16,
              MediaQuery.viewInsetsOf(context).bottom + 20,
            ),
            child: SizedBox(
              height: MediaQuery.sizeOf(context).height * 0.88,
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          editing ? 'Edit Faculty' : 'Add Faculty',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
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
                        textField('faculty_id', 'Faculty ID', enabled: false),
                        textField('name', 'Faculty Name'),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 13),
                          child: DropdownButtonFormField<String>(
                            value: _roles.any((role) =>
                                    _value(role['role_id']) == roleId)
                                ? roleId
                                : null,
                            isExpanded: true,
                            decoration: decoration('Subject / Role'),
                            items: _roles.map((role) {
                              final id = _value(role['role_id']);
                              return DropdownMenuItem(
                                value: id,
                                child: Text(_value(role['role_name'])),
                              );
                            }).toList(),
                            onChanged: (value) =>
                                setSheetState(() => roleId = value ?? ''),
                          ),
                        ),
                        textField(
                          'phone',
                          'Phone Number',
                          keyboard: TextInputType.phone,
                          hint: 'Enter 10 digit phone number',
                        ),
                        textField(
                          'email',
                          'Email',
                          keyboard: TextInputType.emailAddress,
                        ),
                        textField(
                          'password',
                          editing ? 'New Password (optional)' : 'Password',
                          obscure: true,
                          hint: editing
                              ? 'Leave empty to keep old password'
                              : 'Default is the generated faculty ID',
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 13),
                          child: DropdownButtonFormField<String>(
                            value: const ['Part Time', 'Full Time']
                                    .contains(employment)
                                ? employment
                                : null,
                            isExpanded: true,
                            decoration: decoration('Employment Type'),
                            items: const [
                              DropdownMenuItem(
                                value: 'Part Time',
                                child: Text('Part Time'),
                              ),
                              DropdownMenuItem(
                                value: 'Full Time',
                                child: Text('Full Time'),
                              ),
                            ],
                            onChanged: (value) =>
                                setSheetState(() => employment = value ?? ''),
                          ),
                        ),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Date of Joining *'),
                          subtitle: Text(joiningDateLabel(
                              controllers['date_of_joining']!.text)),
                          trailing: IconButton(
                            onPressed: chooseJoiningDate,
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
                          label: Text(saving
                              ? 'Saving...'
                              : editing
                                  ? 'Update Faculty'
                                  : 'Add Faculty'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    for (final controller in controllers.values) {
      controller.dispose();
    }
  }

  String joiningDateLabel(String value) =>
      value.isEmpty ? 'Select date of joining' : value;

  String _dateOnly(dynamic value) {
    final raw = _value(value);
    if (raw.isEmpty) return '';
    return raw.length >= 10 ? raw.substring(0, 10) : raw;
  }

  Future<void> _deleteFaculty(Map<String, dynamic> faculty) async {
    final facultyId = _id(faculty['faculty_id']);
    if (_isProtected(facultyId)) {
      _message('Admin accounts IG001 and IG002 are protected.');
      return;
    }
    if (facultyId == _id(widget.adminId)) {
      _message('You cannot delete the currently logged-in account.');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Faculty'),
        content: Text(
          'Delete $facultyId? This also removes the faculty notifications and assigned tasks, as in the web dashboard.',
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
      await _api.delete('/faculty/${Uri.encodeComponent(facultyId)}');
      _message('Faculty deleted successfully.');
      await _loadData();
    } catch (error) {
      _message('Could not delete faculty: ${_errorText(error)}');
    }
  }

  Future<void> _exportExcel() async {
    final rows = _filteredFaculty;
    if (rows.isEmpty) {
      _message('No faculty available to export.');
      return;
    }
    const headers = [
      'Faculty ID',
      'Name',
      'Subject / Role',
      'Employment',
      'Date of Joining',
      'Phone',
      'Email',
    ];
    String cell(dynamic value) =>
        '"${_value(value).replaceAll('"', '""')}"';
    final csv = [
      headers.map(cell).join(','),
      ...rows.map((faculty) => [
            faculty['faculty_id'],
            faculty['name'],
            _roleName(faculty),
            faculty['employment_type'],
            _dateOnly(faculty['date_of_joining']),
            faculty['phone'],
            faculty['email'],
          ].map(cell).join(',')),
    ].join('\r\n');
    final bytes = Uint8List.fromList([0xEF, 0xBB, 0xBF, ...utf8.encode(csv)]);
    try {
      final path = await FilePicker.platform.saveFile(
        dialogTitle: 'Export faculty list',
        fileName: 'faculty-list.csv',
        type: FileType.custom,
        allowedExtensions: ['csv'],
        bytes: bytes,
      );
      if (path != null) _message('Excel-compatible faculty CSV exported.');
    } catch (error) {
      _message('Could not export Excel file: ${_errorText(error)}');
    }
  }

  Future<void> _exportPdf() async {
    final rows = _filteredFaculty;
    if (rows.isEmpty) {
      _message('No faculty available to export.');
      return;
    }
    final document = pw.Document();
    final data = rows.map((faculty) => [
      _value(faculty['faculty_id']),
      _value(faculty['name']),
      _roleName(faculty),
      _value(faculty['employment_type']),
      _dateOnly(faculty['date_of_joining']),
      _value(faculty['phone']),
      _value(faculty['email']),
    ]).toList();
    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(24),
        build: (context) => [
          pw.Text(
            'INTELLEKT ACADEMY - FACULTY LIST',
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromHex('#000351'),
            ),
          ),
          pw.SizedBox(height: 5),
          pw.Text('Total Faculty: ${rows.length}'),
          pw.SizedBox(height: 14),
          pw.TableHelper.fromTextArray(
            headers: const [
              'Faculty ID',
              'Name',
              'Subject / Role',
              'Employment',
              'Date of Joining',
              'Phone',
              'Email',
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
            cellStyle: const pw.TextStyle(fontSize: 8),
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
        filename: 'intellekt-faculty-list.pdf',
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
                'Export Filtered Faculty',
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
                _exportExcel();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final visible = _filteredFaculty;
    final start = visible.isEmpty ? 0 : (_page - 1) * _pageSize + 1;
    final end = (_page * _pageSize).clamp(0, visible.length);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Manage Faculty'),
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
        onPressed: _loading ? null : () => _openFacultyForm(),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Add Faculty'),
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
                      'Faculty List',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _search,
                      onChanged: (_) => setState(() => _page = 1),
                      decoration: const InputDecoration(
                        labelText: 'Search faculty ID, name, role, phone or email',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                      ),
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
                        FilledButton.tonalIcon(
                          onPressed: _showExportOptions,
                          icon: const Icon(Icons.file_download_outlined),
                          label: const Text('Export'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${_faculty.length} faculty members • Signed in: ${_id(widget.adminId)}',
                      style: const TextStyle(color: AppColors.textSecondary),
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
                  title: const Text('Could not load faculty'),
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
                  child: Center(child: Text('No faculty found.')),
                ),
              )
            else ...[
              ..._pageFaculty.map((faculty) {
                final facultyId = _id(faculty['faculty_id']);
                final protected = _isProtected(facultyId);
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
                                _value(faculty['name']),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            if (protected)
                              const Chip(
                                label: Text('Protected Admin'),
                                visualDensity: VisualDensity.compact,
                              )
                            else
                              PopupMenuButton<String>(
                                onSelected: (action) {
                                  if (action == 'edit') {
                                    _openFacultyForm(existing: faculty);
                                  } else if (action == 'delete') {
                                    _deleteFaculty(faculty);
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
                          'Faculty ID: $facultyId',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const Divider(height: 18),
                        _detail('Subject / Role', _roleName(faculty)),
                        _detail('Employment', _value(faculty['employment_type'])),
                        _detail('Date of Joining', _dateOnly(faculty['date_of_joining'])),
                        _detail('Phone', _value(faculty['phone'])),
                        _detail('Email', _value(faculty['email'])),
                      ],
                    ),
                  ),
                );
              }),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Showing $start–$end of ${visible.length} • Page $_page of $_totalPages',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _page <= 1 ? null : () => setState(() => _page--),
                    icon: const Icon(Icons.chevron_left),
                  ),
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
