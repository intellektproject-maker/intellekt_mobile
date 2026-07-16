import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/colors.dart';
import '../../routes/app_routes.dart';
import '../models/drawer_item.dart';

class AppDrawer extends StatefulWidget {
  final bool isAdmin;
  final String facultyId;

  const AppDrawer({
    super.key,
    required this.isAdmin,
    required this.facultyId,
  });

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  bool manageExpanded = false;

  List<DrawerItemModel> get menu => [
    DrawerItemModel(
      title: "Profile",
      icon: Icons.person_outline,
      route:
      "${AppRoutes.facultyProfile}?id=${widget.facultyId}&loginId=${widget.facultyId}",
    ),

    DrawerItemModel(
      title: "Attendance",
      icon: Icons.how_to_reg_outlined,
      route:
      "${AppRoutes.facultyAttendance}?id=${widget.facultyId}",
    ),

    DrawerItemModel(
      title: "Test",
      icon: Icons.quiz_outlined,
      route: AppRoutes.facultyTest,
    ),

    DrawerItemModel(
      title: "Manage",
      icon: Icons.folder_open_outlined,
      route: "",
      children: [
        DrawerItemModel(
          title: "Students",
          icon: Icons.people_outline,
          route: AppRoutes.facultyManageStudents,
        ),
        DrawerItemModel(
          title: "Faculty",
          icon: Icons.school_outlined,
          route: AppRoutes.facultyManageFaculty,
        ),
      ],
    ),

    DrawerItemModel(
      title: "Student Record",
      icon: Icons.menu_book_outlined,
      route: AppRoutes.facultyStudentRecord,
      adminOnly: true,
    ),

    DrawerItemModel(
      title: "Enquiries",
      icon: Icons.question_answer_outlined,
      route: AppRoutes.facultyEnquiries,
      adminOnly: true,
    ),

    DrawerItemModel(
      title: "Requests",
      icon: Icons.request_page_outlined,
      route: AppRoutes.facultyRequests,
      adminOnly: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Container(
              height: 90,
              width: double.infinity,
              color: AppColors.primary,
              alignment: Alignment.center,
              child: const Text(
                "INTELLEKT",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
            ),

            Expanded(
              child: ListView(
                children: menu.map(_buildItem).toList(),
              ),
            ),

            const Divider(),

            ListTile(
              leading: const Icon(Icons.lock_reset),
              title: const Text("Reset Password"),
              onTap: () {},
            ),

            ListTile(
              leading: const Icon(
                Icons.logout,
                color: Colors.red,
              ),
              title: const Text(
                "Sign Out",
                style: TextStyle(
                  color: Colors.red,
                ),
              ),
              onTap: () {
                context.go(AppRoutes.login);
              },
            ),

            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildItem(DrawerItemModel item) {
    if (item.adminOnly && !widget.isAdmin) {
      return const SizedBox.shrink();
    }

    if (item.hasChildren) {
      return ExpansionTile(
        leading: Icon(item.icon),
        title: Text(item.title),
        initiallyExpanded: manageExpanded,
        onExpansionChanged: (value) {
          setState(() {
            manageExpanded = value;
          });
        },
        children: item.children
            .map(
              (child) => ListTile(
            leading: Icon(child.icon),
            title: Text(child.title),
            onTap: () {
              Navigator.pop(context);
              context.push(child.route);
            },
          ),
        )
            .toList(),
      );
    }

    return ListTile(
      leading: Icon(item.icon),
      title: Text(item.title),
      onTap: () {
        Navigator.pop(context);

        context.push(item.route);
      },
    );
  }
}