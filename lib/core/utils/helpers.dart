import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';

import '../constants/colors.dart';

/// ===========================================================
/// INTELLEKT HELPERS
/// ===========================================================
///
/// Common utility methods used throughout the application.
///
/// Never duplicate these methods inside screens.
///
/// ===========================================================

class Helpers {
  Helpers._();

  // ==========================================================
  // DATE FORMATTERS
  // ==========================================================

  static String formatDate(DateTime date) {
    return DateFormat('dd-MM-yyyy').format(date);
  }

  static String formatDateTime(DateTime date) {
    return DateFormat('dd-MM-yyyy hh:mm a').format(date);
  }

  static String formatTime(TimeOfDay time) {
    final now = DateTime.now();

    final dt = DateTime(
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    return DateFormat('hh:mm a').format(dt);
  }

  // ==========================================================
  // SNACKBAR
  // ==========================================================

  static void showSnackBar(
      BuildContext context,
      String message, {
        bool isError = false,
      }) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
        isError ? AppColors.error : AppColors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ==========================================================
  // TOAST
  // ==========================================================

  static Future<void> showToast(
      String message, {
        bool isError = false,
      }) async {
    await Fluttertoast.showToast(
      msg: message,
      gravity: ToastGravity.BOTTOM,
      backgroundColor:
      isError ? AppColors.error : AppColors.primary,
      textColor: Colors.white,
      toastLength: Toast.LENGTH_SHORT,
    );
  }

  // ==========================================================
  // LOADING DIALOG
  // ==========================================================

  static void showLoading(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );
  }

  static void hideLoading(BuildContext context) {
    Navigator.of(context, rootNavigator: true).pop();
  }

  // ==========================================================
  // DIALOG
  // ==========================================================

  static Future<bool?> showConfirmationDialog({
    required BuildContext context,
    required String title,
    required String message,
    String confirmText = "Yes",
    String cancelText = "No",
  }) {
    return showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              child: Text(cancelText),
              onPressed: () {
                Navigator.pop(context, false);
              },
            ),
            ElevatedButton(
              child: Text(confirmText),
              onPressed: () {
                Navigator.pop(context, true);
              },
            ),
          ],
        );
      },
    );
  }

  // ==========================================================
  // HIDE KEYBOARD
  // ==========================================================

  static void hideKeyboard(BuildContext context) {
    FocusScope.of(context).unfocus();
  }

  // ==========================================================
  // ROLE HELPERS
  // ==========================================================

  static bool isStudent(String id) =>
      id.toUpperCase().startsWith("IA");

  static bool isFaculty(String id) =>
      id.toUpperCase().startsWith("IF");

  static bool isAdmin(String id) =>
      id.toUpperCase().startsWith("IP");

  // ==========================================================
  // INITIALS
  // ==========================================================

  static String getInitials(String name) {
    final names = name.trim().split(" ");

    if (names.isEmpty) return "";

    if (names.length == 1) {
      return names.first[0].toUpperCase();
    }

    return (names.first[0] + names.last[0]).toUpperCase();
  }

  // ==========================================================
  // NULL SAFE TEXT
  // ==========================================================

  static String safeText(dynamic value) {
    if (value == null) return "-";

    if (value.toString().trim().isEmpty) {
      return "-";
    }

    return value.toString();
  }

  // ==========================================================
  // PERCENTAGE
  // ==========================================================

  static double calculatePercentage({
    required double obtained,
    required double total,
  }) {
    if (total == 0) return 0;

    return (obtained / total) * 100;
  }

  // ==========================================================
  // MARKS COLOR
  // ==========================================================

  static Color marksColor(double percentage) {
    if (percentage >= 90) {
      return AppColors.excellent;
    }

    if (percentage >= 60) {
      return AppColors.average;
    }

    return AppColors.poor;
  }

  // ==========================================================
  // ATTENDANCE COLOR
  // ==========================================================

  static Color attendanceColor(String status) {
    switch (status.toUpperCase()) {
      case "P":
      case "PRESENT":
        return AppColors.present;

      case "A":
      case "ABSENT":
        return AppColors.absent;

      case "L":
      case "LATE":
        return AppColors.late;

      default:
        return Colors.grey;
    }
  }
}