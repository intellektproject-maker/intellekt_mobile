import 'package:flutter/material.dart';
import '../../../../core/constants/colors.dart';

class AttendanceFilterCard extends StatelessWidget {
  final String? selectedClass;
  final String? selectedSubject;
  final DateTime selectedDate;

  final ValueChanged<String?> onClassChanged;
  final ValueChanged<String?> onSubjectChanged;
  final VoidCallback onSelectDate;
  final VoidCallback onLoadStudents;

  const AttendanceFilterCard({
    super.key,
    required this.selectedClass,
    required this.selectedSubject,
    required this.selectedDate,
    required this.onClassChanged,
    required this.onSubjectChanged,
    required this.onSelectDate,
    required this.onLoadStudents,
  });

  static const List<String> classes = [
    '12 A',
    '12 B',
    '11 A',
    '11 B',
    '10 A',
  ];

  static const List<String> subjects = [
    'Mathematics',
    'Physics',
    'Chemistry',
    'Biology',
    'Computer Science',
  ];

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            const Text(
              'Attendance Details',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),

            const SizedBox(height: 20),

            DropdownButtonFormField<String>(
              value: selectedClass,
              decoration: const InputDecoration(
                labelText: 'Select Class',
                border: OutlineInputBorder(),
              ),
              items: classes
                  .map(
                    (e) => DropdownMenuItem(
                  value: e,
                  child: Text(e),
                ),
              )
                  .toList(),
              onChanged: onClassChanged,
            ),

            const SizedBox(height: 18),

            DropdownButtonFormField<String>(
              value: selectedSubject,
              decoration: const InputDecoration(
                labelText: 'Select Subject',
                border: OutlineInputBorder(),
              ),
              items: subjects
                  .map(
                    (e) => DropdownMenuItem(
                  value: e,
                  child: Text(e),
                ),
              )
                  .toList(),
              onChanged: onSubjectChanged,
            ),

            const SizedBox(height: 18),

            InkWell(
              onTap: onSelectDate,
              borderRadius: BorderRadius.circular(8),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Attendance Date',
                  border: OutlineInputBorder(),
                ),
                child: Row(
                  children: [

                    const Icon(Icons.calendar_today),

                    const SizedBox(width: 12),

                    Text(
                      "${selectedDate.day}/${selectedDate.month}/${selectedDate.year}",
                    ),

                  ],
                ),
              ),
            ),

            const SizedBox(height: 25),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.people),
                label: const Text('Load Students'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(50),
                ),
                onPressed: onLoadStudents,
              ),
            ),
          ],
        ),
      ),
    );
  }
}