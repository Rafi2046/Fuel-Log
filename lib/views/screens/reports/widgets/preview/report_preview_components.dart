import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/utils/app_formatters.dart';
import '../../../../../models/vehicle_report_model.dart';

/// Reusable Metric Card for Report Previews.
class ReportMetricCard extends StatelessWidget {
  const ReportMetricCard({
    super.key,
    required this.label,
    required this.value,
    this.isHighlighted = false,
  });

  final String label;
  final String value;
  final bool isHighlighted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: isHighlighted
            ? AppColors.primary.withValues(alpha: 0.1)
            : AppColors.wash,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isHighlighted
              ? AppColors.primary.withValues(alpha: 0.35)
              : AppColors.hairline,
        ),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: isHighlighted ? AppColors.primary : AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 5),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: isHighlighted ? AppColors.primary : AppColors.textPrimary,
              ),
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
}

/// Reusable Breakdown Container Card for Report Previews.
class ReportBreakdownCard extends StatelessWidget {
  const ReportBreakdownCard({
    super.key,
    required this.children,
  });

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.wash,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.hairline),
      ),
      child: Column(
        children: children,
      ),
    );
  }
}

/// Reusable Log Item Tile for Report Previews.
class ReportLogItemTile extends StatelessWidget {
  const ReportLogItemTile({
    super.key,
    required this.title,
    required this.date,
    required this.cost,
    this.subtitle,
  });

  final String title;
  final String date;
  final String cost;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  subtitle != null ? '$date • $subtitle' : date,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            cost,
            style: GoogleFonts.inter(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Key-value detail row for Report Previews.
class ReportDetailItemRow extends StatelessWidget {
  const ReportDetailItemRow({
    super.key,
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12.5,
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: highlight ? FontWeight.w700 : FontWeight.w600,
            color: highlight ? AppColors.primary : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

/// Legend indicator dot and label with auto-fit.
class ReportProportionLegend extends StatelessWidget {
  const ReportProportionLegend({
    super.key,
    required this.color,
    required this.text,
  });

  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.sizeOf(context).width - 72,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                text,
                maxLines: 1,
                style: GoogleFonts.inter(
                  fontSize: 11.5,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Reusable full summary details card used across multiple reports.
class ReportSummaryDetailsCard extends StatelessWidget {
  const ReportSummaryDetailsCard({
    super.key,
    required this.report,
  });

  final VehicleReportData report;

  static final DateFormat _dateFormat = DateFormat('d MMM yyyy');

  @override
  Widget build(BuildContext context) {
    final period =
        '${_dateFormat.format(report.startDate)} – ${_dateFormat.format(report.endDate)}';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.wash,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.hairline),
      ),
      child: Column(
        children: [
          ReportDetailItemRow(
            label: 'reportLabelVehicle'.tr(),
            value: '${report.vehicleName} (${report.licensePlate})',
          ),
          Divider(color: AppColors.hairline, height: 16),
          ReportDetailItemRow(label: 'reportLabelPeriod'.tr(), value: period),
          Divider(color: AppColors.hairline, height: 16),
          ReportDetailItemRow(
            label: 'reportLabelTotalSpend'.tr(),
            value: AppCurrency.format(report.grandTotalSpend),
            highlight: true,
          ),
          Divider(color: AppColors.hairline, height: 16),
          ReportDetailItemRow(
            label: 'reportLabelFuelExpenses'.tr(),
            value:
                '${AppCurrency.format(report.totalFuelSpend)} (${'reportFillUpsCount'.tr(namedArgs: {'count': '${report.fuelLogCount}'})})',
          ),
          Divider(color: AppColors.hairline, height: 16),
          ReportDetailItemRow(
            label: 'reportLabelServiceExpenses'.tr(),
            value:
                '${AppCurrency.format(report.totalServiceSpend)} (${'reportServicesCount'.tr(namedArgs: {'count': '${report.serviceLogCount}'})})',
          ),
          Divider(color: AppColors.hairline, height: 16),
          ReportDetailItemRow(
            label: 'reportLabelTotalDistance'.tr(),
            value: '${report.totalDistanceKm.toStringAsFixed(0)} km',
          ),
          Divider(color: AppColors.hairline, height: 16),
          ReportDetailItemRow(
            label: 'reportLabelAvgEfficiency'.tr(),
            value:
                '${report.avgEfficiency.toStringAsFixed(1)} ${report.efficiencyUnit}',
          ),
        ],
      ),
    );
  }
}
