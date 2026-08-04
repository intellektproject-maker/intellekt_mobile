import 'package:flutter/material.dart';

class TestHistoryCard extends StatelessWidget {
  final Map<String, dynamic> test;

  const TestHistoryCard({
    super.key,
    required this.test,
  });

  @override
  Widget build(BuildContext context) {
    final obtained = test['marks_obtained'] ?? "-";
    final total = test['total_marks'] ?? "-";

    return Card(
      elevation: 0,
      color: Colors.grey.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Row(
              mainAxisAlignment:
              MainAxisAlignment.spaceBetween,
              children: [

                Text(
                  test['test_code'] ?? "-",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),

                Text(
                  "$obtained / $total",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 6),

            Text(
              test['test_date']?.toString() ?? "-",
            ),

            const SizedBox(height: 10),

            if ((test['comments'] ?? "")
                .toString()
                .trim()
                .isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius:
                  BorderRadius.circular(10),
                ),
                child: Text(
                  test['comments'],
                ),
              ),
          ],
        ),
      ),
    );
  }
}