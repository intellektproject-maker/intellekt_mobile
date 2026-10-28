import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/colors.dart';
import '../../routes/app_routes.dart';

class AdminMenuScreen extends StatelessWidget {
  const AdminMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Menu'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.primary,
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: AppColors.surface,
            elevation: 0,
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFE8EAF6),
                child: Icon(Icons.assignment_ind_outlined, color: AppColors.primary),
              ),
              title: const Text('Enquiries', style: TextStyle(fontWeight: FontWeight.w700)),
              subtitle: const Text('Review enquiries and admission status'),
              trailing: const Icon(Icons.chevron_right, color: AppColors.primary),
              onTap: () => context.push(AppRoutes.adminEnquiries),
            ),
          ),
        ],
      ),
    );
  }
}
