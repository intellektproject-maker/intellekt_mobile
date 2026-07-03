import 'package:flutter/material.dart';

import '../../../core/constants/colors.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,

      appBar: AppBar(
        title: const Text("Admin Dashboard"),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [

            const SizedBox(height: 20),

            const CircleAvatar(
              radius: 45,
              backgroundColor: AppColors.primary,
              child: Icon(
                Icons.admin_panel_settings,
                color: Colors.white,
                size: 50,
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              "Welcome Admin",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            Text(
              "INTELLEKT Mobile",
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 16,
              ),
            ),

            const SizedBox(height: 40),

            _menuButton(
              icon: Icons.people,
              title: "Student Management",
            ),

            const SizedBox(height: 15),

            _menuButton(
              icon: Icons.school,
              title: "Faculty Management",
            ),

            const SizedBox(height: 15),

            _menuButton(
              icon: Icons.question_answer,
              title: "Enquiries",
            ),

            const SizedBox(height: 15),

            _menuButton(
              icon: Icons.bar_chart,
              title: "Reports",
            ),

            const SizedBox(height: 15),

            _menuButton(
              icon: Icons.analytics,
              title: "Analytics",
            ),

            const SizedBox(height: 15),

            _menuButton(
              icon: Icons.person,
              title: "Profile",
            ),
          ],
        ),
      ),
    );
  }

  Widget _menuButton({
    required IconData icon,
    required String title,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton.icon(
        onPressed: () {},
        icon: Icon(icon),
        label: Text(title),
      ),
    );
  }
}