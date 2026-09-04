import 'dart:async';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../models/vehicle_report_model.dart';
import 'preview/annual_summary_report_view.dart';
import 'preview/custom_report_view.dart';
import 'preview/fuel_efficiency_report_view.dart';
import 'preview/maintenance_report_view.dart';
import 'preview/ownership_report_view.dart';
import 'preview/seller_report_view.dart';

/// Report preview bottom sheet with distinct specialized views for each report type and instant copy feedback.
class ReportPreviewSheet extends StatefulWidget {
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
      barrierColor: Colors.black.withValues(alpha: 0.58),
      builder: (_) => ReportPreviewSheet(reportData: data),
    );
  }

  @override
  State<ReportPreviewSheet> createState() => _ReportPreviewSheetState();
}

class _ReportPreviewSheetState extends State<ReportPreviewSheet> {
  bool _isCopied = false;
  Timer? _copyTimer;

  @override
  void dispose() {
    _copyTimer?.cancel();
    super.dispose();
  }

  void _copyToClipboard() {
    HapticFeedback.mediumImpact();
    Clipboard.setData(ClipboardData(text: widget.reportData.formattedTextReport));
    setState(() => _isCopied = true);

    _copyTimer?.cancel();
    _copyTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _isCopied = false);
      }
    });
  }

  void _shareTextReport() {
    SharePlus.instance.share(
      ShareParams(
        text: widget.reportData.formattedTextReport,
        subject:
            '${widget.reportData.vehicleName} - ${widget.reportData.type.title}',
      ),
    );
  }

  Future<void> _shareCsvReport() async {
    try {
      final dir = await getTemporaryDirectory();
      final sanitizedName = widget.reportData.vehicleName
          .replaceAll(RegExp(r'[^\w\s-]'), '')
          .trim()
          .replaceAll(RegExp(r'\s+'), '_');
      final fileName =
          '${sanitizedName.isEmpty ? "vehicle" : sanitizedName}_${widget.reportData.type.name}_report.csv';
      final file = File('${dir.path}/$fileName');
      await file.writeAsString(widget.reportData.rawCsvData);
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'text/csv', name: fileName)],
          subject:
              '${widget.reportData.vehicleName} - ${widget.reportData.type.title}',
        ),
      );
    } catch (_) {
      SharePlus.instance.share(
        ShareParams(
          text: widget.reportData.rawCsvData,
          subject: '${widget.reportData.vehicleName}_report.csv',
        ),
      );
    }
  }

  Widget _buildSpecializedReportView(VehicleReportData report) {
    switch (report.type) {
      case VehicleReportType.maintenanceHistory:
        return MaintenanceReportView(report: report);
      case VehicleReportType.fuelEfficiency:
        return FuelEfficiencyReportView(report: report);
      case VehicleReportType.ownershipCost:
        return OwnershipReportView(report: report);
      case VehicleReportType.seller:
        return SellerReportView(report: report);
      case VehicleReportType.annualSummary:
        return AnnualSummaryReportView(report: report);
      case VehicleReportType.custom:
        return CustomReportView(report: report);
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final maxHeight = media.size.height * 0.88;
    final report = widget.reportData;

    return Padding(
      padding: EdgeInsets.only(top: media.padding.top + 12),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          constraints: BoxConstraints(maxHeight: maxHeight),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: AppColors.isDark ? 0.45 : 0.12,
                ),
                blurRadius: AppColors.isDark ? 24 : 16,
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
                  color: AppColors.borderStrong,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header Bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 8, 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            report.type.title,
                            style: GoogleFonts.inter(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 16.5,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${report.vehicleName} (${report.licensePlate})',
                            style: GoogleFonts.inter(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
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
                color: AppColors.border,
              ),

              // Copied toast banner if copied
              if (_isCopied)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.success.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        LucideIcons.checkCheck,
                        size: 14,
                        color: AppColors.success,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'reportCopiedToast'.tr(),
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                ),

              // Scrollable Specialized Report Body
              Flexible(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                  shrinkWrap: true,
                  children: [
                    _buildSpecializedReportView(report),
                  ],
                ),
              ),

              // Bottom Action Buttons (Copy / CSV / Share)
              Container(
                padding: EdgeInsets.fromLTRB(
                  16,
                  12,
                  16,
                  media.padding.bottom + 12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  border: Border(
                    top: BorderSide(color: AppColors.border),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: _copyToClipboard,
                        borderRadius: BorderRadius.circular(10),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          height: 42,
                          alignment: Alignment.center,
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            color: _isCopied
                                ? AppColors.success.withValues(alpha: 0.12)
                                : AppColors.wash,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: _isCopied
                                  ? AppColors.success
                                  : AppColors.border,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _isCopied ? LucideIcons.check : LucideIcons.copy,
                                size: 15,
                                color: _isCopied
                                    ? AppColors.success
                                    : AppColors.textPrimary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _isCopied ? 'reportCopied'.tr() : 'reportCopy'.tr(),
                                style: GoogleFonts.inter(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: _isCopied
                                      ? AppColors.success
                                      : AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: InkWell(
                        onTap: _shareCsvReport,
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          height: 42,
                          alignment: Alignment.center,
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            color: AppColors.wash,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AppColors.border,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                LucideIcons.fileSpreadsheet,
                                size: 15,
                                color: Color(0xFF107C41),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'reportCsv'.tr(),
                                style: GoogleFonts.inter(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 1,
                      child: InkWell(
                        onTap: _shareTextReport,
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          height: 42,
                          alignment: Alignment.center,
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                LucideIcons.share2,
                                size: 15,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'reportShare'.tr(),
                                style: GoogleFonts.inter(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
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
