import 'package:flutter/material.dart';
import '../../../models/attendance_student_model.dart';
import '../../../core/constants/colors.dart';
import '../../../repositories/mock/mock_attendance_repository.dart';
import 'widgets/attendance_filter_card.dart';

class EnterAttendanceScreen extends StatefulWidget {
  final String facultyId;

  const EnterAttendanceScreen({
    super.key,
    required this.facultyId,
  });

  @override
  State<EnterAttendanceScreen> createState() =>
      _EnterAttendanceScreenState();
}

class _EnterAttendanceScreenState
    extends State<EnterAttendanceScreen> {
  final MockAttendanceRepository repository =
  MockAttendanceRepository();

  String? selectedClass;
  String? selectedSubject;

  DateTime selectedDate = DateTime.now();

  bool isSunday = false;
  bool isLoading = false;

  List<AttendanceStudentModel> students = [];

  @override
  void initState() {
    super.initState();
    _checkSunday();
  }

  void _checkSunday() {
    isSunday = selectedDate.weekday == DateTime.sunday;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2025),
      lastDate: DateTime.now(),
    );

    if (picked == null) return;

    setState(() {
      selectedDate = picked;
      isSunday = picked.weekday == DateTime.sunday;

      if (isSunday) {
        selectedClass = null;
        selectedSubject = null;
      }
    });
  }

  Future<void> _loadStudents() async {
    if (!isSunday &&
        (selectedClass == null || selectedSubject == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Please select Class and Subject.",
          ),
        ),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    final result = await repository.loadStudents(
      className: selectedClass ?? '',
      subject: selectedSubject ?? '',
      date: selectedDate,
    );

    setState(() {
      students = result;
      isLoading = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "${students.length} students loaded.",
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,

      appBar: AppBar(
        title: const Text("Enter Attendance"),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            if (isSunday)
              Container(
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.blue.shade200,
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "Sunday detected. Test Attendance Mode is active.",
                      ),
                    ),
                  ],
                ),
              ),

            AttendanceFilterCard(
              selectedClass: selectedClass,
              selectedSubject: selectedSubject,
              selectedDate: selectedDate,
              onClassChanged: (value) {
                setState(() {
                  selectedClass = value;
                });
              },
              onSubjectChanged: (value) {
                setState(() {
                  selectedSubject = value;
                });
              },
              onSelectDate: _pickDate,
              onLoadStudents: _loadStudents,
            ),

            const SizedBox(height: 30),

            if (isLoading)
              const Center(
                child: CircularProgressIndicator(),
              ),

            if (!isLoading && students.isNotEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Text(
                    "${students.length} students loaded successfully.\n\nAttendance Table will be added in the next sprint.",
                    style: const TextStyle(
                      fontSize: 16,
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