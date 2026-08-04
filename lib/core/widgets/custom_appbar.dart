import 'package:flutter/material.dart';

import '../constants/colors.dart';

/// ===========================================================
/// INTELLEKT CUSTOM APP BAR
/// ===========================================================
///
/// Reusable AppBar
///
/// Features:
/// • Back Button
/// • Custom Title
/// • Custom Actions
/// • Notification Icon
/// • Profile Icon
/// • Search
/// • Material 3
///
/// ===========================================================

class CustomAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  final String title;

  final bool centerTitle;

  final bool showBackButton;

  final bool showNotification;

  final bool showProfile;

  final List<Widget>? actions;

  final VoidCallback? onBackPressed;

  final VoidCallback? onNotificationPressed;

  final VoidCallback? onProfilePressed;

  final PreferredSizeWidget? bottom;

  const CustomAppBar({
    super.key,
    required this.title,
    this.centerTitle = true,
    this.showBackButton = true,
    this.showNotification = false,
    this.showProfile = false,
    this.actions,
    this.onBackPressed,
    this.onNotificationPressed,
    this.onProfilePressed,
    this.bottom,
  });

  @override
  Size get preferredSize =>
      Size.fromHeight(
        kToolbarHeight +
            (bottom?.preferredSize.height ?? 0),
      );

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 0,

      centerTitle: centerTitle,

      backgroundColor: AppColors.primary,

      foregroundColor: Colors.white,

      automaticallyImplyLeading: false,

      leading: showBackButton
          ? IconButton(
        icon: const Icon(Icons.arrow_back_ios_new),
        onPressed: onBackPressed ??
                () => Navigator.of(context).pop(),
      )
          : null,

      title: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),

      actions: [
        if (showNotification)
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: onNotificationPressed,
          ),

        if (showProfile)
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: onProfilePressed,
              child: const CircleAvatar(
                radius: 16,
                backgroundColor: Colors.white,
                child: Icon(
                  Icons.person,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
            ),
          ),

        if (actions != null) ...actions!,
      ],

      bottom: bottom,
    );
  }
}

/// ===========================================================
/// Search AppBar
/// ===========================================================

class SearchAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  final TextEditingController controller;

  final String hint;

  final ValueChanged<String>? onChanged;

  const SearchAppBar({
    super.key,
    required this.controller,
    this.hint = "Search...",
    this.onChanged,
  });

  @override
  Size get preferredSize =>
      const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.primary,

      title: Container(
        height: 42,

        decoration: BoxDecoration(
          color: Colors.white,

          borderRadius:
          BorderRadius.circular(12),
        ),

        child: TextField(
          controller: controller,

          onChanged: onChanged,

          decoration: InputDecoration(
            hintText: hint,

            prefixIcon: const Icon(Icons.search),

            border: InputBorder.none,

            contentPadding:
            const EdgeInsets.symmetric(
              vertical: 10,
            ),
          ),
        ),
      ),
    );
  }
}