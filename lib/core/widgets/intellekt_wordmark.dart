import 'package:flutter/material.dart';

import '../constants/colors.dart';

class IntellektWordmark extends StatelessWidget {
  final double fontSize;
  final Color color;
  final FontWeight fontWeight;

  const IntellektWordmark({
    super.key,
    this.fontSize = 36,
    this.color = AppColors.primary,
    this.fontWeight = FontWeight.w700,
  });

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: [
          const TextSpan(text: 'Intellekt'),
          WidgetSpan(
            alignment: PlaceholderAlignment.top,
            child: Transform.translate(
              offset: const Offset(1, -1),
              child: Text(
                '®',
                style: TextStyle(
                  color: color,
                  fontFamily: 'Roboto',
                  fontSize: fontSize * 0.32,
                  fontWeight: FontWeight.w700,
                  height: 1,
                ),
              ),
            ),
          ),
        ],
      ),
      style: TextStyle(
        color: color,
        fontFamily: 'Roboto',
        fontSize: fontSize,
        fontWeight: fontWeight,
        letterSpacing: -0.9,
        height: 1,
      ),
    );
  }
}
