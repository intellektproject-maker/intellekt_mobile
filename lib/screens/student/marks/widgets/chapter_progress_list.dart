import 'package:flutter/material.dart';

import 'chapter_details_card.dart';
import 'chapter_progress_card.dart';
import 'package:intellekt_mobile/core/constants/syllabus.dart';
class ChapterProgressList extends StatefulWidget {
  final List<Map<String, dynamic>> marks;

  const ChapterProgressList({
    super.key,
    required this.marks,
  });

  @override
  State<ChapterProgressList> createState() => _ChapterProgressListState();
}

class _ChapterProgressListState extends State<ChapterProgressList> {
  String? expandedChapter;

  @override
  Widget build(BuildContext context) {
    /// Group tests by chapter
    final Map<String, List<Map<String, dynamic>>> grouped = {};

    for (final mark in widget.marks) {
      debugPrint("========== MARK ==========");
      debugPrint(mark.toString());

      final chapter = (mark['chapter'] ?? 'Uncategorized')
          .toString()
          .trim();

      grouped.putIfAbsent(chapter, () => []);
      grouped[chapter]!.add(mark);
    }

    /// Sort chapters (C1, C2, ... C12, Combined)
    final chapters = grouped.keys.toList()
      ..sort((a, b) {
        if (a == "Combined") return 1;
        if (b == "Combined") return -1;

        final aNo = int.tryParse(a.replaceAll("C", "")) ?? 999;
        final bNo = int.tryParse(b.replaceAll("C", "")) ?? 999;

        return aNo.compareTo(bNo);
      });

    return Column(
      children: chapters.map((chapter) {
        final tests = grouped[chapter]!;

        double understanding = 0;

        if (tests.isNotEmpty) {
          double total = 0;

          for (final test in tests) {
            final obtained = double.tryParse(
              test['marks_obtained'].toString(),
            ) ??
                0;

            final maxMarks = double.tryParse(
              test['total_marks'].toString(),
            ) ??
                100;

            if (maxMarks > 0) {
              total += (obtained / maxMarks) * 100;
            }
          }

          understanding = total / tests.length;
        }

        return Column(
          children: [
            ChapterProgressCard(
              chapterCode: chapter,

              chapterName:
              MathsChapters.stateBoard[chapter] ??
                  chapter,

              understanding: understanding,

              testCount: tests.length,

              isExpanded: expandedChapter == chapter,

              onTap: () {
                setState(() {
                  expandedChapter =
                  expandedChapter == chapter
                      ? null
                      : chapter;
                });
              },
            ),

            if (expandedChapter == chapter)
              ChapterDetailsCard(
                chapterCode: chapter,

                chapterName:
                MathsChapters.stateBoard[chapter] ??
                    chapter,

                chapterTests: tests,
              ),
          ],
        );
      }).toList(),
    );
  }
}