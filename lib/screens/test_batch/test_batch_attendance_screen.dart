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
          const SizedBox(height: 4),
          const Text(
            'Select Subject',
            style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800, color: AppColors.primary),
          ),
          const SizedBox(height: 12),
          _SubjectCard(
            subject: 'Mathematics',
            icon: Icons.calculate_outlined,
            records: _subjectRecords(records, 'Mathematics'),
            formatDate: _formatDate,
          ),
          const SizedBox(height: 14),
          _SubjectCard(
            subject: 'Physics',
            icon: Icons.science_outlined,
            records: _subjectRecords(records, 'Physics'),
            formatDate: _formatDate,
          ),        ],
      ),
    );
  }
}

class _SubjectCard extends StatelessWidget {
  final String subject;
  final IconData icon;
  final List<Map<String, dynamic>> records;
  final String Function(dynamic) formatDate;

  const _SubjectCard({required this.subject, required this.icon, required this.records, required this.formatDate});

  @override
  Widget build(BuildContext context) {
    final present = records.where((item) => item['status']?.toString().toLowerCase() == 'present').length;
    final total = records.length;
    final percentage = total > 0 ? present / total * 100 : 0.0;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      elevation: 3,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => _SubjectAttendanceScreen(subject: subject, records: records, formatDate: formatDate),
          ),
        ),
        mouseCursor: SystemMouseCursors.click,
        borderRadius: BorderRadius.circular(18),
        splashColor: AppColors.primary.withValues(alpha: 0.08),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 32),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(subject, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.primary)),
                    const SizedBox(height: 5),
                    Text(
                      records.isEmpty ? 'No attendance records' : present.toString() + ' / ' + total.toString() + ' tests attended',
                      style: const TextStyle(color: Color(0xFF6B7280)),
                    ),
                    if (records.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 5),
                        child: Text(percentage.toStringAsFixed(1) + '%', style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary)),
                      ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.primary, size: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _SubjectAttendanceScreen extends StatelessWidget {
  final String subject;
  final List<Map<String, dynamic>> records;
  final String Function(dynamic) formatDate;

  const _SubjectAttendanceScreen({required this.subject, required this.records, required this.formatDate});

  @override
  Widget build(BuildContext context) {
    final present = records.where((item) => item['status']?.toString().toLowerCase() == 'present').length;
    final total = records.length;
    final percentage = total > 0 ? present / total * 100 : 0.0;

    return Scaffold(
      backgroundColor: const Color(0xFFECECEF),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: Text(subject + ' Attendance'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 4),
          const SizedBox(height: 22),
          Text(subject + ' Attendance Records', style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800, color: AppColors.primary)),
          const SizedBox(height: 12),
          if (records.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('No attendance records are available yet.', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF6B7280))),
              ),
            )
          else
            ...records.map((item) {
              final isPresent = item['status']?.toString().toLowerCase() == 'present';
              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: Icon(isPresent ? Icons.check_circle_outline : Icons.cancel_outlined, color: isPresent ? Colors.green : Colors.red),
                  title: Text(item['test_code']?.toString() ?? '-', style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.primary)),
                  subtitle: Text('Writing Date: ' + formatDate(item['attendance_date'])),
                  trailing: Text(item['status']?.toString() ?? '-', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: isPresent ? Colors.green.shade700 : Colors.red.shade700)),
                ),
              );
            }),
        ],
      ),
    );
  }
}

  List<Map<String, dynamic>> _subjectRecords(
    List<Map<String, dynamic>> records,
    String subject,
  ) {
    return records.where((item) {
      final name = item['subject_name']?.toString().toLowerCase() ?? '';
      final code = item['test_code']?.toString().toUpperCase() ?? '';
      if (name.isNotEmpty) {
        return subject == 'Mathematics' ? name.contains('math') : name.contains('physics');
      }
      if (code.length >= 4) {
        return subject == 'Mathematics' ? code[3] == 'M' : code[3] == 'P';
      }
      return false;
    }).toList();
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
