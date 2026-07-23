import 'package:flutter/material.dart';

import 'package:intellekt_mobile/models/student_details_model.dart';

import 'student_form_bottom_sheet.dart';

class StudentTable extends StatelessWidget {
final List<StudentDetailsModel> students;

final Future<void> Function(StudentDetailsModel)
onDelete;

final Future<void> Function() onRefresh;

const StudentTable({
super.key,
required this.students,
required this.onDelete,
required this.onRefresh,
});

@override
Widget build(BuildContext context) {
if (students.isEmpty) {
return const Center(
child: Padding(
padding: EdgeInsets.all(30),
child: Text(
"No students found",
style: TextStyle(fontSize: 16),
),
),
);
}

return ListView.separated(
shrinkWrap: true,
physics:
const NeverScrollableScrollPhysics(),
itemCount: students.length,
separatorBuilder: (_, __) =>
const SizedBox(height: 12),
itemBuilder: (context, index) {
final student = students[index];

return Card(
elevation: 3,
shape: RoundedRectangleBorder(
borderRadius:
BorderRadius.circular(14),
),
child: InkWell(
borderRadius:
BorderRadius.circular(14),
onTap: () =>
_showStudent(context, student),
child: Padding(
padding:
const EdgeInsets.all(16),
child: Row(
children: [

CircleAvatar(
radius: 28,
backgroundColor:
Colors.blue.shade100,
child: Text(
student.name[0]
.toUpperCase(),
style:
const TextStyle(
fontWeight:
FontWeight.bold,
fontSize: 22,
color: Colors.blue,
),
),
),

const SizedBox(width: 15),

Expanded(
child: Column(
crossAxisAlignment:
CrossAxisAlignment
.start,
children: [

Text(
student.name,
style:
const TextStyle(
fontSize: 18,
fontWeight:
FontWeight
.bold,
),
),

const SizedBox(
height: 5),

Text(
student.rollNo,
),

const SizedBox(
height: 4),

Text(
student.className,
),

const SizedBox(
height: 4),

Text(
student.phone,
),
],
),
),

const Icon(
Icons.arrow_forward_ios,
size: 18,
),
],
),
),
),
);
},
);
}

void _showStudent(
BuildContext context,
StudentDetailsModel student,
) {
showModalBottomSheet(
context: context,
isScrollControlled: true,
showDragHandle: true,
builder: (_) {
return DraggableScrollableSheet(
expand: false,
initialChildSize: .90,
maxChildSize: .95,
minChildSize: .50,
builder: (context, controller) {
return SingleChildScrollView(
controller: controller,
padding: const EdgeInsets.all(20),
child: Column(
crossAxisAlignment:
CrossAxisAlignment.start,
children: [

Center(
child: CircleAvatar(
radius: 36,
backgroundColor:
Colors.blue.shade100,
child: Text(
student.name[0]
.toUpperCase(),
style:
const TextStyle(
fontSize: 30,
fontWeight:
FontWeight.bold,
color: Colors.blue,
),
),
),
),

const SizedBox(height: 15),

Center(
child: Text(
student.name,
style:
const TextStyle(
fontSize: 24,
fontWeight:
FontWeight.bold,
),
),
),

const SizedBox(height: 25),

_infoTile(
"Roll Number",
student.rollNo,
),

_infoTile(
"Class",
student.className,
),

_infoTile(
"Board",
student.board,
),

_infoTile(
"Mode",
student.modeOfEducation,
),

_infoTile(
"Email",
student.email,
),

_infoTile(
"Phone",
student.phone,
),

_infoTile(
"School",
student.schoolName,
),

_infoTile(
"Father",
student.fatherName,
),

_infoTile(
"Mother",
student.motherName,
),

_infoTile(
"Address",
student.address,
),

_infoTile(
"Fee",
"₹${student.paidFee.toStringAsFixed(0)} / ₹${student.totalFee.toStringAsFixed(0)}",
),

_infoTile(
"Status",
student.active
? "Active"
: "Inactive",
),

const SizedBox(height: 20),

const Text(
"Subjects",
style: TextStyle(
fontSize: 18,
fontWeight:
FontWeight.bold,
),
),

const SizedBox(height: 10),

Wrap(
spacing: 8,
runSpacing: 8,
children: student.subjects
.map(
(subject) => Chip(
label: Text(subject),
),
)
.toList(),
),

const SizedBox(height: 25),
  Row(
    children: [
      Expanded(
        child: ElevatedButton.icon(
          icon: const Icon(Icons.edit),
          label: const Text("Edit"),
          onPressed: () async {
            Navigator.pop(context);

            final result =
            await showStudentFormBottomSheet(
              context,
              student: student,
            );

            if (result == true) {
              await onRefresh();
            }
          },
        ),
      ),

      const SizedBox(width: 12),

      Expanded(
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
          ),
          icon: const Icon(Icons.delete),
          label: const Text("Delete"),
          onPressed: () async {
            final confirm =
            await showDialog<bool>(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text(
                  "Delete Student",
                ),
                content: Text(
                  "Delete ${student.name}?",
                ),
                actions: [
                  TextButton(
                    onPressed: () =>
                        Navigator.pop(
                          context,
                          false,
                        ),
                    child:
                    const Text("Cancel"),
                  ),
                  ElevatedButton(
                    style:
                    ElevatedButton
                        .styleFrom(
                      backgroundColor:
                      Colors.red,
                    ),
                    onPressed: () =>
                        Navigator.pop(
                          context,
                          true,
                        ),
                    child:
                    const Text("Delete"),
                  ),
                ],
              ),
            );

            if (confirm == true) {
              Navigator.pop(context);

              await onDelete(student);
            }
          },
        ),
      ),
    ],
  ),

  const SizedBox(height: 30),
],
),
);
},
);
},
);
}

Widget _infoTile(
    String title,
    String value,
    ) {
  return Padding(
    padding:
    const EdgeInsets.only(bottom: 14),
    child: Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 13,
          ),
        ),

        const SizedBox(height: 4),

        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ],
    ),
  );
}
}