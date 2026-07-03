import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/colors.dart';
import '../../core/constants/strings.dart';
import '../../routes/app_routes.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 28,
            vertical: 20,
          ),
          child: Column(
            children: [

              const Spacer(),

              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.school_rounded,
                  color: AppColors.primary,
                  size: 80,
                ),
              ),

              const SizedBox(height: 30),

              Text(
                AppStrings.appName,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),

              const SizedBox(height: 12),

              Text(
                AppStrings.appTagline,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 17,
                  color: Colors.black54,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 50),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: () {
                    context.go(AppRoutes.login);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    "Get Started",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 18),

              Text(
                "Version 1.0.0",
                style: TextStyle(
                  color: Colors.grey.shade600,
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}