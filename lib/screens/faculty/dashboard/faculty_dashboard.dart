import 'package:flutter/material.dart';

import '../../../core/constants/colors.dart';

class FacultyDashboard extends StatelessWidget {
  const FacultyDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,

      appBar: AppBar(
        title: const Text("Faculty Dashboard"),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),

      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [

              const Icon(
                Icons.school_outlined,
                size: 90,
                color: AppColors.primary,
              ),

              const SizedBox(height: 20),

              const Text(
                "Welcome Faculty",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              Text(
                "INTELLEKT Mobile",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
              ),

              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.assignment),
                  label: const Text("Enter Marks"),
                ),
              ),

              const SizedBox(height: 15),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.event_note),
                  label: const Text("Post Test"),
                ),
              ),

              const SizedBox(height: 15),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.people),
                  label: const Text("Registered Students"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}