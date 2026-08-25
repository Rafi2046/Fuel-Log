import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/app_formatters.dart';
import '../../../../models/vehicle_report_model.dart';

/// Luxury bottom sheet displaying generated report summary and export buttons.
class ReportPreviewSheet extends StatelessWidget {
  const ReportPreviewSheet({
    super.key,
    required this.reportData,
  });

  final VehicleReportData reportData;

  static Future<void> show(BuildContext context, VehicleReportData data) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
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
      const SnackBar(
        content: Text('Report copied to clipboard!'),
        backgroundColor: Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final maxHeight = media.size.height * 0.85;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          constraints: BoxConstraints(maxHeight: maxHeight),
          decoration: BoxDecoration(
            color: const Color(0xFF12121A).withValues(alpha: 0.95),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: const Color(0xFF26263A)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle Pill
              const SizedBox(height: 10),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 14),

              // Title Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Icon(reportData.type.icon,
                        color: reportData.type.color, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            reportData.type.title,
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            reportData.vehicleName,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded,
                          color: AppColors.textSecondary),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),

              const Divider(color: Color(0xFF222232)),

              // Scrollable Content
              Flexible(
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  shrinkWrap: true,
                  children: [
                    // Summary Metric Badges Grid
                    Row(
                      children: [
                        Expanded(
                          child: _SummaryMetricBox(
                            label: 'Total Spend',
                            value: AppCurrency.format(reportData.grandTotalSpend),
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _SummaryMetricBox(
                            label: 'Fuel Spend',
                            value: AppCurrency.format(reportData.totalFuelSpend),
                            color: const Color(0xFF38BDF8),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _SummaryMetricBox(
                            label: 'Service Spend',
                            value: AppCurrency.format(reportData.totalServiceSpend),
                            color: const Color(0xFFEC4899),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: _SummaryMetricBox(
                            label: 'Total Distance',
                            value: '${reportData.totalDistanceKm.toStringAsFixed(0)} km',
                            color: const Color(0xFFA855F7),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _SummaryMetricBox(
                            label: 'Avg Mileage',
                            value: '${reportData.avgEfficiency.toStringAsFixed(1)} km/L',
                            color: const Color(0xFF10B981),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _SummaryMetricBox(
                            label: 'Cost / km',
                            value: '৳${reportData.avgCostPerKm.toStringAsFixed(2)}/km',
                            color: const Color(0xFFF59E0B),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    // Preview Document Box
                    const Text(
                      'Report Document Preview',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0B0B12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF222232)),
                      ),
                      child: SelectableText(
                        reportData.formattedTextReport,
                        style: GoogleFonts.firaCode(
                          fontSize: 12,
                          color: const Color(0xFFE2E8F0),
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Action Buttons Bottom Bar
              Container(
                padding: EdgeInsets.fromLTRB(
                  20,
                  12,
                  20,
                  media.padding.bottom + 12,
                ),
                decoration: const BoxDecoration(
                  color: Color(0xFF161622),
                  border: Border(top: BorderSide(color: Color(0xFF26263A))),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _copyToClipboard(context),
                        icon: const Icon(Icons.copy_rounded, size: 15),
                        label: const Text('Copy'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textPrimary,
                          side: const BorderSide(color: Color(0xFF33334A)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _shareCsvReport(context),
                        icon: const Icon(Icons.table_chart_rounded, size: 15),
                        label: const Text('Share CSV'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF10B981),
                          side: const BorderSide(color: Color(0xFF10B981)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _shareTextReport(context),
                        icon: const Icon(Icons.share_rounded, size: 15),
                        label: const Text('Share'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
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

class _SummaryMetricBox extends StatelessWidget {
  const _SummaryMetricBox({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF181826),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF28283E)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textTertiary,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
