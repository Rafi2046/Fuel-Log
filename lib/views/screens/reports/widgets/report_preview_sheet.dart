import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/constants/app_colors.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/utils/app_formatters.dart';
import '../../../../models/vehicle_report_model.dart';

/// Report preview bottom sheet with distinct specialized views for each report type and instant copy feedback.
class ReportPreviewSheet extends StatefulWidget {
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
    // ignore: deprecated_member_use
    Share.share(
      widget.reportData.formattedTextReport,
      subject: '${widget.reportData.vehicleName} - ${widget.reportData.type.title}',
    );
  }

  void _shareCsvReport() {
    // ignore: deprecated_member_use
    Share.share(
      widget.reportData.rawCsvData,
      subject: '${widget.reportData.vehicleName}_report.csv',
    );
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
                color: Colors.black.withValues(alpha: 0.45),
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
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 16.5,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${report.vehicleName} (${report.licensePlate})',
                            style: GoogleFonts.inter(
                              color: const Color(0xFF94A3B8),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Color(0xFF94A3B8),
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
                    color: const Color(0xFF10B981).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFF10B981).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        LucideIcons.checkCheck,
                        size: 14,
                        color: Color(0xFF34D399),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Report text copied to clipboard!',
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF34D399),
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
                  color: AppColors.inputFill,
                  border: Border(
                    top: BorderSide(color: AppColors.border),
                  ),
                ),
                child: Row(
                  children: [
                    // Copy Button with real-time feedback
                    Expanded(
                      child: InkWell(
                        onTap: _copyToClipboard,
                        borderRadius: BorderRadius.circular(10),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          decoration: BoxDecoration(
                            color: _isCopied
                                ? const Color(0xFF10B981).withValues(alpha: 0.18)
                                : AppColors.inputFill,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: _isCopied
                                  ? const Color(0xFF10B981)
                                  : AppColors.border,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _isCopied ? LucideIcons.check : LucideIcons.copy,
                                size: 15,
                                color: _isCopied
                                    ? const Color(0xFF34D399)
                                    : Colors.white,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _isCopied ? 'Copied!' : 'Copy',
                                style: GoogleFonts.inter(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: _isCopied
                                      ? const Color(0xFF34D399)
                                      : Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // CSV Export Button
                    Expanded(
                      child: InkWell(
                        onTap: _shareCsvReport,
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          decoration: BoxDecoration(
                            color: AppColors.inputFill,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AppColors.border,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                LucideIcons.fileSpreadsheet,
                                size: 15,
                                color: Color(0xFF38BDF8),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'CSV',
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
                    const SizedBox(width: 8),
                    // Primary Share Button
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: _shareTextReport,
                        icon: const Icon(LucideIcons.share2, size: 16),
                        label: const Text('Share Report'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF7A50),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          textStyle: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
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

  /// Builds a customized layout tailored to the specific report type.
  Widget _buildSpecializedReportView(VehicleReportData report) {
    switch (report.type) {
      case VehicleReportType.maintenanceHistory:
        return _buildMaintenanceReport(report);
      case VehicleReportType.fuelEfficiency:
        return _buildFuelEfficiencyReport(report);
      case VehicleReportType.ownershipCost:
        return _buildCostOfOwnershipReport(report);
      case VehicleReportType.seller:
        return _buildSellerHistoryReport(report);
      case VehicleReportType.annualSummary:
        return _buildAnnualSummaryReport(report);
      case VehicleReportType.custom:
        return _buildCustomDateReport(report);
    }
  }

  // ─────────────────────────────────────────────────────────────
  // 1. 🛠️ MAINTENANCE & WORKSHOP REPORT
  // ─────────────────────────────────────────────────────────────
  Widget _buildMaintenanceReport(VehicleReportData report) {
    final services = report.serviceLogs.cast<ServiceLog>();
    final avgCost = report.serviceLogCount > 0
        ? (report.totalServiceSpend / report.serviceLogCount)
        : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // KPI Grid
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                label: 'Service Spend',
                value: AppCurrency.format(report.totalServiceSpend),
                isHighlighted: true,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildMetricCard(
                label: 'Total Visits',
                value: '${report.serviceLogCount} services',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildMetricCard(
                label: 'Avg / Service',
                value: AppCurrency.format(avgCost),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Service Category Distribution
        if (report.serviceCategoryCosts.isNotEmpty) ...[
          Text(
            'EXPENSE BREAKDOWN BY CATEGORY',
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: Color(0xFF94A3B8),
            ),
          ),
          SizedBox(height: 8),
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.inputFill,
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
                          color: Color(0xFFFF7A50),
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
                            color: Colors.white,
                          ),
                        ),
                      ),
                      Text(
                        '${AppCurrency.format(e.value)} (${pct.toStringAsFixed(0)}%)',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF94A3B8),
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

        // Chronological Service Logs List
        Text(
          'SERVICE & WORKSHOP LOGS',
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: Color(0xFF94A3B8),
          ),
        ),
        SizedBox(height: 8),
        if (services.isEmpty)
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.inputFill,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.hairline),
            ),
            child: Column(
              children: [
                const Icon(
                  LucideIcons.wrench,
                  size: 28,
                  color: Color(0xFF71717A),
                ),
                const SizedBox(height: 8),
                Text(
                  'No workshop service records logged yet.',
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          )
        else
          ...services.map((s) => Container(
                margin: EdgeInsets.only(bottom: 8),
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.inputFill,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.hairline),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF7A50).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        LucideIcons.wrench,
                        size: 16,
                        color: Color(0xFFFF7A50),
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
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${s.category} · ${DateFormat('d MMM yyyy').format(s.date)}${s.odometer != null ? ' · ${s.odometer!.toStringAsFixed(0)} km' : ''}',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: const Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      AppCurrency.format(s.cost),
                      style: GoogleFonts.inter(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFFF7A50),
                      ),
                    ),
                  ],
                ),
              )),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────
  // 2. ⛽ FUEL EFFICIENCY REPORT
  // ─────────────────────────────────────────────────────────────
  Widget _buildFuelEfficiencyReport(VehicleReportData report) {
    final fuels = report.fuelLogs.cast<FuelLog>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // KPI Grid
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                label: 'Avg Mileage',
                value: '${report.avgEfficiency.toStringAsFixed(1)} km/L',
                isHighlighted: true,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildMetricCard(
                label: 'Best Mileage',
                value: report.bestEfficiency > 0
                    ? '${report.bestEfficiency.toStringAsFixed(1)} km/L'
                    : '--',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildMetricCard(
                label: 'Cost / km',
                value: '${AppCurrency.format(report.avgCostPerKm)}/km',
              ),
            ),
          ],
        ),
        SizedBox(height: 12),

        // Fuel Spend & Liters Summary Card
        Container(
          padding: EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.inputFill,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.hairline),
          ),
          child: Column(
            children: [
              _buildDetailItem(
                'Total Fuel Spend',
                AppCurrency.format(report.totalFuelSpend),
                highlight: true,
              ),
              Divider(color: AppColors.hairline, height: 16),
              _buildDetailItem(
                'Total Volume Consumed',
                '${report.totalLitres.toStringAsFixed(1)} Liters',
              ),
              Divider(color: AppColors.hairline, height: 16),
              _buildDetailItem(
                'Total Fill-up Logs',
                '${report.fuelLogCount} fill-ups',
              ),
              Divider(color: AppColors.hairline, height: 16),
              _buildDetailItem(
                'Average Fuel Price',
                '${AppCurrency.format(report.avgFuelPrice)} / L',
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Chronological Fill-up Records
        Text(
          'REFUELING HISTORY',
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: Color(0xFF94A3B8),
          ),
        ),
        SizedBox(height: 8),
        if (fuels.isEmpty)
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.inputFill,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.hairline),
            ),
            child: Center(
              child: Text(
                'No refueling records found in this range.',
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  color: Color(0xFF94A3B8),
                ),
              ),
            ),
          )
        else
          ...fuels.map((f) => Container(
                margin: EdgeInsets.only(bottom: 8),
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.inputFill,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.hairline),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF38BDF8).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        LucideIcons.fuel,
                        size: 16,
                        color: Color(0xFF38BDF8),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${f.amount.toStringAsFixed(1)} L · ${f.isFullTank ? 'Full Tank' : 'Partial'}',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${DateFormat('d MMM yyyy').format(f.date)} · Odo: ${f.odometer.toStringAsFixed(0)} km',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: const Color(0xFF94A3B8),
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
                        color: const Color(0xFFFF7A50),
                      ),
                    ),
                  ],
                ),
              )),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────
  // 3. 💰 COST OF OWNERSHIP REPORT
  // ─────────────────────────────────────────────────────────────
  Widget _buildCostOfOwnershipReport(VehicleReportData report) {
    final fuelPct = report.grandTotalSpend > 0
        ? (report.totalFuelSpend / report.grandTotalSpend)
        : 0.0;
    final servicePct = report.grandTotalSpend > 0
        ? (report.totalServiceSpend / report.grandTotalSpend)
        : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Main Total Spend Callout
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary.withValues(alpha: 0.12),
                AppColors.inputFill,
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFFF7A50).withValues(alpha: 0.3),
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
                  color: const Color(0xFFFF7A50),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                AppCurrency.format(report.grandTotalSpend),
                style: GoogleFonts.inter(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Running cost: ${AppCurrency.format(report.avgCostPerKm)} for every kilometer driven.',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: const Color(0xFFCBD5E1),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Expense Proportion Progress Bar
        Text(
          'EXPENSE PROPORTION',
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: Color(0xFF94A3B8),
          ),
        ),
        SizedBox(height: 8),
        Container(
          padding: EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.inputFill,
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
                      Expanded(
                        flex: (fuelPct * 100).toInt(),
                        child: Container(color: const Color(0xFFFF7A50)),
                      ),
                      Expanded(
                        flex: (servicePct * 100).toInt(),
                        child: Container(color: const Color(0xFF38BDF8)),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF7A50),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Fuel: ${AppCurrency.format(report.totalFuelSpend)} (${(fuelPct * 100).toStringAsFixed(0)}%)',
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: const Color(0xFF38BDF8),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Service: ${AppCurrency.format(report.totalServiceSpend)} (${(servicePct * 100).toStringAsFixed(0)}%)',
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Breakdown items
        _buildSummaryDetailsCard(report),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────
  // 4. 🚗 SELLER'S HISTORY REPORT
  // ─────────────────────────────────────────────────────────────
  Widget _buildSellerHistoryReport(VehicleReportData report) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Verified Certificate Badge Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFF10B981).withValues(alpha: 0.35),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  LucideIcons.badgeCheck,
                  size: 24,
                  color: Color(0xFF34D399),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Verified Vehicle History',
                      style: GoogleFonts.inter(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF34D399),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Complete digital logbook ready for buyers.',
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Quick Stats Row
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                label: 'Distance Logged',
                value: '${report.totalDistanceKm.toStringAsFixed(0)} km',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildMetricCard(
                label: 'Avg Mileage',
                value: '${report.avgEfficiency.toStringAsFixed(1)} km/L',
                isHighlighted: true,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildMetricCard(
                label: 'Services Done',
                value: '${report.serviceLogCount} records',
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        _buildSummaryDetailsCard(report),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────
  // 5. 📅 ANNUAL VEHICLE SUMMARY
  // ─────────────────────────────────────────────────────────────
  Widget _buildAnnualSummaryReport(VehicleReportData report) {
    final monthlySpend = report.grandTotalSpend / 12;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                label: 'Annual Spend',
                value: AppCurrency.format(report.grandTotalSpend),
                isHighlighted: true,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildMetricCard(
                label: 'Monthly Avg',
                value: AppCurrency.format(monthlySpend),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildMetricCard(
                label: 'Annual KM',
                value: '${report.totalDistanceKm.toStringAsFixed(0)} km',
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _buildSummaryDetailsCard(report),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────
  // 6. 🎛️ CUSTOM DATE-RANGE REPORT
  // ─────────────────────────────────────────────────────────────
  Widget _buildCustomDateReport(VehicleReportData report) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                label: 'Total Spend',
                value: AppCurrency.format(report.grandTotalSpend),
                isHighlighted: true,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildMetricCard(
                label: 'Fuel Cost',
                value: AppCurrency.format(report.totalFuelSpend),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildMetricCard(
                label: 'Service Cost',
                value: AppCurrency.format(report.totalServiceSpend),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _buildSummaryDetailsCard(report),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────
  // REUSABLE COMPONENTS
  // ─────────────────────────────────────────────────────────────
  Widget _buildMetricCard({
    required String label,
    required String value,
    bool isHighlighted = false,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isHighlighted
              ? Color(0xFFFF7A50).withValues(alpha: 0.35)
              : AppColors.hairline,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF94A3B8),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: isHighlighted ? const Color(0xFFFF7A50) : Colors.white,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryDetailsCard(VehicleReportData report) {
    final period =
        '${ReportPreviewSheet._dateFormat.format(report.startDate)} – '
        '${ReportPreviewSheet._dateFormat.format(report.endDate)}';

    return Container(
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.hairline),
      ),
      child: Column(
        children: [
          _buildDetailItem('Vehicle', '${report.vehicleName} (${report.licensePlate})'),
          Divider(color: AppColors.hairline, height: 16),
          _buildDetailItem('Period', period),
          Divider(color: AppColors.hairline, height: 16),
          _buildDetailItem(
            'Total Spend',
            AppCurrency.format(report.grandTotalSpend),
            highlight: true,
          ),
          Divider(color: AppColors.hairline, height: 16),
          _buildDetailItem(
            'Fuel Expenses',
            '${AppCurrency.format(report.totalFuelSpend)} (${report.fuelLogCount} fill-ups)',
          ),
          Divider(color: AppColors.hairline, height: 16),
          _buildDetailItem(
            'Service Expenses',
            '${AppCurrency.format(report.totalServiceSpend)} (${report.serviceLogCount} services)',
          ),
          Divider(color: AppColors.hairline, height: 16),
          _buildDetailItem(
            'Total Distance',
            '${report.totalDistanceKm.toStringAsFixed(0)} km',
          ),
          Divider(color: AppColors.hairline, height: 16),
          _buildDetailItem(
            'Average Efficiency',
            '${report.avgEfficiency.toStringAsFixed(1)} km/L',
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, {bool highlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12.5,
            color: const Color(0xFF94A3B8),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: highlight ? FontWeight.w700 : FontWeight.w600,
            color: highlight ? const Color(0xFFFF7A50) : Colors.white,
          ),
        ),
      ],
    );
  }
}
