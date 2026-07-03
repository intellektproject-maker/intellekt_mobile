import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/colors.dart';
import '../../core/constants/strings.dart';
import '../../routes/app_routes.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() =>
      _SplashScreenState();
}

class _SplashScreenState
    extends State<SplashScreen> {

  @override
  void initState() {
    super.initState();

    _initializeApp();
  }

  Future<void> _initializeApp() async {

    // Simulate loading

    await Future.delayed(
      const Duration(seconds: 2),
    );

    if (!mounted) return;

    context.go(AppRoutes.welcome);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,

      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment:
            MainAxisAlignment.center,

            children: [

              const Icon(
                Icons.school,
                size: 100,
                color: Colors.white,
              ),

              const SizedBox(height: 25),

              Text(
                AppStrings.appName,

                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),

              const SizedBox(height: 10),

              Text(
                AppStrings.appTagline,

                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),

              const SizedBox(height: 60),

              const CircularProgressIndicator(
                color: Colors.white,
              ),
            ],
          ),
        ),
      ),
    );
  }
}