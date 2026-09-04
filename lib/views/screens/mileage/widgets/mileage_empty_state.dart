import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../widgets/app_primary_button.dart';
import '../../refueling_form_screen.dart';

/// Premium empty state for Mileage Log with a clear two-step unlock path.
class MileageEmptyState extends StatelessWidget {
  const MileageEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.xl,
        ),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          border: Border.all(color: AppColors.hairline),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: AppColors.isDark ? 0.3 : 0.06,
              ),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.wash,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(color: AppColors.border),
              ),
              child: Icon(
                Icons.speed_rounded,
                size: 20,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'No Mileage Data Yet',
              style: AppTextStyles.title.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 17,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Log at least 2 full refuelings to calculate average mileage, distance driven, and cost per km.',
              textAlign: TextAlign.center,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
                height: 1.45,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.wash,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: _StepItem(
                      title: 'First Fill',
                      subtitle: 'Sets Odometer',
                      icon: Icons.flag_rounded,
                      align: _StepAlign.start,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      size: 14,
                      color: AppColors.textTertiary,
                    ),
                  ),
                  const Expanded(
                    child: _StepItem(
                      title: 'Second Fill',
                      subtitle: 'Calculates km/L',
                      icon: Icons.insights_rounded,
                      align: _StepAlign.end,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            AppPrimaryButton(
              label: 'Add Refueling Log',
              icon: Icons.add_rounded,
              iconSize: 12,
              compact: true,
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const RefuelingFormScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

enum _StepAlign { start, end }

class _StepItem extends StatelessWidget {
  const _StepItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.align,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final _StepAlign align;

  @override
  Widget build(BuildContext context) {
    final isEnd = align == _StepAlign.end;
    final cross = isEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final textAlign = isEnd ? TextAlign.right : TextAlign.left;

    return Align(
      alignment: isEnd ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: cross,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 13, color: AppColors.textSecondary),
              const SizedBox(width: 5),
              Text(
                title,
                style: AppTextStyles.caption.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  fontSize: 12,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: AppTextStyles.caption.copyWith(
              fontSize: 10,
              color: AppColors.textTertiary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: textAlign,
          ),
        ],
      ),
    );
  }
}
