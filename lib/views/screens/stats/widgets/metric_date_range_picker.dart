import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';

/// Themed date-range picker for the metric explorer period menu.
Future<DateTimeRange?> showMetricDateRangePicker(
  BuildContext context, {
  DateTimeRange? initialRange,
}) async {
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
      tertiary: AppColors.secondary,
      tertiaryContainer: AppColors.primary.withValues(alpha: 0.16),
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      surfaceContainerHighest: AppColors.card,
    ),
    datePickerTheme: DatePickerThemeData(
      backgroundColor: AppColors.background,
      headerBackgroundColor: AppColors.background,
      headerForegroundColor: AppColors.textPrimary,
      rangeSelectionBackgroundColor: rangeFill,
      rangeSelectionOverlayColor: WidgetStateProperty.all(
        AppColors.primary.withValues(alpha: 0.12),
      ),
      dayForegroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return AppColors.textPrimary;
        }
        if (states.contains(WidgetState.disabled)) {
          return AppColors.textTertiary;
        }
        return AppColors.textPrimary;
      }),
      dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return AppColors.primary;
        return null;
      }),
      todayForegroundColor: WidgetStateProperty.all(AppColors.primary),
      todayBorder: BorderSide(color: AppColors.primary.withValues(alpha: 0.7)),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: AppColors.primary),
    ),
  );

  return showDateRangePicker(
    context: context,
    firstDate: DateTime(2020),
    lastDate: now,
    initialDateRange: initialRange ??
        DateTimeRange(
          start: now.subtract(const Duration(days: 30)),
          end: now,
        ),
    builder: (context, child) => Theme(data: pickerTheme, child: child!),
  );
}
