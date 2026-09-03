import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/constants/app_colors.dart';

/// Compact zoom in/out + recenter controls for the trip map.
class TripMapZoomControls extends StatelessWidget {
  const TripMapZoomControls({
    super.key,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onRecenter,
    this.onResetNorth,
  });

  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onRecenter;
  final VoidCallback? onResetNorth;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppColors.mapOverlay,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.mapOverlayBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                onTap: onZoomIn,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                child: Padding(
                  padding: EdgeInsets.all(9),
                  child: Icon(
                    LucideIcons.plus,
                    size: 17,
                    color: AppColors.onMapOverlay,
                  ),
                ),
              ),
              Container(
                width: 22,
                height: 1,
                color: AppColors.mapOverlayBorder,
              ),
              InkWell(
                onTap: onZoomOut,
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(12),
                ),
                child: Padding(
                  padding: EdgeInsets.all(9),
                  child: Icon(
                    LucideIcons.minus,
                    size: 17,
                    color: AppColors.onMapOverlay,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (onResetNorth != null) ...[
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: AppColors.mapOverlay,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.mapOverlayBorder),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: InkWell(
              onTap: onResetNorth,
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: EdgeInsets.all(9),
                child: Icon(
                  LucideIcons.compass,
                  size: 17,
                  color: AppColors.onMapOverlay,
                ),
              ),
            ),
          ),
        ],
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: AppColors.mapOverlay,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.mapOverlayBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: InkWell(
            onTap: onRecenter,
            borderRadius: BorderRadius.circular(20),
            child: const Padding(
              padding: EdgeInsets.all(9),
              child: Icon(
                LucideIcons.locateFixed,
                size: 17,
                color: AppColors.primary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
