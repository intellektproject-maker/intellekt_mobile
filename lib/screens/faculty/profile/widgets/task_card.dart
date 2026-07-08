import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../models/faculty_task_model.dart';

class TaskCard extends StatelessWidget {
  final FacultyTaskModel task;
  final bool showCheckbox;
  final bool showAdminActions;
  final VoidCallback? onToggle;
  final VoidCallback? onReassign;
  final VoidCallback? onDelete;

  const TaskCard({
    super.key,
    required this.task,
    this.showCheckbox = false,
    this.showAdminActions = false,
    this.onToggle,
    this.onReassign,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _getBackgroundColor(),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getBorderColor(),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showCheckbox) ...[
                Checkbox(
                  value: task.isCompleted,
                  onChanged: (_) {
                    onToggle?.call();
                  },
                ),
                const SizedBox(width: 8),
              ],

              Expanded(
                child: _buildTaskDetails(),
              ),
            ],
          ),

          if (showAdminActions) ...[
            const SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: onReassign,
                  child: const Text(
                    'Reassign',
                    style: TextStyle(
                      color: Color(0xFF2563EB),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: onDelete,
                  child: const Text(
                    'Delete',
                    style: TextStyle(
                      color: Color(0xFFDC2626),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTaskDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${task.facultyName} (${task.facultyId})',
          style: const TextStyle(
            color: Color(0xFF1F2937),
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),

        const SizedBox(height: 8),

        _buildDetail(
          label: 'Class',
          value: task.className,
        ),

        _buildDetail(
          label: 'Task Type',
          value: task.taskType,
        ),

        _buildDetail(
          label: 'Priority',
          value: task.priority,
        ),

        _buildDetail(
          label: 'Test Code',
          value: task.subjectName.isEmpty
              ? '-'
              : task.subjectName,
        ),

        _buildDetail(
          label: 'Total Test Note',
          value: task.totalTestNote.isEmpty
              ? '-'
              : task.totalTestNote,
        ),

        _buildDetail(
          label: 'Due Date',
          value: _formatDate(task.dueDate),
        ),

        _buildDetail(
          label: 'Other Tasks',
          value: task.otherTasks.isEmpty
              ? '-'
              : task.otherTasks,
        ),

        if (task.isCompleted) ...[
          const SizedBox(height: 6),
          Text(
            task.completedAt != null
                ? 'Completed on ${_formatDate(task.completedAt)}'
                : 'Completed',
            style: const TextStyle(
              color: Color(0xFF15803D),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],

        const SizedBox(height: 6),

        Text(
          'Assigned by: ${task.assignedBy}',
          style: const TextStyle(
            color: Color(0xFF6B7280),
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _buildDetail({
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(
            color: Color(0xFF374151),
            fontSize: 14,
            height: 1.4,
          ),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }

  String _formatDate(String? date) {
    if (date == null || date.isEmpty) {
      return '-';
    }

    final parsedDate = DateTime.tryParse(date);

    if (parsedDate == null) {
      return '-';
    }

    return DateFormat.yMd().format(parsedDate);
  }

  Color _getBackgroundColor() {
    if (task.taskType == 'Daily') {
      return const Color(0xFFFEF2F2);
    }

    if (task.isOverdue) {
      return const Color(0xFFFEF2F2);
    }

    if (task.isDueToday) {
      return const Color(0xFFFFFBEB);
    }

    return const Color(0xFFF9FAFB);
  }

  Color _getBorderColor() {
    if (task.taskType == 'Daily') {
      return const Color(0xFFFECACA);
    }

    if (task.isOverdue) {
      return const Color(0xFFFECACA);
    }

    if (task.isDueToday) {
      return const Color(0xFFFDE68A);
    }

    return const Color(0xFFE5E7EB);
  }
}