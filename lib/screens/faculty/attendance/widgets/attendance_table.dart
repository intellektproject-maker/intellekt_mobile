import 'package:flutter/material.dart';

import '../../../../core/constants/colors.dart';
import '../../../../models/student_model.dart';

class AttendanceTable extends StatelessWidget {
  final List<StudentModel> students;
  final Map<String, bool> attendance;

  final ValueChanged<String> onPresent;
  final ValueChanged<String> onAbsent;

  final VoidCallback onPreview;
  final VoidCallback onSubmit;

  const AttendanceTable({
    super.key,
    required this.students,
    required this.attendance,
    required this.onPresent,
    required this.onAbsent,
    required this.onPreview,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    if (students.isEmpty) {
      return const Center(
        child: Text(
          "No students loaded.",
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minWidth: 520,
                ),
                child: Column(
                  children: [
                    const Row(
                      children: [
                        SizedBox(
                          width: 90,
                          child: Text(
                            "Roll No",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 150,
                          child: Text(
                            "Student",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 220,
                          child: Center(
                            child: Text(
                              "Attendance",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const Divider(),

                    ...students.map((student) {
                      final present =
                          attendance[student.rollNo] ?? true;

                      return Column(
                        children: [
                          Row(
                            children: [
                              SizedBox(
                                width: 90,
                                child: Text(student.rollNo),
                              ),

                              SizedBox(
                                width: 150,
                                child: Text(student.name),
                              ),

                              SizedBox(
                                width: 220,
                                child: Row(
                                  mainAxisAlignment:
                                  MainAxisAlignment.center,
                                  children: [
                                    Radio<bool>(
                                      value: true,
                                      groupValue: present,
                                      activeColor:
                                      AppColors.success,
                                      onChanged: (_) =>
                                          onPresent(student.rollNo),
                                    ),

                                    const Text("Present"),

                                    const SizedBox(width: 12),

                                    Radio<bool>(
                                      value: false,
                                      groupValue: present,
                                      activeColor:
                                      AppColors.error,
                                      onChanged: (_) =>
                                          onAbsent(student.rollNo),
                                    ),

                                    const Text("Absent"),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const Divider(),
                        ],
                      );
                    }),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onPreview,
                    icon: const Icon(Icons.visibility),
                    label: const Text("Preview"),
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onSubmit,
                    icon: const Icon(Icons.save),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
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