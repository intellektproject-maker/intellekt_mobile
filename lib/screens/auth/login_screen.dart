import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_sizes.dart';
import '../../core/constants/assets.dart';
import '../../core/constants/strings.dart';
import '../../core/constants/colors.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_loader.dart';
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
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();

    final success = await auth.login(
      id: _idController.text.trim().toUpperCase(),
      password: _passwordController.text.trim(),
    );

    if (!mounted) return;

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.error ?? "Login failed"),
        ),
      );
      return;
    }

    final user = auth.user!;

    if (user.mustResetPassword) {
      Navigator.pushReplacementNamed(
        context,
        AppRoutes.changePassword,
      );
      return;
    }

    switch (user.role) {
      case "student":
        Navigator.pushReplacementNamed(
          context,
          AppRoutes.studentDashboard,
        );
        break;

      case "faculty":
        Navigator.pushReplacementNamed(
          context,
          AppRoutes.facultyDashboard,
        );
        break;

      case "admin":
        Navigator.pushReplacementNamed(
          context,
          AppRoutes.adminDashboard,
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSizes.paddingLarge),
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
                      AppAssets.logo,
                      height: 120,
                    ),

                    const SizedBox(height: 25),

                    const Text(
                      AppStrings.appName,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),

                    const SizedBox(height: 8),

                    const Text(
                      "Student • Faculty • Admin",
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 15,
                      ),
                    ),

                    const SizedBox(height: 40),

                    CustomTextField(
                      controller: _passwordController,
                      label: "Password",
                      hint: "Enter Password",
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Enter Password";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 30),

                    auth.isLoading
                        ? const CustomLoader()
                        : SizedBox(
                      width: double.infinity,
                      child: CustomButton(
                        text: "LOGIN",
                        onPressed: _login,
                      ),
                    ),

                    const SizedBox(height: 30),

                    const Text(
                      "Version 1.0.0",
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 13,
                      ),
                    ),

                    const SizedBox(height: 12),

                    const Text(
                      "© INTELLEKT",
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