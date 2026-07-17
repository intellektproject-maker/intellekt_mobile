import 'package:flutter/material.dart';

import '../../../core/constants/colors.dart';
import '../../../models/attendance_record_model.dart';
import '../../../services/attendance_record_service.dart';
import '../../../shared/layout/app_layout.dart';

import 'widgets/attendance_report_table.dart';
import 'widgets/manage_attendance_filters.dart';
import 'widgets/manage_attendance_tabs.dart';

class ManageAttendanceScreen extends StatefulWidget {
  final String facultyId;

  const ManageAttendanceScreen({
    super.key,
    required this.facultyId,
  });

  @override
  State<ManageAttendanceScreen> createState() =>
      _ManageAttendanceScreenState();
}

class _ManageAttendanceScreenState
    extends State<ManageAttendanceScreen> {
  final TextEditingController searchController =
  TextEditingController();

  final AttendanceRecordService attendanceService =
      AttendanceRecordService.instance;

  String? selectedClass;
  String? selectedSubject;

  DateTime? fromDate;
  DateTime? toDate;

  bool loading = false;

  int selectedTab = 0;

  List<AttendanceRecordModel> records = [];

  /// Temporary
  /// Later comes from Railway API
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
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> loadAttendanceReport() async {
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
      loading = true;
    });

    try {
      final result =
      await attendanceService.getAttendanceReport(
        className: selectedClass!,
        subject: selectedSubject!,
        keyword: searchController.text,
        from: fromDate,
        to: toDate,
      );

      if (!mounted) return;

      setState(() {
        records = result;
      });
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  Future<void> loadTodayAttendance() async {
    setState(() {
      loading = true;
    });

    try {
      final result =
      await attendanceService.getTodayAttendance();

      if (!mounted) return;

      setState(() {
        records = result;
      });
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  void clearReport() {
    setState(() {
      records.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppLayout(
      title: "INTELLEKT",
      isAdmin: widget.facultyId == "IG001",
      facultyId: widget.facultyId,
      isHome: false,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            Text(
              "Manage Attendance",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),

            const SizedBox(height: 20),

            ManageAttendanceTabs(
              selectedTab: selectedTab,
              onChanged: (index) async {
                setState(() {
                  selectedTab = index;
                });

                if (index == 1) {
                  await loadTodayAttendance();
                } else {
                  clearReport();
                }
              },
            ),

            const SizedBox(height: 25),

            if (selectedTab == 0)
              ManageAttendanceFilters(
                classes: classes,
                subjects: subjects,
                selectedClass: selectedClass,
                selectedSubject: selectedSubject,
                fromDate: fromDate,
                toDate: toDate,
                searchController: searchController,
                onClassChanged: (value) {
                  setState(() {
                    selectedClass = value;
                  });
                  clearReport();
                },
                onSubjectChanged: (value) {
                  setState(() {
                    selectedSubject = value;
                  });
                  clearReport();
                },
                onFromDateChanged: (value) {
                  setState(() {
                    fromDate = value;
                  });
                  clearReport();
                },
                onToDateChanged: (value) {
                  setState(() {
                    toDate = value;
                  });
                  clearReport();
                },
                onViewReport: loadAttendanceReport,
              ),

            const SizedBox(height: 25),

            if (loading)
              const Center(
                child: CircularProgressIndicator(),
              )
            else
              AttendanceReportTable(
                records: records,
              ),
          ],
        ),
      ),
    );
  }
}