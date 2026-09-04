import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../core/utils/app_formatters.dart';
import '../../../../../models/vehicle_report_model.dart';
import 'report_preview_components.dart';

/// Custom Date-Range Report Preview Section
class CustomReportView extends StatelessWidget {
  const CustomReportView({
    super.key,
    required this.report,
  });

  final VehicleReportData report;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: ReportMetricCard(
                label: 'reportLabelTotalSpend'.tr(),
                value: AppCurrency.format(report.grandTotalSpend),
                isHighlighted: true,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ReportMetricCard(
                label: 'reportLabelFuelCost'.tr(),
                value: AppCurrency.format(report.totalFuelSpend),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ReportMetricCard(
                label: 'reportLabelServiceCost'.tr(),
                value: AppCurrency.format(report.totalServiceSpend),
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
