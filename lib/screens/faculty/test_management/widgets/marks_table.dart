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
    return DataTable(
      columnSpacing: 30,
      columns: const [
        DataColumn(label: Text("Roll No")),
        DataColumn(label: Text("Student")),
        DataColumn(label: Text("Marks")),
      ],
      rows: List.generate(
        students.length,
            (index) {
          final student = students[index];

          return DataRow(
            cells: [
              DataCell(Text(student.rollNo)),
              DataCell(Text(student.studentName)),
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
            ],
          );
        },
      ),
    );
  }
}