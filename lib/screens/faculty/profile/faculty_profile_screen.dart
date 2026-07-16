import 'package:flutter/material.dart';
import '../../../shared/layout/app_layout.dart';
import '../../../models/faculty_model.dart';
import '../../../models/faculty_task_model.dart';
import 'widgets/profile_details_card.dart';
import 'widgets/task_card.dart';
import 'widgets/task_management_card.dart';
import 'widgets/task_stats.dart';

class FacultyProfileScreen extends StatefulWidget {
  final String facultyId;
  final String loginFacultyId;

  const FacultyProfileScreen({
    super.key,
    required this.facultyId,
    required this.loginFacultyId,
  });

  @override
  State<FacultyProfileScreen> createState() => _FacultyProfileScreenState();
}

class _FacultyProfileScreenState extends State<FacultyProfileScreen> {
  FacultyModel? faculty;

  List<FacultyModel> facultyList = [];
  List<FacultyTaskModel> tasks = [];
  List<FacultyTaskModel> allTasks = [];
  List<FacultyTaskModel> dailyTasks = [];

  List<String> classOptions = [];
  List<String> testCodes = [];

  List<Map<String, dynamic>> facultyNotifications = [];

  bool isLoading = true;

  String activeSection = '';
  String myTaskFilter = 'All';

  bool get canAccessAllTasks {
    return widget.loginFacultyId == 'IG001' || widget.loginFacultyId == 'IG002';
  }

  String get profileTitle {
    return canAccessAllTasks ? 'Admin Profile' : 'Faculty Profile';
  }

  @override
  void initState() {
    super.initState();

    _loadDummyData();
  }

  Future<void> _loadDummyData() async {
    setState(() {
      isLoading = true;
    });

    // Small delay so we can see the loading UI.
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) {
      return;
    }

    final dummyTasks = List<FacultyTaskModel>.from(FacultyTaskModel.dummyTasks);

