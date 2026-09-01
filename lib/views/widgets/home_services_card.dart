import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_text_styles.dart';
import '../../viewmodels/reminder_viewmodel.dart';
import '../../viewmodels/service_log_viewmodel.dart';
import '../screens/services/services_screen.dart';
import 'app_card.dart';

/// Clean, minimal Services & Maintenance card on the Home Dashboard.
class HomeServicesCard extends ConsumerWidget {
  const HomeServicesCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(remindersProvider);
    final serviceLogsAsync = ref.watch(serviceLogsProvider);
    final serviceLogsCount = serviceLogsAsync.valueOrNull?.length ?? 0;

    final urgent = state.mostUrgentReminder;
    final hasOverdue = state.overdueCount > 0;
    final hasDueSoon = state.dueSoonCount > 0;

    Color statusColor;
    String statusSubtitle;
    String? alertBadge;
    IconData statusIcon;

    if (hasOverdue) {
      statusColor = AppColors.error;
      statusSubtitle = urgent != null
          ? '${urgent.title} • Overdue'
          : '${state.overdueCount} maintenance schedules overdue';
      alertBadge = '${state.overdueCount} Overdue';
      statusIcon = LucideIcons.triangleAlert;
    } else if (hasDueSoon) {
      statusColor = AppColors.warning;
      statusSubtitle = urgent != null
          ? '${urgent.title} • ${urgent.statusMessage(state.currentOdometer)}'
          : '${state.dueSoonCount} service reminders due soon';
      alertBadge = '${state.dueSoonCount} Due Soon';
      statusIcon = LucideIcons.bellRing;
    } else {
      statusColor = AppColors.success;
      if (urgent != null && urgent.targetOdo != null) {
        final diff = (urgent.targetOdo! - state.currentOdometer)
            .clamp(0, double.infinity)
            .round();
        statusSubtitle = 'Next: ${urgent.title} in $diff km';
      } else if (state.activeReminders.isNotEmpty) {
        statusSubtitle =
            'All ${state.activeReminders.length} maintenance schedules up to date';
      } else if (serviceLogsCount > 0) {
        statusSubtitle = '$serviceLogsCount service records logged';
      } else {
        statusSubtitle = 'Track engine oil, brakes & service records';
      }
      statusIcon = LucideIcons.wrench;
    }

    return AppCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.listCardPaddingH,
        vertical: AppSpacing.listCardPaddingV,
      ),
      onTap: () => ServicesScreen.open(context),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E2A),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              border: Border.all(
                color: const Color(0xFF2A2A3C),
                width: 1,
              ),
            ),
            child: Icon(
              statusIcon,
              color: const Color(0xFFA1A1AA),
              size: 17,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        'servicesHubTitle'.tr(),
                        style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  statusSubtitle,
                  style: AppTextStyles.caption.copyWith(
                    fontSize: 11.5,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          if (alertBadge != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: statusColor.withValues(alpha: 0.25),
                  width: 1,
                ),
              ),
              child: Text(
                alertBadge,
                style: TextStyle(
                  color: statusColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 4),
          ],
          const Icon(
            LucideIcons.chevronRight,
            size: 16,
            color: Color(0xFF71717A),
          ),
        ],
      ),
    );
  }
}
