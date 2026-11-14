import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';
import '../../core/constants/colors.dart';

class FacultyEnquiryFormScreen extends StatefulWidget {
  const FacultyEnquiryFormScreen({super.key});

  @override
  State<FacultyEnquiryFormScreen> createState() => _FacultyEnquiryFormScreenState();
}

class _FacultyEnquiryFormScreenState extends State<FacultyEnquiryFormScreen> {
  final _api = ApiClient();
  final _formKey = GlobalKey<FormState>();
  final _student = TextEditingController();
  final _school = TextEditingController();
  final _parent = TextEditingController();
  final _phone = TextEditingController();
  final _secondary = TextEditingController();
  final _reference = TextEditingController();

  String? _className;
  String? _board;
  String? _subjects;
  String? _batch;
  String? _from;
  String? _to;
  DateTime? _dob;
  bool _saving = false;

  @override
  void dispose() {
    for (final controller in [_student, _school, _parent, _phone, _secondary, _reference]) {
      controller.dispose();
    }
    super.dispose();
  }

  int _age(DateTime dob) {
    final now = DateTime.now();
    var age = now.year - dob.year;
    if (now.month < dob.month || (now.month == dob.month && now.day < dob.day)) age--;
    return age;
  }

  String _formatDob(DateTime date) =>
      date.day.toString().padLeft(2, '0') + '/' +
      date.month.toString().padLeft(2, '0') + '/' + date.year.toString();

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'Required' : null;

