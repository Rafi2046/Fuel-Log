import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_text_styles.dart';
import '../../models/weather_models.dart';
import '../../viewmodels/weather_viewmodel.dart';

/// Compact Home weather + drive tip card.
class WeatherDriveCard extends ConsumerWidget {
  const WeatherDriveCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled = ref.watch(weatherTipsEnabledProvider);
    if (!enabled) return const SizedBox.shrink();

    final adviceAsync = ref.watch(weatherAdviceProvider);

    if (adviceAsync.isLoading && !adviceAsync.hasValue) {
      return _Shell(
        child: Row(
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primary.withValues(alpha: 0.7),
              ),
            ),
            SizedBox(width: 12),
            Text(
              'weatherLoading'.tr(),
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    if (adviceAsync.hasError && !adviceAsync.hasValue) {
      return _Shell(
        child: Row(
          children: [
            Icon(LucideIcons.cloudOff, size: 18, color: AppColors.textTertiary),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'weatherUnavailable'.tr(),
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            TextButton(
              onPressed: () =>
                  ref.read(weatherAdviceProvider.notifier).refresh(),
              child: Text(
                'retry'.tr(),
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final advice = adviceAsync.valueOrNull;
    if (advice == null) return const SizedBox.shrink();

    final accent = advice.accentColor(AppColors.primary);
    final snap = advice.snapshot;
    final temp = snap.temperatureC.round();
    final condition = snap.conditionKey.tr();
    final humidity = snap.relativeHumidity;
    final wind = snap.windSpeedKmh.round();

    return _Shell(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            DriveAdviceEngine.weatherIconForCode(snap.weatherCode),
            color: const Color(0xFFA1A1AA),
            size: 16,
          ),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$temp°C · $condition',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.label.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    if (humidity != null) ...[
                      SizedBox(height: 1),
                      Text(
                        '$humidity% · $wind km/h',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textTertiary,
                          fontSize: 10,
                        ),
                      ),
                    ],
                    const SizedBox(height: 2),
                    Text(
                      advice.titleKey.tr(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption.copyWith(
                        color: accent,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                    Text(
                      advice.bodyKey.tr(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'refresh'.tr(),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: BoxConstraints(minWidth: 32, minHeight: 32),
                onPressed: () =>
                    ref.read(weatherAdviceProvider.notifier).refresh(),
                icon: Icon(
                  LucideIcons.refreshCw,
                  size: 14,
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
        );
  }
}

/// Slim tip strip for Trip / Start Trip area.
class WeatherDriveTripBanner extends ConsumerWidget {
  const WeatherDriveTripBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled = ref.watch(weatherTipsEnabledProvider);
    if (!enabled) return const SizedBox.shrink();

    final adviceAsync = ref.watch(weatherAdviceProvider);
    return adviceAsync.maybeWhen(
      data: (advice) {
        final accent = advice.accentColor(AppColors.primary);
        final snap = advice.snapshot;
        return Container(
          margin: const EdgeInsets.fromLTRB(
            AppSpacing.screenPadding,
            0,
            AppSpacing.screenPadding,
            6,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.card.withValues(alpha: AppColors.isDark ? 0.94 : 1),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(color: accent.withValues(alpha: 0.35)),
          ),
          child: Row(
            children: [
              Icon(advice.lucideIcon, size: 16, color: accent),
              SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${snap.temperatureC.round()}°C · ${snap.conditionKey.tr()}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 11.5,
                      ),
                    ),
                    Text(
                      advice.bodyKey.tr(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
      orElse: () => SizedBox.shrink(),
    );
  }
}

class _Shell extends StatelessWidget {
  _Shell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(14, 12, 6, 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: AppColors.border,
          width: 1,
        ),
      ),
      child: child,
    );
  }
}
