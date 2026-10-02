import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/colors.dart';
import '../../providers/test_batch_provider.dart';
import '../../routes/app_routes.dart';

class TestBatchAcademicOverviewScreen extends StatelessWidget {
  const TestBatchAcademicOverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TestBatchProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFECECEF),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('Academic Overview'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Academic Overview',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.primary),
          ),
          const SizedBox(height: 8),
          const Text(
            'Choose what you want to review.',
            style: TextStyle(fontSize: 15, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 24),
          _OverviewCard(
            icon: Icons.menu_book_rounded,
            title: 'Marks',
            description: 'View subject-wise marks, totals and percentages.',
            value: '${provider.marks.length} record${provider.marks.length == 1 ? '' : 's'}',
            onTap: () => context.push(AppRoutes.testBatchMarks),
          ),
          const SizedBox(height: 16),
          _OverviewCard(
            icon: Icons.fact_check_rounded,
            title: 'Attendance',
            description: 'View attendance percentage and test-wise records.',
            value: '${provider.attendancePercentage.toStringAsFixed(1)}%',
            onTap: () => context.push(AppRoutes.testBatchAttendance),
          ),
        ],
      ),
    );
  }
}

class _OverviewCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String value;
  final VoidCallback onTap;

  const _OverviewCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      elevation: 3,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        splashColor: AppColors.primary.withValues(alpha: 0.08),
        highlightColor: AppColors.primary.withValues(alpha: 0.04),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(icon, color: AppColors.primary, size: 29),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.primary)),
                    const SizedBox(height: 5),
                    Text(description, style: const TextStyle(color: Color(0xFF6B7280), height: 1.35)),
                    const SizedBox(height: 8),
                    Text(value, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right_rounded, color: AppColors.primary, size: 30),
            ],
          ),
        ),
      ),
    );
  }
}