    setState(() {
      faculty = FacultyModel.dummyAdmin;

      facultyList = List<FacultyModel>.from(FacultyModel.dummyFacultyList);

      classOptions = ['Class 9', 'Class 10', 'Class 11', 'Class 12'];

      testCodes = ['MAT101', 'PHY201', 'CHE105', 'ENG110'];

      tasks = dummyTasks;

      allTasks = List<FacultyTaskModel>.from(dummyTasks);

      dailyTasks = dummyTasks
          .where((task) => task.taskType == 'Daily')
          .toList();

      facultyNotifications = [
        {'module_name': 'tasks'},
        {'module_name': 'all-tasks'},
        {'module_name': 'daily-tasks'},
      ];

      isLoading = false;
    });
  }

  bool _hasNotification(String moduleName) {
    return facultyNotifications.any(
      (notification) => notification['module_name'] == moduleName,
    );
  }

  void _markNotificationRead(String moduleName) {
    setState(() {
      facultyNotifications.removeWhere(
        (notification) => notification['module_name'] == moduleName,
      );
    });
  }

  void _changeSection(String section, {String? notificationModule}) {
    setState(() {
      if (activeSection == section) {
        activeSection = '';
      } else {
        activeSection = section;
      }
    });

    if (notificationModule != null) {
      _markNotificationRead(notificationModule);
    }
  }

  Future<void> _refreshPage() async {
    await _loadDummyData();
  }

  List<FacultyTaskModel> get filteredMyTasks {
    switch (myTaskFilter) {
      case 'Pending':
        return tasks.where((task) => !task.isCompleted).toList();

      case 'Completed':
        return tasks.where((task) => task.isCompleted).toList();

      case 'Overdue':
        return tasks.where((task) => task.isOverdue).toList();

      case 'Due Today':
        return tasks.where((task) => task.isDueToday).toList();

      default:
        return tasks;
    }
  }

  void _toggleTask(FacultyTaskModel task) {
    final taskIndex = tasks.indexWhere((item) => item.id == task.id);

    if (taskIndex == -1) {
      return;
    }

    final updatedTask = FacultyTaskModel(
      id: task.id,
      facultyId: task.facultyId,
      facultyName: task.facultyName,
      className: task.className,
      subjectName: task.subjectName,
      totalTestNote: task.totalTestNote,
      otherTasks: task.otherTasks,
      dueDate: task.dueDate,
      priority: task.priority,
      taskType: task.taskType,
      isCompleted: !task.isCompleted,
      assignedBy: task.assignedBy,
      completedAt: task.isCompleted ? null : DateTime.now().toIso8601String(),
    );

    setState(() {
      tasks[taskIndex] = updatedTask;

      final allTaskIndex = allTasks.indexWhere((item) => item.id == task.id);

      if (allTaskIndex != -1) {
        allTasks[allTaskIndex] = updatedTask;
      }

      dailyTasks = allTasks.where((item) => item.taskType == 'Daily').toList();
    });

    _showMessage(
      updatedTask.isCompleted
          ? 'Task marked as completed'
          : 'Task marked as pending',
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF9FAFB),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (faculty == null) {
      return const Scaffold(
        body: Center(child: Text('Faculty details not found')),
      );
    }

    return AppLayout(
      title: profileTitle,
      isAdmin: canAccessAllTasks,
      facultyId: widget.loginFacultyId,
      isHome: true,

      body: RefreshIndicator(
        onRefresh: _refreshPage,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1150),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  ProfileDetailsCard(faculty: faculty!),

                  const SizedBox(height: 32),

                  const Text(
                    'Task Management',
                    style: TextStyle(
                      color: Color(0xFF1D4ED8),
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 20),

                  _buildTaskManagementCards(),

                  const SizedBox(height: 24),

                  _buildActiveSection(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTaskManagementCards() {
    final cards = <Widget>[];

    if (canAccessAllTasks) {
      cards.add(
        TaskManagementCard(
          title: 'All Faculty Assigned Tasks',
          description:
              'View, filter and delete tasks assigned to all faculty members.',
          isActive: activeSection == 'allTasks',
          hasNotification: _hasNotification('all-tasks'),
          onTap: () {
            _changeSection('allTasks', notificationModule: 'all-tasks');
          },
        ),
      );

      cards.add(
        TaskManagementCard(
          title: 'All Faculty Daily Task',
          description: 'View daily repeated tasks for all faculty.',
          isActive: activeSection == 'dailyTasks',
          hasNotification: _hasNotification('daily-tasks'),
          onTap: () {
            _changeSection('dailyTasks', notificationModule: 'daily-tasks');
          },
        ),
      );

      cards.add(
        TaskManagementCard(
          title: 'Task Assignment',
          description: 'Assign weekly or daily tasks.',
          isActive: activeSection == 'myTasks',
          onTap: () {
            _changeSection('myTasks');
          },
        ),
      );
    }

    cards.add(
      TaskManagementCard(
        title: 'My Task Checklist',
        description: 'View, filter and update my assigned tasks.',
        isActive: activeSection == 'myChecklist',
        hasNotification: _hasNotification('tasks'),
        onTap: () {
          _changeSection('myChecklist', notificationModule: 'tasks');
        },
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 900) {
          return GridView.count(
            crossAxisCount: canAccessAllTasks ? 4 : 1,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.2,
            children: cards,
          );
        }

        if (constraints.maxWidth >= 600) {
          return GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.5,
            children: cards,
          );
        }

        return Column(
          children: [
            for (int index = 0; index < cards.length; index++) ...[
              cards[index],
              if (index < cards.length - 1) const SizedBox(height: 16),
            ],
          ],
        );
      },
    );
  }

  Widget _buildActiveSection() {
    if (activeSection.isEmpty) {
      return const SizedBox.shrink();
    }

    switch (activeSection) {
      case 'allTasks':
        return _buildAllTasksSection();

      case 'dailyTasks':
        return _buildDailyTasksSection();

      case 'myTasks':
        return _buildTaskAssignmentPlaceholder();

      case 'myChecklist':
        return _buildMyTaskChecklist();

      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildAllTasksSection() {
    return _buildTaskListSection(
      title: 'All Faculty Assigned Tasks',
      taskList: allTasks,
      emptyMessage: 'No assigned tasks available.',
      showCheckbox: false,
    );
  }

  Widget _buildDailyTasksSection() {
    return _buildTaskListSection(
      title: 'All Faculty Daily Task',
      taskList: dailyTasks,
      emptyMessage: 'No daily tasks available.',
      showCheckbox: false,
    );
  }

  Widget _buildTaskAssignmentPlaceholder() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: _sectionDecoration(),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Task Assignment',
            style: TextStyle(
              color: Color(0xFF1D4ED8),
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 12),
          Text(
            'The Task Assignment form will be connected in Phase 3.',
            style: TextStyle(color: Color(0xFF4B5563), fontSize: 15),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskListSection({
    required String title,
    required List<FacultyTaskModel> taskList,
    required String emptyMessage,
    required bool showCheckbox,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: _sectionDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF1D4ED8),
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 20),

          if (taskList.isEmpty)
            Text(emptyMessage, style: const TextStyle(color: Color(0xFF4B5563)))
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: taskList.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final task = taskList[index];

                return TaskCard(
                  task: task,
                  showCheckbox: showCheckbox,
                  showAdminActions: canAccessAllTasks,
                  onToggle: () {
                    _toggleTask(task);
                  },
                  onReassign: () {
                    _showMessage('Reassign will be added later');
                  },
                  onDelete: () {
                    _showMessage('Delete will be added later');
                  },
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildMyTaskChecklist() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: _sectionDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'My Task Checklist',
            style: TextStyle(
              color: Color(0xFF1D4ED8),
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 20),

          TaskStats(tasks: tasks, prefix: 'My'),

          const SizedBox(height: 24),

          const Text(
            'Filter My Tasks',
            style: TextStyle(
              color: Color(0xFF374151),
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 8),

          SizedBox(
            width: 280,
            child: DropdownButtonFormField<String>(
              initialValue: myTaskFilter,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              items: const [
                DropdownMenuItem(value: 'All', child: Text('All')),
                DropdownMenuItem(value: 'Pending', child: Text('Pending')),
                DropdownMenuItem(value: 'Completed', child: Text('Completed')),
                DropdownMenuItem(value: 'Overdue', child: Text('Overdue')),
                DropdownMenuItem(value: 'Due Today', child: Text('Due Today')),
              ],
              onChanged: (value) {
                if (value == null) {
                  return;
                }

                setState(() {
                  myTaskFilter = value;
                });
              },
            ),
          ),

          const SizedBox(height: 20),

          if (filteredMyTasks.isEmpty)
            const Text(
              'No tasks assigned for this filter.',
              style: TextStyle(color: Color(0xFF4B5563)),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredMyTasks.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final task = filteredMyTasks[index];

                return TaskCard(
                  task: task,
                  showCheckbox: true,
                  showAdminActions: canAccessAllTasks,
                  onToggle: () {
                    _toggleTask(task);
                  },
                  onReassign: () {
                    _showMessage('Reassign will be added later');
                  },
                  onDelete: () {
                    _showMessage('Delete will be added later');
                  },
                );
              },
            ),
        ],
      ),
    );
  }

  BoxDecoration _sectionDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.08),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }
}
