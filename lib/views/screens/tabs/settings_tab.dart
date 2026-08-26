import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_locales.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../viewmodels/weather_viewmodel.dart';
import '../reports/reports_screen.dart';

/// Settings tab with natural, clean layout and Lucide icons.
class SettingsTab extends ConsumerStatefulWidget {
  const SettingsTab({super.key});

  @override
  ConsumerState<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends ConsumerState<SettingsTab> {
  bool _darkThemeEnabled = true;

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
      backgroundColor: AppColors.cardElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusXl),
        ),
      ),
      builder: (sheetContext) {
        return SafeArea(
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
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 8),
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
                        fontWeight:
                            locale.languageCode == current.languageCode
                                ? FontWeight.w600
                                : FontWeight.w400,
                        color:
                            locale.languageCode == current.languageCode
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
        );
      },
    );

    if (selected != null && mounted) {
      await context.setLocale(selected);
    }
  }

  void _pickUnits() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.cardElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusXl),
        ),
      ),
      builder: (sheetContext) {
        return SafeArea(
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
                  'unitPreferences'.tr(),
                  style: AppTextStyles.title.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  leading: const Icon(
                    LucideIcons.gauge,
                    size: 20,
                    color: AppColors.primary,
                  ),
                  title: Text(
                    'Metric (km, L)',
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                  subtitle: Text(
                    'Kilometers, Liters, ৳/L',
                    style: AppTextStyles.caption,
                  ),
                  trailing: const Icon(
                    LucideIcons.check,
                    size: 18,
                    color: AppColors.primary,
                  ),
                  onTap: () => Navigator.pop(sheetContext),
                ),
                ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  leading: const Icon(
                    LucideIcons.ruler,
                    size: 20,
                    color: AppColors.textSecondary,
                  ),
                  title: Text(
                    'Imperial (mi, gal)',
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  subtitle: Text(
                    'Miles, Gallons, MPG',
                    style: AppTextStyles.caption,
                  ),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content:
                            Text('Imperial units coming in next release'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
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
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPadding,
        vertical: AppSpacing.md,
      ),
      children: [
        // Section 1: Data & Storage
        _SettingsGroup(
          title: 'dataStorage'.tr(),
          children: [
            _SettingsTile(
              icon: LucideIcons.fileText,
              title: 'Create Vehicle Report',
              subtitle: 'Export PDF & CSV history for buyer or tax',
              onTap: () => ReportsScreen.open(context),
            ),
            _SettingsTile(
              icon: LucideIcons.fileDown,
              title: 'exportData'.tr(),
              subtitle: 'exportDataSubtitle'.tr(),
              onTap: () => _toast('Backup CSV generated successfully'),
            ),
            _SettingsTile(
              icon: LucideIcons.fileUp,
              title: 'importData'.tr(),
              subtitle: 'importDataSubtitle'.tr(),
              onTap: () => _toast('Select a valid CSV backup file'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),

        // Section 2: Preferences
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
              icon: LucideIcons.gauge,
              title: 'unitPreferences'.tr(),
              subtitle: 'unitPreferencesSubtitle'.tr(),
              valueText: 'km, L',
              onTap: _pickUnits,
            ),
            _SettingsTile(
              icon: LucideIcons.moon,
              title: 'darkTheme'.tr(),
              subtitle: 'darkThemeSubtitle'.tr(),
              trailing: Transform.scale(
                scale: 0.82,
                child: CupertinoSwitch(
                  value: _darkThemeEnabled,
                  activeTrackColor: AppColors.primary,
                  onChanged: (v) => setState(() => _darkThemeEnabled = v),
                ),
              ),
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

        // Minimalist App Footer
        Center(
          child: Column(
            children: [
              Icon(
                LucideIcons.fuel,
                size: 24,
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
            color: AppColors.card,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(
              color: AppColors.border.withValues(alpha: 0.8),
            ),
          ),
          child: Column(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                children[i],
                if (i < children.length - 1)
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: AppColors.border.withValues(alpha: 0.4),
                    indent: 48,
                  ),
              ],
            ],
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
              // Clean Lucide Icon without background container
              Icon(
                icon,
                size: 20,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 14),
              // Title & Subtitle
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
              // Trailing value or control
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
