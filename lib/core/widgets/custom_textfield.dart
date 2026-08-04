import 'package:flutter/material.dart';

import '../constants/app_sizes.dart';
import '../constants/colors.dart';

/// ===========================================================
/// INTELLEKT CUSTOM TEXT FIELD
/// ===========================================================
///
/// Reusable TextFormField
///
/// Features:
/// • Validation
/// • Password Toggle
/// • Prefix/Suffix Icons
/// • Search Mode
/// • ReadOnly
/// • Multi-line
/// • Numeric
/// • Email
/// • Material 3
///
/// ===========================================================

class CustomTextField extends StatefulWidget {
  final TextEditingController controller;

  final String label;

  final String? hint;

  final IconData? prefixIcon;

  final IconData? suffixIcon;

  final bool obscureText;

  final bool enabled;

  final bool readOnly;

  final int maxLines;

  final int? maxLength;

  final TextInputType keyboardType;

  final TextInputAction textInputAction;

  final String? Function(String?)? validator;

  final VoidCallback? onTap;

  final ValueChanged<String>? onChanged;

  final ValueChanged<String>? onFieldSubmitted;

  final Widget? suffix;

  final Widget? prefix;

  const CustomTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.enabled = true,
    this.readOnly = false,
    this.maxLines = 1,
    this.maxLength,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.validator,
    this.onTap,
    this.onChanged,
    this.onFieldSubmitted,
    this.suffix,
    this.prefix,
  });

  @override
  State<CustomTextField> createState() =>
      _CustomTextFieldState();
}

class _CustomTextFieldState
    extends State<CustomTextField> {
  late bool _obscure;

  @override
  void initState() {
    super.initState();
    _obscure = widget.obscureText;
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,

      validator: widget.validator,

      obscureText: _obscure,

      enabled: widget.enabled,

      readOnly: widget.readOnly,

      maxLines:
      widget.obscureText ? 1 : widget.maxLines,

      maxLength: widget.maxLength,

      keyboardType: widget.keyboardType,

      textInputAction: widget.textInputAction,

      onTap: widget.onTap,

      onChanged: widget.onChanged,

      onFieldSubmitted: widget.onFieldSubmitted,

      cursorColor: AppColors.primary,

      decoration: InputDecoration(
        labelText: widget.label,

        hintText: widget.hint,

        counterText: "",

        prefix: widget.prefix,

        suffix: widget.suffix,

        prefixIcon: widget.prefixIcon != null
            ? Icon(
          widget.prefixIcon,
          color: AppColors.primary,
        )
            : null,

        suffixIcon: widget.obscureText
            ? IconButton(
          icon: Icon(
            _obscure
                ? Icons.visibility_off
                : Icons.visibility,
            color: AppColors.primary,
          ),
          onPressed: () {
            setState(() {
              _obscure = !_obscure;
            });
          },
        )
            : widget.suffixIcon != null
            ? Icon(
          widget.suffixIcon,
          color: AppColors.primary,
        )
            : null,

        filled: true,

        fillColor: Colors.white,

        contentPadding:
        const EdgeInsets.symmetric(
          horizontal: AppSizes.md,
          vertical: AppSizes.md,
        ),

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            AppSizes.inputRadius,
          ),
        ),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            AppSizes.inputRadius,
          ),
          borderSide: const BorderSide(
            color: AppColors.border,
          ),
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            AppSizes.inputRadius,
          ),
          borderSide: const BorderSide(
            color: AppColors.primary,
            width: 2,
          ),
        ),

        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            AppSizes.inputRadius,
          ),
          borderSide: const BorderSide(
            color: AppColors.error,
          ),
        ),

        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            AppSizes.inputRadius,
          ),
          borderSide: const BorderSide(
            color: AppColors.error,
            width: 2,
          ),
        ),
      ),
    );
  }
}