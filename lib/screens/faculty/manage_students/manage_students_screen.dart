import 'package:flutter/material.dart';
import 'package:intellekt_mobile/models/student_details_model.dart';
import 'package:intellekt_mobile/services/student/student_service.dart';
import 'package:intellekt_mobile/screens/faculty/manage_students/widgets/student_filters.dart';
import 'package:intellekt_mobile/screens/faculty/manage_students/widgets/student_form_bottom_sheet.dart';
import 'package:intellekt_mobile/screens/faculty/manage_students/widgets/student_table.dart';

class ManageStudentsScreen extends StatefulWidget {
  const ManageStudentsScreen({super.key});

  @override
  State<ManageStudentsScreen> createState() =>
      _ManageStudentsScreenState();
}

class _ManageStudentsScreenState
    extends State<ManageStudentsScreen> {
final StudentService _studentService = StudentService();

List<StudentDetailsModel> _students = [];
List<StudentDetailsModel> _filteredStudents = [];

final TextEditingController _searchController =
TextEditingController();

String? _selectedClass;
String? _selectedBoard;

@override
void initState() {
super.initState();
_loadStudents();

_searchController.addListener(_applyFilters);
}

@override
void dispose() {
_searchController.dispose();
super.dispose();
}

Future<void> _loadStudents() async {
final students =
await _studentService.getStudents();

if (!mounted) return;

setState(() {
_students = students;
});

_applyFilters();
}

void _applyFilters() {
final query =
_searchController.text.toLowerCase();

setState(() {
_filteredStudents = _students.where((student) {
final matchesSearch =
student.name
.toLowerCase()
.contains(query) ||
student.rollNo
.toLowerCase()
.contains(query);

final matchesClass =
_selectedClass == null ||
student.className ==
_selectedClass;

final matchesBoard =
_selectedBoard == null ||
student.board ==
_selectedBoard;

return matchesSearch &&
matchesClass &&
matchesBoard;
}).toList();
});
}

Future<void> _deleteStudent(
StudentDetailsModel student) async {
await _studentService.deleteStudent(
student.id,
);

await _loadStudents();
}

List<String> get _classOptions {
return _students
.map((e) => e.className)
.toSet()
.toList()
..sort();
}

List<String> get _boardOptions {
return _students
.map((e) => e.board)
.toSet()
.toList()
..sort();
}

@override
Widget build(BuildContext context) {
return Scaffold(
  appBar: AppBar(
    leading: IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => Navigator.pop(context),
    ),
    title: const Text("Manage Students"),
  ),
floatingActionButton:
FloatingActionButton.extended(
onPressed: () async {
final result =
await showStudentFormBottomSheet(
context,
);

if (result == true) {
await _loadStudents();
}
},
icon: const Icon(Icons.add),
label: const Text("Student"),
),
body: RefreshIndicator(
onRefresh: _loadStudents,
child: ListView(
padding:
const EdgeInsets.all(16),
children: [
  TextField(
    controller: _searchController,
    decoration: InputDecoration(
      hintText: "Search by name or roll number",
      prefixIcon: const Icon(Icons.search),
      border: OutlineInputBorder(
        borderRadius:
        BorderRadius.circular(12),
      ),
    ),
  ),

  const SizedBox(height: 16),

  StudentFilters(
    selectedClass: _selectedClass,
    selectedBoard: _selectedBoard,
    classOptions: _classOptions,
    boardOptions: _boardOptions,

    onClassChanged: (value) {
      setState(() {
        _selectedClass = value;
      });
      _applyFilters();
    },

    onBoardChanged: (value) {
      setState(() {
        _selectedBoard = value;
      });
      _applyFilters();
    },

    onClearFilters: () {
      _searchController.clear();

      setState(() {
        _selectedClass = null;
        _selectedBoard = null;
      });

      _applyFilters();
    },
  ),

  const SizedBox(height: 20),

  if (_filteredStudents.isEmpty)
    const Padding(
      padding: EdgeInsets.symmetric(
        vertical: 80,
      ),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.school_outlined,
              size: 60,
              color: Colors.grey,
            ),
            SizedBox(height: 12),
            Text(
              "No students found",
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    )
  else
    StudentTable(
      students: _filteredStudents,
      onRefresh: _loadStudents,
      onDelete: _deleteStudent,
    ),

  const SizedBox(height: 100),
],
),
),
);
}
}