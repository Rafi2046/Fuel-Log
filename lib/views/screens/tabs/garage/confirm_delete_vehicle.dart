import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/database/app_database.dart';
import '../../../../viewmodels/vehicle_viewmodel.dart';

/// Confirms and deletes a vehicle; shows snackbar feedback.
Future<bool> deleteVehicleWithConfirmation(
  BuildContext context,
  WidgetRef ref,
  Vehicle vehicle,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.65),
    builder: (context) {
      return Dialog(
        backgroundColor: AppColors.card,
        elevation: 12,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          side: BorderSide(color: AppColors.border.withValues(alpha: 0.9)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.md,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.delete_outline_rounded,
                  color: AppColors.error,
                  size: 26,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'deleteVehicleTitle'.tr(),
                textAlign: TextAlign.center,
                style: AppTextStyles.title.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 17,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'deleteVehicleMessage'.tr(namedArgs: {'name': vehicle.name}),
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySecondary.copyWith(
                  height: 1.4,
                  fontSize: 14,
                ),
              ),
              SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textPrimary,
                        side: BorderSide(color: AppColors.borderStrong),
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.sm + 4,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusMd),
                        ),
                      ),
                      child: Text('cancel'.tr()),
                    ),
                  ),
                  SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.error,
                        foregroundColor: AppColors.textPrimary,
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.sm + 4,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusMd),
                        ),
                      ),
                      child: Text('delete'.tr()),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );

  if (confirmed != true) return false;

  final ok = await ref.read(vehicleProvider.notifier).deleteVehicle(vehicle.id);
  if (!context.mounted) return ok;

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        ok ? 'vehicleDeleted'.tr() : 'vehicleDeleteFailed'.tr(),
        style: AppTextStyles.body.copyWith(color: AppColors.textPrimary),
      ),
      backgroundColor: AppColors.cardElevated,
      behavior: SnackBarBehavior.floating,
    ),
  );

  return ok;
}
