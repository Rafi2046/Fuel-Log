import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/database/app_database.dart';
import '../../core/utils/app_formatters.dart';
import 'app_card.dart';

/// 4-KPI Grid for Home Dashboard using clean Lucide icons & pristine typography
class HomeKeyMetricsGrid extends StatelessWidget {
  const HomeKeyMetricsGrid({
    super.key,
    required this.avgMileage,
    required this.totalFuelSpend,
    required this.totalServiceSpend,
    required this.costPerKm,
    required this.mileageUnit,
    required this.isEV,
    this.onTapMileage,
    this.onTapFuelSpend,
    this.onTapServiceSpend,
    this.onTapCostPerKm,
  });

  final double avgMileage;
  final double totalFuelSpend;
  final double totalServiceSpend;
  final double costPerKm;
  final String mileageUnit;
  final bool isEV;
  final VoidCallback? onTapMileage;
  final VoidCallback? onTapFuelSpend;
  final VoidCallback? onTapServiceSpend;
  final VoidCallback? onTapCostPerKm;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                label: 'avgMileage'.tr(),
                value: avgMileage > 0
                    ? '${avgMileage.toStringAsFixed(1)} $mileageUnit'
                    : '—',
                icon: isEV ? LucideIcons.zap : LucideIcons.gauge,
                onTap: onTapMileage,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _MetricCard(
                label: 'totalFuelSpend'.tr(),
                value: AppCurrency.format(totalFuelSpend),
                icon: isEV ? LucideIcons.batteryCharging : LucideIcons.fuel,
                onTap: onTapFuelSpend,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                label: 'totalServiceSpend'.tr(),
                value: AppCurrency.format(totalServiceSpend),
                icon: LucideIcons.wrench,
                onTap: onTapServiceSpend,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _MetricCard(
                label: 'costPerKm'.tr(),
                value: costPerKm > 0
                    ? '${AppCurrency.format(costPerKm)}/km'
                    : '—',
                icon: LucideIcons.trendingUp,
                onTap: onTapCostPerKm,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 13,
      ),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 14,
                color: const Color(0xFF94A3B8),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.inter(
                    color: const Color(0xFF94A3B8),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              letterSpacing: -0.2,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// Vehicle Running Vitals Panel: Pure clean typography grid without icon clutter
class HomeVehicleVitalsCard extends StatelessWidget {
  const HomeVehicleVitalsCard({
    super.key,
    required this.totalDistance,
    required this.totalFuelConsumed,
    required this.recentLog,
    required this.lastMileage,
    required this.unit,
    required this.mileageUnit,
    required this.isEV,
    this.onTap,
  });

  final double totalDistance;
  final double totalFuelConsumed;
  final FuelLog? recentLog;
  final double lastMileage;
  final String unit;
  final String mileageUnit;
  final bool isEV;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'vehicleVitals'.tr().toUpperCase(),
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF71717A),
                  letterSpacing: 0.8,
                ),
              ),
              const Spacer(),
              const Icon(
                LucideIcons.chevronRight,
                size: 14,
                color: Color(0xFF71717A),
              ),
            ],
          ),
          const SizedBox(height: 14),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 14),
                    child: _VitalItem(
                      label: 'totalDistance'.tr(),
                      value: totalDistance > 0
                          ? '${totalDistance.toStringAsFixed(0)} km'
                          : '0 km',
                    ),
                  ),
                ),
                Container(
                  width: 1,
                  color: const Color(0xFF262638),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 14),
                    child: _VitalItem(
                      label: isEV
                          ? 'totalEnergyConsumed'.tr()
                          : 'totalFuelConsumed'.tr(),
                      value: totalFuelConsumed > 0
                          ? '${totalFuelConsumed.toStringAsFixed(1)} $unit'
                          : '0 $unit',
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(
              height: 1,
              thickness: 1,
              color: Color(0xFF262638),
            ),
          ),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 14),
                    child: _VitalItem(
                      label: 'lastRefill'.tr(),
                      value: recentLog != null
                          ? '${recentLog!.amount.toStringAsFixed(0)} $unit • ${AppCurrency.format(recentLog!.cost)}'
                          : '—',
                    ),
                  ),
                ),
                Container(
                  width: 1,
                  color: const Color(0xFF262638),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 14),
                    child: _VitalItem(
                      label: 'lastMileage'.tr(),
                      value: lastMileage > 0
                          ? '${lastMileage.toStringAsFixed(1)} $mileageUnit'
                          : '—',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VitalItem extends StatelessWidget {
  const _VitalItem({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11.5,
            color: const Color(0xFF94A3B8),
            fontWeight: FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 14.5,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            letterSpacing: -0.2,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
