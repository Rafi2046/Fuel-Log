import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_regions.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/services/backup_restore_service.dart';
import '../../../viewmodels/fuel_log_viewmodel.dart';
import '../../../viewmodels/region_viewmodel.dart';
import '../../../viewmodels/reminder_viewmodel.dart';
import '../../../viewmodels/service_log_viewmodel.dart';
import '../../../viewmodels/trip_log_viewmodel.dart';
import '../../../viewmodels/vehicle_viewmodel.dart';
import '../../../viewmodels/weather_viewmodel.dart';
import '../../widgets/clean_glass_panel.dart';
import '../documents/e_document_vault_screen.dart';
import '../reports/reports_screen.dart';
import 'dashboard_bottom_bar.dart';
import 'widgets/appearance_picker_sheet.dart';
import 'widgets/region_picker_sheet.dart';

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

  String _languageValueLabel(AppLanguage language) {
    return '${language.flagEmoji} ${language.nameKey.tr()}';
  }

  String _currencyValueLabel(AppCurrencyId currency) {
    return '${currency.flagEmoji} ${currency.code} (${currency.glyph})';
  }

  Future<void> _pickLanguage(WidgetRef ref) =>
      showLanguagePickerSheet(context: context, ref: ref);

  Future<void> _pickCurrency(WidgetRef ref) =>
      showCurrencyPickerSheet(context: context, ref: ref);

  Future<void> _handleExport() async {
    if (_isExporting) return;
    setState(() => _isExporting = true);
    try {
      final db = ref.read(databaseProvider);
      await _backupService.shareBackup(db: db);
      if (!mounted) return;
      _toast('backupExportedSuccess'.tr());
    } catch (e) {
      if (!mounted) return;
      _toast('backupExportFailed'.tr(namedArgs: {'error': '$e'}));
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
      if (!mounted) return;

      final shouldRestore = await showDialog<bool>(
        context: context,
        barrierColor: Colors.black.withValues(alpha: 0.68),
        builder: (ctx) => _RestoreBackupDialog(summary: summary),
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
        'backupRestoredSuccess'.tr(
          namedArgs: {
            'vehicles': '${restored.vehicleCount}',
            'records': '${restored.totalRecords}',
          },
        ),
      );
    } catch (e) {
      if (!mounted) return;
      _toast('backupRestoreFailed'.tr(namedArgs: {'error': '$e'}));
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
    final language = ref.watch(appLanguageProvider);
    final currency = ref.watch(appCurrencyProvider);

    return ListView(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        AppSpacing.appBarBodyGap,
        AppSpacing.screenPadding,
        DashboardBottomBar.contentBottomInset(context),
      ),
      children: [
        _SettingsGroup(
          title: 'documentVaultTitle'.tr(),
          children: [
            _SettingsTile(
              icon: LucideIcons.shieldCheck,
              title: 'documentVaultTitle'.tr(),
              subtitle: 'documentVaultSubtitle'.tr(),
              onTap: () => EDocumentVaultScreen.open(context),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        _SettingsGroup(
          title: 'dataStorage'.tr(),
          children: [
            _SettingsTile(
              icon: LucideIcons.fileText,
              title: 'createVehicleReport'.tr(),
              subtitle: 'createVehicleReportSubtitle'.tr(),
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
        const AppearanceThemeSection(),
        const SizedBox(height: AppSpacing.lg),
        _SettingsGroup(
          title: 'preferences'.tr(),
          children: [
            _SettingsTile(
              icon: LucideIcons.languages,
              title: 'language'.tr(),
              subtitle: 'languageSubtitle'.tr(),
              valueText: _languageValueLabel(language),
              onTap: () => _pickLanguage(ref),
            ),
            _SettingsTile(
              icon: LucideIcons.coins,
              title: 'currency'.tr(),
              subtitle: 'currencySubtitle'.tr(),
              valueText: _currencyValueLabel(currency),
              onTap: () => _pickCurrency(ref),
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
        SizedBox(height: AppSpacing.xl),
        Center(
          child: Column(
            children: [
              Icon(
                LucideIcons.fuel,
                size: 22,
                color: AppColors.textTertiary.withValues(alpha: 0.7),
              ),
              SizedBox(height: 6),
              Text(
                'FuelSync · v1.0.0',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
              ),
              SizedBox(height: 2),
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
          padding: EdgeInsets.only(left: 4, bottom: 8),
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
          padding: EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: AppColors.textSecondary,
              ),
              SizedBox(width: 14),
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
                    SizedBox(height: 2),
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
                SizedBox(width: 6),
              ],
              if (trailing != null)
                trailing!
              else if (onTap != null)
                Icon(
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

/// Compact premium confirm dialog for backup restore.
class _RestoreBackupDialog extends StatelessWidget {
  const _RestoreBackupDialog({required this.summary});

  final BackupSummary summary;

  @override
  Widget build(BuildContext context) {
    final rows = <(IconData, String, int)>[
      (LucideIcons.car, 'restoreStatVehicles'.tr(), summary.vehicleCount),
      (LucideIcons.fuel, 'restoreStatFuel'.tr(), summary.fuelLogCount),
      (LucideIcons.map, 'restoreStatTrips'.tr(), summary.tripLogCount),
      (LucideIcons.wrench, 'restoreStatService'.tr(), summary.serviceLogCount),
      (LucideIcons.bell, 'restoreStatReminders'.tr(), summary.reminderCount),
    ];

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 32),
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
        decoration: BoxDecoration(
          color: AppColors.cardElevated,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: const Icon(
                    LucideIcons.rotateCcw,
                    size: 16,
                    color: AppColors.warning,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'restoreBackupTitle'.tr(),
                    style: AppTextStyles.title.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'restoreBackupBody'.tr(),
              style: AppTextStyles.caption.copyWith(
                fontSize: 12.5,
                height: 1.35,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 6),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.border.withValues(alpha: 0.8),
                ),
              ),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final row in rows)
                    _RestoreStatChip(
                      icon: row.$1,
                      label: row.$2,
                      count: row.$3,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(
                  LucideIcons.info,
                  size: 13,
                  color: AppColors.error.withValues(alpha: 0.9),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'restoreBackupOverwrite'.tr(),
                    style: AppTextStyles.caption.copyWith(
                      fontSize: 11.5,
                      color: AppColors.error.withValues(alpha: 0.9),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 42,
                    child: TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(11),
                          side: BorderSide(color: AppColors.border),
                        ),
                      ),
                      child: Text(
                        'restoreBackupCancel'.tr(),
                        style: AppTextStyles.body.copyWith(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 1,
                  child: SizedBox(
                    height: 42,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(11),
                        ),
                      ),
                      child: Text(
                        'restoreBackupConfirm'.tr(),
                        style: AppTextStyles.body.copyWith(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RestoreStatChip extends StatelessWidget {
  const _RestoreStatChip({
    required this.icon,
    required this.label,
    required this.count,
  });

  final IconData icon;
  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.cardElevated.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.textTertiary),
          const SizedBox(width: 5),
          Text(
            '$label  $count',
            style: AppTextStyles.caption.copyWith(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
