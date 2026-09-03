import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/database/app_database.dart';
import '../../core/utils/app_formatters.dart';
import '../../core/utils/vehicle_display.dart';
import '../screens/refueling_form_screen.dart';
import '../screens/services/services_screen.dart';
import '../screens/services/widgets/add_cost_service_sheet.dart';
import '../screens/tabs/logs_tab.dart';

/// Ultra-premium modal detail sheet explaining and breaking down Cost Per Kilometer.
class CostPerKmDetailSheet extends StatelessWidget {
  const CostPerKmDetailSheet({
    super.key,
    this.vehicle,
    required this.costPerKm,
    required this.totalFuelSpend,
    required this.totalServiceSpend,
    required this.totalDistance,
    required this.isEV,
  });

  final Vehicle? vehicle;
  final double costPerKm;
  final double totalFuelSpend;
  final double totalServiceSpend;
  final double totalDistance;
  final bool isEV;

  static Future<void> show(
    BuildContext context, {
    Vehicle? vehicle,
    required double costPerKm,
    required double totalFuelSpend,
    required double totalServiceSpend,
    required double totalDistance,
    required bool isEV,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CostPerKmDetailSheet(
        vehicle: vehicle,
        costPerKm: costPerKm,
        totalFuelSpend: totalFuelSpend,
        totalServiceSpend: totalServiceSpend,
        totalDistance: totalDistance,
        isEV: isEV,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalSpend = totalFuelSpend + totalServiceSpend;
    final fuelCostPerKm =
        totalDistance > 0 ? (totalFuelSpend / totalDistance) : 0.0;
    final serviceCostPerKm =
        totalDistance > 0 ? (totalServiceSpend / totalDistance) : 0.0;

    final fuelPct = totalSpend > 0 ? (totalFuelSpend / totalSpend) : 0.0;
    final servicePct = totalSpend > 0 ? (totalServiceSpend / totalSpend) : 0.0;
    final hasData = totalSpend > 0 || totalDistance > 0;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF13131E),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusXl),
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.6),
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        AppSpacing.md,
        AppSpacing.screenPadding,
        MediaQuery.of(context).padding.bottom + AppSpacing.lg,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Header Row
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Icon(
                    LucideIcons.gauge,
                    size: 20,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Cost Per Kilometer',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          if (vehicle != null) ...[
                            Icon(
                              VehicleDisplay.iconFor(vehicle!),
                              size: 13,
                              color: AppColors.textTertiary,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              '${vehicle!.name} • ${vehicle!.fuelType}',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppColors.textTertiary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ] else
                            Text(
                              'All logs tracked in database',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppColors.textTertiary,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    LucideIcons.x,
                    size: 19,
                    color: Color(0xFFA1A1AA),
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            // Hero KPI Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: costPerKm > 0 ? 0.16 : 0.08),
                    const Color(0xFF191928),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                border: Border.all(
                  color: costPerKm > 0
                      ? AppColors.primary.withValues(alpha: 0.35)
                      : Colors.white.withValues(alpha: 0.08),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: costPerKm > 0
                        ? AppColors.primary.withValues(alpha: 0.08)
                        : Colors.transparent,
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'OVERALL RUNNING COST',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                          letterSpacing: 0.8,
                        ),
                      ),
                      if (costPerKm > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.success.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            'LIVE METRIC',
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: AppColors.success,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        costPerKm > 0 ? AppCurrency.format(costPerKm) : '—',
                        style: GoogleFonts.inter(
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.8,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '/ km',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    costPerKm > 0
                        ? 'Includes all fuel & energy spend plus service, parts and repair expenses divided by total distance.'
                        : 'No fuel or service logs entered yet. Enter your first fill-up or maintenance record below to see live running cost.',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xFF94A3B8),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Expense Split Bar (Visual Progress Ratio)
            Text(
              'EXPENSE RATIO & BREAKDOWN',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF71717A),
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 10),

            if (totalSpend > 0) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: SizedBox(
                  height: 10,
                  child: Row(
                    children: [
                      if (fuelPct > 0)
                        Expanded(
                          flex: (fuelPct * 100).round().clamp(1, 100),
                          child: Container(color: const Color(0xFF38BDF8)),
                        ),
                      if (servicePct > 0)
                        Expanded(
                          flex: (servicePct * 100).round().clamp(1, 100),
                          child: Container(color: const Color(0xFFA78BFA)),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFF38BDF8),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Fuel: ${(fuelPct * 100).toStringAsFixed(0)}%',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: const Color(0xFF94A3B8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFFA78BFA),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Service: ${(servicePct * 100).toStringAsFixed(0)}%',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: const Color(0xFF94A3B8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ] else ...[
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // 2x2 Metric Cards Grid
            Row(
              children: [
                Expanded(
                  child: _MetricTile(
                    icon: LucideIcons.fuel,
                    iconColor: const Color(0xFF38BDF8),
                    label: isEV ? 'Energy Cost' : 'Fuel Spend',
                    value: AppCurrency.format(totalFuelSpend),
                    subValue: fuelCostPerKm > 0
                        ? '${AppCurrency.format(fuelCostPerKm)}/km'
                        : 'Awaiting logs',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _MetricTile(
                    icon: LucideIcons.wrench,
                    iconColor: const Color(0xFFA78BFA),
                    label: 'Service & Repairs',
                    value: AppCurrency.format(totalServiceSpend),
                    subValue: serviceCostPerKm > 0
                        ? '${AppCurrency.format(serviceCostPerKm)}/km'
                        : 'No repairs logged',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _MetricTile(
                    icon: LucideIcons.receipt,
                    iconColor: const Color(0xFF34D399),
                    label: 'Net Total Spend',
                    value: AppCurrency.format(totalSpend),
                    subValue: hasData ? 'Fuel + Service' : '0 records',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _MetricTile(
                    icon: LucideIcons.navigation,
                    iconColor: const Color(0xFFFB923C),
                    label: 'Distance Tracked',
                    value: '${totalDistance.toStringAsFixed(0)} km',
                    subValue: hasData ? 'From odometer logs' : '0 km logged',
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),

            // Quick Interactive Action Buttons
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    icon: const Icon(LucideIcons.fuel, size: 16),
                    label: const Text(
                      'Add Fuel Log',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.textPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const RefuelingFormScreen(),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(LucideIcons.wrench, size: 16),
                    label: const Text(
                      'Add Service',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textPrimary,
                      side: BorderSide(
                        color: Colors.white.withValues(alpha: 0.16),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                      if (vehicle != null) {
                        AddCostServiceSheet.show(
                          context,
                          vehicleId: vehicle!.id,
                          currentOdometer: vehicle!.startOdo,
                        );
                      } else {
                        ServicesScreen.open(context);
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),

            // Secondary link to view history
            Center(
              child: TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  LogsTab.open(context);
                },
                child: Text(
                  'View all history in Logs Tab →',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textTertiary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.subValue,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final String subValue;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1B1B29),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.07),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 14, color: iconColor),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: const Color(0xFF94A3B8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subValue,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 10,
              color: const Color(0xFF71717A),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
