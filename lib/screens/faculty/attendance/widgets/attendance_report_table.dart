import 'package:flutter/material.dart';

import '../../../../core/constants/colors.dart';
import '../../../../models/attendance_record_model.dart';

class AttendanceReportTable extends StatelessWidget {
  final List<AttendanceRecordModel> records;

  const AttendanceReportTable({
    super.key,
    required this.records,
  });

  String formatDate(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}/"
        "${date.month.toString().padLeft(2, '0')}/"
        "${date.year}";
  }

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(top: 40),
        child: Center(
          child: Text(
            "No attendance records found.",
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ),
      );
    }

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 30,
          headingRowHeight: 52,
          dataRowMinHeight: 56,
          dataRowMaxHeight: 60,
          headingRowColor: WidgetStateProperty.all(
            AppColors.primary.withValues(alpha: 0.08),
          ),
          columns: const [
            DataColumn(
              label: Text(
                "Roll No",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                "Student",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                "Class",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                "Subject",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                "Status",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                "Date",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
          rows: records.map((record) {
            return DataRow(
              cells: [
                DataCell(
                  Text(record.rollNo),
                ),
                DataCell(
                  Text(record.studentName),
                ),
                DataCell(
                  Text(record.className),
                ),
                DataCell(
                  Text(record.subject),
                ),
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: record.isPresent
                          ? Colors.green.shade100
                          : Colors.red.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      record.isPresent
                          ? "Present"
                          : "Absent",
                      style: TextStyle(
                        color: record.isPresent
                            ? Colors.green.shade800
                            : Colors.red.shade800,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                DataCell(
                  Text(
                    formatDate(record.attendanceDate),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}