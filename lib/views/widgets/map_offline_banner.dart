import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_text_styles.dart';

/// Shown over the map when tile hosts cannot be resolved / reached.
class MapOfflineBanner extends StatelessWidget {
  const MapOfflineBanner({super.key, this.onRetry});

  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
        decoration: BoxDecoration(
          color: const Color(0xFF18181F).withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: const Color(0xFF353542)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              LucideIcons.wifiOff,
              size: 22,
              color: AppColors.primary,
            ),
            const SizedBox(height: 10),
            Text(
              'mapOfflineHint'.tr(),
              textAlign: TextAlign.center,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
                fontSize: 12,
                height: 1.35,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 12),
              TextButton(
                onPressed: onRetry,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                child: Text('mapOfflineRetry'.tr()),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
