import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/faculty/test_management/manage_marks_provider.dart';
import 'widgets/marks_table.dart';

class ManageMarksScreen extends StatefulWidget {
  const ManageMarksScreen({super.key});

  @override
  State<ManageMarksScreen> createState() => _ManageMarksScreenState();
}

class _ManageMarksScreenState extends State<ManageMarksScreen> {
  final TextEditingController _studentController = TextEditingController();

  @override
  void dispose() {
    _studentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ManageMarksProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Manage Marks"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextField(
                      controller: _studentController,
                      decoration: const InputDecoration(
                        labelText: "Student Name",
                        prefixIcon: Icon(Icons.person_outline),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: provider.updateStudentName,
                    ),

                    const SizedBox(height: 16),

                    DropdownButtonFormField<String>(
                      value: provider.className.isEmpty
                          ? null
                          : provider.className,
                      decoration: const InputDecoration(
                        labelText: "Class",
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: "12 A",
                          child: Text("12 A"),
                        ),
                      ],
                      onChanged: (value) {
                        provider.updateClass(value ?? '');
                      },
                    ),

                    const SizedBox(height: 16),

                    DropdownButtonFormField<String>(
                      value: provider.testCode.isEmpty
                          ? null
                          : provider.testCode,
                      decoration: const InputDecoration(
                        labelText: "Test Code",
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: "UT1",
                          child: Text("UT1"),
                        ),
                      ],
                      onChanged: (value) {
                        provider.updateTestCode(value ?? '');
                      },
                    ),

                    const SizedBox(height: 20),

                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: provider.isLoading
                                ? null
                                : () async {
                              await provider.searchMarks();
                            },
                            icon: const Icon(Icons.search),
                            label: Text(
                              provider.isLoading
                                  ? "Searching..."
                                  : "Search",
                            ),
                          ),
                        ),

                        const SizedBox(width: 12),

                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              _studentController.clear();
                              provider.clearFilters();
                            },
                            icon: const Icon(Icons.clear),
                            label: const Text("Clear"),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            if (provider.students.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(
                    child: Text("No marks found."),
                  ),
                ),
              )
            else
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: MarksTable(
                    students: provider.students,
                    onMarksChanged: provider.updateMarks,
                  ),
                ),
              ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: provider.students.isEmpty || provider.isSaving
                    ? null
                    : () async {
                  final success = await provider.saveMarks();

                  if (!context.mounted) return;

                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Marks saved successfully."),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.save),
                label: Text(
                  provider.isSaving ? "Saving..." : "Save Marks",
                ),
              ),
            ),

          ],
        ),
      ),
    );
  }
}