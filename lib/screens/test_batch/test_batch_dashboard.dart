import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/test_batch_provider.dart';
import '../../routes/app_routes.dart';

class TestBatchDashboard extends StatefulWidget {
  const TestBatchDashboard({super.key});
  @override State<TestBatchDashboard> createState() => _TestBatchDashboardState();
}

class _TestBatchDashboardState extends State<TestBatchDashboard> {
  String _rollNo = '';
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = context.read<AuthProvider>();
    final id = auth.user?.id.trim().toUpperCase() ?? '';
    if (id.isEmpty || !auth.isTestBatchStudent || _rollNo == id) return;
    _rollNo = id;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<TestBatchProvider>().load(_rollNo);
    });
  }
  Future<void> _signOut() async {
    await context.read<AuthProvider>().logout();
    if (mounted) context.go(AppRoutes.login);
  }
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TestBatchProvider>();
    return Scaffold(
      backgroundColor: const Color(0xFFECECEF),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('Test Batch Dashboard'),
        actions: [IconButton(tooltip: 'Sign out', onPressed: _signOut, icon: const Icon(Icons.logout_rounded))],
      ),
      body: RefreshIndicator(
        onRefresh: () => provider.load(_rollNo),
        child: provider.isLoading && provider.student == null
            ? ListView(children: [const SizedBox(height: 300), const Center(child: CircularProgressIndicator())])
            : provider.error != null && provider.student == null
                ? ListView(padding: const EdgeInsets.all(24), children: [const SizedBox(height: 180), Text('Unable to load Test Batch data.\nPlease refresh and try again.', textAlign: TextAlign.center)])
                : ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      _ProfileCard(student: provider.student ?? {}),
                      const SizedBox(height: 16),
                      Row(children: [
                        Expanded(child: _SummaryCard(title: 'Attendance', value: provider.attendancePercentage.toStringAsFixed(1) + '%', icon: Icons.assignment_turned_in_outlined)),
                        const SizedBox(width: 12),
                        Expanded(child: _SummaryCard(title: 'Marks', value: provider.marks.length.toString(), icon: Icons.menu_book_outlined)),
                      ]),
                      const SizedBox(height: 20),
                      _SectionCard(
                        title: 'Marks',
                        child: provider.marks.isEmpty
                            ? const Text('No marks available yet.')
                            : Column(children: provider.marks.take(10).map((mark) => ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: const Icon(Icons.assignment_outlined, color: AppColors.primary),
                                title: Text((mark['subject_name'] ?? 'Subject').toString() + ' • ' + (mark['test_code'] ?? '-').toString()),
                                subtitle: Text((mark['marks_obtained'] ?? '-').toString() + ' / ' + (mark['total_marks'] ?? '-').toString()),
                              )).toList()),
                      ),
                      const SizedBox(height: 16),
                      _SectionCard(
                        title: 'Attendance',
                        child: provider.attendance.isEmpty
                            ? const Text('No attendance records available yet.')
                            : Column(children: provider.attendance.take(10).map((item) => ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: Icon(item['status'] == 'Present' ? Icons.check_circle_outline : Icons.cancel_outlined, color: item['status'] == 'Present' ? Colors.green : Colors.red),
                                title: Text(item['attendance_date']?.toString() ?? '-'),
                                trailing: Text(item['status']?.toString() ?? '-'),
                              )).toList()),
                      ),
                    ],
                  ),
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final Map<String, dynamic> student;
  const _ProfileCard({required this.student});
  @override Widget build(BuildContext context) => Card(
    elevation: 2,
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Welcome, ' + (student['name'] ?? 'Student').toString(), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.primary)),
        const SizedBox(height: 18),
        _Detail('Roll No', student['roll_no']),
        _Detail('Class', student['class']),
        _Detail('Board', student['board']),
        _Detail('Test Series', student['test_series_name']),
      ]),
    ),
  );
}

class _Detail extends StatelessWidget {
  final String label; final dynamic value;
  const _Detail(this.label, this.value);
  @override Widget build(BuildContext context) {
    final text = value?.toString() ?? '';
    return Padding(padding: const EdgeInsets.only(bottom: 9), child: Text(label + ': ' + (text.isEmpty ? '-' : text), style: const TextStyle(fontSize: 16, color: Color(0xFF374151))));
  }
}

class _SummaryCard extends StatelessWidget {
  final String title; final String value; final IconData icon;
  const _SummaryCard({required this.title, required this.value, required this.icon});
  @override Widget build(BuildContext context) => Card(
    elevation: 2,
    child: Padding(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, color: AppColors.primary), const SizedBox(height: 12), Text(title, style: const TextStyle(color: Color(0xFF6B7280))), const SizedBox(height: 4),
      Text(value, style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w800, color: AppColors.primary)),
    ])),
  );
}

class _SectionCard extends StatelessWidget {
  final String title; final Widget child;
  const _SectionCard({required this.title, required this.child});
  @override Widget build(BuildContext context) => Card(
    elevation: 2,
    child: Padding(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.primary)), const SizedBox(height: 12), child,
    ])),
  );
}
