import 'package:flutter/material.dart';

import '../../../../models/mark_entry.dart';

class MarksTable extends StatelessWidget {
  final List<MarkEntry> students;
  final Function(int, int) onMarksChanged;

  const MarksTable({
    super.key,
    required this.students,
    required this.onMarksChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 24,
        columns: const [
          DataColumn(label: Text("Student")),
          DataColumn(label: Text("Roll No")),
          DataColumn(label: Text("Class")),
          DataColumn(label: Text("Test")),
          DataColumn(label: Text("Marks")),
          DataColumn(label: Text("Total")),
        ],
        rows: List.generate(
          students.length,
              (index) {
            final student = students[index];

            return DataRow(
              cells: [
                DataCell(Text(student.studentName)),
                DataCell(Text(student.rollNo)),
                DataCell(Text(student.className)),
                DataCell(Text(student.testCode)),
                DataCell(
                  SizedBox(
                    width: 70,
                    child: TextFormField(
                      initialValue: student.marks.toString(),
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        isDense: true,
                      ),
                      onChanged: (value) {
                        onMarksChanged(
                          index,
                          int.tryParse(value) ?? 0,
                        );
                      },
                    ),
                  ),
                ),
                DataCell(Text(student.totalMarks.toString())),
              ],
            );
          },
        ),
      ),
    );
  }
}