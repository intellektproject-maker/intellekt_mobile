import 'package:flutter/material.dart';

import '../../core/constants/colors.dart';
import 'app_drawer.dart';

class AppLayout extends StatelessWidget {
  final String title;
  final Widget body;

  final bool isAdmin;
  final String facultyId;

  /// true -> Dashboard
  /// false -> Child screens
  final bool isHome;

  const AppLayout({
    super.key,
    required this.title,
    required this.body,
    required this.isAdmin,
    required this.facultyId,
    this.isHome = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      drawer: AppDrawer(
        isAdmin: isAdmin,
        facultyId: facultyId,
      ),

      appBar: AppBar(
        automaticallyImplyLeading: false,

        leading: isHome
            ? Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
        )
            : IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          },
        ),

        title: Text(title),

        centerTitle: true,

        elevation: 0,
      ),

      body: SafeArea(
        child: body,
      ),
    );
  }
}