import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/test_batch_provider.dart';
import '../../routes/app_routes.dart';

class TestBatchDashboard extends StatefulWidget {
  const TestBatchDashboard({super.key});

  @override
  State<TestBatchDashboard> createState() => _TestBatchDashboardState();
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
        actions: [
          IconButton(
            tooltip: 'Sign out',
            onPressed: _signOut,
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => provider.load(_rollNo),
        child: provider.isLoading && provider.student == null
            ? ListView(
                children: const [
                  SizedBox(height: 300),
                  Center(child: CircularProgressIndicator()),
                ],
              )
            : provider.error != null && provider.student == null
                ? ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      const SizedBox(height: 180),
                      Text(
                        'Unable to load Test Batch data.\nPlease refresh and try again.',
                        textAlign: TextAlign.center,
                      ),
                    ],
                  )
                : ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      _ProfileCard(student: provider.student ?? {}),
                      const SizedBox(height: 14),
                      Card(
                        elevation: 2,
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                          leading: const CircleAvatar(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            child: Icon(Icons.app_registration_outlined),
                          ),
                          title: const Text(
                            'Test Registration',
                            style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.primary),
                          ),
                          subtitle: const Text(
                            'View posted tests and register for your test date and slot.',
                          ),
                          trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.primary),
                          onTap: () => context.push(AppRoutes.testBatchRegistration),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _AcademicSummaryLauncher(
                              title: 'Attendance',
                              value: '${provider.attendancePercentage.toStringAsFixed(1)}%',
                              icon: Icons.assignment_turned_in_outlined,
                              route: AppRoutes.testBatchAttendance,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _AcademicSummaryLauncher(
                              title: 'Marks',
                              value: '${provider.marks.length}',
                              icon: Icons.menu_book_outlined,
                              route: AppRoutes.testBatchMarks,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
      ),
    );
  }
}

class _AcademicSummaryLauncher extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final String route;

  const _AcademicSummaryLauncher({
    required this.title,
    required this.value,
    required this.icon,
    required this.route,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 2,
      child: InkWell(
        onTap: () => context.push(route),
        mouseCursor: SystemMouseCursors.click,
        borderRadius: BorderRadius.circular(16),
        splashColor: AppColors.primary.withValues(alpha: 0.08),
        highlightColor: AppColors.primary.withValues(alpha: 0.04),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: AppColors.primary),
              const SizedBox(height: 10),
              Text(title, style: const TextStyle(color: Color(0xFF6B7280))),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final Map<String, dynamic> student;

  const _ProfileCard({required this.student});

  @override
  Widget build(BuildContext context) => Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome, ' + (student['name'] ?? 'Student').toString(),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 18),
              _Detail('Roll No', student['roll_no']),
              _Detail('Class', student['class']),
              _Detail('Board', student['board']),
              _Detail('Test Series', student['test_series_name']),
            ],
          ),
        ),
      );
}

class _Detail extends StatelessWidget {
  final String label;
  final dynamic value;

  const _Detail(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    final text = value?.toString() ?? '';
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Text(
        label + ': ' + (text.isEmpty ? '-' : text),
        style: const TextStyle(fontSize: 16, color: Color(0xFF374151)),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) => Card(
        margin: EdgeInsets.zero,
        elevation: 1,
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: AppColors.primary),
              const SizedBox(height: 10),
              Text(title, style: const TextStyle(color: Color(0xFF6B7280))),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      );
}
