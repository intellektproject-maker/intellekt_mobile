import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/colors.dart';
import '../../core/widgets/intellekt_wordmark.dart';
import '../../routes/app_routes.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) context.go(AppRoutes.welcome);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const Positioned.fill(child: CustomPaint(painter: _WavePainter())),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxHeight < 650;
                return Column(
                  children: [
                    const Spacer(flex: 7),
                    const IntellektWordmark(fontSize: 48),
                    const SizedBox(height: 16),
                    const Text(
                      '“ S c i e n c e   B l e s s   Y o u ”',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontFamily: 'Roboto',
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(flex: 6),
                    const SizedBox(
                      width: 29,
                      height: 29,
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                        strokeWidth: 2.2,
                        backgroundColor: Color(0xFFE9ECFA),
                      ),
                    ),
                    SizedBox(height: compact ? 48 : 76),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  const _WavePainter();

  @override
  void paint(Canvas canvas, Size size) {
    const waveColor = Color(0xFFCCD4FA);

    void drawWave(Path path, double opacity, double width) {
      canvas.drawPath(
        path,
        Paint()
          ..color = waveColor.withValues(alpha: opacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = width
          ..strokeCap = StrokeCap.round,
      );
    }

    for (var index = 0; index < 10; index++) {
      final y = 34.0 + index * 5.2;
      final path = Path()
        ..moveTo(-20, y)
        ..cubicTo(
          size.width * 0.22,
          y - 44,
          size.width * 0.42,
          y + 52,
          size.width * 0.66,
          y + 4,
        )
        ..cubicTo(
          size.width * 0.83,
          y - 29,
          size.width * 0.95,
          y - 38,
          size.width + 24,
          y + 20,
        );
      drawWave(path, 0.12 - index * 0.007, 1);
    }

    for (var index = 0; index < 12; index++) {
      final y = size.height - 132.0 + index * 5.5;
      final path = Path()
        ..moveTo(-24, y)
        ..cubicTo(
          size.width * 0.18,
          y - 55,
          size.width * 0.38,
          y + 56,
          size.width * 0.63,
          y + 9,
        )
        ..cubicTo(
          size.width * 0.82,
          y - 29,
          size.width * 0.93,
          y - 39,
          size.width + 28,
          y - 5,
        );
      drawWave(path, 0.14 - index * 0.007, 1.05);
    }

    final topFill = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, 65)
      ..cubicTo(
        size.width * 0.70,
        5,
        size.width * 0.49,
        126,
        0,
        61,
      )
      ..close();
    canvas.drawPath(
      topFill,
      Paint()..color = waveColor.withValues(alpha: 0.10),
    );

    final bottomFill = Path()
      ..moveTo(0, size.height - 150)
      ..cubicTo(
        size.width * 0.30,
        size.height - 108,
        size.width * 0.38,
        size.height - 34,
        size.width,
        size.height - 116,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      bottomFill,
      Paint()..color = waveColor.withValues(alpha: 0.11),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
