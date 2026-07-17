import 'package:flutter/material.dart';

import '../../../../core/constants/colors.dart';

class ManageAttendanceTabs extends StatelessWidget {
  final int selectedTab;
  final ValueChanged<int> onChanged;

  const ManageAttendanceTabs({
    super.key,
    required this.selectedTab,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _tab(
            index: 0,
            title: "Attendance Report",
          ),
          _tab(
            index: 1,
            title: "Marked Attendance",
          ),
        ],
      ),
    );
  }

  Widget _tab({
    required int index,
    required String title,
  }) {
    final selected = selectedTab == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => onChanged(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color:
            selected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color:
              selected ? Colors.white : Colors.black87,
            ),
          ),
        ),
      ),
    );
  }
}