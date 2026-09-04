import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/database/app_database.dart';
import '../../../../../core/utils/app_formatters.dart';
import '../../../../../models/vehicle_report_model.dart';
import 'report_preview_components.dart';

/// Maintenance & Workshop Report Preview Section
class MaintenanceReportView extends StatelessWidget {
  const MaintenanceReportView({
    super.key,
    required this.report,
  });

  final VehicleReportData report;

  @override
  Widget build(BuildContext context) {
    final services = report.serviceLogs.cast<ServiceLog>();
    final avgCost = report.serviceLogCount > 0
        ? (report.totalServiceSpend / report.serviceLogCount)
        : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: ReportMetricCard(
                label: 'reportLabelServiceSpend'.tr(),
                value: AppCurrency.format(report.totalServiceSpend),
                isHighlighted: true,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ReportMetricCard(
                label: 'reportLabelTotalVisits'.tr(),
                value: '${report.serviceLogCount} services',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ReportMetricCard(
                label: 'reportLabelAvgPerService'.tr(),
                value: AppCurrency.format(avgCost),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        if (report.serviceCategoryCosts.isNotEmpty) ...[
          Text(
            'EXPENSE BREAKDOWN BY CATEGORY',
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.wash,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.hairline),
            ),
            child: Column(
              children: report.serviceCategoryCosts.entries.map((e) {
                final pct = report.totalServiceSpend > 0
                    ? (e.value / report.totalServiceSpend * 100)
                    : 0.0;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          e.key,
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      Text(
                        '${AppCurrency.format(e.value)} (${pct.toStringAsFixed(0)}%)',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 14),
        ],

        Text(
          'SERVICE & WORKSHOP LOGS',
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        if (services.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.wash,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.hairline),
            ),
            child: Column(
              children: [
                Icon(
                  LucideIcons.wrench,
                  size: 28,
                  color: AppColors.textTertiary,
                ),
                const SizedBox(height: 8),
                Text(
                  'No workshop service records logged yet.',
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          )
        else
          ...services.map((s) => Container(
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
                        LucideIcons.wrench,
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
                            s.title,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${s.category} · ${DateFormat('d MMM yyyy').format(s.date)}${s.odometer != null ? ' · ${s.odometer!.toStringAsFixed(0)} km' : ''}',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      AppCurrency.format(s.cost),
                      style: GoogleFonts.inter(
                        fontSize: 13,
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
