import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_spacing.dart';
import '../../../viewmodels/vehicle_viewmodel.dart';
import '../../widgets/app_primary_button.dart';

/// Bottom CTA for vehicle setup — watches save loading from [vehicleProvider].
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

    // AppScaffold already applies SafeArea — avoid a second inset (extra gap).
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        AppSpacing.sm,
        AppSpacing.screenPadding,
        AppSpacing.md,
      ),
      child: AppPrimaryButton(
        label: currentStep == 0 ? 'Continue' : 'Save Vehicle',
        icon: currentStep == 0
            ? Icons.arrow_forward_rounded
            : Icons.check_circle_rounded,
        compact: true,
        isLoading: isSaving,
        onPressed: isSaving ? null : onPressed,
      ),
    );
  }
}
