import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';

class FacultyEnterMarksScreen extends StatelessWidget {
  final String facultyId;
  const FacultyEnterMarksScreen({super.key, required this.facultyId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Enter Marks'),
        foregroundColor: AppColors.primary,
        backgroundColor: AppColors.surface,
      ),
      body: const SizedBox.shrink(),
    );
  }
}
