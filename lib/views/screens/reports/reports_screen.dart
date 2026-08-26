import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/services/report_generator_service.dart';
import '../../../models/vehicle_report_model.dart';
import '../../../viewmodels/fuel_log_viewmodel.dart';
import '../../../viewmodels/service_log_viewmodel.dart';
import '../../../viewmodels/vehicle_viewmodel.dart';
import 'widgets/report_card_tile.dart';
import 'widgets/report_preview_sheet.dart';

/// Full Vehicle Report Center Screen
class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  static Future<void> open(BuildContext context) {
    return Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ReportsScreen()),
    );
  }

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  DateTimeRange? _selectedDateRange;

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final rangeFill = AppColors.primary.withValues(alpha: 0.22);
    final pickerTheme = Theme.of(context).copyWith(
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: ColorScheme.dark(
        primary: AppColors.primary,
        onPrimary: AppColors.textPrimary,
        primaryContainer: rangeFill,
        onPrimaryContainer: AppColors.textPrimary,
        secondary: AppColors.primary,
        onSecondary: AppColors.textPrimary,
        secondaryContainer: rangeFill,
        onSecondaryContainer: AppColors.textPrimary,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: AppColors.background,
        rangeSelectionBackgroundColor: rangeFill,
        dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary;
          }
          return null;
        }),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppColors.primary),
      ),
    );

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: now,
      initialDateRange: _selectedDateRange ??
          DateTimeRange(
            start: now.subtract(const Duration(days: 365)),
            end: now,
          ),
      builder: (context, child) => Theme(data: pickerTheme, child: child!),
    );

    if (picked != null) {
      setState(() => _selectedDateRange = picked);
    }
  }

  void _generateAndShowReport(VehicleReportType type) {
    final vehicle = ref.read(activeVehicleProvider).valueOrNull;
    final fuelLogs = ref.read(vehicleLogsProvider).valueOrNull ?? [];
    final serviceLogs = ref.read(serviceLogsProvider).valueOrNull ?? [];

    if (vehicle == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No active vehicle found')),
      );
      return;
    }

    final reportData = ReportGeneratorService.generateReport(
      type: type,
      activeVehicle: vehicle,
      fuelLogs: fuelLogs,
      serviceLogs: serviceLogs,
      dateRange: _selectedDateRange,
    );

    ReportPreviewSheet.show(context, reportData);
  }

  @override
  Widget build(BuildContext context) {
    final activeVehicle = ref.watch(activeVehicleProvider).valueOrNull;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          'Create Report',
          style: AppTextStyles.title.copyWith(fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenPadding,
          8,
          AppSpacing.screenPadding,
          32,
        ),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: const Icon(
                    LucideIcons.fileText,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        activeVehicle?.name ?? 'Vehicle Report',
                        style: AppTextStyles.label.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'PDF & CSV export',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textTertiary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Material(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  child: InkWell(
                    onTap: _pickDateRange,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            LucideIcons.calendar,
                            size: 14,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _selectedDateRange != null ? 'Filtered' : 'All Dates',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
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

          const SizedBox(height: 20),

          Text(
            'Select Report',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textTertiary,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),

          const SizedBox(height: 10),

          ...VehicleReportType.values.map(
            (type) => ReportCardTile(
              type: type,
              onTap: () => _generateAndShowReport(type),
            ),
          ),
        ],
      ),
    );
  }
}
