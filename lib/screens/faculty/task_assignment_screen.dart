import 'package:flutter/material.dart';

import '../../core/constants/colors.dart';
import '../../models/faculty_model.dart';
import '../../repositories/faculty_task_repository.dart';

class TaskAssignmentScreen extends StatefulWidget {
  final String loginFacultyId;

  const TaskAssignmentScreen({
    super.key,
    required this.loginFacultyId,
  });

  @override
  State<TaskAssignmentScreen> createState() => _TaskAssignmentScreenState();
}

class _TaskAssignmentScreenState extends State<TaskAssignmentScreen> {
  final FacultyTaskRepository _repository = FacultyTaskRepository();

  List<FacultyModel> _facultyList = <FacultyModel>[];
  List<String> _classOptions = <String>[];
  List<String> _testCodes = <String>[];

  String? _facultyId;
  String? _className;
  String? _testCode;
  String _taskType = 'Weekly';
  String _priority = 'Medium';
  DateTime? _dueDate;

  final TextEditingController _totalNoteController = TextEditingController();
  final TextEditingController _otherTasksController = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadOptions();
  }

  @override
  void dispose() {
    _totalNoteController.dispose();
    _otherTasksController.dispose();
    super.dispose();
  }

  Future<void> _loadOptions() async {
    try {
      final facultyFuture = _repository.getFacultyList();
      final classFuture = _repository.getClassOptions();
      final testFuture = _repository.getTestCodes();

      // Keep each request independent so one failed endpoint cannot erase
      // the other valid dropdown data.
      final faculty = await facultyFuture;
      if (!mounted) return;
      setState(() => _facultyList = faculty);

      final classes = await classFuture;
      if (!mounted) return;
      setState(() => _classOptions = classes);

      final tests = await testFuture;
      if (!mounted) return;
      setState(() => _testCodes = tests);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _formatDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  Future<void> _pickDueDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final picked = await showDatePicker(
      context: context,
      firstDate: today,
      lastDate: DateTime(now.year + 5),
      initialDate: _dueDate ?? today,
    );

    if (picked != null && mounted) {
      setState(() => _dueDate = picked);
    }
  }

  Future<void> _assign() async {
    if (_facultyId == null || _facultyId!.isEmpty) {
      _showMessage('Please select Faculty Name');
      return;
    }

    if (_className == null || _className!.isEmpty) {
      _showMessage('Please select Class');
      return;
    }

    if ((_testCode == null || _testCode!.isEmpty) &&
        _otherTasksController.text.trim().isEmpty) {
      _showMessage('Select Test Code or enter Other Tasks');
      return;
    }

    if (_taskType == 'Weekly' && _dueDate == null) {
      _showMessage('Please select Due Date');
      return;
    }

    final selectedFaculty = _facultyList.firstWhere(
      (faculty) => faculty.facultyId == _facultyId,
      orElse: () => const FacultyModel(
        facultyId: '',
        name: '',
        email: '',
        phone: '',
      ),
    );

    if (selectedFaculty.facultyId.isEmpty) {
      _showMessage('Selected faculty is no longer available.');
      return;
    }

    setState(() => _saving = true);

    try {
      await _repository.assignTask(
        loginFacultyId: widget.loginFacultyId.trim().toUpperCase(),
        facultyId: selectedFaculty.facultyId,
        facultyName: selectedFaculty.name,
        className: _className!,
        subjectName: _testCode ?? '',
        totalTestNote: _totalNoteController.text.trim(),
        otherTasks: _otherTasksController.text.trim(),
        dueDate: _taskType == 'Daily' ? null : _formatDate(_dueDate!),
        priority: _taskType == 'Daily' ? 'High' : _priority,
        taskType: _taskType,
      );

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      _showMessage(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.primary,
        elevation: 0,
        title: const Text(
          'Task Assignment',
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              )
            : _buildForm(),
      ),
    );
  }

  Widget _buildForm() {
    final matchingFaculty = _facultyList.where(
      (faculty) => faculty.facultyId == _facultyId,
    );
    final selectedFaculty = matchingFaculty.isEmpty
        ? null
        : matchingFaculty.first;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 36),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Assign a new task',
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Select the faculty member and task details below.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 22),
          if (_loadError != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Text(_loadError!),
            ),
            const SizedBox(height: 16),
          ],
          _dropdown<FacultyModel>(
            label: 'Faculty Name',
            value: selectedFaculty,
            items: _facultyList,
            display: (faculty) => '${faculty.name} (${faculty.facultyId})',
            onChanged: (faculty) => setState(
              () => _facultyId = faculty?.facultyId,
            ),
          ),
          _dropdown<String>(
            label: 'Class',
            value: _className,
            items: _classOptions,
            onChanged: (value) => setState(() => _className = value),
          ),
          _dropdown<String>(
            label: 'Task Type',
            value: _taskType,
            items: const ['Weekly', 'Daily'],
            onChanged: (value) => setState(() {
              _taskType = value ?? 'Weekly';
              if (_taskType == 'Daily') {
                _priority = 'High';
                _dueDate = null;
              }
            }),
          ),
          _dropdown<String>(
            label: 'Test Code',
            value: _testCode,
            items: _testCodes,
            onChanged: (value) => setState(() => _testCode = value),
          ),
          _textField(
            controller: _totalNoteController,
            label: 'Total Test Note',
          ),
          const SizedBox(height: 14),
          if (_taskType == 'Weekly') ...[
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: _pickDueDate,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Due Date',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_today_outlined),
                ),
                child: Text(
                  _dueDate == null ? 'Select due date' : _formatDate(_dueDate!),
                ),
              ),
            ),
            const SizedBox(height: 14),
            _dropdown<String>(
              label: 'Priority',
              value: _priority,
              items: const ['High', 'Medium', 'Low'],
              onChanged: (value) => setState(
                () => _priority = value ?? 'Medium',
              ),
            ),
          ],
          _textField(
            controller: _otherTasksController,
            label: 'Other Tasks',
            maxLines: 5,
          ),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              onPressed: _saving ? null : _assign,
              child: _saving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Assign Task',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String label,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }

  Widget _dropdown<T>({
    required String label,
    required T? value,
    required List<T> items,
    required ValueChanged<T?> onChanged,
    String Function(T)? display,
  }) {
    final safeValue = items.contains(value) ? value : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: DropdownButtonFormField<T>(
        initialValue: safeValue,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        items: items
            .map(
              (item) => DropdownMenuItem<T>(
                value: item,
                child: Text(
                  display?.call(item) ?? item.toString(),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            )
            .toList(),
        onChanged: onChanged,
      ),
    );
  }
}
