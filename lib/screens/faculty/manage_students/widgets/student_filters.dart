import 'package:flutter/material.dart';

class StudentFilters extends StatelessWidget {
  final String? selectedClass;
  final String? selectedBoard;

  final List<String> classOptions;
  final List<String> boardOptions;

  final ValueChanged<String?> onClassChanged;
  final ValueChanged<String?> onBoardChanged;

  final VoidCallback onClearFilters;

  const StudentFilters({
    super.key,
    required this.selectedClass,
    required this.selectedBoard,
    required this.classOptions,
    required this.boardOptions,
    required this.onClassChanged,
    required this.onBoardChanged,
    required this.onClearFilters,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            DropdownButtonFormField<String>(
              initialValue: selectedClass,
              decoration: const InputDecoration(
                labelText: "Class",
                border: OutlineInputBorder(),
              ),
              items: classOptions
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

            DropdownButtonFormField<String>(
              initialValue: selectedBoard,
              decoration: const InputDecoration(
                labelText: "Board",
                border: OutlineInputBorder(),
              ),
              items: boardOptions
                  .map(
                    (e) => DropdownMenuItem(
                  value: e,
                  child: Text(e),
                ),
              )
                  .toList(),
              onChanged: onBoardChanged,
            ),

            const SizedBox(height: 18),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onClearFilters,
                icon: const Icon(Icons.refresh),
                label: const Text("Clear Filters"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}