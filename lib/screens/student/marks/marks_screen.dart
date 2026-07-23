import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../services/student/marks_service.dart';

class MarksScreen extends StatefulWidget {
  final String rollNo;

  const MarksScreen({
    super.key,
    required this.rollNo,
  });

  @override
  State<MarksScreen> createState() => _MarksScreenState();
}

class _MarksScreenState extends State<MarksScreen> {
  bool _isLoading = true;

  List<Map<String, dynamic>> _mathsMarks = [];
  List<Map<String, dynamic>> _physicsMarks = [];

  @override
  void initState() {
    super.initState();
    _loadMarks();
  }

  Future<void> _loadMarks() async {
    final marks = await MarksService.getMarks(widget.rollNo);

    if (!mounted) return;

    setState(() {
      _mathsMarks = marks
          .where(
            (mark) =>
        mark['subject_name']
            ?.toString()
            .toLowerCase() ==
            'maths',
      )
          .toList();

      _physicsMarks = marks
          .where(
            (mark) =>
        mark['subject_name']
            ?.toString()
            .toLowerCase() ==
            'physics',
      )
          .toList();

      _isLoading = false;
    });
  }

  String _formatDate(dynamic dateValue) {
    final date = DateTime.tryParse(
      dateValue?.toString() ?? '',
    );

    if (date == null) {
      return '-';
    }

    return DateFormat('dd/MM/yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFECECEF),

      appBar: AppBar(
        backgroundColor: const Color(0xFF1D4ED8),
        foregroundColor: Colors.white,
        elevation: 0,

        title: const Text(
          'INTELLEKT',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 32,
        ),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            const Text(
              'Marks',
              style: TextStyle(
                color: Color(0xFF1746C7),
                fontSize: 36,
                fontWeight: FontWeight.w800,
              ),
            ),

            const SizedBox(height: 38),

            _SubjectMarksSection(
              title: 'Mathematics',
              marks: _mathsMarks,
              formatDate: _formatDate,

              onViewReport: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Mathematics detailed report will be added next.',
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 36),

            _SubjectMarksSection(
              title: 'Physics',
              marks: _physicsMarks,
              formatDate: _formatDate,

              onViewReport: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Physics detailed report will be added next.',
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

class _SubjectMarksSection extends StatelessWidget {
  final String title;

  final List<Map<String, dynamic>> marks;

  final VoidCallback onViewReport;

  final String Function(dynamic) formatDate;

  const _SubjectMarksSection({
    required this.title,
    required this.marks,
    required this.onViewReport,
    required this.formatDate,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF1746C7),
            fontSize: 28,
            fontWeight: FontWeight.w800,
          ),
        ),

        const SizedBox(height: 22),

        SizedBox(
          height: 58,

          child: ElevatedButton(
            onPressed: onViewReport,

            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1D56E7),
              foregroundColor: Colors.white,
              elevation: 0,

              padding: const EdgeInsets.symmetric(
                horizontal: 30,
              ),

              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),

            child: const Text(
              'View Report',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),

        const SizedBox(height: 30),

        Container(
          width: double.infinity,

          padding: const EdgeInsets.all(18),

          decoration: BoxDecoration(
            color: Colors.white,

            borderRadius: BorderRadius.circular(16),

            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: 0.08,
                ),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),

          child: marks.isEmpty
              ? const SizedBox(
            height: 150,

            child: Center(
              child: Text(
                'No records found',
                style: TextStyle(
                  color: Colors.grey,
                ),
              ),
            ),
          )
              : SingleChildScrollView(
            scrollDirection: Axis.horizontal,

            child: _MarksTable(
              marks: marks,
              formatDate: formatDate,
            ),
          ),
        ),
      ],
    );
  }
}

class _MarksTable extends StatelessWidget {
  final List<Map<String, dynamic>> marks;

  final String Function(dynamic) formatDate;

  const _MarksTable({
    required this.marks,
    required this.formatDate,
  });

  @override
  Widget build(BuildContext context) {
    return DataTable(
      headingRowColor: WidgetStateProperty.all(
        const Color(0xFFE5E7EB),
      ),

      border: TableBorder.all(
        color: Colors.black54,
        width: 1,
      ),

      columnSpacing: 24,

      horizontalMargin: 14,

      dataRowMinHeight: 58,

      dataRowMaxHeight: 80,

      headingTextStyle: const TextStyle(
        color: Colors.black,
        fontWeight: FontWeight.bold,
        fontSize: 15,
      ),

      dataTextStyle: const TextStyle(
        color: Colors.black87,
        fontSize: 14,
      ),

      columns: const [
        DataColumn(
          label: Text('Test Code'),
        ),

        DataColumn(
          label: Text('Test Date'),
        ),

        DataColumn(
          label: Text('Marks Obtained'),
        ),

        DataColumn(
          label: Text('Total Marks'),
        ),

        DataColumn(
          label: Text('Comments'),
        ),
      ],

      rows: marks.map(
            (mark) {
          final obtainedMarks =
              mark['marks_obtained']?.toString() ?? '-';

          final displayMarks =
          obtainedMarks.toUpperCase() == 'A'
              ? 'Absent'
              : obtainedMarks;

          return DataRow(
            cells: [
              DataCell(
                Text(
                  mark['test_code']?.toString() ?? '-',
                ),
              ),

              DataCell(
                Text(
                  formatDate(
                    mark['test_date'],
                  ),
                ),
              ),

              DataCell(
                Text(displayMarks),
              ),

              DataCell(
                Text(
                  mark['total_marks']?.toString() ?? '-',
                ),
              ),

              DataCell(
                SizedBox(
                  width: 130,

                  child: Text(
                    mark['comments']?.toString() ?? '-',
                  ),
                ),
              ),
            ],
          );
        },
      ).toList(),
    );
  }
}