import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_motion.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';

/// Clean modern top navigation header with back button, step badge, and progress line.
class SetupWizardHeader extends StatelessWidget {
  const SetupWizardHeader({
    super.key,
    required this.currentStep,
    required this.onBack,
  });

  final int currentStep;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    final showBackButton = currentStep > 0 || canPop;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPadding,
        vertical: AppSpacing.sm,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Back / Dismiss Button
              AnimatedOpacity(
                duration: AppMotion.fast,
                opacity: showBackButton ? 1.0 : 0.0,
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    iconSize: 18,
                    icon: Icon(Icons.arrow_back_ios_new_rounded),
                    color: AppColors.textPrimary,
                    onPressed: showBackButton
                        ? () {
                            if (currentStep > 0) {
                              onBack();
                            } else if (canPop) {
                              Navigator.of(context).pop();
                            }
                          }
                        : null,
                    tooltip: currentStep > 0 ? 'Back' : 'Close',
                  ),
                ),
              ),

              // Step indicator pill badge
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.25),
                  ),
                ),
                child: Text(
                  'STEP ${currentStep + 1} OF 2',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                    letterSpacing: 0.8,
                  ),
                ),
              ),

              // Symmetrical spacing box
              const SizedBox(width: 38, height: 38),
            ],
          ),
          const SizedBox(height: 12),
          // Sleek progress bar
          Row(
            children: List.generate(2, (index) {
              final isActive = index <= currentStep;
              return Expanded(
                child: AnimatedContainer(
                  duration: AppMotion.normal,
                  curve: AppMotion.emphasized,
                  height: 3,
                  margin: EdgeInsets.only(right: index == 0 ? 6 : 0),
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppColors.primary
                        : AppColors.wash,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
