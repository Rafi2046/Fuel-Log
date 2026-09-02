import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/models/intercom_rider_role.dart';
import '../../../../viewmodels/intercom_viewmodel.dart';
import '../../../widgets/clean_glass_panel.dart';

/// Contextual guidance and lock-screen status for the active rider role.
class IntercomRoleStatusCard extends StatelessWidget {
  const IntercomRoleStatusCard({
    super.key,
    required this.state,
  });

  final IntercomState state;

  @override
  Widget build(BuildContext context) {
    final tips = _RoleTips.forRole(state.riderRole);

    return CleanGlassPanel(
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.22),
                  ),
                ),
                child: Text(
                  state.riderRole.label,
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const Spacer(),
              if (state.isBackgroundSessionActive)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.lock_rounded,
                      size: 13,
                      color: AppColors.success.withValues(alpha: 0.9),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Lock-screen ready',
                      style: AppTextStyles.caption.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            tips.headline,
            style: AppTextStyles.label.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            tips.body,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleTips {
  const _RoleTips({required this.headline, required this.body});

  final String headline;
  final String body;

  static _RoleTips forRole(IntercomRiderRole role) => switch (role) {
        IntercomRiderRole.groupRider => const _RoleTips(
              headline: 'Bluetooth helmet recommended',
              body:
                  'Use a Sena or Cardo intercom for the best multi-bike range. '
                  'Volume buttons still work as push-to-talk.',
            ),
        IntercomRiderRole.sameBikeDriver => const _RoleTips(
              headline: 'Mount your phone and use push-to-talk',
              body:
                  'Loudspeaker is on. Hold the mic button or a volume key to talk. '
                  'You can lock the screen — the notification keeps intercom alive.',
            ),
        IntercomRiderRole.sameBikePillion => const _RoleTips(
              headline: 'Plug in earphones, then pocket your phone',
              body:
                  'Hands-free stays on so you can talk without opening the app. '
                  'Use wired or Bluetooth earphones with a mic. Tap Hold PTT on the '
                  'lock-screen notification or press your headset button.',
            ),
      };
}
