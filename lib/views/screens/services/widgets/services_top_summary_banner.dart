import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/utils/app_formatters.dart';
import '../../../../viewmodels/reminder_viewmodel.dart';

/// Top summary banner for the Services dashboard.
class ServicesTopSummaryBanner extends StatelessWidget {
  const ServicesTopSummaryBanner({
    super.key,
    required this.state,
    required this.totalSpend,
    required this.logCount,
  });

  final RemindersState state;
  final double totalSpend;
  final int logCount;

  @override
  Widget build(BuildContext context) {
    final hasOverdue = state.overdueCount > 0;
    final hasDueSoon = state.dueSoonCount > 0;

    Color healthColor = AppColors.textSecondary;
    String healthTitle = 'All Systems Optimal';
    IconData healthIcon = LucideIcons.shieldCheck;
    final isNeutralHealth = !hasOverdue && !hasDueSoon;

    if (hasOverdue) {
      healthColor = AppColors.error;
      healthTitle = '${state.overdueCount} Overdue Schedule';
      healthIcon = LucideIcons.triangleAlert;
    } else if (hasDueSoon) {
      healthColor = AppColors.warning;
      healthTitle = '${state.dueSoonCount} Service Due Soon';
      healthIcon = LucideIcons.bellRing;
    }

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPadding,
        vertical: 4,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: hasOverdue
              ? AppColors.error.withValues(alpha: 0.28)
              : hasDueSoon
                  ? AppColors.warning.withValues(alpha: 0.28)
                  : AppColors.hairline,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isNeutralHealth
                  ? AppColors.wash
                  : healthColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isNeutralHealth
                    ? AppColors.border
                    : healthColor.withValues(alpha: 0.22),
              ),
            ),
            child: Icon(
              healthIcon,
              color: isNeutralHealth ? AppColors.textSecondary : healthColor,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  healthTitle,
                  style: GoogleFonts.inter(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: isNeutralHealth
                        ? AppColors.textPrimary
                        : healthColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${state.activeReminders.length} Schedules · $logCount Records',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Text(
                  AppCurrency.format(totalSpend),
                  style: GoogleFonts.inter(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Total Spend',
                style: TextStyle(
                  fontSize: 10,
                  color: AppColors.textTertiary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
