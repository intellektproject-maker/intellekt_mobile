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
    Map<String, dynamic>? metadataMark;
    for (final mark in marks) {
      final markClass = mark['class']?.toString().trim() ?? '';
      final markBoard = mark['board']?.toString().trim() ?? '';
      if (markClass.isNotEmpty && markBoard.isNotEmpty) {
        metadataMark = mark;
        break;
      }
    }

    final className = metadataMark?['class'] ?? '12';
    final board = metadataMark?['board'] ?? 'STATE_BOARD';
    final syllabus = AppSyllabus.chapters(
      subjectName: subjectName,
      className: className,
      board: board,
    );

    final grouped = <String, List<Map<String, dynamic>>>{};
    final combined = <Map<String, dynamic>>[];
    for (final mark in marks) {
      final chapter = _chapterCode(mark, syllabus);
      if (chapter == 'Combined') {
        combined.add(mark);
      } else if (chapter != null) {
        grouped.putIfAbsent(chapter, () => []).add(mark);
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFECECEF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF000153),
        foregroundColor: Colors.white,
        title: Text(subjectName),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        children: [
          Text(
            '$subjectName Detailed Report',
            style: const TextStyle(
              color: Color(0xFF000153),
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
                    color: Color(0xFF000153),
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
          showChart: code != 'Combined',
        ),
      ),
    );
  }
}

String _normalizeChapter(dynamic value) {
  return (value ?? '')
      .toString()
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'\s+'), ' ');
}

