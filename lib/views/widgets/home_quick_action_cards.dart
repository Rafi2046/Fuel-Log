import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import 'app_card.dart';

/// 2-Segment Quick Action Row on Home Dashboard: [Add Fuel] & [Add Service]
class HomeQuickActionCards extends StatelessWidget {
  const HomeQuickActionCards({
    super.key,
    required this.isEV,
    required this.onTapAddFuel,
    required this.onTapAddService,
    this.serviceAlertBadge,
  });

  final bool isEV;
  final VoidCallback onTapAddFuel;
  final VoidCallback onTapAddService;
  final String? serviceAlertBadge;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // 1. Add Fuel / Charge Tile
        Expanded(
          child: _ActionTile(
            icon: isEV ? LucideIcons.zap : LucideIcons.fuel,
            title: isEV ? 'addChargeQuick'.tr() : 'addFuelQuick'.tr(),
            subtitle: isEV ? 'addChargeSubtitle'.tr() : 'addFuelSubtitle'.tr(),
            onTap: onTapAddFuel,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),

        // 2. Add Service / Maintenance Tile
        Expanded(
          child: _ActionTile(
            icon: LucideIcons.wrench,
            title: 'addServiceQuick'.tr(),
            subtitle: 'addServiceSubtitle'.tr(),
            badge: serviceAlertBadge,
            onTap: onTapAddService,
          ),
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.badge,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.control,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              border: Border.all(
                color: AppColors.controlBorder,
                width: 1,
              ),
            ),
            child: Icon(
              icon,
              size: 15,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          title,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          softWrap: false,
                        ),
                      ),
                    ),
                    if (badge != null) ...[
                      const SizedBox(width: 4),
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Color(0xFFEF4444),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 10.5,
                    color: AppColors.textTertiary,
                    fontWeight: FontWeight.w400,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 2),
          Icon(
            LucideIcons.plus,
            size: 13,
            color: AppColors.textTertiary,
          ),
        ],
      ),
    );
  }
}
