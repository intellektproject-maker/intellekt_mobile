import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_sizes.dart';
import '../../core/constants/colors.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_textfield.dart';
import '../../providers/auth_provider.dart';
import '../../routes/app_routes.dart';
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _idController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _idController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final authProvider = context.read<AuthProvider>();

    final success = await authProvider.login(
      id: _idController.text.trim(),
      password: _passwordController.text.trim(),
    );

    if (!mounted) return;

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            authProvider.error ?? 'Invalid ID or Password',
          ),
        ),
      );
      return;
    }

    final user = authProvider.user!;

    if (user.role == 'student') {
      context.go(
        '${AppRoutes.studentDashboard}?roll=${user.id}',
      );
    } else if (user.role == 'faculty') {
      context.go(
        '${AppRoutes.facultyProfile}?id=${user.id}&loginId=${user.id}',
      );
    } else if (user.role == 'admin') {
      context.go(
        '${AppRoutes.facultyProfile}?id=${user.id}&loginId=${user.id}',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(
              AppSizes.paddingLarge,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 420,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const SizedBox(height: 20),

                    Image.asset(
                      'assets/logo/logo.png',
                      height: 120,
                      fit: BoxFit.contain,
                    ),

                    const SizedBox(height: 25),

                    const Text(
                      'INTELLEKT',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),

                    const SizedBox(height: 8),

                    const Text(
                      'Student Login',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 15,
                      ),
                    ),

                    const SizedBox(height: 40),

                    CustomTextField(
                      controller: _idController,
                      label: 'Student ID',
                      hint: 'Enter Student ID',
                      validator: (value) {
                        if (value == null ||
                            value.trim().isEmpty) {
                          return 'Enter Student ID';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 20),

                    CustomTextField(
                      controller: _passwordController,
                      label: 'Password',
                      hint: 'Enter Password',
                      obscureText: true,
                      validator: (value) {
                        if (value == null ||
                            value.isEmpty) {
                          return 'Enter Password';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 30),

                    SizedBox(
                      width: double.infinity,
                      child: CustomButton(
                        text: 'LOGIN',
                        onPressed: _login,
                      ),
                    ),

                    const SizedBox(height: 30),

                    const Text(
                      'Version 1.0.0',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 13,
                      ),
                    ),

                    const SizedBox(height: 12),

                    const Text(
                      '© INTELLEKT',
                      style: TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}