import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/database/app_database.dart';
import '../../../../../core/utils/app_formatters.dart';
import '../../../../../models/vehicle_report_model.dart';
import 'report_preview_components.dart';

/// Fuel Efficiency Analysis Report Preview Section
class FuelEfficiencyReportView extends StatelessWidget {
  const FuelEfficiencyReportView({
    super.key,
    required this.report,
  });

  final VehicleReportData report;

  @override
  Widget build(BuildContext context) {
    final fuels = report.fuelLogs.cast<FuelLog>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: ReportMetricCard(
                label: 'reportLabelAvgMileage'.tr(),
                value:
                    '${report.avgEfficiency.toStringAsFixed(1)} ${report.efficiencyUnit}',
                isHighlighted: true,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ReportMetricCard(
                label: 'reportLabelBestMileage'.tr(),
                value: report.bestEfficiency > 0
                    ? '${report.bestEfficiency.toStringAsFixed(1)} ${report.efficiencyUnit}'
                    : '--',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ReportMetricCard(
                label: 'reportLabelCostPerKm'.tr(),
                value: '${AppCurrency.format(report.avgCostPerKm)}/km',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.wash,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.hairline),
          ),
          child: Column(
            children: [
              ReportDetailItemRow(
                label: 'Total Fuel Spend',
                value: AppCurrency.format(report.totalFuelSpend),
                highlight: true,
              ),
              Divider(color: AppColors.hairline, height: 16),
              ReportDetailItemRow(
                label: 'Total Volume Consumed',
                value:
                    '${report.totalLitres.toStringAsFixed(1)} ${report.volumeUnit == "L" ? "Liters" : "kWh"}',
              ),
              Divider(color: AppColors.hairline, height: 16),
              ReportDetailItemRow(
                label: 'Total Fill-up Logs',
                value: '${report.fuelLogCount} fill-ups',
              ),
              Divider(color: AppColors.hairline, height: 16),
              ReportDetailItemRow(
                label: 'Average Fuel Price',
                value:
                    '${AppCurrency.format(report.avgFuelPrice)} / ${report.volumeUnit}',
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        Text(
          'REFUELING HISTORY',
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        if (fuels.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.wash,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.hairline),
            ),
            child: Center(
              child: Text(
                'No refueling records found in this range.',
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          )
        else
          ...fuels.map((f) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.wash,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.hairline),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        LucideIcons.fuel,
                        size: 16,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${f.amount.toStringAsFixed(1)} ${report.volumeUnit} · ${f.isFullTank ? 'Full Tank' : 'Partial'}',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${DateFormat('d MMM yyyy').format(f.date)} · Odo: ${f.odometer.toStringAsFixed(0)} km',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      AppCurrency.format(f.cost),
                      style: GoogleFonts.inter(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              )),
      ],
    );
  }
}
