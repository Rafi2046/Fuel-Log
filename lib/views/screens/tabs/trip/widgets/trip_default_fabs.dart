import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_spacing.dart';
import 'start_trip_fab.dart';

/// Manual-entry circle + history circle + start/stop trip FAB row shown when idle on the map.
class TripDefaultFabs extends StatelessWidget {
  const TripDefaultFabs({
    super.key,
    required this.isTracking,
    required this.onManualEntry,
    required this.onToggleTracking,
    this.onHistory,
    this.onIntercom,
  });

  final bool isTracking;
  final VoidCallback onManualEntry;
  final VoidCallback onToggleTracking;
  final VoidCallback? onHistory;
  final VoidCallback? onIntercom;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPadding,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF18181F).withValues(alpha: 0.94),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF2E2E38)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onManualEntry,
                child: const Center(
                  child: Icon(
                    LucideIcons.mapPin,
                    size: 18,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
          ),
          if (onHistory != null) ...[
            const SizedBox(width: 6),
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF18181F).withValues(alpha: 0.94),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF2E2E38)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: onHistory,
                  child: const Center(
                    child: Icon(
                      LucideIcons.route,
                      size: 18,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
            ),
          ],
          if (onIntercom != null) ...[
            const SizedBox(width: 6),
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF18181F).withValues(alpha: 0.94),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.4),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.18),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: onIntercom,
                  child: const Center(
                    child: Icon(
                      LucideIcons.radio,
                      size: 18,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(width: 8),
          Expanded(
            child: StartTripFab(
              isTracking: isTracking,
              onPressed: onToggleTracking,
            ),
          ),
        ],
      ),
    );
  }
}
