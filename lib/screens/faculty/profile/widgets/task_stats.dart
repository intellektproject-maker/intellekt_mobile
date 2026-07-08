import 'package:flutter/material.dart';

import '../../../../models/faculty_task_model.dart';

class TaskStats extends StatelessWidget {
  final List<FacultyTaskModel> tasks;
  final String prefix;

  const TaskStats({
    super.key,
    required this.tasks,
    required this.prefix,
  });

  @override
  Widget build(BuildContext context) {
    final pending =
        tasks.where((task) => !task.isCompleted).length;

    final completed =
        tasks.where((task) => task.isCompleted).length;

    final overdue =
        tasks.where((task) => task.isOverdue).length;

    final dueToday =
        tasks.where((task) => task.isDueToday).length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 700;

        if (isWide) {
          return Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  title: '$prefix Pending',
                  count: pending,
                  backgroundColor:
                  const Color(0xFFDBEAFE),
                  textColor:
                  const Color(0xFF1E40AF),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  title: '$prefix Completed',
                  count: completed,
                  backgroundColor:
                  const Color(0xFFDCFCE7),
                  textColor:
                  const Color(0xFF166534),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  title: '$prefix Overdue',
                  count: overdue,
                  backgroundColor:
                  const Color(0xFFFEE2E2),
                  textColor:
                  const Color(0xFF991B1B),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  title: '$prefix Due Today',
                  count: dueToday,
                  backgroundColor:
                  const Color(0xFFFEF3C7),
                  textColor:
                  const Color(0xFF92400E),
                ),
              ),
            ],
          );
        }

        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    title: '$prefix Pending',
                    count: pending,
                    backgroundColor:
                    const Color(0xFFDBEAFE),
                    textColor:
                    const Color(0xFF1E40AF),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    title: '$prefix Completed',
                    count: completed,
                    backgroundColor:
                    const Color(0xFFDCFCE7),
                    textColor:
                    const Color(0xFF166534),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    title: '$prefix Overdue',
                    count: overdue,
                    backgroundColor:
                    const Color(0xFFFEE2E2),
                    textColor:
                    const Color(0xFF991B1B),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    title: '$prefix Due Today',
                    count: dueToday,
                    backgroundColor:
                    const Color(0xFFFEF3C7),
                    textColor:
                    const Color(0xFF92400E),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard({
    required String title,
    required int count,
    required Color backgroundColor,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: textColor,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            count.toString(),
            style: TextStyle(
              color: textColor,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}