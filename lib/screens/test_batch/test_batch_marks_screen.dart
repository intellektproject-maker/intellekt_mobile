import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/colors.dart';
import '../../providers/test_batch_provider.dart';

class TestBatchMarksScreen extends StatelessWidget {
  const TestBatchMarksScreen({super.key});

  List<Map<String, dynamic>> _subjectMarks(
    List<Map<String, dynamic>> marks,
    String subject,
  ) {
    final key = subject.toLowerCase();
    return marks.where((mark) {
      final name = mark['subject_name']?.toString().toLowerCase() ?? '';
      return name.contains(key);
    }).toList();
  }

  double _number(dynamic value) => double.tryParse(value?.toString() ?? '') ?? 0;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TestBatchProvider>();
    final marks = provider.marks;
    final totalObtained = marks.fold<double>(0, (sum, item) => sum + _number(item['marks_obtained']));
    final totalMaximum = marks.fold<double>(0, (sum, item) => sum + _number(item['total_marks']));
    final percentage = totalMaximum > 0 ? (totalObtained / totalMaximum) * 100 : 0.0;

    return Scaffold(
      backgroundColor: const Color(0xFFECECEF),
      appBar: AppBar(backgroundColor: AppColors.primary, foregroundColor: Colors.white, title: const Text('Marks')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            children: [
              Expanded(child: _SummaryCard(title: 'Total', value: '${_display(totalObtained)} / ${_display(totalMaximum)}')),
              const SizedBox(width: 12),
              Expanded(child: _SummaryCard(title: 'Percentage', value: '${percentage.toStringAsFixed(1)}%')),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'Select Subject',
            style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800, color: AppColors.primary),
          ),
          const SizedBox(height: 12),
          _SubjectCard(
            subject: 'Mathematics',
            icon: Icons.calculate_outlined,
            marks: _subjectMarks(marks, 'math'),
          ),
          const SizedBox(height: 14),
          _SubjectCard(
            subject: 'Physics',
            icon: Icons.science_outlined,
            marks: _subjectMarks(marks, 'physics'),
          ),
        ],
      ),
    );
  }

  String _display(double value) => value % 1 == 0 ? value.toInt().toString() : value.toStringAsFixed(2);
}

class _SubjectCard extends StatelessWidget {
  final String subject;
  final IconData icon;
  final List<Map<String, dynamic>> marks;

  const _SubjectCard({
    required this.subject,
    required this.icon,
    required this.marks,
  });

  double _number(dynamic value) =>
      double.tryParse(value?.toString() ?? '') ?? 0;

  String _display(double value) =>
      value % 1 == 0 ? value.toInt().toString() : value.toStringAsFixed(2);

  @override
  Widget build(BuildContext context) {
    final obtained = marks.fold<double>(
      0,
      (sum, item) => sum + _number(item['marks_obtained']),
    );
    final maximum = marks.fold<double>(
      0,
      (sum, item) => sum + _number(item['total_marks']),
    );
    final percentage = maximum > 0 ? obtained / maximum * 100 : 0.0;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      elevation: 3,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => _SubjectMarksScreen(
              subject: subject,
              marks: marks,
            ),
          ),
        ),
        mouseCursor: SystemMouseCursors.click,
        borderRadius: BorderRadius.circular(18),
        splashColor: AppColors.primary.withValues(alpha: 0.08),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(icon, color: AppColors.primary, size: 29),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subject,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      marks.isEmpty
                          ? 'No marks available'
                          : marks.length.toString() +
                              (marks.length == 1 ? ' test' : ' tests'),
                      style: const TextStyle(color: Color(0xFF6B7280)),
                    ),
                    if (marks.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 5),
                        child: Text(
                          _display(obtained) +
                              ' / ' +
                              _display(maximum) +
                              '  •  ' +
                              percentage.toStringAsFixed(1) +
                              '%',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.primary,
                size: 32,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SubjectMarksScreen extends StatelessWidget {
  final String subject;
  final List<Map<String, dynamic>> marks;

  const _SubjectMarksScreen({
    required this.subject,
    required this.marks,
  });

  double _number(dynamic value) =>
      double.tryParse(value?.toString() ?? '') ?? 0;

  String _display(double value) =>
      value % 1 == 0 ? value.toInt().toString() : value.toStringAsFixed(2);

  @override
  Widget build(BuildContext context) {
    final obtained = marks.fold<double>(
      0,
      (sum, item) => sum + _number(item['marks_obtained']),
    );
    final maximum = marks.fold<double>(
      0,
      (sum, item) => sum + _number(item['total_marks']),
    );
    final percentage = maximum > 0 ? obtained / maximum * 100 : 0.0;

    return Scaffold(
      backgroundColor: const Color(0xFFECECEF),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: Text(subject + ' Marks'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            children: [
              Expanded(
                child: _SummaryCard(
                  title: 'Total',
                  value: _display(obtained) + ' / ' + _display(maximum),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SummaryCard(
                  title: 'Percentage',
                  value: percentage.toStringAsFixed(1) + '%',
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Text(
            subject + ' Tests',
            style: const TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 12),
          if (marks.isEmpty)
            const _EmptyCard(message: 'No marks are available yet.')
          else
            ...marks.map((mark) => _MarkCard(mark: mark)),
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
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.primary)),
      ]),
    ),
  );
}

class _MarkCard extends StatelessWidget {
  final Map<String, dynamic> mark;
  const _MarkCard({required this.mark});

  double _number(dynamic value) => double.tryParse(value?.toString() ?? '') ?? 0;
  String _display(dynamic value) {
    final number = _number(value);
    return number % 1 == 0 ? number.toInt().toString() : number.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    final subject = mark['subject_name']?.toString() ?? 'Subject';
    final code = mark['test_code']?.toString() ?? '-';
    final hasInternal = mark['internal_marks'] != null;
    final hasExternal = mark['external_marks'] != null;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(17),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.assignment_outlined, color: AppColors.primary),
            const SizedBox(width: 10),
            Expanded(child: Text('${subject}  •  ${code}', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.primary))),
          ]),
          const SizedBox(height: 12),
          Text('${_display(mark['marks_obtained'])} / ${_display(mark['total_marks'])}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          if (hasInternal || hasExternal) ...[
            const SizedBox(height: 10),
            if (hasInternal) _DetailRow('Internal', _display(mark['internal_marks'])),
            if (hasExternal) _DetailRow('External', _display(mark['external_marks'])),
          ],
          if (mark['comments']?.toString().trim().isNotEmpty == true) ...[
            const SizedBox(height: 8),
            Text(mark['comments'].toString(), style: const TextStyle(color: Color(0xFF6B7280))),
          ],
        ]),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: const TextStyle(color: Color(0xFF6B7280))),
      Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
    ]),
  );
}

class _EmptyCard extends StatelessWidget {
  final String message;
  const _EmptyCard({required this.message});

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF6B7280))),
    ),
  );
}
