import 'package:flutter/material.dart';

import '../../core/constants/colors.dart';
import '../../models/faculty_model.dart';
import '../../models/faculty_task_model.dart';
import '../../repositories/faculty_repository.dart';
import '../../repositories/faculty_task_repository.dart';

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
  List<FacultyTaskModel> _myTasks = [];
  List<FacultyTaskModel> _allTasks = [];
  List<FacultyTaskModel> _dailyTasks = [];
  List<FacultyModel> _facultyList = [];
  List<String> _classOptions = [];
  List<String> _testCodes = [];
  Set<String> _notifications = {};

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
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final faculty = await _facultyRepository.getFacultyProfile(_id);
      final results = await Future.wait([
        _taskRepository.getMyTasks(_id),
        _taskRepository.getFacultyNotifications(_id),
      ]);

      if (!mounted) return;
      setState(() {
        _faculty = faculty;
        _myTasks = results[0] as List<FacultyTaskModel>;
        _notifications = (results[1] as List<Map<String, dynamic>>)
            .map((e) => e['module_name']?.toString() ?? '')
            .where((e) => e.isNotEmpty)
            .toSet();
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
      final results = await Future.wait([
        _taskRepository.getAllTasks(_id),
        _taskRepository.getDailyTasks(_id),
        _taskRepository.getFacultyList(),
        _taskRepository.getClassOptions(),
        _taskRepository.getTestCodes(),
      ]);
      if (!mounted) return;
      setState(() {
        _allTasks = results[0] as List<FacultyTaskModel>;
        _dailyTasks = results[1] as List<FacultyTaskModel>;
        _facultyList = results[2] as List<FacultyModel>;
        _classOptions = results[3] as List<String>;
        _testCodes = results[4] as List<String>;
      });
    } catch (_) {
      // The normal faculty checklist remains usable if optional admin data fails.
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
      final results = await Future.wait([
        _taskRepository.getAllTasks(_id),
        _taskRepository.getDailyTasks(_id),
      ]);
      if (!mounted) return;
      setState(() {
        _allTasks = results[0] as List<FacultyTaskModel>;
        _dailyTasks = results[1] as List<FacultyTaskModel>;
      });
    } catch (e) {
      _showMessage(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _markNotification(String module) async {
    if (!_notifications.contains(module)) return;
    setState(() => _notifications.remove(module));
    await _taskRepository.markNotificationRead(facultyId: _id, moduleName: module);
  }

  List<FacultyTaskModel> _filtered(List<FacultyTaskModel> source, String filter) {
    switch (filter) {
      case 'Pending':
        return source.where((t) => !t.isCompleted).toList();
      case 'Completed':
        return source.where((t) => t.isCompleted).toList();
      case 'Overdue':
        return source.where((t) => t.isOverdue).toList();
      case 'Due Today':
        return source.where((t) => t.isDueToday).toList();
      default:
        return source;
    }
  }

  int _count(List<FacultyTaskModel> list, String type) {
    switch (type) {
      case 'pending': return list.where((t) => !t.isCompleted).length;
      case 'completed': return list.where((t) => t.isCompleted).length;
      case 'overdue': return list.where((t) => t.isOverdue).length;
      case 'today': return list.where((t) => t.isDueToday).length;
      default: return 0;
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
      builder: (context) => AlertDialog(
        title: const Text('Delete Task'),
        content: const Text('Are you sure you want to delete this task?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
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
      builder: (context) => SimpleDialog(
        title: const Text('Reassign Task'),
        children: _facultyList.map((faculty) {
          return SimpleDialogOption(
            onPressed: () => Navigator.pop(context, faculty),
            child: Text('${faculty.name} (${faculty.facultyId})'),
          );
        }).toList(),
      ),
    );
    if (selected == null || selected.facultyId.toUpperCase() == task.facultyId.toUpperCase()) return;

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
    String? facultyId;
    String? className;
    String? testCode;
    String taskType = 'Weekly';
    String priority = 'Medium';
    String dueDate = '';
    final totalNote = TextEditingController();
    final otherTasks = TextEditingController();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return StatefulBuilder(builder: (context, setSheetState) {
          final bottom = MediaQuery.of(context).viewInsets.bottom;
          return Padding(
            padding: EdgeInsets.fromLTRB(20, 8, 20, bottom + 20),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Task Assignment', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.primary)),
                  const SizedBox(height: 18),
                  _drop<String>(label: 'Faculty Name', value: facultyId, items: _facultyList.map((f) => f.facultyId).toList(), display: (id) {
                    final f = _facultyList.firstWhere((x) => x.facultyId == id, orElse: () => _facultyList.first);
                    return '${f.name} (${f.facultyId})';
                  }, onChanged: (v) => setSheetState(() => facultyId = v)),
                  _drop<String>(label: 'Class', value: className, items: _classOptions, onChanged: (v) => setSheetState(() => className = v)),
                  _drop<String>(label: 'Task Type', value: taskType, items: const ['Weekly', 'Daily'], onChanged: (v) => setSheetState(() {
                    taskType = v ?? 'Weekly';
                    if (taskType == 'Daily') priority = 'High';
                  })),
                  _drop<String>(label: 'Test Code', value: testCode, items: _testCodes, onChanged: (v) => setSheetState(() => testCode = v)),
                  TextField(controller: totalNote, decoration: const InputDecoration(labelText: 'Total Test Note', border: OutlineInputBorder())),
                  const SizedBox(height: 14),
                  if (taskType == 'Weekly') ...[
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(dueDate.isEmpty ? 'Due Date' : 'Due Date: $dueDate'),
                      trailing: const Icon(Icons.calendar_today_outlined),
                      onTap: () async {
                        final now = DateTime.now();
                        final picked = await showDatePicker(context: context, firstDate: DateTime(now.year, now.month, now.day), lastDate: DateTime(now.year + 5), initialDate: now);
                        if (picked != null) setSheetState(() => dueDate = '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}');
                      },
                    ),
                    const SizedBox(height: 4),
                    _drop<String>(label: 'Priority', value: priority, items: const ['High', 'Medium', 'Low'], onChanged: (v) => setSheetState(() => priority = v ?? 'Medium')),
                  ],
                  TextField(controller: otherTasks, maxLines: 4, decoration: const InputDecoration(labelText: 'Other Tasks', border: OutlineInputBorder())),
                  const SizedBox(height: 18),
                  SizedBox(width: double.infinity, child: FilledButton(
                    onPressed: () async {
                      if (facultyId == null || facultyId!.isEmpty || className == null || className!.isEmpty) {
                        _showMessage('Please select Faculty and Class');
                        return;
                      }
                      if ((testCode == null || testCode!.isEmpty) && otherTasks.text.trim().isEmpty) {
                        _showMessage('Select Test Code or enter Other Tasks');
                        return;
                      }
                      if (taskType == 'Weekly' && dueDate.isEmpty) {
                        _showMessage('Please select Due Date');
                        return;
                      }
                      try {
                        final faculty = _facultyList.firstWhere((f) => f.facultyId == facultyId);
                        await _taskRepository.assignTask(
                          loginFacultyId: _id,
                          facultyId: facultyId!,
                          facultyName: faculty.name,
                          className: className!,
                          subjectName: testCode ?? '',
                          totalTestNote: totalNote.text.trim(),
                          otherTasks: otherTasks.text.trim(),
                          dueDate: taskType == 'Daily' ? null : dueDate,
                          priority: taskType == 'Daily' ? 'High' : priority,
                          taskType: taskType,
                        );
                        if (!mounted) return;
                        Navigator.pop(sheetContext);
                        _showMessage('Task assigned successfully');
                        await _refreshAdminTasks();
                        await _refreshMyTasks();
                      } catch (e) {
                        _showMessage(e.toString().replaceFirst('Exception: ', ''));
                      }
                    },
                    child: const Text('Assign Task'),
                  )),
                ],
              ),
            ),
          );
        });
      },
    );
    totalNote.dispose();
    otherTasks.dispose();
  }

  Widget _drop<T>({required String label, required T? value, required List<T> items, String Function(T)? display, required ValueChanged<T?> onChanged}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: DropdownButtonFormField<T>(
        value: items.contains(value) ? value : null,
        isExpanded: true,
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
        items: items.map((item) => DropdownMenuItem<T>(value: item, child: Text(display?.call(item) ?? item.toString(), overflow: TextOverflow.ellipsis))).toList(),
        onChanged: onChanged,
      ),
    );
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.primary,
        elevation: 0,
        title: const Text('Faculty Profile', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800)),
      ),
      body: SafeArea(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    if (_error != null) {
      return Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.primary),
        const SizedBox(height: 12),
        const Text('Unable to load faculty profile', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Text(_error!, textAlign: TextAlign.center),
        const SizedBox(height: 18),
        FilledButton(onPressed: _loadEverything, child: const Text('Retry')),
      ])));
    }

    final faculty = _faculty;
    if (faculty == null) return const Center(child: Text('Faculty profile not found.'));

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _loadEverything,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 36),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _ProfileHeader(faculty: faculty),
          const SizedBox(height: 20),
          _SectionCard(title: 'Personal Details', children: [
            _ProfileDetailRow(icon: Icons.badge_outlined, label: 'Faculty ID', value: faculty.facultyId),
            _ProfileDetailRow(icon: Icons.person_outline_rounded, label: 'Name', value: faculty.name),
            _ProfileDetailRow(icon: Icons.email_outlined, label: 'Email', value: faculty.email),
            _ProfileDetailRow(icon: Icons.phone_outlined, label: 'Phone', value: faculty.phone, showDivider: false),
          ]),
          const SizedBox(height: 28),
          Text('Task Management', style: TextStyle(color: AppColors.primary, fontSize: 24, fontWeight: FontWeight.w800)),
          const SizedBox(height: 14),
          _buildTaskBoxes(),
          if (_activeSection == 'myChecklist') ...[
            const SizedBox(height: 16),
            _TaskPanel(
              title: 'My Task Checklist',
              loading: _tasksLoading,
              tasks: _filtered(_myTasks, _myFilter),
              filter: _myFilter,
              onFilter: (v) => setState(() => _myFilter = v),
              stats: _myTasks,
              showCheckbox: true,
              canManage: _isAdmin,
              onToggle: _toggleTask,
              onDelete: _deleteTask,
              onReassign: _reassignTask,
            ),
          ],
          if (_isAdmin && _activeSection == 'allTasks') ...[
            const SizedBox(height: 16),
            _TaskPanel(title: 'All Faculty Assigned Tasks', loading: _allLoading, tasks: _filtered(_allTasks, _allFilter), filter: _allFilter, onFilter: (v) => setState(() => _allFilter = v), stats: _allTasks, showCheckbox: false, canManage: true, onToggle: _toggleTask, onDelete: _deleteTask, onReassign: _reassignTask),
          ],
          if (_isAdmin && _activeSection == 'dailyTasks') ...[
            const SizedBox(height: 16),
            _TaskPanel(title: 'All Faculty Daily Task', loading: _dailyLoading, tasks: _filtered(_dailyTasks, _dailyFilter), filter: _dailyFilter, onFilter: (v) => setState(() => _dailyFilter = v), stats: _dailyTasks, showCheckbox: false, canManage: true, onToggle: _toggleTask, onDelete: _deleteTask, onReassign: _reassignTask),
          ],
          if (_isAdmin && _activeSection == 'assignTask') ...[
            const SizedBox(height: 16),
            _AssignmentCard(onAssign: _showAssignmentForm),
          ],
        ]),
      ),
    );
  }

  Widget _buildTaskBoxes() {
    final boxes = <Widget>[];
    if (_isAdmin) {
      boxes.add(_TaskBox(title: 'All Faculty Assigned Tasks', description: 'View, filter and delete tasks assigned to all faculty members.', notification: _notifications.contains('all-tasks'), active: _activeSection == 'allTasks', onTap: () async { setState(() { _activeSection = _activeSection == 'allTasks' ? '' : 'allTasks'; _allLoading = true; }); await _markNotification('all-tasks'); if (_activeSection == 'allTasks') { try { final tasks = await _taskRepository.getAllTasks(_id); if (mounted) setState(() => _allTasks = tasks); } finally { if (mounted) setState(() => _allLoading = false); } } }),
        boxes.add(_TaskBox(title: 'All Faculty Daily Task', description: 'View daily repeated tasks for all faculty.', notification: _notifications.contains('daily-tasks'), active: _activeSection == 'dailyTasks', onTap: () async { setState(() { _activeSection = _activeSection == 'dailyTasks' ? '' : 'dailyTasks'; _dailyLoading = true; }); await _markNotification('daily-tasks'); if (_activeSection == 'dailyTasks') { try { final tasks = await _taskRepository.getDailyTasks(_id); if (mounted) setState(() => _dailyTasks = tasks); } finally { if (mounted) setState(() => _dailyLoading = false); } } }),
        boxes.add(_TaskBox(title: 'Task Assignment', description: 'Assign weekly or daily tasks.', active: _activeSection == 'assignTask', onTap: () => setState(() => _activeSection = _activeSection == 'assignTask' ? '' : 'assignTask')),
      );
    }
    boxes.add(_TaskBox(title: 'My Task Checklist', description: 'View, filter and update my assigned tasks.', notification: _notifications.contains('tasks'), active: _activeSection == 'myChecklist', onTap: () async { final next = _activeSection == 'myChecklist' ? '' : 'myChecklist'; setState(() { _activeSection = next; _tasksLoading = true; }); if (next == 'myChecklist') { await _markNotification('tasks'); try { final tasks = await _taskRepository.getMyTasks(_id); if (mounted) setState(() => _myTasks = tasks); } finally { if (mounted) setState(() => _tasksLoading = false); } } else if (mounted) { setState(() => _tasksLoading = false); } }));
    return Column(children: boxes.map((box) => Padding(padding: const EdgeInsets.only(bottom: 12), child: box)).toList());
  }
}

class _TaskPanel extends StatelessWidget {
  final String title;
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

  const _TaskPanel({required this.title, required this.loading, required this.tasks, required this.filter, required this.onFilter, required this.stats, required this.showCheckbox, required this.canManage, required this.onToggle, required this.onDelete, required this.onReassign});

  int _count(String type) {
    if (type == 'pending') return stats.where((t) => !t.isCompleted).length;
    if (type == 'completed') return stats.where((t) => t.isCompleted).length;
    if (type == 'overdue') return stats.where((t) => t.isOverdue).length;
    return stats.where((t) => t.isDueToday).length;
  }

  @override
  Widget build(BuildContext context) {
    return _SectionCard(title: title, children: [
      GridView.count(crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), childAspectRatio: 1.8, children: [
        _StatBox(label: 'Pending', value: _count('pending'), type: 'pending'),
        _StatBox(label: 'Completed', value: _count('completed'), type: 'completed'),
        _StatBox(label: 'Overdue', value: _count('overdue'), type: 'overdue'),
        _StatBox(label: 'Due Today', value: _count('today'), type: 'today'),
      ]),
      const SizedBox(height: 16),
      DropdownButtonFormField<String>(value: filter, decoration: const InputDecoration(labelText: 'Filter Tasks', border: OutlineInputBorder()), items: const ['All', 'Pending', 'Completed', 'Overdue', 'Due Today'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(), onChanged: (v) { if (v != null) onFilter(v); }),
      const SizedBox(height: 16),
      if (loading) const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: AppColors.primary)))
      else if (tasks.isEmpty) const Padding(padding: EdgeInsets.all(12), child: Text('No tasks assigned for this filter.'))
      else ...tasks.map((task) => _TaskCard(task: task, showCheckbox: showCheckbox, canManage: canManage, onToggle: () => onToggle(task), onDelete: () => onDelete(task), onReassign: () => onReassign(task))),
    ]);
  }
}

