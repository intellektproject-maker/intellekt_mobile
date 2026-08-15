import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intellekt_mobile/core/constants/syllabus.dart';
import 'package:intl/intl.dart';

class ReportScreen extends StatelessWidget {
  final String subjectName;
  final List<Map<String, dynamic>> marks;

  const ReportScreen({
    super.key,
    required this.subjectName,
    required this.marks,
  });

  @override
  Widget build(BuildContext context) {
    final className = marks.isEmpty ? '12' : marks.first['class'];
    final board = marks.isEmpty ? 'STATE_BOARD' : marks.first['board'];
    final syllabus = AppSyllabus.chapters(
      subjectName: subjectName,
      className: className,
      board: board,
    );

    final grouped = <String, List<Map<String, dynamic>>>{};
    final combined = <Map<String, dynamic>>[];
    for (final mark in marks) {
      final chapter = _chapterCode(mark);
      if (chapter == 'Combined') {
        combined.add(mark);
      } else if (chapter != null) {
        grouped.putIfAbsent(chapter, () => []).add(mark);
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFECECEF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1D4ED8),
        foregroundColor: Colors.white,
        title: Text(subjectName),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        children: [
          Text(
            '$subjectName Detailed Report',
            style: const TextStyle(
              color: Color(0xFF1746C7),
              fontSize: 25,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          const Text('Chapter-wise understanding based on test marks.'),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0xFFD7DCE5)),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Chapter Progress',
                  style: TextStyle(
                    color: Color(0xFF1746C7),
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                ...syllabus.entries.map((chapter) => _ProgressRow(
                      chapterCode: chapter.key,
                      chapterName: chapter.value,
                      tests: grouped[chapter.key] ?? const [],
                      onTap: () => _openDetails(
                        context,
                        chapter.key,
                        chapter.value,
                        grouped[chapter.key] ?? const [],
                      ),
                    )),
                if (combined.isNotEmpty) ...[
                  const Divider(height: 30),
                  const Text(
                    'Combined Assessment',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                  ),
                  _ProgressRow(
                    chapterCode: 'Combined',
                    chapterName: 'Multiple Chapters',
                    tests: combined,
                    onTap: () => _openDetails(
                      context,
                      'Combined',
                      'Combined Assessment',
                      combined,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openDetails(
    BuildContext context,
    String code,
    String name,
    List<Map<String, dynamic>> tests,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _ChapterDetailsScreen(
          chapterCode: code,
          chapterName: name,
          tests: tests,
        ),
      ),
    );
  }
}

String? _chapterCode(Map<String, dynamic> mark) {
  final stored = (mark['chapter'] ?? '').toString().trim().toUpperCase();
  if (stored == 'COMBINED' || stored.contains(',') || stored.contains('-')) {
    return 'Combined';
  }
  final storedMatch = RegExp(r'^C(\d+)(?:\.\d+)?$').firstMatch(stored);
  if (storedMatch != null) return 'C${int.parse(storedMatch.group(1)!)}';

  final code = (mark['test_code'] ?? '').toString().trim().toUpperCase();
  if (code.contains('COMBINED')) return 'Combined';
  final match = RegExp(r'C(\d+)(?:\.\d+)?$').firstMatch(code);
  if (match != null) return 'C${int.parse(match.group(1)!)}';
  if (RegExp(r'C\d+[,-]').hasMatch(code)) return 'Combined';
  return null;
}

double? _obtained(Map<String, dynamic> test) {
  final value = test['marks_obtained']?.toString().trim();
  if (value == null || value.toUpperCase() == 'A') return null;
  return double.tryParse(value);
}

double? _total(Map<String, dynamic> test) =>
    double.tryParse(test['total_marks']?.toString() ?? '');

double _understanding(List<Map<String, dynamic>> tests) {
  final values = <double>[];
  for (final test in tests) {
    final obtained = _obtained(test);
    final total = _total(test);
    if (obtained != null && total != null && total > 0) {
      values.add((obtained / total) * 100);
    }
  }
  return values.isEmpty ? 0 : values.reduce((a, b) => a + b) / values.length;
}

class _ProgressRow extends StatelessWidget {
  final String chapterCode;
  final String chapterName;
  final List<Map<String, dynamic>> tests;
  final VoidCallback onTap;

  const _ProgressRow({
    required this.chapterCode,
    required this.chapterName,
    required this.tests,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final percent = _understanding(tests);
    final color = percent < 40
        ? Colors.red
        : percent < 70
            ? Colors.orange
            : Colors.green;
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 7),
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: Color(0xFFDDE2EA)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$chapterCode - $chapterName',
                style: const TextStyle(
                  color: Color(0xFF0B45F5),
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 5),
              Text('${tests.length} test${tests.length == 1 ? '' : 's'} recorded'),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text('Understanding'),
                  const Spacer(),
                  Text(
                    '${percent.round()}%',
                    style: TextStyle(color: color, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              LinearProgressIndicator(
                value: (percent / 100).clamp(0.0, 1.0).toDouble(),
                minHeight: 8,
                backgroundColor: const Color(0xFFE1E4E9),
                valueColor: AlwaysStoppedAnimation(color),
                borderRadius: BorderRadius.circular(8),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChapterDetailsScreen extends StatefulWidget {
  final String chapterCode;
  final String chapterName;
  final List<Map<String, dynamic>> tests;

  const _ChapterDetailsScreen({
    required this.chapterCode,
    required this.chapterName,
    required this.tests,
  });

  @override
  State<_ChapterDetailsScreen> createState() => _ChapterDetailsScreenState();
}

class _ChapterDetailsScreenState extends State<_ChapterDetailsScreen> {
  int? selectedIndex;

  @override
  Widget build(BuildContext context) {
    final tests = [...widget.tests]
      ..sort((a, b) => (a['test_date'] ?? '').toString().compareTo(
            (b['test_date'] ?? '').toString(),
          ));
    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F7),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1D4ED8),
        foregroundColor: Colors.white,
        title: Text(widget.chapterCode),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            '${widget.chapterCode} - ${widget.chapterName}',
            style: const TextStyle(
              color: Color(0xFF1746C7),
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Overall Understanding: ${_understanding(tests).round()}%',
            style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 20),
          _TestTable(
            tests: tests,
            selectedIndex: selectedIndex,
            onSelected: (index) => setState(() => selectedIndex = index),
          ),
          const SizedBox(height: 24),
          const Text(
            'Chapter Graph',
            style: TextStyle(
              color: Color(0xFF1746C7),
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          if (tests.where((test) => _obtained(test) != null).isEmpty)
            const Padding(
              padding: EdgeInsets.all(30),
              child: Center(child: Text('No graph data available for this chapter.')),
            )
          else
            _MarksGraph(
              tests: tests,
              selectedIndex: selectedIndex,
              onSelected: (index) => setState(() => selectedIndex = index),
            ),
        ],
      ),
    );
  }
}

class _TestTable extends StatelessWidget {
  final List<Map<String, dynamic>> tests;
  final int? selectedIndex;
  final ValueChanged<int> onSelected;

  const _TestTable({
    required this.tests,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (tests.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: Text('No tests found for this chapter')),
        ),
      );
    }
    return Card(
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(const Color(0xFFE1E4E9)),
          border: TableBorder.all(color: Colors.black54),
          columns: const [
            DataColumn(label: Text('Test Code')),
            DataColumn(label: Text('Test Date')),
            DataColumn(label: Text('Marks Obtained')),
            DataColumn(label: Text('Total Marks')),
            DataColumn(label: Text('Comments')),
          ],
          rows: tests.asMap().entries.map((entry) {
            final test = entry.value;
            final selected = selectedIndex == entry.key;
            return DataRow(
              selected: selected,
              onSelectChanged: (_) => onSelected(entry.key),
              cells: [
                DataCell(Text(test['test_code']?.toString() ?? '-')),
                DataCell(Text(_date(test['test_date']))),
                DataCell(Text(_displayMark(test['marks_obtained']))),
                DataCell(Text(test['total_marks']?.toString() ?? '-')),
                DataCell(Text(test['comments']?.toString() ?? '-')),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  String _date(dynamic value) {
    final parsed = DateTime.tryParse(value?.toString() ?? '');
    return parsed == null ? '-' : DateFormat('dd/MM/yyyy').format(parsed);
  }

  String _displayMark(dynamic value) =>
      value?.toString().toUpperCase() == 'A' ? 'Absent' : value?.toString() ?? '-';
}

class _MarksGraph extends StatelessWidget {
  final List<Map<String, dynamic>> tests;
  final int? selectedIndex;
  final ValueChanged<int> onSelected;

  const _MarksGraph({
    required this.tests,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final values = tests.map((test) => _obtained(test) ?? 0).toList();
    final largest = tests.fold<double>(0, (current, test) {
      return math.max(current, math.max(_obtained(test) ?? 0, _total(test) ?? 0));
    });
    final maxY = math.max(10.0, (largest / 10).ceil() * 10.0).toDouble();
    final width = math
        .max(MediaQuery.sizeOf(context).width - 64, tests.length * 90.0)
        .toDouble();
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 18, 8, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Marks', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: width,
                height: 280,
                child: LineChart(
                  LineChartData(
                    minX: 0,
                    maxX: math.max(1, tests.length - 1).toDouble(),
                    minY: 0,
                    maxY: maxY,
                    lineTouchData: LineTouchData(
                      touchCallback: (event, response) {
                        final spots = response?.lineBarSpots;
                        if (event is FlTapUpEvent && spots != null && spots.isNotEmpty) {
                          onSelected(spots.first.x.round());
                        }
                      },
                    ),
                    gridData: const FlGridData(show: true),
                    borderData: FlBorderData(show: true),
                    titlesData: FlTitlesData(
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      leftTitles: AxisTitles(
                        axisNameWidget: const Text('Marks'),
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 38,
                          interval: math.max(1, maxY / 4),
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        axisNameWidget: const Text('Tests'),
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 32,
                          interval: 1,
                          getTitlesWidget: (value, meta) {
                            final index = value.round();
                            if (index < 0 || index >= tests.length) return const SizedBox.shrink();
                            return Padding(
                              padding: const EdgeInsets.only(top: 7),
                              child: Text('T${index + 1}'),
                            );
                          },
                        ),
                      ),
                    ),
                    lineBarsData: [
                      LineChartBarData(
                        spots: values.asMap().entries
                            .map((entry) => FlSpot(entry.key.toDouble(), entry.value))
                            .toList(),
                        isCurved: false,
                        color: const Color(0xFF2D6CDF),
                        barWidth: 2,
                        dotData: FlDotData(
                          show: true,
                          getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                            radius: selectedIndex == index ? 7 : 4,
                            color: selectedIndex == index ? Colors.orange : const Color(0xFF2D6CDF),
                            strokeColor: Colors.white,
                            strokeWidth: selectedIndex == index ? 3 : 1,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
