import 'package:flutter/material.dart';

import '../../../core/constants/colors.dart';

class EnterAttendanceScreen extends StatelessWidget {
  final String facultyId;

  const EnterAttendanceScreen({
    super.key,
    required this.facultyId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Enter Attendance'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: const Center(
        child: Text(
          'Enter Attendance Screen',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}