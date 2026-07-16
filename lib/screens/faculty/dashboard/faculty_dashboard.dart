import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../routes/app_routes.dart';
import '../../../shared/layout/app_layout.dart';
import 'widgets/dashboard_menu_card.dart';

class FacultyDashboard extends StatelessWidget {
  final String facultyId;

  const FacultyDashboard({
    super.key,
    required this.facultyId,
  });

  bool get isAdmin {
    final number =
        int.tryParse(facultyId.substring(2)) ?? 999;

    return number == 1 || number == 2;
  }

  @override
  Widget build(BuildContext context) {
    return AppLayout(
      title: "INTELLEKT",
      facultyId: facultyId,
      isAdmin: isAdmin,
      isHome: true,

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            const SizedBox(height: 10),

            Text(
              isAdmin ? "Welcome Admin 👋" : "Welcome 👋",
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 5),

            Text(
              isAdmin ? "Administrator" : "Faculty",
              style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 30),

            DashboardMenuCard(
              title: "Attendance",
              subtitle: "Enter & Manage Attendance",
              icon: Icons.how_to_reg,
              onTap: () {
                context.push(
                  "${AppRoutes.facultyAttendance}?id=$facultyId",
                );
              },
            ),

            DashboardMenuCard(
              title: "Marks",
              subtitle: "Enter Student Marks",
              icon: Icons.assignment,
              onTap: () {},
            ),

            DashboardMenuCard(
              title: "Post Test",
              subtitle: "Create New Test",
              icon: Icons.quiz,
              onTap: () {},
            ),

            DashboardMenuCard(
              title: "Registered Students",
              subtitle: "View Student List",
              icon: Icons.people,
              onTap: () {},
            ),

            if (isAdmin)
              DashboardMenuCard(
                title: "Analytics",
                subtitle: "View Reports & Analytics",
                icon: Icons.analytics,
                onTap: () {},
              ),

            if (isAdmin)
              DashboardMenuCard(
                title: "Enquiries",
                subtitle: "Manage Student Enquiries",
                icon: Icons.question_answer,
                onTap: () {},
              ),

            DashboardMenuCard(
              title: "Profile",
              subtitle: "Faculty Profile",
              icon: Icons.person,
              onTap: () {
                context.push(
                  "${AppRoutes.facultyProfile}?id=$facultyId&loginId=$facultyId",
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}