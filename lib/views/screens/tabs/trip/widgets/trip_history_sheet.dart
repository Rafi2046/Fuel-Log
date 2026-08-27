import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/constants/app_text_styles.dart';
import 'trip_list_view.dart';

/// Modal bottom sheet displaying the list of recorded trips for the active vehicle.
Future<void> showTripHistoryModalSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF141419),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppSpacing.radiusXl),
      ),
    ),
    builder: (context) => const TripHistorySheet(),
  );
}

class TripHistorySheet extends StatelessWidget {
  const TripHistorySheet({super.key});

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.sizeOf(context).height * 0.85;

    return SizedBox(
      height: maxHeight,
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            // Handle Bar
            const SizedBox(height: AppSpacing.sm),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFF33333F),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),

            // Header Row
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenPadding,
                vertical: AppSpacing.xs,
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.xs + 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                    child: const Icon(
                      LucideIcons.route,
                      size: 20,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'tripHistory'.tr(),
                      style: AppTextStyles.title.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),

            const Divider(
              color: Color(0xFF22222B),
              height: 1,
              thickness: 1,
            ),

            // Trip List
            const Expanded(
              child: TripListView(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.screenPadding,
                  AppSpacing.md,
                  AppSpacing.screenPadding,
                  AppSpacing.lg,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
