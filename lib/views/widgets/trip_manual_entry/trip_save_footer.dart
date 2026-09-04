import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../app_primary_button.dart';

/// Bottom sticky save footer for trip manual entry sheet.
class TripSaveFooter extends StatelessWidget {
  const TripSaveFooter({
    super.key,
    required this.isSaving,
    required this.onSave,
  });

  final bool isSaving;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: AppColors.border),
        ),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.card.withValues(alpha: 0.2),
            AppColors.card,
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenPadding,
          AppSpacing.sm,
          AppSpacing.screenPadding,
          AppSpacing.md,
        ),
        child: AppPrimaryButton(
          label: 'saveTrip'.tr(),
          icon: Icons.check_rounded,
          isLoading: isSaving,
          compact: true,
          onPressed: isSaving ? null : onSave,
        ),
      ),
    );
  }
}
