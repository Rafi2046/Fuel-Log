import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_locales.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/services/backup_restore_service.dart';
import '../../../viewmodels/fuel_log_viewmodel.dart';
import '../../../viewmodels/reminder_viewmodel.dart';
import '../../../viewmodels/service_log_viewmodel.dart';
import '../../../viewmodels/trip_log_viewmodel.dart';
import '../../../viewmodels/vehicle_viewmodel.dart';
import '../../../viewmodels/weather_viewmodel.dart';
import '../../widgets/clean_glass_panel.dart';
import '../reports/reports_screen.dart';
import 'dashboard_bottom_bar.dart';

/// Settings tab — clean, minimal dark layout.
class SettingsTab extends ConsumerStatefulWidget {
  const SettingsTab({super.key});

  @override
  ConsumerState<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends ConsumerState<SettingsTab> {
  bool _isExporting = false;
  bool _isRestoring = false;
  final _backupService = const BackupRestoreService();

  String _languageLabel(Locale locale) {
    switch (locale.languageCode) {
      case 'bn':
        return 'languageBangla'.tr();
      case 'hi':
        return 'languageHindi'.tr();
      default:
        return 'languageEnglish'.tr();
    }
  }

  Future<void> _pickLanguage() async {
    final current = context.locale;
    final selected = await showModalBottomSheet<Locale>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppSpacing.radiusXl),
          ),
          child: CleanGlassPanel(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppSpacing.radiusXl),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenPadding,
                  AppSpacing.sm,
                  AppSpacing.screenPadding,
                  AppSpacing.md,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.border,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'language'.tr(),
                      style: AppTextStyles.title.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    for (final locale in supportedAppLocales) ...[
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusMd),
                        ),
                        leading: Icon(
                          LucideIcons.globe,
                          size: 20,
                          color: locale.languageCode == current.languageCode
                              ? AppColors.primary
                              : AppColors.textSecondary,
                        ),
                        title: Text(
                          _languageLabel(locale),
                          style: AppTextStyles.body.copyWith(
                            fontWeight: locale.languageCode == current.languageCode
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: locale.languageCode == current.languageCode
                                ? AppColors.primary
                                : AppColors.textPrimary,
                          ),
                        ),
                        trailing: locale.languageCode == current.languageCode
                            ? const Icon(
                                LucideIcons.check,
                                size: 18,
                                color: AppColors.primary,
                              )
                            : null,
                        onTap: () => Navigator.pop(sheetContext, locale),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );

    if (selected != null && mounted) {
      await context.setLocale(selected);
    }
  }

  Future<void> _handleExport() async {
    if (_isExporting) return;
    setState(() => _isExporting = true);
    try {
      final db = ref.read(databaseProvider);
      await _backupService.shareBackup(db: db);
      if (!mounted) return;
      _toast('Backup exported successfully');
    } catch (e) {
      if (!mounted) return;
      _toast('Could not export backup: $e');
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _handleImport() async {
    if (_isRestoring) return;
    try {
      final file = await _backupService.pickBackupFile();
      if (file == null || !mounted) return;

      final summary = await _backupService.inspectBackupFile(file);

      final shouldRestore = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.cardElevated,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
            side: const BorderSide(color: AppColors.border),
          ),
          title: Row(
            children: [
              const Icon(
                LucideIcons.triangleAlert,
                color: AppColors.warning,
                size: 22,
              ),
              const SizedBox(width: 8),
              Text(
                'Restore Backup?',
                style: AppTextStyles.title.copyWith(fontSize: 18),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'This will replace your current data with the selected backup:',
                style: AppTextStyles.bodySecondary,
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('🚗 Vehicles: ${summary.vehicleCount}',
                        style: AppTextStyles.body),
                    Text('⛽ Fuel Logs: ${summary.fuelLogCount}',
                        style: AppTextStyles.body),
                    Text('🗺️ Trip Logs: ${summary.tripLogCount}',
                        style: AppTextStyles.body),
                    Text('🔧 Service Logs: ${summary.serviceLogCount}',
                        style: AppTextStyles.body),
                    Text('⏰ Reminders: ${summary.reminderCount}',
                        style: AppTextStyles.body),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '⚠️ Existing records will be overwritten.',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Cancel', style: AppTextStyles.bodySecondary),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Restore Data'),
            ),
          ],
        ),
      );

      if (shouldRestore != true || !mounted) return;

      setState(() => _isRestoring = true);

      final db = ref.read(databaseProvider);
      final restored =
          await _backupService.restoreBackupFromFile(file: file, db: db);

      ref.invalidate(vehiclesProvider);
      ref.invalidate(selectedVehicleIdProvider);
      ref.invalidate(activeVehicleProvider);
      ref.invalidate(vehicleLogsProvider);
      ref.invalidate(serviceLogsProvider);
      ref.invalidate(vehicleTripsProvider);
      ref.invalidate(remindersProvider);

      if (!mounted) return;
      _toast(
          '✅ Restored ${restored.vehicleCount} vehicles & ${restored.totalRecords} records!');
    } catch (e) {
      if (!mounted) return;
      _toast('Restore error: $e');
    } finally {
      if (mounted) setState(() => _isRestoring = false);
    }
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: AppTextStyles.body.copyWith(color: AppColors.textPrimary),
        ),
        backgroundColor: AppColors.cardElevated,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.locale;

    return ListView(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        AppSpacing.md,
        AppSpacing.screenPadding,
        DashboardBottomBar.contentBottomInset(context),
      ),
      children: [
        _SettingsGroup(
          title: 'dataStorage'.tr(),
          children: [
            _SettingsTile(
              icon: LucideIcons.fileText,
              title: 'Create Vehicle Report',
              subtitle: 'Share CSV & text reports for buyer or tax',
              onTap: () => ReportsScreen.open(context),
            ),
            _SettingsTile(
              icon: LucideIcons.fileDown,
              title: 'exportData'.tr(),
              subtitle: 'exportDataSubtitle'.tr(),
              trailing: _isExporting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    )
                  : null,
              onTap: _isExporting ? null : _handleExport,
            ),
            _SettingsTile(
              icon: LucideIcons.fileUp,
              title: 'importData'.tr(),
              subtitle: 'importDataSubtitle'.tr(),
              trailing: _isRestoring
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    )
                  : null,
              onTap: _isRestoring ? null : _handleImport,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        _SettingsGroup(
          title: 'preferences'.tr(),
          children: [
            _SettingsTile(
              icon: LucideIcons.globe,
              title: 'language'.tr(),
              subtitle: 'languageSubtitle'.tr(),
              valueText: _languageLabel(locale),
              onTap: _pickLanguage,
            ),
            _SettingsTile(
              icon: LucideIcons.cloudSun,
              title: 'weatherTipsAlerts'.tr(),
              subtitle: 'weatherTipsAlertsSubtitle'.tr(),
              trailing: Transform.scale(
                scale: 0.82,
                child: CupertinoSwitch(
                  value: ref.watch(weatherTipsEnabledProvider),
                  activeTrackColor: AppColors.primary,
                  onChanged: (v) => ref
                      .read(weatherTipsEnabledProvider.notifier)
                      .setEnabled(v),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        Center(
          child: Column(
            children: [
              Icon(
                LucideIcons.fuel,
                size: 22,
                color: AppColors.textTertiary.withValues(alpha: 0.7),
              ),
              const SizedBox(height: 6),
              Text(
                'Fuel Log · v1.0.0',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '100% On-Device & Private',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textTertiary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title.toUpperCase(),
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textTertiary,
              fontWeight: FontWeight.w600,
              fontSize: 11,
              letterSpacing: 0.6,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          ),
          child: CleanGlassPanel(
            child: Column(
              children: [
                for (var i = 0; i < children.length; i++) ...[
                  children[i],
                  if (i < children.length - 1)
                    Divider(
                      height: 1,
                      thickness: 1,
                      color: AppColors.border.withValues(alpha: 0.5),
                      indent: 48,
                    ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.valueText,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? valueText;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.body.copyWith(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: AppTextStyles.caption.copyWith(
                        fontSize: 11.5,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              if (valueText != null) ...[
                Text(
                  valueText!,
                  style: AppTextStyles.bodySecondary.copyWith(
                    fontSize: 13,
                    color: AppColors.textTertiary,
                  ),
                ),
                const SizedBox(width: 6),
              ],
              if (trailing != null)
                trailing!
              else if (onTap != null)
                const Icon(
                  LucideIcons.chevronRight,
                  size: 16,
                  color: AppColors.textTertiary,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
