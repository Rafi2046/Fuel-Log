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
  });

  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onRecenter;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF18181F).withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF2E2E38)),
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
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                child: const Padding(
                  padding: EdgeInsets.all(9),
                  child: Icon(
                    LucideIcons.plus,
                    size: 17,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Container(
                width: 22,
                height: 1,
                color: const Color(0xFF2E2E38),
              ),
              InkWell(
                onTap: onZoomOut,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(12),
                ),
                child: const Padding(
                  padding: EdgeInsets.all(9),
                  child: Icon(
                    LucideIcons.minus,
                    size: 17,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF18181F).withValues(alpha: 0.94),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF2E2E38)),
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
