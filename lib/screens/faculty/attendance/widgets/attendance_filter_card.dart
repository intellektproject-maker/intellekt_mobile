import 'package:flutter/material.dart';

import '../../../../core/constants/colors.dart';

class AttendanceFilterCard extends StatelessWidget {
  final List<String> classes;
  final List<String> subjects;

  final String? selectedClass;
  final String? selectedSubject;

  final DateTime selectedDate;

  final ValueChanged<String?> onClassChanged;
  final ValueChanged<String?> onSubjectChanged;

  final VoidCallback onSelectDate;
  final VoidCallback onLoadStudents;

  const AttendanceFilterCard({
    super.key,
    required this.classes,
    required this.subjects,
    required this.selectedClass,
    required this.selectedSubject,
    required this.selectedDate,
    required this.onClassChanged,
    required this.onSubjectChanged,
    required this.onSelectDate,
    required this.onLoadStudents,
  });

  String get formattedDate {
    return "${selectedDate.day.toString().padLeft(2, '0')}/"
        "${selectedDate.month.toString().padLeft(2, '0')}/"
        "${selectedDate.year}";
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            const Text(
              "Attendance Details",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),

            const SizedBox(height: 20),

            DropdownButtonFormField<String>(
              value: selectedClass,
              decoration: const InputDecoration(
                labelText: "Class",
                border: OutlineInputBorder(),
              ),
              items: classes
                  .map(
                    (item) => DropdownMenuItem(
                  value: item,
                  child: Text(item),
                ),
              )
                  .toList(),
              onChanged: onClassChanged,
            ),

            const SizedBox(height: 18),

            DropdownButtonFormField<String>(
              value: selectedSubject,
              decoration: const InputDecoration(
                labelText: "Subject",
                border: OutlineInputBorder(),
              ),
              items: subjects
                  .map(
                    (item) => DropdownMenuItem(
                  value: item,
                  child: Text(item),
                ),
              )
                  .toList(),
              onChanged: onSubjectChanged,
            ),

            const SizedBox(height: 18),

            InkWell(
              onTap: onSelectDate,
              borderRadius: BorderRadius.circular(12),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: "Attendance Date",
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                child: Text(
                  formattedDate,
                  style: const TextStyle(
                    fontSize: 16,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 25),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: onLoadStudents,
                icon: const Icon(Icons.people),
                label: const Text("Load Students"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}