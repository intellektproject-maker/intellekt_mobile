import 'package:flutter/material.dart';

class ChapterProgressBar extends StatelessWidget {
  final int percentage;

  const ChapterProgressBar({
    super.key,
    required this.percentage,
  });

  Color _color() {
    if (percentage < 40) {
      return Colors.red;
    }

    if (percentage < 70) {
      return Colors.orange;
    }

    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: percentage / 100,
            minHeight: 10,
            backgroundColor: Colors.grey.shade300,
            valueColor: AlwaysStoppedAnimation(_color()),
          ),
        ),
        const SizedBox(height: 6),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            "$percentage%",
            style: TextStyle(
              color: _color(),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}