import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_motion.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_text_styles.dart';

/// Animated step progress bar widget for wizard flows.
class AppStepIndicator extends StatelessWidget {
  const AppStepIndicator({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    this.stepTitle,
  });

  final int currentStep;
  final int totalSteps;
  final String? stepTitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Step $currentStep of $totalSteps',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            if (stepTitle != null)
              Text(
                stepTitle!,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: List.generate(
            totalSteps,
            (index) {
              final isCompletedOrActive = index < currentStep;
              return Expanded(
                child: AnimatedContainer(
                  duration: AppMotion.normal,
                  curve: AppMotion.emphasized,
                  height: 4,
                  margin: EdgeInsets.only(
                    right: index == totalSteps - 1 ? 0 : AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: isCompletedOrActive
                        ? AppColors.primary
                        : AppColors.surface,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
