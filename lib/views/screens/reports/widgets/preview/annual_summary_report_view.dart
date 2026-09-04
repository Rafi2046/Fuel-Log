import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../core/utils/app_formatters.dart';
import '../../../../../models/vehicle_report_model.dart';
import 'report_preview_components.dart';

/// Annual Vehicle Summary Report Preview Section
class AnnualSummaryReportView extends StatelessWidget {
  const AnnualSummaryReportView({
    super.key,
    required this.report,
  });

  final VehicleReportData report;

  @override
  Widget build(BuildContext context) {
    final monthlySpend = report.grandTotalSpend / 12;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: ReportMetricCard(
                label: 'reportLabelAnnualSpend'.tr(),
                value: AppCurrency.format(report.grandTotalSpend),
                isHighlighted: true,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ReportMetricCard(
                label: 'reportLabelMonthlyAvg'.tr(),
                value: AppCurrency.format(monthlySpend),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ReportMetricCard(
                label: 'reportLabelAnnualKm'.tr(),
                value: '${report.totalDistanceKm.toStringAsFixed(0)} km',
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