String? _chapterCode(
    Map<String, dynamic> mark,
    Map<String, String> syllabus,
    ) {
  final stored = _normalizeChapter(mark['chapter']);

  if (stored.isEmpty) return null;

  // Keep combined assessments separate.
  if (stored == 'combined') {
    return 'Combined';
  }

  // Supports database values: 4, C4, Chapter 4, 5.6, etc.
  final numberMatch = RegExp(r'\d+').firstMatch(stored);

  if (numberMatch != null) {
    final chapterNumber = int.parse(numberMatch.group(0)!);

    // Supports either C4 or 4 as the AppSyllabus key.
    final cKey = 'C$chapterNumber';
    final numericKey = chapterNumber.toString();

    if (syllabus.containsKey(cKey)) return cKey;
    if (syllabus.containsKey(numericKey)) return numericKey;
  }

  // Supports a chapter name stored in DB, e.g. "Construction".
  for (final entry in syllabus.entries) {
    if (_normalizeChapter(entry.value) == stored) {
      return entry.key;
    }
  }

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
  double totalObtained = 0;
  double totalPossible = 0;

  for (final test in tests) {
    final obtained = _obtained(test);
    final total = _total(test);

    if (obtained != null && total != null && total > 0) {
      totalObtained += obtained;
      totalPossible += total;
    }
  }

  if (totalPossible == 0) return 0;

  return (totalObtained / totalPossible) * 100;
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
                  color: Color(0xFF000153),
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
  final bool showChart;

  const _ChapterDetailsScreen({
    required this.chapterCode,
    required this.chapterName,
    required this.tests,
    required this.showChart,
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
        backgroundColor: const Color(0xFF000153),
        foregroundColor: Colors.white,
        title: Text(widget.chapterCode),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            '${widget.chapterCode} - ${widget.chapterName}',
            style: const TextStyle(
              color: Color(0xFF000153),
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
          if (widget.showChart) ...[
            const SizedBox(height: 24),
            const Text(
              'Chapter Histogram',
              style: TextStyle(
                color: Color(0xFF000153),
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            if (tests.isEmpty)
              const Padding(
                padding: EdgeInsets.all(30),
                child: Center(
                  child: Text('No graph data available for this chapter.'),
                ),
              )
            else
              _MarksBarChart(
                tests: tests,
                selectedIndex: selectedIndex,
                onSelected: (index) => setState(() => selectedIndex = index),
              ),
          ],
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
      child: DataTable(
        showCheckboxColumn: false,
        headingRowColor: WidgetStateProperty.all(const Color(0xFFE1E4E9)),
        border: TableBorder.all(color: Colors.black54),
        columnSpacing: 12,
        horizontalMargin: 8,
        headingRowHeight: 46,
        dataRowMinHeight: 48,
        dataRowMaxHeight: 58,
        headingTextStyle: const TextStyle(
          color: Colors.black,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
        dataTextStyle: const TextStyle(
          color: Colors.black87,
          fontSize: 12,
        ),
        columns: const [
          DataColumn(label: Text('Test Code')),
          DataColumn(label: Text('Date')),
          DataColumn(label: Text('Marks')),
        ],
        rows: tests.asMap().entries.map((entry) {
          final test = entry.value;
          final selected = selectedIndex == entry.key;
          return DataRow(
            selected: selected,
            onSelectChanged: (_) => onSelected(entry.key),
            cells: [
              DataCell(
                SizedBox(
                  width: 128,
                  child: Text(
                    test['test_code']?.toString() ?? '-',
                    softWrap: true,
                  ),
                ),
              ),
              DataCell(Text(_date(test['test_date']))),
              DataCell(
                Text(
                  _marksDisplay(test),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  String _marksDisplay(Map<String, dynamic> test) {
    final obtained = _displayMark(test['marks_obtained']);
    if (obtained == 'Absent') return obtained;

    final total = test['total_marks']?.toString() ?? '-';
    return '$obtained / $total';
  }

  String _date(dynamic value) {
    final parsed = DateTime.tryParse(value?.toString() ?? '');
    return parsed == null ? '-' : DateFormat('dd/MM/yyyy').format(parsed);
  }

  String _displayMark(dynamic value) =>
      value?.toString().toUpperCase() == 'A' ? 'Absent' : value?.toString() ?? '-';
}

class _MarksBarChart extends StatelessWidget {
  final List<Map<String, dynamic>> tests;
  final int? selectedIndex;
  final ValueChanged<int> onSelected;

  const _MarksBarChart({
    required this.tests,
    required this.selectedIndex,
    required this.onSelected,
  });

  double _percentage(Map<String, dynamic> test) {
    final obtained = _obtained(test);
    final total = _total(test);

    if (obtained == null || total == null || total <= 0) {
      return 0;
    }

    return ((obtained / total) * 100).clamp(0, 100).toDouble();
  }

  Color _barColor(double percentage, bool selected) {
    if (selected) return const Color(0xFF000153);
    if (percentage < 40) return Colors.red;
    if (percentage < 70) return Colors.orange;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    final width = math
        .max(
      MediaQuery.sizeOf(context).width - 64,
      tests.length * 90.0,
    )
        .toDouble();

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 18, 12, 12),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: width,
            height: 310,
            child: BarChart(
              BarChartData(
                minY: 0,
                maxY: 100,
                alignment: BarChartAlignment.spaceAround,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchCallback: (event, response) {
                    final group = response?.spot?.touchedBarGroupIndex;

                    if (event is FlTapUpEvent && group != null) {
                      onSelected(group);
                    }
                  },
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (
                        group,
                        groupIndex,
                        rod,
                        rodIndex,
                        ) {
                      final test = tests[groupIndex];
                      final percentage = _percentage(test);

                      return BarTooltipItem(
                        '${test['test_code'] ?? '-'}\n'
                            '${percentage.round()}%',
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  horizontalInterval: 25,
                  drawVerticalLine: false,
                ),
                borderData: FlBorderData(
                  show: true,
                  border: const Border(
                    left: BorderSide(color: Colors.black54),
                    bottom: BorderSide(color: Colors.black54),
                  ),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: const AxisTitles(
                    axisNameWidget: Text('Percentage'),
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 42,
                      interval: 25,
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    axisNameWidget: const Text('Test Code'),
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 55,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();

                        if (index < 0 || index >= tests.length) {
                          return const SizedBox.shrink();
                        }

                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: SizedBox(
                            width: 76,
                            child: Text(
                              tests[index]['test_code']?.toString() ?? '-',
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 10),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: tests.asMap().entries.map((entry) {
                  final percentage = _percentage(entry.value);
                  final selected = selectedIndex == entry.key;

                  return BarChartGroupData(
                    x: entry.key,
                    barRods: [
                      BarChartRodData(
                        toY: percentage,
                        width: selected ? 26 : 22,
                        color: _barColor(percentage, selected),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(6),
                        ),
                      ),
                    ],
                    showingTooltipIndicators: selected ? [0] : [],
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
