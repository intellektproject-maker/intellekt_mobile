import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/colors.dart';
import '../../providers/test_batch_provider.dart';

class TestBatchAttendanceScreen extends StatelessWidget {
  const TestBatchAttendanceScreen({super.key});

  String _formatDate(dynamic value) {
    if (value == null) return '-';
    final parsed = DateTime.tryParse(value.toString());
    if (parsed == null) return value.toString().split('T').first;
    final local = parsed.toLocal();
    return '${local.day.toString().padLeft(2, '0')}-${local.month.toString().padLeft(2, '0')}-${local.year}';
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TestBatchProvider>();
    final records = provider.attendance;
    final present = records.where((item) => item['status']?.toString().toLowerCase() == 'present').length;
    final total = records.length;

    return Scaffold(
      backgroundColor: const Color(0xFFECECEF),
      appBar: AppBar(backgroundColor: AppColors.primary, foregroundColor: Colors.white, title: const Text('Attendance')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            children: [
              Expanded(child: _SummaryCard(title: 'Attendance', value: '${provider.attendancePercentage.toStringAsFixed(1)}%')),
              const SizedBox(width: 12),
              Expanded(child: _SummaryCard(title: 'Classes', value: '${present} / ${total}')),
            ],
          ),
          const SizedBox(height: 20),
          const Text('Attendance Records', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800, color: AppColors.primary)),
          const SizedBox(height: 12),
          if (records.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('No attendance records are available yet.', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF6B7280))),
              ),
            )
          else
            ...records.map((item) => Card(
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: Icon(
                  item['status']?.toString().toLowerCase() == 'present' ? Icons.check_circle_outline : Icons.cancel_outlined,
                  color: item['status']?.toString().toLowerCase() == 'present' ? Colors.green : Colors.red,
                ),
                title: Text(item['test_code']?.toString() ?? '-', style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.primary)),
                subtitle: Text('Writing Date: ${_formatDate(item['attendance_date'])}'),
                trailing: Text(
                  item['status']?.toString() ?? '-',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: item['status']?.toString().toLowerCase() == 'present' ? Colors.green.shade700 : Colors.red.shade700,
                  ),
                ),
              ),
            )),
          if (total > 0) ...[
            const SizedBox(height: 8),
            Text(
              'Calculated from ${present} attended test${present == 1 ? '' : 's'} out of ${total} recorded test${total == 1 ? '' : 's'}.',
              style: const TextStyle(color: Color(0xFF6B7280), fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  const _SummaryCard({required this.title, required this.value});

  @override
  Widget build(BuildContext context) => Card(
    elevation: 2,
    child: Padding(
      padding: const EdgeInsets.all(17),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(color: Color(0xFF6B7280))),
        const SizedBox(height: 7),
        Text(value, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800, color: AppColors.primary)),
      ]),
    ),
  );
}
