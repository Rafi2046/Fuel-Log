import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/utils/app_formatters.dart';
import '../../../../../models/vehicle_report_model.dart';
import 'report_preview_components.dart';

/// Cost of Ownership Report Preview Section
class OwnershipReportView extends StatelessWidget {
  const OwnershipReportView({
    super.key,
    required this.report,
  });

  final VehicleReportData report;

  @override
  Widget build(BuildContext context) {
    final fuelPct = report.grandTotalSpend > 0
        ? (report.totalFuelSpend / report.grandTotalSpend)
        : 0.0;
    final servicePct = report.grandTotalSpend > 0
        ? (report.totalServiceSpend / report.grandTotalSpend)
        : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary.withValues(alpha: 0.12),
                AppColors.wash,
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'TOTAL OPERATING INVESTMENT',
                style: GoogleFonts.inter(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 6),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  AppCurrency.format(report.grandTotalSpend),
                  style: GoogleFonts.inter(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Running cost: ${AppCurrency.format(report.avgCostPerKm)} for every kilometer driven.',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        Text(
          'EXPENSE PROPORTION',
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.wash,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.hairline),
          ),
          child: Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: SizedBox(
                  height: 10,
                  child: Row(
                    children: [
                      if (fuelPct > 0)
                        Expanded(
                          flex: (fuelPct * 1000).round().clamp(1, 1000),
                          child: Container(color: AppColors.primary),
                        ),
                      if (servicePct > 0)
                        Expanded(
                          flex: (servicePct * 1000).round().clamp(1, 1000),
                          child: Container(color: const Color(0xFF38BDF8)),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  ReportProportionLegend(
                    color: AppColors.primary,
                    text:
                        'Fuel: ${AppCurrency.format(report.totalFuelSpend)} (${(fuelPct * 100).toStringAsFixed(0)}%)',
                  ),
                  ReportProportionLegend(
                    color: const Color(0xFF38BDF8),
                    text:
                        'Service: ${AppCurrency.format(report.totalServiceSpend)} (${(servicePct * 100).toStringAsFixed(0)}%)',
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        ReportSummaryDetailsCard(report: report),
      ],
    );
  }
}
