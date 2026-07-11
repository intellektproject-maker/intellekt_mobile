import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/colors.dart';
import '../../../routes/app_routes.dart';

class AttendanceScreen extends StatelessWidget {
  final String facultyId;

  const AttendanceScreen({
    super.key,
    required this.facultyId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Attendance Management'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _AttendanceCard(
              title: 'Enter Attendance',
              description: 'Mark daily attendance for students.',
              icon: Icons.how_to_reg_outlined,
              onTap: () {
                context.push(
                  '${AppRoutes.facultyEnterAttendance}'
                      '?id=${Uri.encodeQueryComponent(facultyId)}',
                );
              },
            ),
            const SizedBox(height: 20),
            _AttendanceCard(
              title: 'Manage Attendance',
              description:
              'View, edit and download attendance report.',
              icon: Icons.manage_accounts_outlined,
              onTap: () {
                context.push(
                  '${AppRoutes.facultyManageAttendance}'
                      '?id=${Uri.encodeQueryComponent(facultyId)}',
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _AttendanceCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final VoidCallback onTap;

  const _AttendanceCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Colors.grey.shade200,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              Icon(
                icon,
                size: 40,
                color: AppColors.primary,
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}