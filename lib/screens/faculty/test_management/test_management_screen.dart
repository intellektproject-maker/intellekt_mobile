import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
class TestManagementScreen extends StatelessWidget {
  const TestManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text("INTELLEKT"),
        backgroundColor: const Color(0xFF1D4ED8),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Test Management",
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1D4ED8),
              ),
            ),

            const SizedBox(height: 30),

            _MenuCard(
              title: "Enter Marks",
              subtitle: "Add marks for students after a test.",
              onTap: () {
                context.push('/faculty/enter-marks');
              },
            ),

            const SizedBox(height: 20),

            _MenuCard(
              title: "Manage Marks",
              subtitle: "View and edit student marks.",
              onTap: () {
                context.push('/faculty/manage-marks');
              },
            ),

            const SizedBox(height: 20),

            _MenuCard(
              title: "Post Test",
              subtitle: "Schedule upcoming tests.",
              onTap: () {
                context.push('/faculty/post-test');
              },
            ),

            const SizedBox(height: 20),

            _MenuCard(
              title: "Registered Students",
              subtitle: "View registered students and download PDF.",
              onTap: () {
                context.push('/faculty/registered-students');
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _MenuCard({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1D4ED8),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 18,
                color: Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}