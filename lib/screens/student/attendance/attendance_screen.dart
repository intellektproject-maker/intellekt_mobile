import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../providers/student/attendance_provider.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  String _rollNo = '';

  late DateTime _selectedMonth;

  String _presentSubjectFilter = 'All';
  String _absentSubjectFilter = 'All';

  @override
  void initState() {
    super.initState();

    _selectedMonth = DateTime(
      DateTime.now().year,
      DateTime.now().month,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final roll =
        GoRouterState.of(context).uri.queryParameters['roll'] ?? 'IA001';

    if (_rollNo != roll) {
      _rollNo = roll;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        context.read<AttendanceProvider>().loadAttendance(_rollNo);
      });
    }
  }

  Future<void> _selectMonth() async {
    final now = DateTime.now();

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime(2020),
      lastDate: now,
      helpText: 'Select Month',
    );

    if (selectedDate == null) return;

    setState(() {
      _selectedMonth = DateTime(
        selectedDate.year,
        selectedDate.month,
      );
    });
  }

  List<Map<String, dynamic>> _filterBySelectedMonth(
      List<Map<String, dynamic>> attendance,
      ) {
    return attendance.where((item) {
      final date = DateTime.tryParse(
        item['attendance_date']?.toString() ?? '',
      );

      if (date == null) return false;

      return date.year == _selectedMonth.year &&
          date.month == _selectedMonth.month;
    }).toList();
  }

  String _getSubjectName(dynamic subjectId) {
    switch (subjectId) {
      case 1:
        return 'Maths';

      case 2:
        return 'Physics';

      default:
        return 'Unknown';
    }
  }

  List<Map<String, dynamic>> _filterBySubject(
      List<Map<String, dynamic>> attendance,
      String filter,
      ) {
    if (filter == 'All') {
      return attendance;
    }

    return attendance.where((item) {
      return _getSubjectName(item['subject_id']) == filter;
    }).toList();
  }

  String _formatDate(dynamic dateValue) {
    final date = DateTime.tryParse(
      dateValue?.toString() ?? '',
    );

    if (date == null) {
      return 'Invalid Date';
    }

    return DateFormat('dd-MM-yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final attendanceProvider = context.watch<AttendanceProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFECECEF),
      body: SafeArea(
        child: _buildBody(attendanceProvider),
      ),
    );
  }

  Widget _buildBody(
      AttendanceProvider attendanceProvider,
      ) {
    if (attendanceProvider.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (attendanceProvider.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            attendanceProvider.error!,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final monthAttendance = _filterBySelectedMonth(
      attendanceProvider.attendance,
    );

    final presentDates = monthAttendance.where((item) {
      return item['status']?.toString().toLowerCase() == 'present';
    }).toList()
      ..sort(
            (a, b) => DateTime.parse(
          b['attendance_date'].toString(),
        ).compareTo(
          DateTime.parse(
            a['attendance_date'].toString(),
          ),
        ),
      );

    final absentDates = monthAttendance.where((item) {
      return item['status']?.toString().toLowerCase() == 'absent';
    }).toList()
      ..sort(
            (a, b) => DateTime.parse(
          b['attendance_date'].toString(),
        ).compareTo(
          DateTime.parse(
            a['attendance_date'].toString(),
          ),
        ),
      );

    final filteredPresentDates = _filterBySubject(
      presentDates,
      _presentSubjectFilter,
    );

    final filteredAbsentDates = _filterBySubject(
      absentDates,
      _absentSubjectFilter,
    );

    final daysInMonth = DateTime(
      _selectedMonth.year,
      _selectedMonth.month + 1,
      0,
    ).day;

    final present = presentDates.length;
    final absent = absentDates.length;

    final notEntered = (daysInMonth - monthAttendance.length)
        .clamp(0, daysInMonth);

    final sortedAttendance =
    List<Map<String, dynamic>>.from(monthAttendance)
      ..sort(
            (a, b) => DateTime.parse(
          b['attendance_date'].toString(),
        ).compareTo(
          DateTime.parse(
            a['attendance_date'].toString(),
          ),
        ),
      );

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 30,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Attendance',
            style: TextStyle(
              color: Color(0xFF0B3A82),
              fontSize: 30,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 35),

          Row(
            children: [
              const Text(
                'Month',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(width: 18),

              InkWell(
                onTap: _selectMonth,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 11,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(
                      color: Colors.grey.shade400,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Text(
                        DateFormat('MM/yyyy').format(_selectedMonth),
                      ),

                      const SizedBox(width: 12),

                      const Icon(
                        Icons.calendar_month_outlined,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 25),

          _AttendanceSummaryCard(
            present: present,
            absent: absent,
            notEntered: notEntered,
            lastUpdatedDate: sortedAttendance.isEmpty
                ? 'No Data'
                : _formatDate(
              sortedAttendance.first['attendance_date'],
            ),
          ),

          const SizedBox(height: 24),

          _AttendanceListCard(
            title: 'Presents',
            attendance: filteredPresentDates,
            selectedFilter: _presentSubjectFilter,
            onFilterChanged: (value) {
              setState(() {
                _presentSubjectFilter = value;
              });
            },
            getSubjectName: _getSubjectName,
            formatDate: _formatDate,
          ),

          const SizedBox(height: 24),

          _AttendanceListCard(
            title: 'Absents',
            attendance: filteredAbsentDates,
            selectedFilter: _absentSubjectFilter,
            onFilterChanged: (value) {
              setState(() {
                _absentSubjectFilter = value;
              });
            },
            getSubjectName: _getSubjectName,
            formatDate: _formatDate,
          ),

          const SizedBox(height: 30),
        ],
      ),
    );
  }
}

class _AttendanceSummaryCard extends StatelessWidget {
  final int present;
  final int absent;
  final int notEntered;
  final String lastUpdatedDate;

  const _AttendanceSummaryCard({
    required this.present,
    required this.absent,
    required this.notEntered,
    required this.lastUpdatedDate,
  });

  @override
  Widget build(BuildContext context) {
    final total = present + absent + notEntered;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Attendance Summary',
            style: TextStyle(
              color: Color(0xFF1769E0),
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 25),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SummaryText(
                      label: 'Present',
                      value: present,
                      color: Colors.green,
                    ),

                    const SizedBox(height: 16),

                    _SummaryText(
                      label: 'Absent',
                      value: absent,
                      color: Colors.red,
                    ),

                    const SizedBox(height: 16),

                    _SummaryText(
                      label: 'Not Entered',
                      value: notEntered,
                      color: Colors.grey,
                    ),
                  ],
                ),
              ),

              SizedBox(
                width: 145,
                height: 145,
                child: total == 0
                    ? const Center(
                  child: Text('No Data'),
                )
                    : PieChart(
                  PieChartData(
                    centerSpaceRadius: 0,
                    sectionsSpace: 1,
                    sections: [
                      PieChartSectionData(
                        value: present.toDouble(),
                        color: Colors.green,
                        showTitle: false,
                        radius: 65,
                      ),
                      PieChartSectionData(
                        value: absent.toDouble(),
                        color: Colors.red,
                        showTitle: false,
                        radius: 65,
                      ),
                      PieChartSectionData(
                        value: notEntered.toDouble(),
                        color: Colors.grey,
                        showTitle: false,
                        radius: 65,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 25),

          Text(
            'Last Attendance Updated Date: $lastUpdatedDate',
            style: const TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryText extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _SummaryText({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(
          fontSize: 16,
          color: Color(0xFF4B5563),
        ),
        children: [
          TextSpan(
            text: '$label: ',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
          TextSpan(
            text: value.toString(),
          ),
        ],
      ),
    );
  }
}

class _AttendanceListCard extends StatelessWidget {
  final String title;
  final List<Map<String, dynamic>> attendance;
  final String selectedFilter;

  final ValueChanged<String> onFilterChanged;

  final String Function(dynamic) getSubjectName;
  final String Function(dynamic) formatDate;

  const _AttendanceListCard({
    required this.title,
    required this.attendance,
    required this.selectedFilter,
    required this.onFilterChanged,
    required this.getSubjectName,
    required this.formatDate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF1769E0),
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                ),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.grey.shade400,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedFilter,
                    items: const [
                      DropdownMenuItem(
                        value: 'All',
                        child: Text('All'),
                      ),
                      DropdownMenuItem(
                        value: 'Maths',
                        child: Text('Maths'),
                      ),
                      DropdownMenuItem(
                        value: 'Physics',
                        child: Text('Physics'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        onFilterChanged(value);
                      }
                    },
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          Container(
            width: double.infinity,
            height: 200,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.grey.shade300,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: attendance.isEmpty
                ? const Align(
              alignment: Alignment.topLeft,
              child: Text(
                'No Data',
                style: TextStyle(
                  color: Colors.grey,
                ),
              ),
            )
                : ListView.separated(
              itemCount: attendance.length,
              separatorBuilder: (_, _) {
                return const SizedBox(height: 10);
              },
              itemBuilder: (context, index) {
                final item = attendance[index];

                return Row(
                  children: [
                    Expanded(
                      child: Text(
                        formatDate(
                          item['attendance_date'],
                        ),
                      ),
                    ),
                    Text(
                      getSubjectName(
                        item['subject_id'],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

BoxDecoration _cardDecoration() {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(
      color: const Color(0xFFE5E7EB),
    ),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.08),
        blurRadius: 8,
        offset: const Offset(0, 4),
      ),
    ],
  );
}