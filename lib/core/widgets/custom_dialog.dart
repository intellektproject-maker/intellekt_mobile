import 'package:flutter/material.dart';

import '../constants/colors.dart';
import '../constants/app_sizes.dart';

/// ===========================================================
/// INTELLEKT CUSTOM DIALOG
/// ===========================================================
///
/// Production Ready Dialog System
///
/// Supports:
/// • Success Dialog
/// • Error Dialog
/// • Warning Dialog
/// • Confirmation Dialog
/// • Loading Dialog
///
/// ===========================================================

class CustomDialog {
  CustomDialog._();

  // ==========================================================
  // SUCCESS
  // ==========================================================

  static Future<void> success({
    required BuildContext context,
    required String title,
    required String message,
    String buttonText = "OK",
    VoidCallback? onPressed,
  }) {
    return _show(
      context: context,
      title: title,
      message: message,
      icon: Icons.check_circle,
      color: AppColors.success,
      buttonText: buttonText,
      onPressed: onPressed,
    );
  }

  // ==========================================================
  // ERROR
  // ==========================================================

  static Future<void> error({
    required BuildContext context,
    required String title,
    required String message,
    String buttonText = "OK",
    VoidCallback? onPressed,
  }) {
    return _show(
      context: context,
      title: title,
      message: message,
      icon: Icons.error,
      color: AppColors.error,
      buttonText: buttonText,
      onPressed: onPressed,
    );
  }

  // ==========================================================
  // WARNING
  // ==========================================================

  static Future<void> warning({
    required BuildContext context,
    required String title,
    required String message,
    String buttonText = "OK",
    VoidCallback? onPressed,
  }) {
    return _show(
      context: context,
      title: title,
      message: message,
      icon: Icons.warning_amber_rounded,
      color: AppColors.warning,
      buttonText: buttonText,
      onPressed: onPressed,
    );
  }

  // ==========================================================
  // CONFIRMATION
  // ==========================================================

  static Future<bool?> confirmation({
    required BuildContext context,
    required String title,
    required String message,
    String confirmText = "Yes",
    String cancelText = "Cancel",
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius:
            BorderRadius.circular(AppSizes.radiusLG),
          ),
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: Text(cancelText),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: Text(confirmText),
            ),
          ],
        );
      },
    );
  }

  // ==========================================================
  // LOADING
  // ==========================================================

  static void showLoading(
      BuildContext context, {
        String message = "Please wait...",
      }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return PopScope(
          canPop: false,
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius:
              BorderRadius.circular(AppSizes.radiusLG),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),

                const SizedBox(height: 24),

                Text(
                  message,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static void hideLoading(BuildContext context) {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  // ==========================================================
  // PRIVATE
  // ==========================================================

  static Future<void> _show({
    required BuildContext context,
    required String title,
    required String message,
    required IconData icon,
    required Color color,
    required String buttonText,
    VoidCallback? onPressed,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius:
            BorderRadius.circular(AppSizes.radiusLG),
          ),
          contentPadding:
          const EdgeInsets.all(AppSizes.lg),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [

              CircleAvatar(
                radius: 34,
                backgroundColor:
                color.withOpacity(.12),
                child: Icon(
                  icon,
                  color: color,
                  size: 36,
                ),
              ),

              const SizedBox(height: 20),

              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              Text(
                message,
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);

                    if (onPressed != null) {
                      onPressed();
                    }
                  },
                  child: Text(buttonText),
                ),
              )
            ],
          ),
        );
      },
    );
  }
}