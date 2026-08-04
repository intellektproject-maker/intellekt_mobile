import 'package:flutter/material.dart';

class ChapterProgressCard extends StatelessWidget {
  final String chapterCode;
  final String chapterName;
  final double understanding;
  final int testCount;
  final bool isExpanded;
  final VoidCallback onTap;

  const ChapterProgressCard({
    super.key,
    required this.chapterCode,
    required this.chapterName,
    required this.understanding,
    required this.testCount,
    required this.isExpanded,
    required this.onTap,
  });

  Color get progressColor {
    if (understanding >= 80) {
      return Colors.green;
    } else if (understanding >= 60) {
      return Colors.orange;
    }
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1.5,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              /// Chapter Code
              Text(
                chapterCode,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.grey,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 4),

              /// Chapter Name
              Text(
                chapterName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 18),

              Row(
                children: [

                  const Expanded(
                    child: Text(
                      "Understanding",
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                  Text(
                    "${understanding.toStringAsFixed(0)}%",
                    style: TextStyle(
                      color: progressColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: LinearProgressIndicator(
                  value: understanding / 100,
                  minHeight: 8,
                  backgroundColor: Colors.grey.shade300,
                  valueColor: AlwaysStoppedAnimation(progressColor),
                ),
              ),

              const SizedBox(height: 18),

              Row(
                children: [

                  Icon(
                    Icons.assignment_outlined,
                    size: 20,
                    color: Colors.grey.shade700,
                  ),

                  const SizedBox(width: 8),

                  Text(
                    "$testCount Test${testCount == 1 ? '' : 's'}",
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  const Spacer(),

                  AnimatedRotation(
                    duration: const Duration(milliseconds: 250),
                    turns: isExpanded ? 0.5 : 0,
                    child: const Icon(Icons.keyboard_arrow_down),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}