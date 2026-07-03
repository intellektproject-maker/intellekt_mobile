import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';

class StudentDashboard extends StatelessWidget {
  const StudentDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,

      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text("Student Dashboard"),
      ),

      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            const Icon(
              Icons.school,
              size: 90,
              color: AppColors.primary,
            ),

            const SizedBox(height: 20),

            const Text(
              "Welcome Student",
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            const Text(
              "INTELLEKT Mobile",
              style: TextStyle(
                color: Colors.grey,
                fontSize: 16,
              ),
            ),

            const SizedBox(height: 40),

            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.notifications),
              label: const Text("Notifications"),
            ),

            const SizedBox(height: 15),

            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.person),
              label: const Text("Profile"),
            ),
          ],
        ),
      ),
    );
  }
}