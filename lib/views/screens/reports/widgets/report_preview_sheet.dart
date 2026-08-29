import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/app_formatters.dart';
import '../../../../models/vehicle_report_model.dart';
import '../../../widgets/clean_glass_panel.dart';

/// Report preview bottom sheet — premium layout, structured summary.
class ReportPreviewSheet extends StatelessWidget {
  const ReportPreviewSheet({
    super.key,
    required this.reportData,
  });

  final VehicleReportData reportData;

  static final _dateFormat = DateFormat('d MMM yyyy');

  static Future<void> show(BuildContext context, VehicleReportData data) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.58),
      builder: (_) => ReportPreviewSheet(reportData: data),
    );
  }

  void _shareTextReport(BuildContext context) {
    // ignore: deprecated_member_use
    Share.share(
      reportData.formattedTextReport,
      subject: '${reportData.vehicleName} - ${reportData.type.title}',
    );
  }

  void _shareCsvReport(BuildContext context) {
    // ignore: deprecated_member_use
    Share.share(
      reportData.rawCsvData,
      subject: '${reportData.vehicleName}_report.csv',
    );
  }

  void _copyToClipboard(BuildContext context) {
    Clipboard.setData(ClipboardData(text: reportData.formattedTextReport));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Report copied to clipboard',
          style: AppTextStyles.caption.copyWith(color: AppColors.textPrimary),
        ),
        backgroundColor: AppColors.cardElevated,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final maxHeight = media.size.height * 0.88;

    return Padding(
      padding: EdgeInsets.only(top: media.padding.top + 12),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          constraints: BoxConstraints(maxHeight: maxHeight),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 24,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 8, 10),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.22),
                        ),
                      ),
                      child: Icon(
                        reportData.type.icon,
                        color: AppColors.primary,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            reportData.type.title,
                            style: AppTextStyles.label.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            reportData.vehicleName,
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textTertiary,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.close_rounded,
                        color: AppColors.textTertiary,
                        size: 22,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              Container(
                height: 1,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                color: Colors.white.withValues(alpha: 0.06),
              ),
              Flexible(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                  shrinkWrap: true,
                  children: [
                    _MetricsGrid(reportData: reportData),
                    const SizedBox(height: 14),
                    Text(
                      'SUMMARY',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textTertiary,
                        fontWeight: FontWeight.w600,
                        fontSize: 10,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _ReportSummaryCard(reportData: reportData),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.fromLTRB(
                  16,
                  12,
                  16,
                  media.padding.bottom + 14,
                ),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  border: Border(
                    top: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _ActionButton(
                        icon: LucideIcons.copy,
                        label: 'Copy',
                        onTap: () => _copyToClipboard(context),
                        style: _ActionStyle.outlined,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _ActionButton(
                        icon: LucideIcons.sheet,
                        label: 'CSV',
                        onTap: () => _shareCsvReport(context),
                        style: _ActionStyle.muted,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: _ActionButton(
                        icon: LucideIcons.share2,
                        label: 'Share',
                        onTap: () => _shareTextReport(context),
                        style: _ActionStyle.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricsGrid extends StatelessWidget {
  const _MetricsGrid({required this.reportData});

  final VehicleReportData reportData;

  @override
  Widget build(BuildContext context) {
    final cells = [
      _MetricCell(
        label: 'Total spend',
        value: AppCurrency.format(reportData.grandTotalSpend),
        highlight: true,
      ),
      _MetricCell(
        label: 'Fuel',
        value: AppCurrency.format(reportData.totalFuelSpend),
      ),
      _MetricCell(
        label: 'Service',
        value: AppCurrency.format(reportData.totalServiceSpend),
      ),
      _MetricCell(
        label: 'Distance',
        value: '${reportData.totalDistanceKm.toStringAsFixed(0)} km',
      ),
      _MetricCell(
        label: 'Mileage',
        value: '${reportData.avgEfficiency.toStringAsFixed(1)} km/L',
      ),
      _MetricCell(
        label: 'Cost / km',
        value: '${AppCurrency.format(reportData.avgCostPerKm)}/km',
      ),
    ];

    return CleanGlassPanel(
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
      child: Column(
        children: [
          for (var row = 0; row < 2; row++) ...[
            if (row > 0) const SizedBox(height: 8),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var col = 0; col < 3; col++) ...[
                    if (col > 0)
                      VerticalDivider(
                        width: 1,
                        thickness: 1,
                        color: Colors.white.withValues(alpha: 0.06),
                      ),
                    Expanded(child: cells[row * 3 + col]),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MetricCell extends StatelessWidget {
  const _MetricCell({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textTertiary,
              fontSize: 9,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: AppTextStyles.label.copyWith(
              color: highlight ? AppColors.primary : AppColors.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: highlight ? 13 : 12,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _ReportSummaryCard extends StatelessWidget {
  const _ReportSummaryCard({required this.reportData});

  final VehicleReportData reportData;

  @override
  Widget build(BuildContext context) {
    final period =
        '${ReportPreviewSheet._dateFormat.format(reportData.startDate)} – '
        '${ReportPreviewSheet._dateFormat.format(reportData.endDate)}';

    final rows = [
      _SummaryRow(
        icon: LucideIcons.car,
        label: 'Vehicle',
        value: '${reportData.vehicleName} (${reportData.licensePlate})',
      ),
      _SummaryRow(
        icon: LucideIcons.calendar,
        label: 'Period',
        value: period,
      ),
      _SummaryRow(
        icon: LucideIcons.wallet,
        label: 'Total spend',
        value: AppCurrency.format(reportData.grandTotalSpend),
        valueColor: AppColors.primary,
      ),
      _SummaryRow(
        icon: LucideIcons.fuel,
        label: 'Fuel cost',
        value:
            '${AppCurrency.format(reportData.totalFuelSpend)} · ${reportData.fuelLogCount} fill-ups',
      ),
      _SummaryRow(
        icon: LucideIcons.wrench,
        label: 'Service cost',
        value:
            '${AppCurrency.format(reportData.totalServiceSpend)} · ${reportData.serviceLogCount} services',
      ),
      _SummaryRow(
        icon: LucideIcons.route,
        label: 'Distance',
        value: '${reportData.totalDistanceKm.toStringAsFixed(0)} km',
      ),
      _SummaryRow(
        icon: LucideIcons.gauge,
        label: 'Avg mileage',
        value: '${reportData.avgEfficiency.toStringAsFixed(1)} km/L',
      ),
      _SummaryRow(
        icon: LucideIcons.circleDollarSign,
        label: 'Cost per km',
        value: '${AppCurrency.format(reportData.avgCostPerKm)} / km',
      ),
    ];

    return CleanGlassPanel(
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            rows[i],
            if (i < rows.length - 1)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Divider(
                  height: 1,
                  color: Colors.white.withValues(alpha: 0.05),
                ),
              ),
          ],
          const SizedBox(height: 10),
          Text(
            'Generated ${ReportPreviewSheet._dateFormat.format(reportData.dateGenerated)}',
            textAlign: TextAlign.center,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textTertiary,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(7),
          ),
          child: Icon(icon, size: 13, color: AppColors.textTertiary),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textTertiary,
                  fontSize: 10,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: AppTextStyles.label.copyWith(
                  color: valueColor ?? AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

enum _ActionStyle { outlined, muted, primary }

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.style,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final _ActionStyle style;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(10);

    Color bg;
    Color fg;
    BorderSide border;

    switch (style) {
      case _ActionStyle.outlined:
        bg = Colors.transparent;
        fg = AppColors.textPrimary;
        border = BorderSide(color: Colors.white.withValues(alpha: 0.12));
      case _ActionStyle.muted:
        bg = Colors.white.withValues(alpha: 0.04);
        fg = AppColors.textSecondary;
        border = BorderSide(color: Colors.white.withValues(alpha: 0.08));
      case _ActionStyle.primary:
        bg = AppColors.primary;
        fg = AppColors.textPrimary;
        border = BorderSide(color: AppColors.primary.withValues(alpha: 0.5));
    }

    return Material(
      color: bg,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.fromBorderSide(border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: fg),
              const SizedBox(width: 5),
              Text(
                label,
                style: AppTextStyles.caption.copyWith(
                  color: fg,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
