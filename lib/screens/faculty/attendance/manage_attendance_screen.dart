import 'package:flutter/material.dart';

import '../../../core/constants/colors.dart';

class ManageAttendanceScreen extends StatelessWidget {
  final String facultyId;

  const ManageAttendanceScreen({
    super.key,
    required this.facultyId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Manage Attendance'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: const Center(
        child: Text(
          'Manage Attendance Screen',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}