class _TaskCard extends StatelessWidget {
  final FacultyTaskModel task;
  final bool showCheckbox;
  final bool canManage;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final VoidCallback onReassign;

  const _TaskCard({required this.task, required this.showCheckbox, required this.canManage, required this.onToggle, required this.onDelete, required this.onReassign});

  @override
  Widget build(BuildContext context) {
    Color border = AppColors.border;
    Color background = AppColors.surface;
    if (task.taskType == 'Daily' || task.isOverdue) { border = Colors.red.shade200; background = Colors.red.shade50; }
    else if (task.isDueToday) { border = Colors.amber.shade200; background = Colors.amber.shade50; }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(14), border: Border.all(color: border)),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (showCheckbox) Padding(padding: const EdgeInsets.only(right: 8), child: Checkbox(value: task.isCompleted, onChanged: (_) => onToggle())),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${task.facultyName} (${task.facultyId})', style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
          const SizedBox(height: 7),
          _TaskLine('Class', task.className),
          _TaskLine('Task Type', task.taskType),
          _TaskLine('Priority', task.priority),
          _TaskLine('Test Code', task.subjectName.isEmpty ? '-' : task.subjectName),
          _TaskLine('Total Test Note', task.totalTestNote.isEmpty ? '-' : task.totalTestNote),
          _TaskLine('Due Date', task.dueDate ?? '-'),
          _TaskLine('Other Tasks', task.otherTasks.isEmpty ? '-' : task.otherTasks),
          if (task.isCompleted) ...[
            const SizedBox(height: 5),
            Text('Completed${task.completedAt == null ? '' : ' on ${task.completedAt}'}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w700)),
          ],
          if (task.assignedBy.isNotEmpty) ...[
            const SizedBox(height: 5),
            Text('Assigned by: ${task.assignedBy}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          ],
          if (canManage) ...[
            const SizedBox(height: 10),
            Wrap(spacing: 8, children: [TextButton(onPressed: onReassign, child: const Text('Reassign')), TextButton(onPressed: onDelete, child: const Text('Delete'))]),
          ],
        ])),
      ]),
    );
  }
}

