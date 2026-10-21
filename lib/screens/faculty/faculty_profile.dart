import 'package:flutter/material.dart';

import '../../core/constants/colors.dart';
import '../../models/faculty_model.dart';
import '../../models/faculty_task_model.dart';
import '../../repositories/faculty_repository.dart';
import '../../repositories/faculty_task_repository.dart';
import 'task_assignment_screen.dart';
import 'test_batch_student_status_screen.dart';

class FacultyProfile extends StatefulWidget {
  final String facultyId;

  const FacultyProfile({super.key, required this.facultyId});

  @override
  State<FacultyProfile> createState() => _FacultyProfileState();
}

class _FacultyProfileState extends State<FacultyProfile> {
  final FacultyRepository _facultyRepository = FacultyRepository();
  final FacultyTaskRepository _taskRepository = FacultyTaskRepository();

  FacultyModel? _faculty;
  List<FacultyTaskModel> _myTasks = <FacultyTaskModel>[];
  List<FacultyTaskModel> _allTasks = <FacultyTaskModel>[];
  List<FacultyTaskModel> _dailyTasks = <FacultyTaskModel>[];
  List<FacultyModel> _facultyList = <FacultyModel>[];
  Set<String> _notifications = <String>{};

  String? _error;
  bool _loading = true;
  bool _tasksLoading = false;
  bool _allLoading = false;
  bool _dailyLoading = false;

  String _activeSection = '';
  String _myFilter = 'All';
  String _allFilter = 'All';
  String _dailyFilter = 'All';

  String get _id => widget.facultyId.trim().toUpperCase();

  bool get _isAdmin => _id == 'IG001' || _id == 'IG002';

  @override
  void initState() {
    super.initState();
    _loadEverything();
  }

  Future<void> _loadEverything() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final faculty = await _facultyRepository.getFacultyProfile(_id);

      List<FacultyTaskModel> myTasks = <FacultyTaskModel>[];
      try {
        myTasks = await _taskRepository.getMyTasks(_id);
      } catch (e) {
        debugPrint('Optional faculty task load failed: $e');
      }

      Set<String> notifications = <String>{};
      try {
        final notificationList =
            await _taskRepository.getFacultyNotifications(_id);
        notifications = notificationList
            .map((item) => item['module_name']?.toString() ?? '')
            .where((item) => item.isNotEmpty)
            .toSet();
      } catch (e) {
        debugPrint('Optional faculty notification load failed: $e');
      }

      if (!mounted) return;

      if (!_isAdmin) {
        try {
          _facultyList = await _taskRepository.getFacultyList();
        } catch (e) {
          debugPrint('Faculty directory load failed: $e');
        }
      }

      if (!mounted) return;

      setState(() {
        _faculty = faculty;
        _myTasks = myTasks;
        _notifications = notifications;
        _loading = false;
      });

