import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/colors.dart';
import '../../../providers/student/student_provider.dart';
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

    final roll =
        GoRouterState.of(context).uri.queryParameters['roll'] ?? 'IA001';

    if (_rollNo != roll) {
      _rollNo = roll;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        context.read<StudentProvider>().loadStudent(_rollNo);
      });
    }
  }
  void _openMarks() {
    context.push(
      '${AppRoutes.studentMarks}?roll=$_rollNo',
    );
  }
  void _openAttendance() {
    context.push(
      '${AppRoutes.studentAttendance}?roll=$_rollNo',
    );
  }

  @override
  Widget build(BuildContext context) {
    final studentProvider = context.watch<StudentProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFECECEF),
      body: SafeArea(
        child: _buildBody(studentProvider),
      ),
    );
  }

  Widget _buildBody(StudentProvider studentProvider) {
    if (studentProvider.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
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
      return const Center(
        child: Text('Student data not found'),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 30,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Student\nDashboard',
            style: TextStyle(
              color: Color(0xFF1769E0),
              fontSize: 42,
              height: 0.95,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 35),

          _StudentProfileCard(
            student: student,
          ),

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
            value: 'M: 45.4 | P: 42.8',
            subtitle: 'Maths & Physics Avg',
            showNotification: true,
            onTap: _openMarks,
          ),

          const SizedBox(height: 22),

          const _DashboardCard(
            icon: Icons.calendar_month_outlined,
            title: 'Test Schedule',
            value: '2',
            subtitle: 'Upcoming Tests',
            showNotification: true,
          ),

          const SizedBox(height: 22),

          const _DashboardCard(
            icon: Icons.account_balance_wallet_outlined,
            title: 'Fee',
            value: 'View',
            subtitle: 'Fee Details',
          ),

          const SizedBox(height: 22),

          const _DashboardCard(
            icon: Icons.link,
            title: 'Useful Links',
            value: 'Open',
            subtitle: 'Quick Access',
          ),

          const SizedBox(height: 22),

          const _DashboardCard(
            icon: Icons.description_outlined,
            title: 'Request PDF',
            value: 'Open',
            subtitle: 'Request answer sheet',
          ),

          const SizedBox(height: 30),
        ],
      ),
    );
  }
}

class _StudentProfileCard extends StatelessWidget {
  final Map<String, dynamic> student;

  const _StudentProfileCard({
    required this.student,
  });

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
      padding: EdgeInsets.only(
        bottom: showBottomSpace ? 14 : 0,
      ),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(
            fontSize: 16,
            color: Color(0xFF4B5563),
            height: 1.4,
          ),
          children: [
            TextSpan(
              text: '$label: ',
            ),
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
                  Icon(
                    icon,
                    size: 27,
                    color: AppColors.primary,
                  ),

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
                      color: Color(0xFF1769E0),
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