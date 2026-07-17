import 'package:flutter/material.dart';

import '../../../../core/constants/colors.dart';
import '../../../../models/student_model.dart';

class AttendancePreviewDialog extends StatelessWidget {
  final List<StudentModel> students;
  final Map<String, bool> attendance;

  final VoidCallback onSubmit;

  const AttendancePreviewDialog({
    super.key,
    required this.students,
    required this.attendance,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(20),

      child: Container(
        constraints: const BoxConstraints(
          maxHeight: 650,
          maxWidth: 600,
        ),

        padding: const EdgeInsets.all(20),

        child: Column(
          children: [

            const Text(
              "Attendance Preview",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),

            const SizedBox(height: 20),

            Expanded(
              child: ListView.separated(
                itemCount: students.length,

                separatorBuilder: (_, __) =>
                const Divider(),

                itemBuilder: (context, index) {

                  final student = students[index];

                  final present =
                      attendance[student.rollNo] ?? true;

                  return ListTile(

                    leading: CircleAvatar(
                      backgroundColor: AppColors.primary,
                      child: Text(
                        student.rollNo.substring(
                          student.rollNo.length - 2,
                        ),
                        style: const TextStyle(
                          color: Colors.white,
                        ),
                      ),
                    ),

                    title: Text(student.name),

                    subtitle: Text(student.rollNo),

                    trailing: Chip(
                      backgroundColor: present
                          ? Colors.green.shade100
                          : Colors.red.shade100,

                      label: Text(
                        present
                            ? "Present"
                            : "Absent",
                        style: TextStyle(
                          color: present
                              ? Colors.green.shade800
                              : Colors.red.shade800,
                          fontWeight:
                          FontWeight.w600,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 20),

            Row(
              children: [

                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text("Cancel"),
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      onSubmit();
                    },
                    icon: const Icon(Icons.save),
                    label: const Text("Submit"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}