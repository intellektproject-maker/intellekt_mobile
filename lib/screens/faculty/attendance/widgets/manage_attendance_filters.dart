import 'package:flutter/material.dart';

import '../../../../core/constants/colors.dart';

class ManageAttendanceFilters extends StatelessWidget {
  final List<String> classes;
  final List<String> subjects;

  final String? selectedClass;
  final String? selectedSubject;

  final DateTime? fromDate;
  final DateTime? toDate;

  final TextEditingController searchController;

  final ValueChanged<String?> onClassChanged;
  final ValueChanged<String?> onSubjectChanged;

  final ValueChanged<DateTime?> onFromDateChanged;
  final ValueChanged<DateTime?> onToDateChanged;

  final VoidCallback onViewReport;

  const ManageAttendanceFilters({
    super.key,
    required this.classes,
    required this.subjects,
    required this.selectedClass,
    required this.selectedSubject,
    required this.searchController,
    required this.onClassChanged,
    required this.onSubjectChanged,
    required this.fromDate,
    required this.toDate,
    required this.onFromDateChanged,
    required this.onToDateChanged,
    required this.onViewReport,
  });

  Future<void> _pickDate(
      BuildContext context,
      DateTime? initialDate,
      ValueChanged<DateTime?> onChanged,
      ) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime.now(),
      firstDate: DateTime(2023),
      lastDate: DateTime(2035),
    );

    if (picked != null) {
      onChanged(picked);
    }
  }

  String _format(DateTime? date) {
    if (date == null) return "";

    return "${date.day.toString().padLeft(2, '0')}/"
        "${date.month.toString().padLeft(2, '0')}/"
        "${date.year}";
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            /// CLASS
            DropdownButtonFormField<String>(
              value: selectedClass,
              decoration: const InputDecoration(
                labelText: "Class",
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

            const SizedBox(height: 16),

            /// SUBJECT
            DropdownButtonFormField<String>(
              value: selectedSubject,
              decoration: const InputDecoration(
                labelText: "Subject",
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

            const SizedBox(height: 16),

            /// SEARCH
            TextField(
              controller: searchController,
              decoration: const InputDecoration(
                hintText: "Search Student...",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 18),

            /// DATE RANGE
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _pickDate(
                      context,
                      fromDate,
                      onFromDateChanged,
                    ),
                    child: AbsorbPointer(
                      child: TextFormField(
                        controller: TextEditingController(
                          text: _format(fromDate),
                        ),
                        decoration: const InputDecoration(
                          labelText: "From",
                          suffixIcon: Icon(Icons.calendar_today),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: GestureDetector(
                    onTap: () => _pickDate(
                      context,
                      toDate,
                      onToDateChanged,
                    ),
                    child: AbsorbPointer(
                      child: TextFormField(
                        controller: TextEditingController(
                          text: _format(toDate),
                        ),
                        decoration: const InputDecoration(
                          labelText: "To",
                          suffixIcon: Icon(Icons.calendar_today),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            /// VIEW REPORT
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: onViewReport,
                icon: const Icon(Icons.visibility),
                label: const Text("View Report"),
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