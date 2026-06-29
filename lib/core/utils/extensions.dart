import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// ===========================================================
/// INTELLEKT EXTENSIONS
/// ===========================================================
///
/// Helpful extensions used throughout the application.
///
/// ===========================================================

/// ===========================================================
/// BuildContext Extensions
/// ===========================================================

extension ContextExtensions on BuildContext {
  // Screen Size

  Size get screenSize => MediaQuery.of(this).size;

  double get screenWidth => MediaQuery.of(this).size.width;

  double get screenHeight => MediaQuery.of(this).size.height;

  // Theme

  ThemeData get theme => Theme.of(this);

  TextTheme get textTheme => Theme.of(this).textTheme;

  ColorScheme get colorScheme => Theme.of(this).colorScheme;

  // Keyboard

  void hideKeyboard() {
    FocusScope.of(this).unfocus();
  }

  // SnackBar

  void showSnackBar(
      String message, {
        bool isError = false,
      }) {
    ScaffoldMessenger.of(this).hideCurrentSnackBar();

    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
        isError ? Colors.red : Theme.of(this).primaryColor,
      ),
    );
  }
}

/// ===========================================================
/// String Extensions
/// ===========================================================

extension StringExtensions on String {
  String get capitalize {
    if (trim().isEmpty) return this;

    return "${this[0].toUpperCase()}${substring(1)}";
  }

  bool get isStudent =>
      toUpperCase().startsWith("IA");

  bool get isFaculty =>
      toUpperCase().startsWith("IF");

  bool get isAdmin =>
      toUpperCase().startsWith("IP");

  bool get isEmail {
    final regex = RegExp(
      r'^[\w\-.]+@([\w-]+\.)+[\w-]{2,4}$',
    );

    return regex.hasMatch(this);
  }

  bool get isPhone {
    final regex = RegExp(r'^[6-9]\d{9}$');

    return regex.hasMatch(this);
  }

  bool get isNumeric =>
      double.tryParse(this) != null;
}

/// ===========================================================
/// DateTime Extensions
/// ===========================================================

extension DateTimeExtensions on DateTime {
  String get ddMMyyyy =>
      DateFormat('dd-MM-yyyy').format(this);

  String get ddMMMMyyyy =>
      DateFormat('dd MMM yyyy').format(this);

  String get time =>
      DateFormat('hh:mm a').format(this);

  String get full =>
      DateFormat('dd-MM-yyyy hh:mm a').format(this);
}

/// ===========================================================
/// TimeOfDay Extensions
/// ===========================================================

extension TimeOfDayExtensions on TimeOfDay {
  String format(BuildContext context) {
    final now = DateTime.now();

    final date = DateTime(
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    return DateFormat('hh:mm a').format(date);
  }
}

/// ===========================================================
/// Integer Extensions
/// ===========================================================

extension IntExtensions on int {
  Duration get milliseconds =>
      Duration(milliseconds: this);

  Duration get seconds =>
      Duration(seconds: this);

  Duration get minutes =>
      Duration(minutes: this);
}

/// ===========================================================
/// Double Extensions
/// ===========================================================

extension DoubleExtensions on double {
  String get percentage =>
      "${toStringAsFixed(1)}%";

  String get twoDecimal =>
      toStringAsFixed(2);
}