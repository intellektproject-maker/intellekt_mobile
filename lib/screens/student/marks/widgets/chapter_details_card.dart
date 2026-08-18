import 'package:flutter/material.dart';

import 'test_history_card.dart';

class ChapterDetailsCard extends StatelessWidget {
  final String chapterCode;
  final String chapterName;
  final List<Map<String, dynamic>> chapterTests;

  const ChapterDetailsCard({
    super.key,
    required this.chapterCode,
    required this.chapterName,
    required this.chapterTests,
  });

  double _percentage(Map<String, dynamic> test) {
    final obtained = double.tryParse(
      test['marks_obtained'].toString(),
    ) ??
        0;

    final total = double.tryParse(
      test['total_marks'].toString(),
    ) ??
        100;

    if (total <= 0) return 0;

    return (obtained / total) * 100;
  }

  @override
  Widget build(BuildContext context) {
    if (chapterTests.isEmpty) {
      return const SizedBox();
    }

    double average = 0;
    double highest = 0;

    for (final test in chapterTests) {
      final p = _percentage(test);

      average += p;

      if (p > highest) {
        highest = p;
      }
    }

    average /= chapterTests.length;

    final latest = _percentage(chapterTests.last);

    return Container(
      margin: const EdgeInsets.only(
        left: 10,
        right: 10,
        bottom: 16,
      ),
      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE8ECFD),
        ),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          /// Header
          Text(
            "$chapterCode • $chapterName",
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            "Overall Understanding ${average.toStringAsFixed(1)}%",
            style: TextStyle(
              fontSize: 15,
              color: average >= 70
                  ? Colors.green
                  : average >= 40
                  ? Colors.orange
                  : Colors.red,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 22),

          /// Analytics Row
          Row(
            children: [

              Expanded(
                child: _analyticsCard(
                  "Average",
                  "${average.toStringAsFixed(0)}%",
                  Icons.analytics,
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: _analyticsCard(
                  "Highest",
                  "${highest.toStringAsFixed(0)}%",
                  Icons.emoji_events,
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: _analyticsCard(
                  "Latest",
                  "${latest.toStringAsFixed(0)}%",
                  Icons.trending_up,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          const Text(
            "Tests",
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          ...chapterTests.map(
                (test) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: TestHistoryCard(
                test: test,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _analyticsCard(
      String title,
      String value,
      IconData icon,
      ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 16,
      ),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Icon(icon),

          const SizedBox(height: 8),

          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            title,
            style: const TextStyle(fontSize: 13),
          ),
        ],
      ),
    );
  }
}
