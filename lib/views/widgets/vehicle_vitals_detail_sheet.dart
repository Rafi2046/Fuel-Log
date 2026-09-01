import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/database/app_database.dart';
import '../screens/mileage/mileage_log_screen.dart';
import '../screens/tabs/logs_tab.dart';

/// Comprehensive modal detail sheet showing full vehicle running vitals, lifetime odometer,
/// total fuel consumed, refill frequency, and efficiency.
class VehicleVitalsDetailSheet extends StatelessWidget {
  const VehicleVitalsDetailSheet({
    super.key,
    required this.vehicle,
    required this.totalDistance,
    required this.totalFuelConsumed,
    required this.avgMileage,
    required this.lastMileage,
    required this.recentLog,
    required this.logsCount,
    required this.unit,
    required this.mileageUnit,
    required this.isEV,
  });

  final Vehicle? vehicle;
  final double totalDistance;
  final double totalFuelConsumed;
  final double avgMileage;
  final double lastMileage;
  final FuelLog? recentLog;
  final int logsCount;
  final String unit;
  final String mileageUnit;
  final bool isEV;

  static Future<void> show(
    BuildContext context, {
    required Vehicle? vehicle,
    required double totalDistance,
    required double totalFuelConsumed,
    required double avgMileage,
    required double lastMileage,
    required FuelLog? recentLog,
    required int logsCount,
    required String unit,
    required String mileageUnit,
    required bool isEV,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => VehicleVitalsDetailSheet(
        vehicle: vehicle,
        totalDistance: totalDistance,
        totalFuelConsumed: totalFuelConsumed,
        avgMileage: avgMileage,
        lastMileage: lastMileage,
        recentLog: recentLog,
        logsCount: logsCount,
        unit: unit,
        mileageUnit: mileageUnit,
        isEV: isEV,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final avgFillSize = logsCount > 0 ? (totalFuelConsumed / logsCount) : 0.0;
    final currentOdo = recentLog != null
        ? recentLog!.odometer
        : (vehicle?.startOdo ?? 0.0);

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusXl),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        MediaQuery.of(context).padding.bottom + AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFF3F3F50),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Header
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Vehicle Running Vitals',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${vehicle?.name ?? 'Vehicle'} • ${isEV ? 'Electric (EV)' : (vehicle?.fuelType ?? 'Fuel')}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(
                  LucideIcons.x,
                  size: 18,
                  color: Color(0xFFA1A1AA),
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Distance & Odometer Group
          Text(
            'ODOMETER & RANGE',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF71717A),
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF1B1B27),
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              border: Border.all(color: const Color(0xFF262638), width: 1),
            ),
            child: Column(
              children: [
                _RowItem(
                  label: 'Current Odometer',
                  value: '${currentOdo.toStringAsFixed(0)} km',
                  isBold: true,
                ),
                const Divider(height: 16, color: Color(0xFF262638)),
                _RowItem(
                  label: 'Initial Starting Odometer',
                  value: '${(vehicle?.startOdo ?? 0).toStringAsFixed(0)} km',
                ),
                const Divider(height: 16, color: Color(0xFF262638)),
                _RowItem(
                  label: 'Total Tracked Distance',
                  value: '${totalDistance.toStringAsFixed(0)} km',
                  isBold: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Fuel & Efficiency Group
          Text(
            'FUEL & EFFICIENCY',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF71717A),
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF1B1B27),
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              border: Border.all(color: const Color(0xFF262638), width: 1),
            ),
            child: Column(
              children: [
                _RowItem(
                  label: isEV ? 'Total Energy Consumed' : 'Total Fuel Consumed',
                  value: '${totalFuelConsumed.toStringAsFixed(1)} $unit',
                  isBold: true,
                ),
                const Divider(height: 16, color: Color(0xFF262638)),
                _RowItem(
                  label: isEV ? 'Total Charging Sessions' : 'Total Refill Count',
                  value: '$logsCount fill-ups',
                ),
                const Divider(height: 16, color: Color(0xFF262638)),
                _RowItem(
                  label: 'Average Refill Volume',
                  value: '${avgFillSize.toStringAsFixed(1)} $unit / fill',
                ),
                const Divider(height: 16, color: Color(0xFF262638)),
                _RowItem(
                  label: 'Average Fuel Efficiency',
                  value: avgMileage > 0
                      ? '${avgMileage.toStringAsFixed(1)} $mileageUnit'
                      : '—',
                  isBold: true,
                ),
                const Divider(height: 16, color: Color(0xFF262638)),
                _RowItem(
                  label: 'Last Recorded Mileage',
                  value: lastMileage > 0
                      ? '${lastMileage.toStringAsFixed(1)} $mileageUnit'
                      : '—',
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Quick Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(LucideIcons.gauge, size: 14),
                  label: const Text('Mileage Log'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    side: const BorderSide(color: Color(0xFF262638)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const MileageLogScreen(),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(LucideIcons.fuel, size: 14),
                  label: const Text('All Refuels'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    side: const BorderSide(color: Color(0xFF262638)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                    LogsTab.open(context);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RowItem extends StatelessWidget {
  const _RowItem({
    required this.label,
    required this.value,
    this.isBold = false,
  });

  final String label;
  final String value;
  final bool isBold;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: const Color(0xFF94A3B8),
              fontWeight: isBold ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
