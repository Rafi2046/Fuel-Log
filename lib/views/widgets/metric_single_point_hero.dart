import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';

/// Compact hero row for single-point metric charts (value above curve).
class MetricSinglePointHero extends StatelessWidget {
  const MetricSinglePointHero({
    super.key,
    required this.value,
    required this.unit,
    this.accentStart = AppColors.secondary,
    this.accentEnd = AppColors.primary,
  });

  final String value;
  final String unit;
  final Color accentStart;
  final Color accentEnd;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 2, 8, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: [accentStart, accentEnd],
            ).createShader(bounds),
            child: Text(
              value,
              style: AppTextStyles.title.copyWith(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                height: 1,
              ),
            ),
          ),
          SizedBox(width: 6),
          Flexible(
            child: Text(
              unit,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textTertiary,
                fontSize: 11,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
