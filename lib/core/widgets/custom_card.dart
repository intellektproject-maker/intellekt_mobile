import 'package:flutter/material.dart';

import '../constants/app_sizes.dart';
import '../constants/colors.dart';

/// ===========================================================
/// INTELLEKT CUSTOM CARD
/// ===========================================================
///
/// Enterprise reusable Card Widget.
///
/// Features:
/// • Tap Animation
/// • Leading Icon
/// • Title
/// • Subtitle
/// • Trailing Widget
/// • Status Badge
/// • Custom Child
/// • Material 3
///
/// ===========================================================

class CustomCard extends StatelessWidget {
  final Widget? child;

  final String? title;

  final String? subtitle;

  final IconData? icon;

  final Widget? trailing;

  final VoidCallback? onTap;

  final EdgeInsetsGeometry? padding;

  final Color? backgroundColor;

  final Color? iconColor;

  final double elevation;

  final bool showBorder;

  final Widget? badge;

  const CustomCard({
    super.key,
    this.child,
    this.title,
    this.subtitle,
    this.icon,
    this.trailing,
    this.onTap,
    this.padding,
    this.backgroundColor,
    this.iconColor,
    this.elevation = AppSizes.cardElevation,
    this.showBorder = false,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: elevation,

      color: backgroundColor ?? AppColors.surface,

      shape: RoundedRectangleBorder(
        borderRadius:
        BorderRadius.circular(AppSizes.cardRadius),

        side: showBorder
            ? const BorderSide(
          color: AppColors.border,
        )
            : BorderSide.none,
      ),

      child: InkWell(
        borderRadius:
        BorderRadius.circular(AppSizes.cardRadius),

        onTap: onTap,

        child: Padding(
          padding: padding ??
              const EdgeInsets.all(AppSizes.md),

          child: child ??
              Row(
                children: [

                  if (icon != null)
                    Container(
                      padding:
                      const EdgeInsets.all(12),

                      decoration: BoxDecoration(
                        color: (iconColor ??
                            AppColors.primary)
                            .withOpacity(.1),

                        borderRadius:
                        BorderRadius.circular(12),
                      ),

                      child: Icon(
                        icon,
                        color: iconColor ??
                            AppColors.primary,
                        size: 26,
                      ),
                    ),

                  if (icon != null)
                    const SizedBox(width: 16),

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,

                      children: [

                        if (title != null)
                          Text(
                            title!,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium,
                          ),

                        if (subtitle != null) ...[
                          const SizedBox(height: 6),

                          Text(
                            subtitle!,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                              color: AppColors
                                  .textSecondary,
                            ),
                          ),
                        ]
                      ],
                    ),
                  ),

                  if (badge != null) badge!,

                  if (trailing != null)
                    Padding(
                      padding:
                      const EdgeInsets.only(
                        left: 12,
                      ),
                      child: trailing!,
                    ),
                ],
              ),
        ),
      ),
    );
  }
}

/// ===========================================================
/// Dashboard Card
/// ===========================================================

class DashboardCard extends StatelessWidget {
  final String title;

  final String value;

  final IconData icon;

  final Color color;

  final VoidCallback? onTap;

  const DashboardCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      onTap: onTap,

      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,

        children: [

          CircleAvatar(
            radius: 24,

            backgroundColor:
            color.withOpacity(.12),

            child: Icon(
              icon,
              color: color,
            ),
          ),

          const SizedBox(height: 18),

          Text(
            value,
            style: Theme.of(context)
                .textTheme
                .headlineMedium
                ?.copyWith(
              fontWeight:
              FontWeight.bold,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            title,
            style: Theme.of(context)
                .textTheme
                .bodyMedium,
          ),
        ],
      ),
    );
  }
}

/// ===========================================================
/// Status Badge
/// ===========================================================

class StatusBadge extends StatelessWidget {
  final String text;

  final Color color;

  const StatusBadge({
    super.key,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
      const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 6,
      ),

      decoration: BoxDecoration(
        color: color.withOpacity(.12),

        borderRadius:
        BorderRadius.circular(100),
      ),

      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}