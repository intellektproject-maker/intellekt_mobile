import 'package:flutter/material.dart';

import 'package:intellekt_mobile/models/student_details_model.dart';
import 'package:intellekt_mobile/services/student/student_service.dart';

Future<bool?> showStudentFormBottomSheet(
    BuildContext context, {
      StudentDetailsModel? student,
    }) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => StudentFormBottomSheet(
      student: student,
    ),
  );
}

class StudentFormBottomSheet extends StatefulWidget {
  final StudentDetailsModel? student;

  const StudentFormBottomSheet({
    super.key,
    this.student,
  });

  @override
  State<StudentFormBottomSheet> createState() =>
      _StudentFormBottomSheetState();
}

class _StudentFormBottomSheetState
    extends State<StudentFormBottomSheet> {
final StudentService _studentService = StudentService();

final _formKey = GlobalKey<FormState>();

late TextEditingController _rollNoController;
late TextEditingController _nameController;
late TextEditingController _classController;
late TextEditingController _boardController;
late TextEditingController _modeController;
late TextEditingController _emailController;
late TextEditingController _phoneController;
late TextEditingController _schoolController;
late TextEditingController _fatherController;
late TextEditingController _motherController;
late TextEditingController _addressController;

bool _saving = false;

bool get isEdit => widget.student != null;

@override
void initState() {
super.initState();

final s = widget.student;

_rollNoController =
TextEditingController(text: s?.rollNo ?? "");

_nameController =
TextEditingController(text: s?.name ?? "");

_classController =
TextEditingController(text: s?.className ?? "");

_boardController =
TextEditingController(text: s?.board ?? "");

_modeController =
TextEditingController(text: s?.modeOfEducation ?? "");

_emailController =
TextEditingController(text: s?.email ?? "");

_phoneController =
TextEditingController(text: s?.phone ?? "");

_schoolController =
TextEditingController(text: s?.schoolName ?? "");

_fatherController =
TextEditingController(text: s?.fatherName ?? "");

_motherController =
TextEditingController(text: s?.motherName ?? "");

_addressController =
TextEditingController(text: s?.address ?? "");
}

@override
void dispose() {
_rollNoController.dispose();
_nameController.dispose();
_classController.dispose();
_boardController.dispose();
_modeController.dispose();
_emailController.dispose();
_phoneController.dispose();
_schoolController.dispose();
_fatherController.dispose();
_motherController.dispose();
_addressController.dispose();

super.dispose();
}

InputDecoration decoration(String title) {
return InputDecoration(
labelText: title,
border: OutlineInputBorder(
borderRadius: BorderRadius.circular(12),
),
);
}

Widget buildField(
TextEditingController controller,
String label, {
int maxLines = 1,
}) {
return Padding(
padding: const EdgeInsets.only(bottom: 16),
child: TextFormField(
controller: controller,
maxLines: maxLines,
decoration: decoration(label),
validator: (value) {
if (value == null || value.trim().isEmpty) {
return "Required";
}
return null;
},
),
);
}

@override
Widget build(BuildContext context) {
final keyboard =
MediaQuery.of(context).viewInsets.bottom;

return Padding(
padding: EdgeInsets.only(bottom: keyboard),
child: DraggableScrollableSheet(
expand: false,
initialChildSize: .92,
maxChildSize: .95,
minChildSize: .60,
builder: (_, controller) {
return Form(
key: _formKey,
child: ListView(
controller: controller,
padding: const EdgeInsets.all(20),
children: [
Text(
isEdit
? "Edit Student"
: "Add Student",
style: const TextStyle(
fontSize: 26,
fontWeight: FontWeight.bold,
),
),

const SizedBox(height: 25),

buildField(
_rollNoController,
"Roll Number",
),

buildField(
_nameController,
"Student Name",
),

buildField(
_classController,
"Class",
),

buildField(
_boardController,
"Board",
),

buildField(
_modeController,
"Mode Of Education",
),

buildField(
_emailController,
"Email",
),

buildField(
_phoneController,
"Phone",
),

buildField(
_schoolController,
"School",
),

buildField(
_fatherController,
"Father Name",
),

buildField(
_motherController,
"Mother Name",
),

buildField(
_addressController,
"Address",
maxLines: 3,
),

const SizedBox(height: 20),
SizedBox(
height: 55,
child: ElevatedButton.icon(
icon: _saving
? const SizedBox(
width: 20,
height: 20,
child: CircularProgressIndicator(
strokeWidth: 2,
color: Colors.white,
),
)
: Icon(
isEdit
? Icons.save
: Icons.person_add,
),
label: Text(
isEdit
? "Update Student"
: "Add Student",
),
onPressed: _saving
? null
: () async {
if (!_formKey.currentState!.validate()) {
return;
}

setState(() {
_saving = true;
});

try {
if (isEdit) {
final updatedStudent =
widget.student!.copyWith(
rollNo: _rollNoController.text.trim(),
name: _nameController.text.trim(),
className:
_classController.text.trim(),
board:
_boardController.text.trim(),
modeOfEducation:
_modeController.text.trim(),
email:
_emailController.text.trim(),
phone:
_phoneController.text.trim(),
schoolName:
_schoolController.text.trim(),
fatherName:
_fatherController.text.trim(),
motherName:
_motherController.text.trim(),
address:
_addressController.text.trim(),
);

await _studentService
.updateStudent(updatedStudent);
} else {
final newStudent =
StudentDetailsModel(
id: DateTime.now()
.millisecondsSinceEpoch
.toString(),
rollNo:
_rollNoController.text.trim(),
name:
_nameController.text.trim(),
gender: "Male",
dob: "",
className:
_classController.text.trim(),
board:
_boardController.text.trim(),
modeOfEducation:
_modeController.text.trim(),
email:
_emailController.text.trim(),
phone:
_phoneController.text.trim(),
fatherName:
_fatherController.text.trim(),
motherName:
_motherController.text.trim(),
schoolName:
_schoolController.text.trim(),
address:
_addressController.text.trim(),
subjects: const [],
password: "123456",
totalFee: 0,
paidFee: 0,
active: true,
);

await _studentService
.addStudent(newStudent);
}

if (!mounted) return;

Navigator.pop(context, true);
} catch (e) {
  if (!mounted) return;

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      backgroundColor: Colors.red,
      content: Text(
        "Error: $e",
      ),
    ),
  );
} finally {
  if (mounted) {
    setState(() {
      _saving = false;
    });
  }
}
},
),
),

  const SizedBox(height: 20),
],
),
);
},
),
);
}
}