class _TaskLine extends StatelessWidget {
  final String label;
  final String value;
  const _TaskLine(this.label, this.value);
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 3), child: Text('$label: $value', style: const TextStyle(color: AppColors.textPrimary)));
}

class _StatBox extends StatelessWidget {
  final String label;
  final int value;
  final String type;
  const _StatBox({required this.label, required this.value, required this.type});
  @override
  Widget build(BuildContext context) {
    Color border = Colors.blue.shade200;
    Color bg = Colors.blue.shade50;
    Color text = Colors.blue.shade900;
    if (type == 'completed') { border = Colors.green.shade200; bg = Colors.green.shade50; text = Colors.green.shade900; }
    if (type == 'overdue') { border = Colors.red.shade200; bg = Colors.red.shade50; text = Colors.red.shade900; }
    if (type == 'today') { border = Colors.amber.shade200; bg = Colors.amber.shade50; text = Colors.amber.shade900; }
    return Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12), border: Border.all(color: border)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [Text(label, style: TextStyle(color: text, fontSize: 12, fontWeight: FontWeight.w600)), const SizedBox(height: 5), Text('$value', style: TextStyle(color: text, fontSize: 25, fontWeight: FontWeight.w800))]);
  }
}

class _TaskBox extends StatelessWidget {
  final String title;
  final String description;
  final bool active;
  final bool notification;
  final VoidCallback onTap;
  const _TaskBox({required this.title, required this.description, required this.onTap, this.active = false, this.notification = false});
  @override
  Widget build(BuildContext context) => InkWell(onTap: onTap, borderRadius: BorderRadius.circular(16), child: Container(width: double.infinity, padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: active ? AppColors.primary.withValues(alpha: .06) : AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: active ? AppColors.primary : AppColors.border), boxShadow: const [BoxShadow(color: AppColors.shadow, blurRadius: 8, offset: Offset(0, 3))]), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Expanded(child: Text(title, style: const TextStyle(color: AppColors.primary, fontSize: 18, fontWeight: FontWeight.w800))), if (notification) Container(width: 10, height: 10, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle))]), const SizedBox(height: 7), Text(description, style: const TextStyle(color: AppColors.textSecondary))]));
}

