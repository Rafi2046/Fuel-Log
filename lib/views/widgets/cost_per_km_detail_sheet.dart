import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/utils/app_formatters.dart';
import '../screens/services/services_screen.dart';
import '../screens/tabs/logs_tab.dart';

/// Comprehensive modal detail sheet explaining and breaking down Cost Per Km.
class CostPerKmDetailSheet extends StatelessWidget {
  const CostPerKmDetailSheet({
    super.key,
    required this.costPerKm,
    required this.totalFuelSpend,
    required this.totalServiceSpend,
    required this.totalDistance,
    required this.isEV,
  });

  final double costPerKm;
  final double totalFuelSpend;
  final double totalServiceSpend;
  final double totalDistance;
  final bool isEV;

  static Future<void> show(
    BuildContext context, {
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
              Text(
                'Cost Per Kilometer',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
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

          // Main KPI Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF1B1B27),
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              border: Border.all(color: const Color(0xFF262638), width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'OVERALL RUNNING COST',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF94A3B8),
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      costPerKm > 0 ? AppCurrency.format(costPerKm) : '—',
                      style: GoogleFonts.inter(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '/ km',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Includes all fuel/charging costs + service & maintenance expenses.',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF71717A),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Formula & Metric Breakdown
          Text(
            'EXPENSE BREAKDOWN',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF71717A),
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 10),

          // Fuel vs Service Split Bar
          if (totalSpend > 0) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: SizedBox(
                height: 8,
                child: Row(
                  children: [
                    Expanded(
                      flex: (fuelPct * 100).round().clamp(1, 99),
                      child: Container(color: const Color(0xFF38BDF8)),
                    ),
                    Expanded(
                      flex: (servicePct * 100).round().clamp(1, 99),
                      child: Container(color: const Color(0xFFA78BFA)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Grid of 4 Breakdown items
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
                  label: isEV ? 'Total Energy Spend' : 'Total Fuel Spend',
                  value: AppCurrency.format(totalFuelSpend),
                  subValue: fuelCostPerKm > 0
                      ? '${AppCurrency.format(fuelCostPerKm)}/km (${(fuelPct * 100).toStringAsFixed(0)}%)'
                      : null,
                ),
                const Divider(height: 16, color: Color(0xFF262638)),
                _RowItem(
                  label: 'Total Service & Repairs',
                  value: AppCurrency.format(totalServiceSpend),
                  subValue: serviceCostPerKm > 0
                      ? '${AppCurrency.format(serviceCostPerKm)}/km (${(servicePct * 100).toStringAsFixed(0)}%)'
                      : null,
                ),
                const Divider(height: 16, color: Color(0xFF262638)),
                _RowItem(
                  label: 'Total Net Expenditure',
                  value: AppCurrency.format(totalSpend),
                  isBold: true,
                ),
                const Divider(height: 16, color: Color(0xFF262638)),
                _RowItem(
                  label: 'Total Distance Tracked',
                  value: '${totalDistance.toStringAsFixed(0)} km',
                  isBold: true,
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
                  icon: const Icon(LucideIcons.fuel, size: 14),
                  label: const Text('Fuel Logs'),
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
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(LucideIcons.wrench, size: 14),
                  label: const Text('Service Logs'),
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
                    ServicesScreen.open(context);
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
    this.subValue,
    this.isBold = false,
  });

  final String label;
  final String value;
  final String? subValue;
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
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            if (subValue != null)
              Text(
                subValue!,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: const Color(0xFF71717A),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
