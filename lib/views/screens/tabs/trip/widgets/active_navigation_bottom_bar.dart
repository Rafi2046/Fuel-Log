import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/constants/app_text_styles.dart';
import '../../../../../models/mock_gas_station.dart';
import '../../../../../core/services/navigation_routing_service.dart';

class ActiveNavigationBottomBar extends StatelessWidget {
  const ActiveNavigationBottomBar({
    super.key,
    required this.station,
    required this.route,
    required this.onExit,
    required this.onExternalMaps,
    required this.onLogFuel,
  });

  final MockGasStation station;
  final NavigationRouteResult? route;
  final VoidCallback onExit;
  final VoidCallback onExternalMaps;
  final VoidCallback onLogFuel;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin:
          const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF14141C).withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF2C2C3A),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.6),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top Row: Big Duration, Distance, and ETA
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        route?.formattedDuration ?? '...',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF00E5FF),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '(${route?.formattedDistance ?? station.distance})',
                        style: AppTextStyles.caption.copyWith(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'Estimated Arrival: ${route?.formattedEta ?? '...'}',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textTertiary,
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ),

              // End Navigation Red Button
              Material(
                color: const Color(0xFFD32F2F),
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: onExit,
                  borderRadius: BorderRadius.circular(12),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.x, size: 16, color: Colors.white),
                        SizedBox(width: 4),
                        Text(
                          'Exit',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(color: Color(0xFF262634), height: 1),
          const SizedBox(height: 10),

          // Bottom actions: Open in Google Maps voice nav + Log Fuel
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onExternalMaps,
                  icon: const Icon(LucideIcons.externalLink, size: 14),
                  label: const Text(
                    'Voice Nav (Maps)',
                    style:
                        TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF80DEEA),
                    side: const BorderSide(color: Color(0xFF00838F)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onLogFuel,
                  icon: const Icon(LucideIcons.fuel, size: 14),
                  label: const Text(
                    'Log Fuel Here',
                    style:
                        TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: Color(0xFF4E2C1A)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

