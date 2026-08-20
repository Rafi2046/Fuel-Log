import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';

/// Dual-style headline: solid accent word + outlined white word(s).
class OutlineHeadline extends StatelessWidget {
  const OutlineHeadline({
    super.key,
    required this.accent,
    required this.outline,
    this.fontSize = 44,
  });

  final String accent;
  final String outline;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final solid = GoogleFonts.plusJakartaSans(
      fontSize: fontSize,
      fontWeight: FontWeight.w800,
      color: AppColors.primary,
      height: 1.05,
    );
    final stroked = GoogleFonts.plusJakartaSans(
      fontSize: fontSize,
      fontWeight: FontWeight.w800,
      height: 1.05,
      foreground: Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..color = AppColors.textPrimary,
    );

    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: accent, style: solid),
          TextSpan(text: outline, style: stroked),
        ],
      ),
    );
  }
}
