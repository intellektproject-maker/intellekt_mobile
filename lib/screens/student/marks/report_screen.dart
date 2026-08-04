import 'package:flutter/material.dart';
import 'widgets/performance_trend_chart.dart';
import 'widgets/chapter_progress_list.dart';
class ReportScreen extends StatelessWidget {
  final String subjectName;
  final List<Map<String, dynamic>> marks;

  const ReportScreen({
    super.key,
    required this.subjectName,
    required this.marks,
  });

  int get totalTests => marks.length;

  int get absentCount {
    return marks.where((m) {
      return (m['marks_obtained'] ?? '')
          .toString()
          .toUpperCase() ==
          'A';
    }).length;
  }

  Map<String, dynamic>? get highestMark {
    final valid = marks.where((m) {
      return (m['marks_obtained'] ?? '')
          .toString()
          .toUpperCase() !=
          'A';
    }).toList();

    if (valid.isEmpty) return null;

    valid.sort((a, b) {
      final aValue =
          int.tryParse(a['marks_obtained'].toString()) ?? 0;
      final bValue =
          int.tryParse(b['marks_obtained'].toString()) ?? 0;

      return bValue.compareTo(aValue);
    });

    return valid.first;
  }

  Map<String, dynamic>? get lowestMark {
    final valid = marks.where((m) {
      return (m['marks_obtained'] ?? '')
          .toString()
          .toUpperCase() !=
          'A';
    }).toList();

    if (valid.isEmpty) return null;

    valid.sort((a, b) {
      final aValue =
          int.tryParse(a['marks_obtained'].toString()) ?? 0;
      final bValue =
          int.tryParse(b['marks_obtained'].toString()) ?? 0;

      return aValue.compareTo(bValue);
    });

    return valid.first;
  }

  @override
  Widget build(BuildContext context) {
    final highest = highestMark;
    final lowest = lowestMark;

    return Scaffold(
      backgroundColor: const Color(0xFFECECEF),

      appBar: AppBar(
        backgroundColor: const Color(0xFF1D4ED8),
        foregroundColor: Colors.white,
        title: Text(subjectName),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [

            Text(
              "$subjectName Report",
              style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1746C7),
              ),
            ),

            const SizedBox(height: 28),

            const Text(
              "Performance Summary",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(.06),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [

                  const Row(
                    children: [
                      Icon(
                        Icons.analytics_rounded,
                        color: Color(0xFF1746C7),
                      ),
                      SizedBox(width: 8),
                      Text(
                        "Performance Summary",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  Row(
                    children: [

                      Expanded(
                        child: _SummaryItem(
                          icon: Icons.trending_up,
                          color: Colors.green,
                          title: "Highest",
                          value: highest == null
                              ? "-"
                              : "${highest['marks_obtained']} / ${highest['total_marks']}",
                        ),
                      ),

                      const SizedBox(width: 20),

                      Expanded(
                        child: _SummaryItem(
                          icon: Icons.trending_down,
                          color: Colors.red,
                          title: "Lowest",
                          value: lowest == null
                              ? "-"
                              : "${lowest['marks_obtained']} / ${lowest['total_marks']}",
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  Row(
                    children: [

                      Expanded(
                        child: _SummaryItem(
                          icon: Icons.assignment,
                          color: Colors.blue,
                          title: "Tests",
                          value: totalTests.toString(),
                        ),
                      ),

                      const SizedBox(width: 20),

                      Expanded(
                        child: _SummaryItem(
                          icon: Icons.event_busy,
                          color: Colors.orange,
                          title: "Absent",
                          value: absentCount.toString(),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            PerformanceTrendChart(
              marks: marks,
            ),

            const SizedBox(height: 36),

            const Text(
              "Chapter Progress",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 18),

            ChapterProgressList(
              marks: marks,
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String value;

  const _SummaryItem({
    required this.icon,
    required this.color,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [

        CircleAvatar(
          radius: 24,
          backgroundColor: color.withOpacity(.12),
          child: Icon(
            icon,
            color: color,
          ),
        ),

        const SizedBox(height: 10),

        Text(
          title,
          style: const TextStyle(
            color: Colors.grey,
            fontWeight: FontWeight.w600,
          ),
        ),

        const SizedBox(height: 6),

        Text(
          value,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}