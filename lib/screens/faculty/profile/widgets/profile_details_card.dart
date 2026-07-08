import 'package:flutter/material.dart';

import '../../../../models/faculty_model.dart';

class ProfileDetailsCard extends StatelessWidget {
  final FacultyModel faculty;

  const ProfileDetailsCard({
    super.key,
    required this.faculty,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetail(
            label: 'Faculty ID',
            value: faculty.facultyId,
          ),
          const SizedBox(height: 16),
          _buildDetail(
            label: 'Name',
            value: faculty.name,
          ),
          const SizedBox(height: 16),
          _buildDetail(
            label: 'Email',
            value: faculty.email,
          ),
          const SizedBox(height: 16),
          _buildDetail(
            label: 'Phone',
            value: faculty.phone,
          ),
        ],
      ),
    );
  }

  Widget _buildDetail({
    required String label,
    required String value,
  }) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(
          color: Color(0xFF374151),
          fontSize: 17,
        ),
        children: [
          TextSpan(
            text: '$label: ',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          TextSpan(text: value),
        ],
      ),
    );
  }
}