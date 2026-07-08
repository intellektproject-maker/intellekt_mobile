import 'package:flutter/material.dart';

import '../../../../models/faculty_model.dart';

class TaskAssignmentForm extends StatefulWidget {
  final List<FacultyModel> facultyList;
  final List<String> classOptions;
  final List<String> testCodes;
  final bool isLoading;

  final Future<void> Function({
  required String facultyId,
  required String facultyName,
  required String className,
  required String subjectName,
  required String totalTestNote,
  required String otherTasks,
  required String? dueDate,
  required String priority,
  required String taskType,
  }) onAssignTask;

  const TaskAssignmentForm({
    super.key,
    required this.facultyList,
    required this.classOptions,
    required this.testCodes,
    required this.isLoading,
    required this.onAssignTask,
  });

  @override
  State<TaskAssignmentForm> createState() =>
      _TaskAssignmentFormState();
}

class _TaskAssignmentFormState
    extends State<TaskAssignmentForm> {
  String? selectedFacultyId;
  String selectedFacultyName = '';
  String? selectedClass;
  String taskType = 'Weekly';
  String? selectedTestCode;
  String priority = 'Medium';
  DateTime? dueDate;

  final TextEditingController totalTestNoteController =
  TextEditingController();

  final TextEditingController otherTasksController =
  TextEditingController();

  @override
  void dispose() {
    totalTestNoteController.dispose();
    otherTasksController.dispose();
    super.dispose();
  }

  Future<void> _selectDueDate() async {
    final today = DateTime.now();

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: dueDate ?? today,
      firstDate: DateTime(
        today.year,
        today.month,
        today.day,
      ),
      lastDate: DateTime(today.year + 5),
    );

    if (selectedDate != null) {
      setState(() {
        dueDate = selectedDate;
      });
    }
  }

  Future<void> _submitForm() async {
    if (selectedFacultyId == null ||
        selectedFacultyName.isEmpty ||
        selectedClass == null) {
      _showMessage(
        'Please fill Faculty Name and Class',
      );
      return;
    }

    if ((selectedTestCode == null ||
        selectedTestCode!.isEmpty) &&
        otherTasksController.text.trim().isEmpty) {
      _showMessage(
        'Please select Test Code or enter Other Tasks',
      );
      return;
    }

    if (taskType == 'Weekly' && dueDate == null) {
      _showMessage(
        'Please select Due Date for Weekly Task',
      );
      return;
    }

    await widget.onAssignTask(
      facultyId: selectedFacultyId!,
      facultyName: selectedFacultyName,
      className: selectedClass!,
      subjectName: selectedTestCode ?? '',
      totalTestNote:
      totalTestNoteController.text.trim(),
      otherTasks: otherTasksController.text.trim(),
      dueDate:
      taskType == 'Daily' ? null : _formatDate(dueDate),
      priority: taskType == 'Daily' ? 'High' : priority,
      taskType: taskType,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      selectedClass = null;
      taskType = 'Weekly';
      selectedTestCode = null;
      priority = 'Medium';
      dueDate = null;
      totalTestNoteController.clear();
      otherTasksController.clear();
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  String? _formatDate(DateTime? date) {
    if (date == null) {
      return null;
    }

    final year = date.year.toString();

    final month =
    date.month.toString().padLeft(2, '0');

    final day =
    date.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Task Assignment',
            style: TextStyle(
              color: Color(0xFF1D4ED8),
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 20),

          _buildLabel('1. Faculty Name'),

          DropdownButtonFormField<String>(
            initialValue: selectedFacultyId,
            decoration: _inputDecoration(),
            hint: const Text('Select Faculty'),
            isExpanded: true,
            items: widget.facultyList.map((faculty) {
              return DropdownMenuItem<String>(
                value: faculty.facultyId,
                child: Text(
                  '${faculty.name} (${faculty.facultyId})',
                ),
              );
            }).toList(),
            onChanged: (value) {
              if (value == null) {
                return;
              }

              final faculty = widget.facultyList.firstWhere(
                    (item) => item.facultyId == value,
              );

              setState(() {
                selectedFacultyId = value;
                selectedFacultyName = faculty.name;
              });
            },
          ),

          const SizedBox(height: 16),

          _buildLabel('2. Class'),

          DropdownButtonFormField<String>(
            initialValue: selectedClass,
            decoration: _inputDecoration(),
            hint: const Text('Select Class'),
            isExpanded: true,
            items: widget.classOptions.map((className) {
              return DropdownMenuItem<String>(
                value: className,
                child: Text(className),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                selectedClass = value;
              });
            },
          ),

          const SizedBox(height: 16),

          _buildLabel('3. Task Type'),

          DropdownButtonFormField<String>(
            initialValue: taskType,
            decoration: _inputDecoration(),
            items: const [
              DropdownMenuItem(
                value: 'Weekly',
                child: Text('Weekly Task'),
              ),
              DropdownMenuItem(
                value: 'Daily',
                child: Text('Daily Task'),
              ),
            ],
            onChanged: (value) {
              if (value == null) {
                return;
              }

              setState(() {
                taskType = value;

                if (taskType == 'Daily') {
                  dueDate = null;
                  priority = 'High';
                } else {
                  priority = 'Medium';
                }
              });
            },
          ),

          const SizedBox(height: 16),

          _buildLabel('4. Test Code'),

          DropdownButtonFormField<String>(
            initialValue: selectedTestCode,
            decoration: _inputDecoration(),
            hint: const Text('Select Test Code'),
            isExpanded: true,
            items: widget.testCodes.map((testCode) {
              return DropdownMenuItem<String>(
                value: testCode,
                child: Text(testCode),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                selectedTestCode = value;
              });
            },
          ),

          const SizedBox(height: 16),

          _buildLabel('5. Total Test Note'),

          TextFormField(
            controller: totalTestNoteController,
            decoration: _inputDecoration(
              hintText: 'Enter total test note',
            ),
          ),

          if (taskType == 'Weekly') ...[
            const SizedBox(height: 16),

            _buildLabel('Due Date'),

            InkWell(
              onTap: _selectDueDate,
              borderRadius: BorderRadius.circular(8),
              child: InputDecorator(
                decoration: _inputDecoration(),
                child: Row(
                  mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      dueDate == null
                          ? 'Select Due Date'
                          : _formatDate(dueDate)!,
                    ),
                    const Icon(
                      Icons.calendar_today_outlined,
                    ),
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: 16),

          _buildLabel('Priority'),

          DropdownButtonFormField<String>(
            initialValue: priority,
            decoration: _inputDecoration(),
            items: const [
              DropdownMenuItem(
                value: 'High',
                child: Text('High'),
              ),
              DropdownMenuItem(
                value: 'Medium',
                child: Text('Medium'),
              ),
              DropdownMenuItem(
                value: 'Low',
                child: Text('Low'),
              ),
            ],
            onChanged: taskType == 'Daily'
                ? null
                : (value) {
              if (value == null) {
                return;
              }

              setState(() {
                priority = value;
              });
            },
          ),

          const SizedBox(height: 16),

          _buildLabel('Other Tasks'),

          TextFormField(
            controller: otherTasksController,
            maxLines: 4,
            decoration: _inputDecoration(
              hintText: 'Enter other tasks',
            ),
          ),

          const SizedBox(height: 24),

          ElevatedButton(
            onPressed:
            widget.isLoading ? null : _submitForm,
            style: ElevatedButton.styleFrom(
              backgroundColor:
              const Color(0xFF1D4ED8),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 14,
              ),
              shape: RoundedRectangleBorder(
                borderRadius:
                BorderRadius.circular(8),
              ),
            ),
            child: Text(
              widget.isLoading
                  ? 'Assigning...'
                  : 'Assign Task',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF374151),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    String? hintText,
  }) {
    return InputDecoration(
      hintText: hintText,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(
          color: Color(0xFFD1D5DB),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(
          color: Color(0xFF3B82F6)
        ),
      ),
    );
  }
}