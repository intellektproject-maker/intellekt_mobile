import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

import '../constants/colors.dart';

/// ===========================================================
/// INTELLEKT CUSTOM LOADER
/// ===========================================================
///
/// Reusable Loading Widget
///
/// Features:
/// • Full Screen Loader
/// • Small Loader
/// • Overlay Loader
/// • Button Loader
/// • Material 3
///
/// ===========================================================

class CustomLoader extends StatelessWidget {
  final double size;

  final Color? color;

  const CustomLoader({
    super.key,
    this.size = 45,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: LoadingAnimationWidget.staggeredDotsWave(
        color: color ?? AppColors.primary,
        size: size,
      ),
    );
  }
}

/// ===========================================================
/// Full Screen Loader
/// ===========================================================

class FullScreenLoader extends StatelessWidget {
  final String? message;

  const FullScreenLoader({
    super.key,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CustomLoader(
              size: 55,
            ),
            if (message != null) ...[
              const SizedBox(height: 20),
              Text(
                message!,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium,
              ),
            ]
          ],
        ),
      ),
    );
  }
}

/// ===========================================================
/// Overlay Loader
/// ===========================================================

class LoaderOverlay extends StatelessWidget {
  final bool loading;

  final Widget child;

  final String? message;

  const LoaderOverlay({
    super.key,
    required this.loading,
    required this.child,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,

        if (loading)
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(.35),
              child: Center(
                child: Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                    BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding:
                    const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CustomLoader(),

                        if (message != null) ...[
                          const SizedBox(height: 16),
                          Text(
                            message!,
                            textAlign:
                            TextAlign.center,
                          ),
                        ]
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// ===========================================================
/// Inline Loader
/// ===========================================================

class InlineLoader extends StatelessWidget {
  final String text;

  const InlineLoader({
    super.key,
    this.text = "Loading...",
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment:
      MainAxisAlignment.center,
      children: [
        const SizedBox(
          height: 20,
          width: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
          ),
        ),
        const SizedBox(width: 12),
        Text(text),
      ],
    );
  }
}