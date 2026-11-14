import 'package:flutter/material.dart';

import '../core/constants/colors.dart';

/// Optional local filter for students with academic-year metadata.
/// It only filters the already-loaded rows and does not change API requests.
class AcademicYearRangeFilter extends StatelessWidget {
  final List<Map<String, dynamic>> students;
  final String fromYear;
  final String toYear;
  final ValueChanged<String?> onFromChanged;
  final ValueChanged<String?> onToChanged;

  const AcademicYearRangeFilter({
    super.key,
    required this.students,
    required this.fromYear,
    required this.toYear,
    required this.onFromChanged,
    required this.onToChanged,
  });

  List<String> _years(String key) => students
      .map((student) => (student[key] ?? '').toString().trim())
      .where((year) => year.isNotEmpty)
      .toSet()
      .toList()
    ..sort();

  @override
  Widget build(BuildContext context) {
    final fromYears = _years('academic_year_from');
    final toYears = _years('academic_year_to');
    final validFrom = fromYears.contains(fromYear) ? fromYear : '';
    final validTo = toYears.contains(toYear) ? toYear : '';

    Widget dropdown(
      String label,
      String value,
      List<String> years,
      ValueChanged<String?> onChanged,
    ) {
      return DropdownButtonFormField<String>(
        value: value,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          filled: true,
          fillColor: AppColors.surface,
        ),
        items: [
          const DropdownMenuItem(value: '', child: Text('All')),
          ...years.map((year) => DropdownMenuItem(value: year, child: Text(year))),
        ],
        onChanged: onChanged,
      );
    }

    return Card(
      color: AppColors.surface,
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Academic Year Filter',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: dropdown('Academic Year From', validFrom, fromYears, onFromChanged)),
                const SizedBox(width: 10),
                Expanded(child: dropdown('Academic Year To', validTo, toYears, onToChanged)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Match the selected values against each student's stored academic-year
/// endpoints. Empty selections leave that endpoint unfiltered.
List<Map<String, dynamic>> filterStudentsByAcademicYear(
  List<Map<String, dynamic>> students, {
  String fromYear = '',
  String toYear = '',
}) {
  return students.where((student) {
    final from = (student['academic_year_from'] ?? '').toString().trim();
    final to = (student['academic_year_to'] ?? '').toString().trim();
    return (fromYear.isEmpty || from == fromYear) &&
        (toYear.isEmpty || to == toYear);
  }).toList();
}
