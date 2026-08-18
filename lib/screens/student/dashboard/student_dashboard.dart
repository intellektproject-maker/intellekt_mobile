import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/colors.dart';
import '../../../core/widgets/intellekt_wordmark.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/student/marks_provider.dart';
import '../../../providers/student/student_provider.dart';
import '../../../providers/student/test_schedule_provider.dart';
import '../../../routes/app_routes.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  String _rollNo = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final authenticatedId =
    context.read<AuthProvider>().user?.id.trim().toUpperCase();

    if (authenticatedId == null || authenticatedId.isEmpty) {
      return;
    }

    if (_rollNo != authenticatedId) {
      _rollNo = authenticatedId;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        context.read<StudentProvider>().loadStudent(_rollNo);
        context.read<TestScheduleProvider>().loadTests(_rollNo);
        context.read<MarksProvider>().loadMarks(_rollNo);
      });
    }
  }

  void _openMarks() {
    context.push('${AppRoutes.studentMarks}?roll=$_rollNo');
  }

  void _openAttendance() {
    context.push('${AppRoutes.studentAttendance}?roll=$_rollNo');
  }

  void _openTestSchedule() {
    context.push('${AppRoutes.studentTestSchedule}?roll=$_rollNo');
  }

  void _openFee() {
    context.push('${AppRoutes.studentFee}?roll=$_rollNo');
  }

  void _openUsefulLinks() {
    context.push(AppRoutes.studentUsefulLinks);
  }

  void _openRequestPdf() {
    context.push('${AppRoutes.studentRequestPdf}?roll=$_rollNo');
  }

  @override
  Widget build(BuildContext context) {
    final studentProvider = context.watch<StudentProvider>();
    final marksProvider = context.watch<MarksProvider>();
    final testScheduleProvider = context.watch<TestScheduleProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFECECEF),
      drawer: _StudentDrawer(rollNo: _rollNo),
      body: SafeArea(
        child: _buildBody(
          studentProvider,
          marksProvider,
          testScheduleProvider,
        ),
      ),
    );
  }

  Widget _buildBody(
      StudentProvider studentProvider,
      MarksProvider marksProvider,
      TestScheduleProvider testScheduleProvider,
      ) {
    if (studentProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (studentProvider.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            studentProvider.error!,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final student = studentProvider.student;

    if (student == null) {
      return const Center(child: Text('Student data not found'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Builder(
                builder: (context) => IconButton(
                  onPressed: () => Scaffold.of(context).openDrawer(),
                  tooltip: 'Open menu',
                  padding: const EdgeInsets.only(right: 15, top: 1),
                  constraints: const BoxConstraints(),
                  icon: const Icon(
                    Icons.menu_rounded,
                    size: 32,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const Expanded(
                child: Text(
                  'Student\nDashboard',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 40,
                    height: 0.95,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 35),
          _StudentProfileCard(student: student),
          const SizedBox(height: 28),
          _DashboardCard(
            icon: Icons.assignment_turned_in_outlined,
            title: 'Attendance',
            value: '94%',
            subtitle: 'Total Attendance',
            onTap: _openAttendance,
          ),
          const SizedBox(height: 22),
          _DashboardCard(
            icon: Icons.menu_book_outlined,
            title: 'Marks',
            value: marksProvider.isLoading
                ? 'Loading...'
                : marksProvider.error != null
                ? 'Unavailable'
                : marksProvider.dashboardValue,
            subtitle: 'Maths & Physics Avg',
            showNotification: true,
            onTap: _openMarks,
          ),
          const SizedBox(height: 22),
          _DashboardCard(
            icon: Icons.calendar_month_outlined,
            title: 'Test Schedule',
            value: testScheduleProvider.isLoading
                ? '...'
                : testScheduleProvider.hasError
                ? 'Unavailable'
                : testScheduleProvider.tests.length.toString(),
            subtitle: 'Upcoming Tests',
            showNotification: true,
            onTap: _openTestSchedule,
          ),
          const SizedBox(height: 22),
          _DashboardCard(
            icon: Icons.account_balance_wallet_outlined,
            title: 'Fee',
            value: 'View',
            subtitle: 'Fee Details',
            onTap: _openFee,
          ),
          const SizedBox(height: 22),
          _DashboardCard(
            icon: Icons.link,
            title: 'Useful Links',
            value: 'Open',
            subtitle: 'Quick Access',
            onTap: _openUsefulLinks,
          ),
          const SizedBox(height: 22),
          _DashboardCard(
            icon: Icons.description_outlined,
            title: 'Request PDF',
            value: 'Open',
            subtitle: 'Request answer sheet',
            onTap: _openRequestPdf,
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}

class _StudentProfileCard extends StatelessWidget {
  final Map<String, dynamic> student;

  const _StudentProfileCard({required this.student});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome, ${student['name'] ?? 'Student'}',
            style: const TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 24),
          _StudentDetail(
            label: 'Roll No',
            value: student['roll_no']?.toString() ?? '-',
          ),
          _StudentDetail(
            label: 'Name',
            value: student['name']?.toString() ?? '-',
          ),
          _StudentDetail(
            label: 'Class',
            value: student['class']?.toString() ?? '-',
          ),
          _StudentDetail(
            label: 'Board',
            value: student['board']?.toString() ?? '-',
          ),
          _StudentDetail(
            label: 'Phone',
            value: student['phone']?.toString() ?? '-',
          ),
          _StudentDetail(
            label: 'Email',
            value: student['email']?.toString() ?? '-',
          ),
          _StudentDetail(
            label: 'School Name',
            value: student['school_name']?.toString() ?? '-',
            showBottomSpace: false,
          ),
        ],
      ),
    );
  }
}

class _StudentDetail extends StatelessWidget {
  final String label;
  final String value;
  final bool showBottomSpace;

  const _StudentDetail({
    required this.label,
    required this.value,
    this.showBottomSpace = true,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: showBottomSpace ? 14 : 0),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(
            fontSize: 16,
            color: Color(0xFF4B5563),
            height: 1.4,
          ),
          children: [
            TextSpan(text: '$label: '),
            TextSpan(
              text: value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF374151),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String subtitle;
  final bool showNotification;
  final VoidCallback? onTap;

  const _DashboardCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
    this.showNotification = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: _cardDecoration(),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, size: 27, color: AppColors.primary),
                  const SizedBox(height: 18),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
              const Positioned(
                top: 0,
                right: 0,
                child: Text(
                  'Open',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ),
              if (showNotification)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Transform.translate(
                    offset: const Offset(7, -7),
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StudentDrawer extends StatelessWidget {
  final String rollNo;

  const _StudentDrawer({required this.rollNo});

  Future<void> _signOut(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text(
          'You will need your Student ID and password to sign in again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;
    await context.read<AuthProvider>().logout();
    if (context.mounted) context.go(AppRoutes.login);
  }

  void _go(BuildContext context, String route) {
    Navigator.pop(context);
    context.push(route);
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(28)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 30, 18, 26),
              decoration: const BoxDecoration(
                color: Color(0xFFF0F2FD),
                borderRadius: BorderRadius.only(
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Row(
                children: [
                  const Expanded(child: IntellektWordmark(fontSize: 31)),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                    color: AppColors.primary,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _DrawerItem(
              icon: Icons.dashboard_rounded,
              label: 'Dashboard',
              selected: true,
              onTap: () => Navigator.pop(context),
            ),
            _DrawerItem(
              icon: Icons.assignment_turned_in_outlined,
              label: 'Attendance',
              onTap: () => _go(
                context,
                '${AppRoutes.studentAttendance}?roll=$rollNo',
              ),
            ),
            _DrawerItem(
              icon: Icons.menu_book_rounded,
              label: 'Marks',
              onTap: () =>
                  _go(context, '${AppRoutes.studentMarks}?roll=$rollNo'),
            ),
            _DrawerItem(
              icon: Icons.calendar_month_rounded,
              label: 'Test Schedule',
              onTap: () => _go(
                context,
                '${AppRoutes.studentTestSchedule}?roll=$rollNo',
              ),
            ),
            _DrawerItem(
              icon: Icons.account_balance_wallet_outlined,
              label: 'Fee',
              onTap: () =>
                  _go(context, '${AppRoutes.studentFee}?roll=$rollNo'),
            ),
            _DrawerItem(
              icon: Icons.link_rounded,
              label: 'Useful Links',
              onTap: () => _go(context, AppRoutes.studentUsefulLinks),
            ),
            _DrawerItem(
              icon: Icons.description_outlined,
              label: 'Request PDF',
              onTap: () => _go(
                context,
                '${AppRoutes.studentRequestPdf}?roll=$rollNo',
              ),
            ),
            const Spacer(),
            const Divider(height: 1, indent: 20, endIndent: 20),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 20),
              child: _DrawerItem(
                icon: Icons.logout_rounded,
                label: 'Sign Out',
                foregroundColor: const Color(0xFFB3261E),
                onTap: () => _signOut(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool selected;
  final Color foregroundColor;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
    this.foregroundColor = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: ListTile(
        onTap: onTap,
        selected: selected,
        selectedTileColor: const Color(0xFFE8ECFD),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        leading: Icon(icon, color: foregroundColor),
        title: Text(
          label,
          style: TextStyle(
            color: foregroundColor,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
        trailing: selected
            ? const Icon(Icons.chevron_right_rounded, color: AppColors.primary)
            : null,
      ),
    );
  }
}

BoxDecoration _cardDecoration() {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.12),
        blurRadius: 8,
        offset: const Offset(0, 4),
      ),
    ],
  );
}
