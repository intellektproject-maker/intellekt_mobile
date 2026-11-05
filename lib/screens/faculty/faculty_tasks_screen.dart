import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../models/faculty_model.dart';
import '../../models/faculty_task_model.dart';
import '../../repositories/faculty_task_repository.dart';
import 'task_assignment_screen.dart';

class FacultyTasksScreen extends StatefulWidget {
  final String facultyId;
  final bool facultyOnly;
  const FacultyTasksScreen({super.key, required this.facultyId, this.facultyOnly = false});

  @override
  State<FacultyTasksScreen> createState() => _FacultyTasksScreenState();
}

class _FacultyTasksScreenState extends State<FacultyTasksScreen> with SingleTickerProviderStateMixin {
  final _repo = FacultyTaskRepository();
  late final TabController _tabs;
  final _pages = PageController();
  List<FacultyTaskModel> _all = [], _daily = [], _mine = [];
  List<FacultyModel> _faculty = [];
  bool _loadingAll = false, _loadingDaily = false, _loadingMine = false;
  String _allFilter = 'All', _dailyFilter = 'All', _mineFilter = 'All';
  String get _id => widget.facultyId.trim().toUpperCase();
  bool get _admin => _id == 'IG001' || _id == 'IG002';
  static const _titles = ['All Faculty Assigned Tasks', 'All Faculty Daily Tasks', 'Task Assignment', 'My Task Checklist'];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: widget.facultyOnly ? 1 : 4, vsync: this);
    _tabs.addListener(() {
      if (!_tabs.indexIsChanging && _pages.hasClients) _pages.jumpToPage(_tabs.index);
    });
    _loadPage(0);
  }

  @override
  void dispose() { _tabs.dispose(); _pages.dispose(); super.dispose(); }

  Future<void> _loadPage(int index) async {
    if (!mounted) return;
    try {
      if (widget.facultyOnly || index == 3) {
        setState(() => _loadingMine = true);
        final v = await _repo.getMyTasks(_id);
        if (mounted) setState(() => _mine = v);
      } else if (index == 0 && _admin) {
        setState(() => _loadingAll = true);
        final v = await _repo.getAllTasks(_id);
        if (mounted) setState(() => _all = v);
      } else if (index == 1 && _admin) {
        setState(() => _loadingDaily = true);
        final v = await _repo.getDailyTasks(_id);
        if (mounted) setState(() => _daily = v);
      }
      if (_admin && _faculty.isEmpty) {
        final v = await _repo.getFacultyList();
        if (mounted) setState(() => _faculty = v);
      }
    } catch (e) {
      if (mounted) _message(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() { _loadingAll = false; _loadingDaily = false; _loadingMine = false; });
    }
  }

  List<FacultyTaskModel> _filter(List<FacultyTaskModel> source, String filter) => source.where((t) {
    switch (filter) {
      case 'Pending': return !t.isCompleted;
      case 'Completed': return t.isCompleted;
      case 'Overdue': return t.isOverdue;
      case 'Due Today': return t.isDueToday;
      default: return true;
    }
  }).toList();

  void _message(String value) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));

  Future<void> _toggle(FacultyTaskModel task) async {
    try {
      await _repo.updateTaskStatus(task.id, !task.isCompleted);
      await _reloadCurrent();
    } catch (e) { _message(e.toString().replaceFirst('Exception: ', '')); }
  }

  Future<void> _reloadCurrent() async {
    await _loadPage(widget.facultyOnly ? 0 : _tabs.index);
    if (_admin) {
      try {
        final a = await _repo.getAllTasks(_id), d = await _repo.getDailyTasks(_id);
        if (mounted) setState(() { _all = a; _daily = d; });
      } catch (_) {}
    }
  }

  Future<void> _delete(FacultyTaskModel task) async {
    final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Delete task?'), content: const Text('This task will be permanently deleted.'),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete'))],
    ));
    if (ok != true) return;
    try { await _repo.deleteTask(task.id, _id); await _reloadCurrent(); }
    catch (e) { _message(e.toString().replaceFirst('Exception: ', '')); }
  }

  Future<void> _reassign(FacultyTaskModel task) async {
    if (_faculty.isEmpty) { _message('Faculty list is unavailable.'); return; }
    final selected = await showDialog<FacultyModel>(context: context, builder: (ctx) => SimpleDialog(
      title: const Text('Reassign task'),
      children: _faculty.map((f) => SimpleDialogOption(
        onPressed: () => Navigator.pop(ctx, f), child: Text('${f.name} (${f.facultyId})'),
      )).toList(),
    ));
    if (selected == null) return;
    try {
      await _repo.reassignTask(taskId: task.id, facultyId: selected.facultyId, facultyName: selected.name);
      await _reloadCurrent();
    } catch (e) { _message(e.toString().replaceFirst('Exception: ', '')); }
  }

  Future<void> _assign() async {
    final result = await Navigator.of(context).push<bool>(MaterialPageRoute(
      builder: (_) => TaskAssignmentScreen(loginFacultyId: _id),
    ));
    if (result == true) { _message('Task assigned successfully'); await _loadPage(0); await _loadPage(1); await _loadPage(3); }
  }

  Widget _taskList(List<FacultyTaskModel> tasks, bool loading, String filter, ValueChanged<String> onFilter, {required bool checklist}) {
    final filtered = _filter(tasks, filter);
    final counts = [
      ('Pending', tasks.where((t) => !t.isCompleted).length),
      ('Completed', tasks.where((t) => t.isCompleted).length),
      ('Overdue', tasks.where((t) => t.isOverdue).length),
      ('Due Today', tasks.where((t) => t.isDueToday).length),
    ];
    return RefreshIndicator(
      onRefresh: _reloadCurrent,
      child: ListView(padding: const EdgeInsets.all(16), children: [
        LayoutBuilder(builder: (context, constraints) {
          // Keep the statistic tiles tall enough for both the label and count
          // on narrow phones and when the system text scale is increased.
          final tileWidth = (constraints.maxWidth - 10) / 2;
          final tileHeight = (tileWidth / 1.75).clamp(116.0, 150.0);
          return GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            childAspectRatio: tileWidth / tileHeight,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            children: counts.map((c) => Card(
              color: AppColors.surface,
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      c.$1,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${c.$2}',
                      style: const TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            )).toList(),
          );
        }),
        const SizedBox(height: 14),
        DropdownButtonFormField<String>(value: filter, decoration: const InputDecoration(labelText: 'Filter tasks', border: OutlineInputBorder()),
          items: const ['All', 'Pending', 'Completed', 'Overdue', 'Due Today'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
          onChanged: (v) { if (v != null) onFilter(v); }),
        const SizedBox(height: 14),
        if (loading) const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
        else if (filtered.isEmpty) const Card(child: ListTile(title: Text('No tasks found for this filter.')))
        else ...filtered.map((t) => Card(color: AppColors.surface, margin: const EdgeInsets.only(bottom: 10), child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [Expanded(child: Text('${t.facultyName} (${t.facultyId})', style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.primary))),
            if (checklist) Checkbox(value: t.isCompleted, onChanged: (_) => _toggle(t))]),
          Text('Class: ${t.className}'),
          Text('Frequency: ${t.taskType}   •   Priority: ${t.priority}'),
          Text('Test / Subject: ${t.subjectName.isEmpty ? '-' : t.subjectName}'),
          if (t.totalTestNote.isNotEmpty) Text('Task: ${t.totalTestNote}'),
          if (t.otherTasks.isNotEmpty) Text('Other tasks: ${t.otherTasks}'),
          Text('Due: ${t.dueDate ?? 'No due date'}'),
          if (t.assignedBy.isNotEmpty) Text('Assigned by: ${t.assignedBy}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          if (t.isCompleted) const Text('Completed', style: TextStyle(color: Colors.green, fontWeight: FontWeight.w700)),
          if (_admin && !checklist) Wrap(spacing: 8, children: [
            TextButton(onPressed: () => _reassign(t), child: const Text('Reassign')),
            TextButton(onPressed: () => _delete(t), child: const Text('Delete', style: TextStyle(color: Colors.red))),
          ]),
        ])))),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final labels = widget.facultyOnly ? const ['My Task Checklist'] : _titles;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Tasks'), backgroundColor: AppColors.surface, foregroundColor: AppColors.primary,
        bottom: widget.facultyOnly ? null : TabBar(controller: _tabs, isScrollable: true, tabAlignment: TabAlignment.start,
          labelColor: AppColors.primary, unselectedLabelColor: AppColors.textSecondary, tabs: labels.map((t) => Tab(text: t)).toList())),
      body: widget.facultyOnly
        ? _taskList(_mine, _loadingMine, _mineFilter, (v) => setState(() => _mineFilter = v), checklist: true)
        : PageView(controller: _pages, onPageChanged: (i) { _tabs.animateTo(i); _loadPage(i); }, children: [
            _taskList(_all, _loadingAll, _allFilter, (v) => setState(() => _allFilter = v), checklist: false),
            _taskList(_daily, _loadingDaily, _dailyFilter, (v) => setState(() => _dailyFilter = v), checklist: false),
            ListView(padding: const EdgeInsets.all(16), children: [
              Card(color: AppColors.surface, child: Padding(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Task Assignment', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.primary)),
                const SizedBox(height: 8), const Text('Create and assign weekly or daily tasks to faculty members.'),
                const SizedBox(height: 18), SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: _assign, icon: const Icon(Icons.add_task), label: const Text('Assign Task'))),
              ]))),
            ]),
            _taskList(_mine, _loadingMine, _mineFilter, (v) => setState(() => _mineFilter = v), checklist: true),
          ]),
    );
  }
}
