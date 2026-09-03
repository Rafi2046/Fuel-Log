import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/services/report_generator_service.dart';
import '../../../models/vehicle_report_model.dart';
import '../../../viewmodels/fuel_log_viewmodel.dart';
import '../../../viewmodels/service_log_viewmodel.dart';
import '../../../viewmodels/vehicle_viewmodel.dart';
import '../../widgets/app_app_bar.dart';
import '../../widgets/app_shimmer.dart';
import '../../widgets/clean_glass_panel.dart';
import 'widgets/report_card_tile.dart';
import 'widgets/report_preview_sheet.dart';

/// Vehicle report center — premium glass layout.
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
  static final _shortDate = DateFormat('d MMM');

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
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 1),
      initialDateRange: _selectedDateRange ??
          DateTimeRange(
            start: now.subtract(const Duration(days: 30)),
            end: now,
          ),
      builder: (context, child) => Theme(data: pickerTheme, child: child!),
    );

    if (picked != null) {
      setState(() => _selectedDateRange = picked);
    }
  }

  String get _dateLabel {
    if (_selectedDateRange == null) return 'All dates';
    final start = _shortDate.format(_selectedDateRange!.start);
    final end = _shortDate.format(_selectedDateRange!.end);
    return '$start – $end';
  }

  void _generateAndShowReport(VehicleReportType type) {
    final vehicle = ref.read(activeVehicleProvider).valueOrNull;
    final fuelLogs = ref.read(vehicleLogsProvider).valueOrNull ?? [];
    final serviceLogs = ref.read(serviceLogsProvider).valueOrNull ?? [];

    if (vehicle == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an active vehicle first.')),
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
    final reportTypes = VehicleReportType.values;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppAppBar(
        leading: AppBackButton(),
        title: 'Create Report',
      ),
      body: AppRefreshIndicator(
        onRefresh: () async {
          ref.invalidate(vehicleLogsProvider);
          ref.invalidate(serviceLogsProvider);
          ref.invalidate(vehiclesProvider);
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenPadding,
            AppSpacing.appBarBodyGap,
            AppSpacing.screenPadding,
            32,
          ),
        children: [
          CleanGlassPanel(
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.primary.withValues(alpha: 0.22),
                        AppColors.primary.withValues(alpha: 0.08),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.2),
                    ),
                  ),
                  child: const Icon(
                    LucideIcons.fileText,
                    color: AppColors.primary,
                    size: 19,
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
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Share CSV & text reports',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textTertiary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _DateFilterChip(
                  label: _dateLabel,
                  active: _selectedDateRange != null,
                  onTap: _pickDateRange,
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Padding(
            padding: const EdgeInsets.only(left: 2, bottom: 8),
            child: Text(
              'SELECT REPORT',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textTertiary,
                fontWeight: FontWeight.w600,
                fontSize: 10,
                letterSpacing: 0.8,
              ),
            ),
          ),
          CleanGlassPanel(
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              children: [
                for (var i = 0; i < reportTypes.length; i++)
                  ReportCardTile(
                    type: reportTypes[i],
                    onTap: () => _generateAndShowReport(reportTypes[i]),
                    showDivider: i < reportTypes.length - 1,
                  ),
              ],
            ),
          ),
        ],
      ),
    ),
    );
  }
}

class _DateFilterChip extends StatelessWidget {
  const _DateFilterChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active
          ? AppColors.primary.withValues(alpha: 0.14)
          : Colors.white.withValues(alpha: 0.04),
      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            border: Border.all(
              color: active
                  ? AppColors.primary.withValues(alpha: 0.35)
                  : Colors.white.withValues(alpha: 0.08),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                LucideIcons.calendar,
                size: 13,
                color: active ? AppColors.primary : AppColors.textTertiary,
              ),
              const SizedBox(width: 5),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 96),
                child: Text(
                  label,
                  style: AppTextStyles.caption.copyWith(
                    color: active ? AppColors.primary : AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                    fontSize: 10,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