      if (_isAdmin) {
        await _loadAdminData();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _loadAdminData() async {
    try {
      List<FacultyTaskModel> allTasks = <FacultyTaskModel>[];
      List<FacultyTaskModel> dailyTasks = <FacultyTaskModel>[];
      List<FacultyModel> facultyList = <FacultyModel>[];

      try {
        allTasks = await _taskRepository.getAllTasks(_id);
      } catch (e) {
        debugPrint('All faculty tasks load failed: $e');
      }

      try {
        dailyTasks = await _taskRepository.getDailyTasks(_id);
      } catch (e) {
        debugPrint('Daily faculty tasks load failed: $e');
      }

      try {
        facultyList = await _taskRepository.getFacultyList();
      } catch (e) {
        debugPrint('Faculty list load failed: $e');
      }

      if (!mounted) return;

      setState(() {
        _allTasks = allTasks;
        _dailyTasks = dailyTasks;
        _facultyList = facultyList;
      });
    } catch (e) {
      debugPrint('Optional admin task data failed: $e');
    }
  }

  Future<void> _refreshMyTasks() async {
    try {
      final tasks = await _taskRepository.getMyTasks(_id);
      if (mounted) setState(() => _myTasks = tasks);
    } catch (e) {
      _showMessage(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _refreshAdminTasks() async {
    if (!_isAdmin) return;

    try {
      final allTasks = await _taskRepository.getAllTasks(_id);
      if (mounted) setState(() => _allTasks = allTasks);
    } catch (e) {
      _showMessage(e.toString().replaceFirst('Exception: ', ''));
    }

    try {
      final dailyTasks = await _taskRepository.getDailyTasks(_id);
      if (mounted) setState(() => _dailyTasks = dailyTasks);
    } catch (e) {
      _showMessage(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _markNotification(String module) async {
    if (!_notifications.contains(module)) return;

    if (mounted) {
      setState(() => _notifications.remove(module));
    }

    await _taskRepository.markNotificationRead(
      facultyId: _id,
      moduleName: module,
    );
  }

  List<FacultyTaskModel> _filtered(
    List<FacultyTaskModel> source,
    String filter,
  ) {
    switch (filter) {
      case 'Pending':
        return source.where((task) => !task.isCompleted).toList();
      case 'Completed':
        return source.where((task) => task.isCompleted).toList();
      case 'Overdue':
        return source.where((task) => task.isOverdue).toList();
      case 'Due Today':
        return source.where((task) => task.isDueToday).toList();
      default:
        return source;
    }
  }

  Future<void> _toggleTask(FacultyTaskModel task) async {
    try {
      await _taskRepository.updateTaskStatus(task.id, !task.isCompleted);
      await _refreshMyTasks();
      if (_isAdmin) await _refreshAdminTasks();
    } catch (e) {
      _showMessage(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _deleteTask(FacultyTaskModel task) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Task'),
          content: const Text('Are you sure you want to delete this task?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await _taskRepository.deleteTask(task.id, _id);
      await _refreshMyTasks();
      await _refreshAdminTasks();
    } catch (e) {
      _showMessage(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _reassignTask(FacultyTaskModel task) async {
    if (_facultyList.isEmpty) {
      _showMessage('Faculty list is unavailable.');
      return;
    }

    final selected = await showDialog<FacultyModel>(
      context: context,
      builder: (dialogContext) {
        return SimpleDialog(
          title: const Text('Reassign Task'),
          children: _facultyList.map((faculty) {
            return SimpleDialogOption(
              onPressed: () => Navigator.pop(dialogContext, faculty),
              child: Text('${faculty.name} (${faculty.facultyId})'),
            );
          }).toList(),
        );
      },
    );

    if (selected == null ||
        selected.facultyId.toUpperCase() == task.facultyId.toUpperCase()) {
      return;
    }

    try {
      await _taskRepository.reassignTask(
        taskId: task.id,
        facultyId: selected.facultyId,
        facultyName: selected.name,
      );
      await _refreshAdminTasks();
      await _refreshMyTasks();
    } catch (e) {
      _showMessage(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _showAssignmentForm() async {
    final assigned = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => TaskAssignmentScreen(loginFacultyId: _id),
      ),
    );

    if (assigned == true && mounted) {
      _showMessage('Task assigned successfully');
      await _refreshAdminTasks();
      await _refreshMyTasks();
    }
  }



class _TaskPanel extends StatelessWidget {
  final String title;
  final List<FacultyModel> facultyList;
  final bool loading;
  final List<FacultyTaskModel> tasks;
  final String filter;
  final ValueChanged<String> onFilter;
  final List<FacultyTaskModel> stats;
  final bool showCheckbox;
  final bool canManage;
  final Future<void> Function(FacultyTaskModel) onToggle;
  final Future<void> Function(FacultyTaskModel) onDelete;
  final Future<void> Function(FacultyTaskModel) onReassign;

  const _TaskPanel({
    required this.title,
    required this.facultyList,
    required this.loading,
    required this.tasks,
    required this.filter,
    required this.onFilter,
    required this.stats,
    required this.showCheckbox,
    required this.canManage,
    required this.onToggle,
    required this.onDelete,
    required this.onReassign,
  });

  int _count(String type) {
    if (type == 'pending') {
      return stats.where((task) => !task.isCompleted).length;
    }
    if (type == 'completed') {
      return stats.where((task) => task.isCompleted).length;
    }
    if (type == 'overdue') {
      return stats.where((task) => task.isOverdue).length;
    }
    return stats.where((task) => task.isDueToday).length;
  }

  String _assignedByDisplay(FacultyTaskModel task) {
    final assignedById = task.assignedBy.trim().toUpperCase();

    for (final faculty in facultyList) {
      if (faculty.facultyId.trim().toUpperCase() == assignedById &&
          faculty.name.trim().isNotEmpty) {
        return '${faculty.name} (${faculty.facultyId})';
      }
    }

    return task.assignedBy;
  }

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: title,
      children: [
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.8,
          children: [
            _StatBox(
              label: 'Pending',
              value: _count('pending'),
              type: 'pending',
            ),
            _StatBox(
              label: 'Completed',
              value: _count('completed'),
              type: 'completed',
            ),
            _StatBox(
              label: 'Overdue',
              value: _count('overdue'),
              type: 'overdue',
            ),
            _StatBox(
              label: 'Due Today',
              value: _count('today'),
              type: 'today',
            ),
          ],
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          initialValue: filter,
          decoration: const InputDecoration(
            labelText: 'Filter Tasks',
            border: OutlineInputBorder(),
          ),
          items: const [
            'All',
            'Pending',
            'Completed',
            'Overdue',
            'Due Today',
          ]
              .map(
                (value) => DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value != null) onFilter(value);
          },
        ),
        const SizedBox(height: 16),
        if (loading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          )
        else if (tasks.isEmpty)
          const Padding(
            padding: EdgeInsets.all(12),
            child: Text('No tasks assigned for this filter.'),
          )
        else
          ...tasks.map(
            (task) => _TaskCard(
              task: task,
              showCheckbox: showCheckbox,
              canManage: canManage,
              onToggle: () => onToggle(task),
              onDelete: () => onDelete(task),
              onReassign: () => onReassign(task),
              assignedByDisplay: _assignedByDisplay(task),
            ),
          ),
      ],
    );
  }
}

class _TaskCard extends StatelessWidget {
  final FacultyTaskModel task;
  final String assignedByDisplay;
  final bool showCheckbox;
  final bool canManage;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final VoidCallback onReassign;

  const _TaskCard({
    required this.task,
    required this.assignedByDisplay,
    required this.showCheckbox,
    required this.canManage,
    required this.onToggle,
    required this.onDelete,
    required this.onReassign,
  });

  @override
  Widget build(BuildContext context) {
    Color border = AppColors.border;
    Color background = AppColors.surface;

    if (task.taskType == 'Daily' || task.isOverdue) {
      border = Colors.red.shade200;
      background = Colors.red.shade50;
    } else if (task.isDueToday) {
      border = Colors.amber.shade200;
      background = Colors.amber.shade50;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showCheckbox)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Checkbox(
                value: task.isCompleted,
                onChanged: (_) => onToggle(),
              ),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${task.facultyName} (${task.facultyId})',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 7),
                _TaskLine('Class', task.className),
                _TaskLine('Task Frequency', task.taskType),
                _TaskLine('Priority', task.priority),
                _TaskLine(
                  'Test Code',
                  task.subjectName.isEmpty ? '-' : task.subjectName,
                ),
                _TaskLine(
                  'Total Test Note',
                  task.totalTestNote.isEmpty ? '-' : task.totalTestNote,
                ),
                _TaskLine('Due Date', task.dueDate ?? '-'),
                _TaskLine(
                  'Other Tasks',
                  task.otherTasks.isEmpty ? '-' : task.otherTasks,
                ),
                if (task.isCompleted) ...[
                  const SizedBox(height: 5),
                  Text(
                    'Completed${task.completedAt == null ? '' : ' on ${task.completedAt}'}',
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
                if (task.assignedBy.isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Text(
                    'Assigned by: $assignedByDisplay',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ],
                if (canManage) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OutlinedButton(
                        onPressed: onReassign,
                        child: const Text('Reassign'),
                      ),
                      OutlinedButton(
                        onPressed: onDelete,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskLine extends StatelessWidget {
  final String label;
  final String value;

  const _TaskLine(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}

class _TaskBox extends StatelessWidget {
  final String title;
  final String description;
  final bool notification;
  final bool active;
  final VoidCallback onTap;

  const _TaskBox({
    required this.title,
    required this.description,
    required this.onTap,
    this.notification = false,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: active ? AppColors.primary.withValues(alpha: 0.06) : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: active ? AppColors.primary : AppColors.border,
          ),
          boxShadow: const [
            BoxShadow(
              blurRadius: 8,
              offset: Offset(0, 3),
              color: Color(0x14000000),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      if (notification)
                        Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Icon(
              active ? Icons.keyboard_arrow_up : Icons.arrow_forward_ios,
              size: 18,
              color: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final int value;
  final String type;

  const _StatBox({
    required this.label,
    required this.value,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    final Color border;
    final Color background;
    final Color text;

    switch (type) {
      case 'completed':
        border = Colors.green.shade200;
        background = Colors.green.shade50;
        text = Colors.green.shade800;
        break;
      case 'overdue':
        border = Colors.red.shade200;
        background = Colors.red.shade50;
        text = Colors.red.shade800;
        break;
      case 'today':
        border = Colors.amber.shade200;
        background = Colors.amber.shade50;
        text = Colors.amber.shade900;
        break;
      default:
        border = Colors.blue.shade200;
        background = Colors.blue.shade50;
        text = AppColors.primary;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              color: text,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            '$value',
            style: TextStyle(
              color: text,
              fontSize: 25,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _AssignmentCard extends StatelessWidget {
  final VoidCallback onAssign;

  const _AssignmentCard({required this.onAssign});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Task Assignment',
      children: [
        const Text(
          'Create and assign weekly or daily tasks to faculty members.',
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: onAssign,
            icon: const Icon(Icons.add_task_outlined),
            label: const Text('Assign Task'),
          ),
        ),
      ],
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final FacultyModel faculty;

  const _ProfileHeader({required this.faculty});

  @override
  Widget build(BuildContext context) {
    final initials = faculty.name.trim().isEmpty
        ? '?'
        : faculty.name
            .trim()
            .split(RegExp(r'\s+'))
            .take(2)
            .map((part) => part[0])
            .join()
            .toUpperCase();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            blurRadius: 10,
            offset: Offset(0, 4),
            color: Color(0x26000000),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white24,
            child: Text(
              initials,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  faculty.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  faculty.facultyId,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SectionCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            blurRadius: 8,
            offset: Offset(0, 3),
            color: Color(0x14000000),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _ProfileDetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool showDivider;

  const _ProfileDetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 9),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(
                  icon,
                  size: 18,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      value.isEmpty ? '-' : value,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          const Divider(height: 1, color: AppColors.border),
      ],
    );
  }
}