  String? _studentNameValidator(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty || !RegExp(r'^[A-Za-z\s]+$').hasMatch(v)) {
      return 'Student name should contain only letters and spaces.';
    }
    return null;
  }

  String? _schoolNameValidator(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty || !RegExp('^[A-Za-z ]+
    return null;
  }

  String? _parentNameValidator(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty || !RegExp(r'^[A-Za-z\s]+$').hasMatch(v)) {
      return 'Parent name should contain only letters and spaces.';
    }
    return null;
  }

  String? _phoneValidator(String? value) {
    final v = (value ?? '').trim();
    if (!RegExp(r'^\d{10}$').hasMatch(v)) return 'Enter exactly 10 digits.';
    return null;
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 15, now.month, now.day),
      firstDate: DateTime(now.year - 19, now.month, now.day),
      lastDate: DateTime(now.year - 12, now.month, now.day),
    );
    if (picked != null) setState(() => _dob = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_dob == null || _age(_dob!) < 12 || _age(_dob!) > 19) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Student must be between 12 and 19 years old.')),
      );
      return;
    }

    if (_to == null || _from == null || int.parse(_to!) <= int.parse(_from!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Academic Year To must be greater than From.')),
      );
      return;
    }

    if (_phone.text.trim() == _secondary.text.trim()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Primary and secondary contact numbers cannot be the same.')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await _api.post('/enquiries', data: {
        'studentName': _student.text.trim(),
        'classBoard': _board! + '-' + _className!,
        'schoolName': _school.text.trim(),
        'subjects': _subjects,
        'academicYearFrom': _from,
        'academicYearTo': _to,
        'batch': _batch,
        'dateOfBirth': _dob!.toIso8601String().split('T').first,
        'parentName': _parent.text.trim(),
        'mobileNumber': _phone.text.trim(),
        'secondaryContact': _secondary.text.trim(),
        'reference': _reference.text.trim(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enquiry submitted successfully.')),
      );
      _formKey.currentState!.reset();
      for (final controller in [_student, _school, _parent, _phone, _secondary, _reference]) {
        controller.clear();
      }
      setState(() {
        _className = null;
        _board = null;
        _subjects = null;
        _batch = null;
        _from = null;
        _to = null;
        _dob = null;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _text(
    TextEditingController controller,
    String label, {
    bool required = true,
    TextInputType? keyboard,
    int maxLength = 100,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboard,
        maxLength: maxLength,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          counterText: '',
        ),
        validator: validator ?? (required ? _required : null),
      ),
    );
  }

  Widget _dropdown(
    String label,
    String? value,
    List<String> values,
    ValueChanged<String?> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        value: value,
        isExpanded: true,
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
        items: values.map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
        onChanged: onChanged,
        validator: _required,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Enquiry Form'),
        foregroundColor: AppColors.primary,
        backgroundColor: AppColors.surface,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              color: AppColors.surface,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _text(_student, 'Student Name', maxLength: 50, validator: _studentNameValidator),
                    _dropdown('Class', _className, const ['10', '11', '12'], (v) => setState(() => _className = v)),
                    _dropdown('Board', _board, const ['CBSE', 'Stateboard', 'ICSE', 'Isc'], (v) => setState(() => _board = v)),
                    _text(_school, 'School Name', validator: _schoolNameValidator),
                    _dropdown('Subjects Looking for', _subjects, const ['Physics', 'Maths', 'Both'], (v) => setState(() => _subjects = v)),
                    _dropdown(
                      'Academic Year From',
                      _from,
                      List.generate(4, (i) => (DateTime.now().year + i).toString()),
                      (v) => setState(() {
                        _from = v;
                        if (_to != null && v != null && int.parse(_to!) <= int.parse(v)) _to = null;
                      }),
                    ),
                    _dropdown(
                      'Academic Year To',
                      _to,
                      List.generate(5, (i) => (DateTime.now().year + i).toString())
                          .where((year) => _from == null || int.parse(year) > int.parse(_from!))
                          .toList(),
                      (v) => setState(() => _to = v),
                    ),
                    _dropdown('Batch', _batch, const ['Test Batch', 'Regular Batch'], (v) => setState(() => _batch = v)),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: OutlinedButton.icon(
                        onPressed: _pickDob,
                        icon: const Icon(Icons.calendar_month),
                        label: Text(_dob == null ? 'Date of Birth (D/M/Y)' : 'Date of Birth: ' + _formatDob(_dob!)),
                      ),
                    ),
                    if (_dob != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          'Age: ' + _age(_dob!).toString() + ' years (allowed: 12–19)',
                          style: TextStyle(
                            color: _age(_dob!) >= 12 && _age(_dob!) <= 19 ? Colors.green : Colors.red,
                          ),
                        ),
                      ),
                    _text(_parent, 'Parent Name', validator: _parentNameValidator),
                    _text(_phone, 'Phone Number', keyboard: TextInputType.phone, maxLength: 10, validator: _phoneValidator),
                    _text(_secondary, 'Secondary Contact', keyboard: TextInputType.phone, maxLength: 10, validator: _phoneValidator),
                    _text(_reference, 'Reference', required: false),
                    FilledButton.icon(
                      onPressed: _saving ? null : _submit,
                      icon: _saving
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.send),
                      label: Text(_saving ? 'Submitting...' : 'Submit Enquiry'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
).hasMatch(v)) {
      return 'School name should contain only letters and spaces.';
    }
    return null;
  }

  String? _parentNameValidator(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty || !RegExp(r'^[A-Za-z\s]+$').hasMatch(v)) {
      return 'Parent name should contain only letters and spaces.';
    }
    return null;
  }

  String? _phoneValidator(String? value) {
    final v = (value ?? '').trim();
    if (!RegExp(r'^\d{10}$').hasMatch(v)) return 'Enter exactly 10 digits.';
    return null;
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 15, now.month, now.day),
      firstDate: DateTime(now.year - 19, now.month, now.day),
      lastDate: DateTime(now.year - 12, now.month, now.day),
    );
    if (picked != null) setState(() => _dob = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_dob == null || _age(_dob!) < 12 || _age(_dob!) > 19) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Student must be between 12 and 19 years old.')),
      );
      return;
    }

    if (_to == null || _from == null || int.parse(_to!) <= int.parse(_from!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Academic Year To must be greater than From.')),
      );
      return;
    }

    if (_phone.text.trim() == _secondary.text.trim()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Primary and secondary contact numbers cannot be the same.')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await _api.post('/enquiries', data: {
        'studentName': _student.text.trim(),
        'classBoard': _board! + '-' + _className!,
        'schoolName': _school.text.trim(),
        'subjects': _subjects,
        'academicYearFrom': _from,
        'academicYearTo': _to,
        'batch': _batch,
        'dateOfBirth': _dob!.toIso8601String().split('T').first,
        'parentName': _parent.text.trim(),
        'mobileNumber': _phone.text.trim(),
        'secondaryContact': _secondary.text.trim(),
        'reference': _reference.text.trim(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enquiry submitted successfully.')),
      );
      _formKey.currentState!.reset();
      for (final controller in [_student, _school, _parent, _phone, _secondary, _reference]) {
        controller.clear();
      }
      setState(() {
        _className = null;
        _board = null;
        _subjects = null;
        _batch = null;
        _from = null;
        _to = null;
        _dob = null;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _text(
    TextEditingController controller,
    String label, {
    bool required = true,
    TextInputType? keyboard,
    int maxLength = 100,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboard,
        maxLength: maxLength,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          counterText: '',
        ),
        validator: validator ?? (required ? _required : null),
      ),
    );
  }

  Widget _dropdown(
    String label,
    String? value,
    List<String> values,
    ValueChanged<String?> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        value: value,
        isExpanded: true,
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
        items: values.map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
        onChanged: onChanged,
        validator: _required,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Enquiry Form'),
        foregroundColor: AppColors.primary,
        backgroundColor: AppColors.surface,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              color: AppColors.surface,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _text(_student, 'Student Name', maxLength: 50, validator: _studentNameValidator),
                    _dropdown('Class', _className, const ['10', '11', '12'], (v) => setState(() => _className = v)),
                    _dropdown('Board', _board, const ['CBSE', 'Stateboard', 'ICSE', 'Isc'], (v) => setState(() => _board = v)),
                    _text(_school, 'School Name', validator: _schoolNameValidator),
                    _dropdown('Subjects Looking for', _subjects, const ['Physics', 'Maths', 'Both'], (v) => setState(() => _subjects = v)),
                    _dropdown(
                      'Academic Year From',
                      _from,
                      List.generate(4, (i) => (DateTime.now().year + i).toString()),
                      (v) => setState(() {
                        _from = v;
                        if (_to != null && v != null && int.parse(_to!) <= int.parse(v)) _to = null;
                      }),
                    ),
                    _dropdown(
                      'Academic Year To',
                      _to,
                      List.generate(5, (i) => (DateTime.now().year + i).toString())
                          .where((year) => _from == null || int.parse(year) > int.parse(_from!))
                          .toList(),
                      (v) => setState(() => _to = v),
                    ),
                    _dropdown('Batch', _batch, const ['Test Batch', 'Regular Batch'], (v) => setState(() => _batch = v)),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: OutlinedButton.icon(
                        onPressed: _pickDob,
                        icon: const Icon(Icons.calendar_month),
                        label: Text(_dob == null ? 'Date of Birth (D/M/Y)' : 'Date of Birth: ' + _formatDob(_dob!)),
                      ),
                    ),
                    if (_dob != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          'Age: ' + _age(_dob!).toString() + ' years (allowed: 12–19)',
                          style: TextStyle(
                            color: _age(_dob!) >= 12 && _age(_dob!) <= 19 ? Colors.green : Colors.red,
                          ),
                        ),
                      ),
                    _text(_parent, 'Parent Name', validator: _parentNameValidator),
                    _text(_phone, 'Phone Number', keyboard: TextInputType.phone, maxLength: 10, validator: _phoneValidator),
                    _text(_secondary, 'Secondary Contact', keyboard: TextInputType.phone, maxLength: 10, validator: _phoneValidator),
                    _text(_reference, 'Reference', required: false),
                    FilledButton.icon(
                      onPressed: _saving ? null : _submit,
                      icon: _saving
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.send),
                      label: Text(_saving ? 'Submitting...' : 'Submit Enquiry'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
).hasMatch(v)) {
      return 'School name should contain only letters and spaces.';
    }
    return null;
  }

  String? _parentNameValidator(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty || !RegExp(r'^[A-Za-z\s]+$').hasMatch(v)) {
      return 'Parent name should contain only letters and spaces.';
    }
    return null;
  }

  String? _phoneValidator(String? value) {
    final v = (value ?? '').trim();
    if (!RegExp(r'^\d{10}$').hasMatch(v)) return 'Enter exactly 10 digits.';
    return null;
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 15, now.month, now.day),
      firstDate: DateTime(now.year - 19, now.month, now.day),
      lastDate: DateTime(now.year - 12, now.month, now.day),
    );
    if (picked != null) setState(() => _dob = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_dob == null || _age(_dob!) < 12 || _age(_dob!) > 19) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Student must be between 12 and 19 years old.')),
      );
      return;
    }

    if (_to == null || _from == null || int.parse(_to!) <= int.parse(_from!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Academic Year To must be greater than From.')),
      );
      return;
    }

    if (_phone.text.trim() == _secondary.text.trim()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Primary and secondary contact numbers cannot be the same.')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await _api.post('/enquiries', data: {
        'studentName': _student.text.trim(),
        'classBoard': _board! + '-' + _className!,
        'schoolName': _school.text.trim(),
        'subjects': _subjects,
        'academicYearFrom': _from,
        'academicYearTo': _to,
        'batch': _batch,
        'dateOfBirth': _dob!.toIso8601String().split('T').first,
        'parentName': _parent.text.trim(),
        'mobileNumber': _phone.text.trim(),
        'secondaryContact': _secondary.text.trim(),
        'reference': _reference.text.trim(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enquiry submitted successfully.')),
      );
      _formKey.currentState!.reset();
      for (final controller in [_student, _school, _parent, _phone, _secondary, _reference]) {
        controller.clear();
      }
      setState(() {
        _className = null;
        _board = null;
        _subjects = null;
        _batch = null;
        _from = null;
        _to = null;
        _dob = null;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _text(
    TextEditingController controller,
    String label, {
    bool required = true,
    TextInputType? keyboard,
    int maxLength = 100,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboard,
        maxLength: maxLength,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          counterText: '',
        ),
        validator: validator ?? (required ? _required : null),
      ),
    );
  }

  Widget _dropdown(
    String label,
    String? value,
    List<String> values,
    ValueChanged<String?> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        value: value,
        isExpanded: true,
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
        items: values.map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
        onChanged: onChanged,
        validator: _required,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Enquiry Form'),
        foregroundColor: AppColors.primary,
        backgroundColor: AppColors.surface,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              color: AppColors.surface,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _text(_student, 'Student Name', maxLength: 50, validator: _studentNameValidator),
                    _dropdown('Class', _className, const ['10', '11', '12'], (v) => setState(() => _className = v)),
                    _dropdown('Board', _board, const ['CBSE', 'Stateboard', 'ICSE', 'Isc'], (v) => setState(() => _board = v)),
                    _text(_school, 'School Name', validator: _schoolNameValidator),
                    _dropdown('Subjects Looking for', _subjects, const ['Physics', 'Maths', 'Both'], (v) => setState(() => _subjects = v)),
                    _dropdown(
                      'Academic Year From',
                      _from,
                      List.generate(4, (i) => (DateTime.now().year + i).toString()),
                      (v) => setState(() {
                        _from = v;
                        if (_to != null && v != null && int.parse(_to!) <= int.parse(v)) _to = null;
                      }),
                    ),
                    _dropdown(
                      'Academic Year To',
                      _to,
                      List.generate(5, (i) => (DateTime.now().year + i).toString())
                          .where((year) => _from == null || int.parse(year) > int.parse(_from!))
                          .toList(),
                      (v) => setState(() => _to = v),
                    ),
                    _dropdown('Batch', _batch, const ['Test Batch', 'Regular Batch'], (v) => setState(() => _batch = v)),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: OutlinedButton.icon(
                        onPressed: _pickDob,
                        icon: const Icon(Icons.calendar_month),
                        label: Text(_dob == null ? 'Date of Birth (D/M/Y)' : 'Date of Birth: ' + _formatDob(_dob!)),
                      ),
                    ),
                    if (_dob != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          'Age: ' + _age(_dob!).toString() + ' years (allowed: 12–19)',
                          style: TextStyle(
                            color: _age(_dob!) >= 12 && _age(_dob!) <= 19 ? Colors.green : Colors.red,
                          ),
                        ),
                      ),
                    _text(_parent, 'Parent Name', validator: _parentNameValidator),
                    _text(_phone, 'Phone Number', keyboard: TextInputType.phone, maxLength: 10, validator: _phoneValidator),
                    _text(_secondary, 'Secondary Contact', keyboard: TextInputType.phone, maxLength: 10, validator: _phoneValidator),
                    _text(_reference, 'Reference', required: false),
                    FilledButton.icon(
                      onPressed: _saving ? null : _submit,
                      icon: _saving
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.send),
                      label: Text(_saving ? 'Submitting...' : 'Submit Enquiry'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
).hasMatch(v)) {
      return 'School name should contain only letters and spaces.';
    }
    return null;
  }

  String? _parentNameValidator(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty || !RegExp(r'^[A-Za-z\s]+$').hasMatch(v)) {
      return 'Parent name should contain only letters and spaces.';
    }
    return null;
  }

  String? _phoneValidator(String? value) {
    final v = (value ?? '').trim();
    if (!RegExp(r'^\d{10}$').hasMatch(v)) return 'Enter exactly 10 digits.';
    return null;
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 15, now.month, now.day),
      firstDate: DateTime(now.year - 19, now.month, now.day),
      lastDate: DateTime(now.year - 12, now.month, now.day),
    );
    if (picked != null) setState(() => _dob = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_dob == null || _age(_dob!) < 12 || _age(_dob!) > 19) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Student must be between 12 and 19 years old.')),
      );
      return;
    }

    if (_to == null || _from == null || int.parse(_to!) <= int.parse(_from!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Academic Year To must be greater than From.')),
      );
      return;
    }

    if (_phone.text.trim() == _secondary.text.trim()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Primary and secondary contact numbers cannot be the same.')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await _api.post('/enquiries', data: {
        'studentName': _student.text.trim(),
        'classBoard': _board! + '-' + _className!,
        'schoolName': _school.text.trim(),
        'subjects': _subjects,
        'academicYearFrom': _from,
        'academicYearTo': _to,
        'batch': _batch,
        'dateOfBirth': _dob!.toIso8601String().split('T').first,
        'parentName': _parent.text.trim(),
        'mobileNumber': _phone.text.trim(),
        'secondaryContact': _secondary.text.trim(),
        'reference': _reference.text.trim(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enquiry submitted successfully.')),
      );
      _formKey.currentState!.reset();
      for (final controller in [_student, _school, _parent, _phone, _secondary, _reference]) {
        controller.clear();
      }
      setState(() {
        _className = null;
        _board = null;
        _subjects = null;
        _batch = null;
        _from = null;
        _to = null;
        _dob = null;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _text(
    TextEditingController controller,
    String label, {
    bool required = true,
    TextInputType? keyboard,
    int maxLength = 100,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboard,
        maxLength: maxLength,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          counterText: '',
        ),
        validator: validator ?? (required ? _required : null),
      ),
    );
  }

  Widget _dropdown(
    String label,
    String? value,
    List<String> values,
    ValueChanged<String?> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        value: value,
        isExpanded: true,
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
        items: values.map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
        onChanged: onChanged,
        validator: _required,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Enquiry Form'),
        foregroundColor: AppColors.primary,
        backgroundColor: AppColors.surface,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              color: AppColors.surface,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _text(_student, 'Student Name', maxLength: 50, validator: _studentNameValidator),
                    _dropdown('Class', _className, const ['10', '11', '12'], (v) => setState(() => _className = v)),
                    _dropdown('Board', _board, const ['CBSE', 'Stateboard', 'ICSE', 'Isc'], (v) => setState(() => _board = v)),
                    _text(_school, 'School Name', validator: _schoolNameValidator),
                    _dropdown('Subjects Looking for', _subjects, const ['Physics', 'Maths', 'Both'], (v) => setState(() => _subjects = v)),
                    _dropdown(
                      'Academic Year From',
                      _from,
                      List.generate(4, (i) => (DateTime.now().year + i).toString()),
                      (v) => setState(() {
                        _from = v;
                        if (_to != null && v != null && int.parse(_to!) <= int.parse(v)) _to = null;
                      }),
                    ),
                    _dropdown(
                      'Academic Year To',
                      _to,
                      List.generate(5, (i) => (DateTime.now().year + i).toString())
                          .where((year) => _from == null || int.parse(year) > int.parse(_from!))
                          .toList(),
                      (v) => setState(() => _to = v),
                    ),
                    _dropdown('Batch', _batch, const ['Test Batch', 'Regular Batch'], (v) => setState(() => _batch = v)),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: OutlinedButton.icon(
                        onPressed: _pickDob,
                        icon: const Icon(Icons.calendar_month),
                        label: Text(_dob == null ? 'Date of Birth (D/M/Y)' : 'Date of Birth: ' + _formatDob(_dob!)),
                      ),
                    ),
                    if (_dob != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          'Age: ' + _age(_dob!).toString() + ' years (allowed: 12–19)',
                          style: TextStyle(
                            color: _age(_dob!) >= 12 && _age(_dob!) <= 19 ? Colors.green : Colors.red,
                          ),
                        ),
                      ),
                    _text(_parent, 'Parent Name', validator: _parentNameValidator),
                    _text(_phone, 'Phone Number', keyboard: TextInputType.phone, maxLength: 10, validator: _phoneValidator),
                    _text(_secondary, 'Secondary Contact', keyboard: TextInputType.phone, maxLength: 10, validator: _phoneValidator),
                    _text(_reference, 'Reference', required: false),
                    FilledButton.icon(
                      onPressed: _saving ? null : _submit,
                      icon: _saving
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.send),
                      label: Text(_saving ? 'Submitting...' : 'Submit Enquiry'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
