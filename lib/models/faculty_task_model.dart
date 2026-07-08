class FacultyTaskModel {
  final int id;
  final String facultyId;
  final String facultyName;
  final String className;
  final String subjectName;
  final String totalTestNote;
  final String otherTasks;
  final String? dueDate;
  final String priority;
  final String taskType;
  final bool isCompleted;
  final String assignedBy;
  final String? completedAt;

  const FacultyTaskModel({
    required this.id,
    required this.facultyId,
    required this.facultyName,
    required this.className,
    required this.subjectName,
    required this.totalTestNote,
    required this.otherTasks,
    required this.dueDate,
    required this.priority,
    required this.taskType,
    required this.isCompleted,
    required this.assignedBy,
    required this.completedAt,
  });

  factory FacultyTaskModel.fromJson(Map<String, dynamic> json) {
    return FacultyTaskModel(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      facultyId: json['faculty_id']?.toString() ?? '',
      facultyName: json['faculty_name']?.toString() ?? '',
      className: json['class_name']?.toString() ?? '',
      subjectName: json['subject_name']?.toString() ?? '',
      totalTestNote: json['total_test_note']?.toString() ?? '',
      otherTasks: json['other_tasks']?.toString() ?? '',
      dueDate: json['due_date']?.toString(),
      priority: json['priority']?.toString() ?? 'Medium',
      taskType: json['task_type']?.toString() ?? 'Weekly',
      isCompleted: json['is_completed'] == true,
      assignedBy: json['assigned_by']?.toString() ?? '',
      completedAt: json['completed_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'faculty_id': facultyId,
      'faculty_name': facultyName,
      'class_name': className,
      'subject_name': subjectName,
      'total_test_note': totalTestNote,
      'other_tasks': otherTasks,
      'due_date': dueDate,
      'priority': priority,
      'task_type': taskType,
      'is_completed': isCompleted,
      'assigned_by': assignedBy,
      'completed_at': completedAt,
    };
  }

  bool get isOverdue {
    if (dueDate == null || dueDate!.isEmpty || isCompleted) {
      return false;
    }

    final due = DateTime.tryParse(dueDate!);

    if (due == null) {
      return false;
    }

    final now = DateTime.now();

    final today = DateTime(
      now.year,
      now.month,
      now.day,
    );

    final dueDay = DateTime(
      due.year,
      due.month,
      due.day,
    );

    return dueDay.isBefore(today);
  }

  bool get isDueToday {
    if (dueDate == null || dueDate!.isEmpty || isCompleted) {
      return false;
    }

    final due = DateTime.tryParse(dueDate!);

    if (due == null) {
      return false;
    }

    final now = DateTime.now();

    return now.year == due.year &&
        now.month == due.month &&
        now.day == due.day;
  }

  // ==========================================================
  // DUMMY TASK DATA FOR UI DEVELOPMENT
  // ==========================================================

  static List<FacultyTaskModel> get dummyTasks {
    final now = DateTime.now();

    final yesterday = now.subtract(
      const Duration(days: 1),
    );

    final tomorrow = now.add(
      const Duration(days: 1),
    );

    final nextWeek = now.add(
      const Duration(days: 7),
    );

    return [
      FacultyTaskModel(
        id: 1,
        facultyId: 'IG001',
        facultyName: 'Admin User',
        className: 'Class 10',
        subjectName: 'MAT101',
        totalTestNote: 'Prepare weekly mathematics test',
        otherTasks: 'Upload marks after correction',
        dueDate: _formatDate(tomorrow),
        priority: 'High',
        taskType: 'Weekly',
        isCompleted: false,
        assignedBy: 'IG001',
        completedAt: null,
      ),

      FacultyTaskModel(
        id: 2,
        facultyId: 'IG001',
        facultyName: 'Admin User',
        className: 'Class 12',
        subjectName: 'PHY201',
        totalTestNote: 'Complete physics test correction',
        otherTasks: '',
        dueDate: _formatDate(yesterday),
        priority: 'High',
        taskType: 'Weekly',
        isCompleted: false,
        assignedBy: 'IG002',
        completedAt: null,
      ),

      FacultyTaskModel(
        id: 3,
        facultyId: 'IG001',
        facultyName: 'Admin User',
        className: 'Class 11',
        subjectName: 'CHE105',
        totalTestNote: 'Update chemistry marks',
        otherTasks: 'Verify absent students',
        dueDate: _formatDate(now),
        priority: 'Medium',
        taskType: 'Weekly',
        isCompleted: false,
        assignedBy: 'IG002',
        completedAt: null,
      ),

      FacultyTaskModel(
        id: 4,
        facultyId: 'IG001',
        facultyName: 'Admin User',
        className: 'Class 9',
        subjectName: 'ENG110',
        totalTestNote: 'Prepare English worksheet',
        otherTasks: '',
        dueDate: _formatDate(nextWeek),
        priority: 'Low',
        taskType: 'Weekly',
        isCompleted: true,
        assignedBy: 'IG001',
        completedAt: _formatDate(now),
      ),

      FacultyTaskModel(
        id: 5,
        facultyId: 'IG001',
        facultyName: 'Admin User',
        className: 'Class 10',
        subjectName: '',
        totalTestNote: '',
        otherTasks: 'Check student attendance records',
        dueDate: null,
        priority: 'High',
        taskType: 'Daily',
        isCompleted: false,
        assignedBy: 'IG001',
        completedAt: null,
      ),

      FacultyTaskModel(
        id: 6,
        facultyId: 'IG001',
        facultyName: 'Admin User',
        className: 'Class 12',
        subjectName: '',
        totalTestNote: '',
        otherTasks: 'Contact parents regarding absentees',
        dueDate: null,
        priority: 'High',
        taskType: 'Daily',
        isCompleted: true,
        assignedBy: 'IG002',
        completedAt: _formatDate(now),
      ),
    ];
  }

  static String _formatDate(DateTime date) {
    final year = date.year.toString();

    final month = date.month
        .toString()
        .padLeft(2, '0');

    final day = date.day
        .toString()
        .padLeft(2, '0');

    return '$year-$month-$day';
  }
}