class _AssignmentCard extends StatelessWidget {
  final VoidCallback onAssign;
  const _AssignmentCard({required this.onAssign});
  @override
  Widget build(BuildContext context) => _SectionCard(title: 'Task Assignment', children: [const Text('Assign weekly or daily tasks to faculty members.'), const SizedBox(height: 14), SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: onAssign, icon: const Icon(Icons.add_task), label: const Text('Open Task Assignment')))]);
}

class _ProfileHeader extends StatelessWidget {
  final FacultyModel faculty;
  const _ProfileHeader({required this.faculty});
  @override
  Widget build(BuildContext context) {
    final name = faculty.name.trim().isEmpty ? 'Faculty' : faculty.name.trim();
    final parts = name.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    final initials = parts.length == 1 ? parts.first.substring(0, 1) : '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}';
    return Container(width: double.infinity, padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(20), boxShadow: const [BoxShadow(color: AppColors.shadow, blurRadius: 14, offset: Offset(0, 6))]), child: Row(children: [Container(width: 64, height: 64, alignment: Alignment.center, decoration: BoxDecoration(color: Colors.white.withValues(alpha: .14), shape: BoxShape.circle, border: Border.all(color: Colors.white24)), child: Text(initials.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w800))), const SizedBox(width: 15), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w800)), const SizedBox(height: 5), Text(faculty.facultyId, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600))]))]));
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _SectionCard({required this.title, required this.children});
  @override
  Widget build(BuildContext context) => Container(width: double.infinity, padding: const EdgeInsets.fromLTRB(18, 18, 18, 8), decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.border), boxShadow: const [BoxShadow(color: AppColors.shadow, blurRadius: 10, offset: Offset(0, 4))]), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(color: AppColors.primary, fontSize: 18, fontWeight: FontWeight.w800)), const SizedBox(height: 8), ...children]);
}

class _ProfileDetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool showDivider;
  const _ProfileDetailRow({required this.icon, required this.label, required this.value, this.showDivider = true});
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.symmetric(vertical: 13), decoration: showDivider ? const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.divider))) : null, child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Container(width: 38, height: 38, alignment: Alignment.center, decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: .08), borderRadius: BorderRadius.circular(10)), child: Icon(icon, size: 20, color: AppColors.primary)), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)), const SizedBox(height: 4), Text(value.trim().isEmpty ? '-' : value, style: const TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w600))]))]));
}
