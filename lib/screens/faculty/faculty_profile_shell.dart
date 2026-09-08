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
          left: 20,
          right: 20,
          bottom: 16,
          child: SafeArea(
            top: false,
            child: FilledButton.icon(
              onPressed: () => _logout(context),
              icon: const Icon(Icons.logout_outlined),
              label: const Text('Logout'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(48),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
