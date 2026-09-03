import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../viewmodels/vehicle_viewmodel.dart';
import '../../widgets/app_primary_button.dart';

/// Floating bottom CTA with subtle gradient fade — watches save loading from [vehicleProvider].
class SetupBottomAction extends ConsumerWidget {
  const SetupBottomAction({
    super.key,
    required this.currentStep,
    required this.onPressed,
  });

  final int currentStep;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSaving =
        currentStep == 1 && ref.watch(vehicleProvider).isLoading;

    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        AppSpacing.sm,
        AppSpacing.screenPadding,
        AppSpacing.md,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.background.withValues(alpha: 0.0),
            AppColors.background.withValues(alpha: 0.9),
            AppColors.background,
          ],
          stops: const [0.0, 0.2, 1.0],
        ),
      ),
      child: SafeArea(
        top: false,
        child: AppPrimaryButton(
          label: currentStep == 0 ? 'Continue' : 'Save Vehicle',
          icon: currentStep == 0
              ? Icons.arrow_forward_rounded
              : Icons.check_circle_rounded,
          isLoading: isSaving,
          onPressed: isSaving ? null : onPressed,
        ),
      ),
    );
  }
}
