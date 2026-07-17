import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/faculty/test_management/enter_marks_provider.dart';
import 'widgets/filter_dropdown.dart';
import 'widgets/marks_table.dart';
import 'widgets/search_box.dart';
import 'widgets/section_title.dart';
import 'widgets/test_code_dropdown.dart';

class EnterMarksScreen extends StatefulWidget {
  const EnterMarksScreen({super.key});

  @override
  State<EnterMarksScreen> createState() => _EnterMarksScreenState();
}

class _EnterMarksScreenState extends State<EnterMarksScreen> {
final TextEditingController searchController = TextEditingController();
final TextEditingController totalMarksController = TextEditingController();

@override
void initState() {
super.initState();

Future.microtask(() {
context.read<EnterMarksProvider>().initialize();
});

searchController.addListener(() {
context.read<EnterMarksProvider>().updateSearch(
searchController.text,
);
});
}

@override
void dispose() {
searchController.dispose();
totalMarksController.dispose();
super.dispose();
}

@override
Widget build(BuildContext context) {
final provider = context.watch<EnterMarksProvider>();

return Scaffold(
appBar: AppBar(
title: const Text("Enter Marks"),
elevation: 0,
),
body: provider.isLoading
? const Center(
child: CircularProgressIndicator(),
)
: ListView(
padding: const EdgeInsets.all(20),
children: [
const SectionTitle(
title: "Enter Marks",
),

const SizedBox(height: 24),

SearchBox(
controller: searchController,
),

const SizedBox(height: 20),

Row(
children: [
Expanded(
child: FilterDropdown(
label: "Class",
value: provider.selectedClass,
items: const [
"XI",
"XII",
],
onChanged: (value) async {
if (value == null) return;

await provider.loadTestCodes(
className: value,
board: provider.selectedBoard,
subject: provider.selectedSubject,
);
},
),
),

const SizedBox(width: 16),

Expanded(
child: FilterDropdown(
label: "Board",
value: provider.selectedBoard,
items: const [
"State Board",
"CBSE",
],
onChanged: (value) async {
if (value == null) return;

await provider.loadTestCodes(
className: provider.selectedClass,
board: value,
subject: provider.selectedSubject,
);
},
),
),
],
),

const SizedBox(height: 16),

FilterDropdown(
label: "Subject",
value: provider.selectedSubject,
items: const [
"Mathematics",
"Physics",
"Chemistry",
],
onChanged: (value) async {
if (value == null) return;

await provider.loadTestCodes(
className: provider.selectedClass,
board: provider.selectedBoard,
subject: value,
);
},
),

const SizedBox(height: 20),

TestCodeDropdown(
codes: provider.filteredTestCodes,
selected: provider.selectedTestCode,
onChanged: (value) {
if (value != null) {
provider.selectTestCode(value);
}
},
),

const SizedBox(height: 20),

TextField(
readOnly: true,
decoration: const InputDecoration(
labelText: "Class",
filled: true,
border: OutlineInputBorder(),
),
controller: TextEditingController(
text: provider.selectedTestCode == null
? ""
: "${provider.selectedTestCode!.className} • ${provider.selectedTestCode!.board}",
),
),

const SizedBox(height: 20),

TextField(
controller: totalMarksController,
keyboardType: TextInputType.number,
decoration: const InputDecoration(
labelText: "Total Marks",
border: OutlineInputBorder(),
),
onChanged: provider.updateTotalMarks,
),
  const SizedBox(height: 24),

  SizedBox(
    height: 48,
    child: ElevatedButton.icon(
      onPressed: provider.selectedTestCode == null
          ? null
          : () async {
        await provider.loadStudents();
      },
      icon: const Icon(Icons.people),
      label: const Text("Load Students"),
    ),
  ),

  const SizedBox(height: 20),

  if (provider.selectedTestCode != null)
    Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.blue.shade200,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline,
            color: Colors.blue,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              "Selected Test: ${provider.selectedTestCode!.code}",
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    ),

  const SizedBox(height: 24),

  if (provider.selectedTestCode != null)
    Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: MarksTable(
          students: provider.students,
          onMarksChanged: provider.updateMarks,
        ),
      ),
    ),

  const SizedBox(height: 30),

  SizedBox(
    height: 50,
    child: ElevatedButton(
      onPressed: provider.selectedTestCode == null ||
          provider.isSaving
          ? null
          : () async {
        await provider.saveMarks();

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Marks saved successfully",
            ),
          ),
        );
      },
      child: provider.isSaving
          ? const SizedBox(
        height: 22,
        width: 22,
        child: CircularProgressIndicator(
          strokeWidth: 2,
        ),
      )
          : const Text(
        "Save Marks",
      ),
    ),
  ),
],
),
);
}
}