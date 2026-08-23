import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_motion.dart';
import '../../../core/constants/app_spacing.dart';
import '../../widgets/app_step_indicator.dart';

/// Back button + step indicator for the vehicle setup wizard.
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
    return Padding(
      padding: const EdgeInsets.only(
        left: AppSpacing.screenPadding,
        right: AppSpacing.screenPadding,
        top: AppSpacing.md,
        bottom: AppSpacing.sm,
      ),
      child: Row(
        children: [
          AnimatedOpacity(
            duration: AppMotion.fast,
            opacity: currentStep > 0 ? 1 : 0,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
              color: AppColors.textPrimary,
              onPressed: currentStep > 0 ? onBack : null,
              tooltip: 'Back to Step 1',
            ),
          ),
          Expanded(
            child: AppStepIndicator(
              currentStep: currentStep + 1,
              totalSteps: 2,
              stepTitle: currentStep == 0
                  ? 'Machine Identity'
                  : 'Technical Specs',
            ),
          ),
        ],
      ),
    );
  }
}
