import 'package:flutter/material.dart';

import '../constants/app_sizes.dart';
import '../constants/colors.dart';

/// ===========================================================
/// INTELLEKT CUSTOM BUTTON
/// ===========================================================
///
/// Reusable Primary Button
///
/// Features:
/// • Loading State
/// • Disabled State
/// • Icon Support
/// • Material 3
/// • Consistent Design
///
/// ===========================================================

class CustomButton extends StatelessWidget {
  final String text;

  final VoidCallback? onPressed;

  final bool isLoading;

  final bool enabled;

  final IconData? icon;

  final Color? backgroundColor;

  final Color? foregroundColor;

  final double? width;

  final double height;

  final double borderRadius;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.enabled = true,
    this.icon,
    this.backgroundColor,
    this.foregroundColor,
    this.width,
    this.height = AppSizes.buttonHeight,
    this.borderRadius = AppSizes.buttonRadius,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width ?? double.infinity,
      height: height,
      child: ElevatedButton(
        onPressed: (!enabled || isLoading)
            ? null
            : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor:
          backgroundColor ?? AppColors.primary,
          foregroundColor:
          foregroundColor ?? Colors.white,
          disabledBackgroundColor:
          Colors.grey.shade400,
          disabledForegroundColor:
          Colors.white70,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius:
            BorderRadius.circular(borderRadius),
          ),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: isLoading
              ? const SizedBox(
            key: ValueKey("loader"),
            height: 22,
            width: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor:
              AlwaysStoppedAnimation<Color>(
                Colors.white,
              ),
            ),
          )
              : Row(
            key: const ValueKey("button"),
            mainAxisAlignment:
            MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20),
                const SizedBox(width: 8),
              ],
              Text(
                text,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: .2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}