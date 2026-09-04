import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../models/vehicle_report_model.dart';
import 'report_preview_components.dart';

/// Seller's History Report Preview Section
class SellerReportView extends StatelessWidget {
  const SellerReportView({
    super.key,
    required this.report,
  });

  final VehicleReportData report;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.success.withValues(alpha: 0.35),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  LucideIcons.badgeCheck,
                  size: 24,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'reportVerifiedTitle'.tr(),
                      style: GoogleFonts.inter(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.success,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'reportVerifiedSubtitle'.tr(),
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        Row(
          children: [
            Expanded(
              child: ReportMetricCard(
                label: 'reportLabelDistanceLogged'.tr(),
                value: '${report.totalDistanceKm.toStringAsFixed(0)} km',
              ),
            ),
            const SizedBox(width: 8),
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
                label: 'reportLabelServicesDone'.tr(),
                value: 'reportRecordsCount'
                    .tr(namedArgs: {'count': '${report.serviceLogCount}'}),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        ReportSummaryDetailsCard(report: report),
      ],
    );
  }
}
