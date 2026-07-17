  import 'package:flutter/material.dart';
  import '../../../core/constants/colors.dart';
  import '../../../services/attendance_record_service.dart';
  import '../../../models/student_model.dart';
  import '../../../models/attendance_record_model.dart';

  import 'widgets/attendance_table.dart';
  import 'widgets/attendance_preview_dialog.dart';
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
    final AttendanceRecordService attendanceService =
        AttendanceRecordService.instance;

    String? selectedClass;
    String? selectedSubject;

    DateTime selectedDate = DateTime.now();

    bool isSunday = false;
    bool isLoading = false;

    List<StudentModel> students = [];


    void markPresent(String rollNo) {
      setState(() {
        attendance[rollNo] = true;
      });
    }

    void markAbsent(String rollNo) {
      setState(() {
        attendance[rollNo] = false;
      });
    }
    Future<void> submitAttendance() async {
      final records = students.map((student) {
        return AttendanceRecordModel(
          rollNo: student.rollNo,
          studentName: student.name,
          className: student.className,
          board: student.board,
          subject: student.subject,
          attendanceDate: selectedDate,
          isPresent: attendance[student.rollNo] ?? true,
        );
      }).toList();

      await attendanceService.saveAttendance(
        records: records,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Attendance submitted successfully.",
          ),
        ),
      );
    }
    final Map<String, bool> attendance = {};
    final List<String> classes = [
      "I B.Sc",
      "II B.Sc",
      "III B.Sc",
    ];

    final List<String> subjects = [
      "Java",
      "Python",
      "Flutter",
    ];
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
      if (selectedClass == null ||
          selectedSubject == null) {
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

      final result =
      await attendanceService.loadStudents(
        className: selectedClass!,
        subject: selectedSubject!,
      );

      setState(() {
        students = result;

        attendance.clear();

        for (final student in students) {
          attendance[student.rollNo] = true;
        }

        isLoading = false;
      });

      if (!mounted) return;

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
                classes: classes,
                subjects: subjects,

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
                AttendanceTable(
                  students: students,
                  attendance: attendance,

                  onPresent: markPresent,

                  onAbsent: markAbsent,

                  onPreview: () {
                    showDialog(
                      context: context,
                      builder: (_) => AttendancePreviewDialog(
                        students: students,
                        attendance: attendance,
                        onSubmit: submitAttendance,
                      ),
                    );
                  },

                  onSubmit: submitAttendance,
                ),

            ],
          ),
        ),
      );
    }
  }