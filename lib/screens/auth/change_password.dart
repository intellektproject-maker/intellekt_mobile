import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_sizes.dart';
import '../../core/constants/colors.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_loader.dart';
import '../../core/widgets/custom_textfield.dart';
import '../../providers/auth_provider.dart';
import '../../routes/app_routes.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState
    extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();

  final _newPasswordController =
  TextEditingController();

  final _confirmPasswordController =
  TextEditingController();



  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;

    final auth =
    Provider.of<AuthProvider>(context, listen: false);

    final success = await auth.changePassword(
      newPassword:
      _newPasswordController.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
          Text("Password changed successfully"),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.login,
            (route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
          Text(auth.error ?? "Something went wrong"),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Change Password"),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(
            AppSizes.paddingLarge,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              children: [

                const SizedBox(height: 20),

                const Icon(
                  Icons.lock_reset,
                  color: AppColors.primary,
                  size: 80,
                ),

                const SizedBox(height: 20),

                const Text(
                  "Create a New Password",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 10),

                const Text(
                  "For security reasons, you must change your password before continuing.",
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 40),

                CustomTextField(
                  controller: _newPasswordController,
                  label: "New Password",
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Enter new password";
                    }

                    if (value.length < 6) {
                      return "Minimum 6 characters";
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 20),

                CustomTextField(
                  controller: _confirmPasswordController,
                  label: "Confirm Password",
                  obscureText: true,
                  validator: (value) {
                    if (value != _newPasswordController.text) {
                      return "Passwords do not match";
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 40),

                auth.isLoading
                    ? const CustomLoader()
                    : SizedBox(
                  width: double.infinity,
                  child: CustomButton(
                    text: "UPDATE PASSWORD",
                    onPressed:
                    _changePassword,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}