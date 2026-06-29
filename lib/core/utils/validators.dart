import '../constants/strings.dart';

/// ===========================================================
/// INTELLEKT VALIDATORS
/// ===========================================================
///
/// Centralized Validators
///
/// Never validate directly inside screens.
///
/// Example:
///
/// validator: Validators.userId
///
/// ===========================================================

class Validators {
  Validators._();

  // ==========================================================
  // REQUIRED FIELD
  // ==========================================================

  static String? requiredField(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppStrings.requiredField;
    }
    return null;
  }

  // ==========================================================
  // USER ID
  // ==========================================================
  //
  // IA001
  // IF001
  // IP001
  //
  // ==========================================================

  static String? userId(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppStrings.requiredField;
    }

    final regex = RegExp(r'^(IA|IF|IP)\d{3}$');

    if (!regex.hasMatch(value.trim().toUpperCase())) {
      return "Enter a valid User ID (IA001 / IF001 / IP001)";
    }

    return null;
  }

  // ==========================================================
  // PASSWORD
  // ==========================================================

  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return AppStrings.requiredField;
    }

    if (value.length < 6) {
      return "Password must contain at least 6 characters";
    }

    return null;
  }

  // ==========================================================
  // CONFIRM PASSWORD
  // ==========================================================

  static String? confirmPassword(
      String? password,
      String? confirmPassword,
      ) {
    if (confirmPassword == null || confirmPassword.isEmpty) {
      return AppStrings.requiredField;
    }

    if (password != confirmPassword) {
      return AppStrings.passwordMismatch;
    }

    return null;
  }

  // ==========================================================
  // EMAIL
  // ==========================================================

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppStrings.requiredField;
    }

    final regex = RegExp(
      r'^[\w\-.]+@([\w-]+\.)+[\w-]{2,4}$',
    );

    if (!regex.hasMatch(value.trim())) {
      return AppStrings.invalidEmail;
    }

    return null;
  }

  // ==========================================================
  // PHONE
  // ==========================================================

  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppStrings.requiredField;
    }

    final regex = RegExp(r'^[6-9]\d{9}$');

    if (!regex.hasMatch(value.trim())) {
      return AppStrings.invalidPhone;
    }

    return null;
  }

  // ==========================================================
  // ROLL NUMBER
  // ==========================================================

  static String? rollNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppStrings.requiredField;
    }

    final regex = RegExp(r'^IA\d{3}$');

    if (!regex.hasMatch(value.trim().toUpperCase())) {
      return "Invalid Roll Number";
    }

    return null;
  }

  // ==========================================================
  // FACULTY ID
  // ==========================================================

  static String? facultyId(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppStrings.requiredField;
    }

    final regex = RegExp(r'^IF\d{3}$');

    if (!regex.hasMatch(value.trim().toUpperCase())) {
      return "Invalid Faculty ID";
    }

    return null;
  }

  // ==========================================================
  // ADMIN ID
  // ==========================================================

  static String? adminId(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppStrings.requiredField;
    }

    final regex = RegExp(r'^IP\d{3}$');

    if (!regex.hasMatch(value.trim().toUpperCase())) {
      return "Invalid Admin ID";
    }

    return null;
  }

  // ==========================================================
  // NUMBERS ONLY
  // ==========================================================

  static String? number(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppStrings.requiredField;
    }

    if (double.tryParse(value.trim()) == null) {
      return "Enter a valid number";
    }

    return null;
  }

  // ==========================================================
  // MARKS
  // ==========================================================

  static String? marks(
      String? value, {
        int maxMarks = 100,
      }) {
    if (value == null || value.trim().isEmpty) {
      return AppStrings.requiredField;
    }

    // Allow Absent
    if (value.trim().toUpperCase() == "A") {
      return null;
    }

    final marks = int.tryParse(value);

    if (marks == null) {
      return "Invalid Marks";
    }

    if (marks < 0 || marks > maxMarks) {
      return "Marks should be between 0 and $maxMarks";
    }

    return null;
  }

  // ==========================================================
  // NOT EMPTY LIST
  // ==========================================================

  static String? notEmptyList(List? list) {
    if (list == null || list.isEmpty) {
      return "Please select at least one item";
    }

    return null;
  }
}