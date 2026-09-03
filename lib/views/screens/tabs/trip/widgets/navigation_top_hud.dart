import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../../core/constants/app_text_styles.dart';
import '../../../../../models/mock_gas_station.dart';
import '../../../../../core/services/navigation_routing_service.dart';

class NavigationTopHud extends StatelessWidget {
  const NavigationTopHud({
    super.key,
    required this.station,
    required this.route,
    required this.onExit,
  });

  final MockGasStation station;
  final NavigationRouteResult? route;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.mapOverlay,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFF00E5FF).withValues(alpha: 0.4),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: const Color(0xFF00E5FF).withValues(alpha: 0.12),
            blurRadius: 16,
          ),
        ],
      ),
      child: Row(
        children: [
          // Turn Maneuver Icon Box
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF00E5FF).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF00E5FF).withValues(alpha: 0.4),
              ),
            ),
            child: const Icon(
              LucideIcons.arrowUpRight,
              color: Color(0xFF00E5FF),
              size: 24,
            ),
          ),
          const SizedBox(width: 12),

          // Maneuver instruction + destination
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  route?.nextInstruction ?? 'Calculating optimal route...',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Towards ${station.name}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption.copyWith(
                    color: const Color(0xFF80DEEA),
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Exit button
          IconButton(
            onPressed: onExit,
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF2E1A1A),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFFE53935).withValues(alpha: 0.5),
                ),
              ),
              child: const Icon(
                LucideIcons.x,
                size: 14,
                color: Color(0xFFFF8A80),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

