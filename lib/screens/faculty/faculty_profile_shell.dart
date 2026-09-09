import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/colors.dart';
import '../../providers/auth_provider.dart';
import '../../routes/app_routes.dart';
import 'faculty_profile.dart';

class FacultyProfileShell extends StatelessWidget {
  final String facultyId;
  final AuthProvider authProvider;

  const FacultyProfileShell({
    super.key,
    required this.facultyId,
    required this.authProvider,
  });

  Future<void> _logout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    await authProvider.logout();
    if (context.mounted) context.go(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        FacultyProfile(facultyId: facultyId),
        Positioned(
          top: MediaQuery.paddingOf(context).top + 4,
          right: 8,
          child: IconButton.filledTonal(
            onPressed: () => _logout(context),
            tooltip: 'Logout',
            icon: const Icon(Icons.logout_outlined, size: 20),
            style: IconButton.styleFrom(
              foregroundColor: AppColors.primary,
              backgroundColor: Colors.white,
              padding: const EdgeInsets.all(9),
              minimumSize: const Size(40, 40),
              maximumSize: const Size(40, 40),
            ),
          ),
        ),
      ],
    );
  }
}
