import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_locales.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../widgets/app_card.dart';

/// Settings tab listing export, import, language, and dark mode.
class SettingsTab extends StatefulWidget {
  const SettingsTab({super.key});

  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> {
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
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusLg),
        ),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final locale in supportedAppLocales)
                ListTile(
                  title: Text(
                    _languageLabel(locale),
                    style: AppTextStyles.body,
                  ),
                  trailing: locale.languageCode == current.languageCode
                      ? const Icon(Icons.check_rounded, color: AppColors.primary)
                      : null,
                  onTap: () => Navigator.pop(sheetContext, locale),
                ),
            ],
          ),
        );
      },
    );

    if (selected != null && mounted) {
      await context.setLocale(selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.locale;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      children: [
        Text('dataStorage'.tr(), style: AppTextStyles.label),
        const SizedBox(height: AppSpacing.sm),
        AppCard(
          child: Column(
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.download_rounded,
                    color: AppColors.primary,
                  ),
                ),
                title: Text('exportData'.tr(), style: AppTextStyles.body),
                subtitle: Text(
                  'exportDataSubtitle'.tr(),
                  style: AppTextStyles.caption,
                ),
                trailing: const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textTertiary,
                ),
                onTap: () {},
              ),
              const Divider(color: AppColors.divider),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.upload_rounded,
                    color: AppColors.secondary,
                  ),
                ),
                title: Text('importData'.tr(), style: AppTextStyles.body),
                subtitle: Text(
                  'importDataSubtitle'.tr(),
                  style: AppTextStyles.caption,
                ),
                trailing: const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textTertiary,
                ),
                onTap: () {},
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Text('preferences'.tr(), style: AppTextStyles.label),
        const SizedBox(height: AppSpacing.sm),
        AppCard(
          child: Column(
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: const BoxDecoration(
                    color: AppColors.surface,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.language_rounded,
                    color: AppColors.textPrimary,
                  ),
                ),
                title: Text('language'.tr(), style: AppTextStyles.body),
                subtitle: Text(
                  '${'languageSubtitle'.tr()} • ${_languageLabel(locale)}',
                  style: AppTextStyles.caption,
                ),
                trailing: const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textTertiary,
                ),
                onTap: _pickLanguage,
              ),
              const Divider(color: AppColors.divider),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: const BoxDecoration(
                    color: AppColors.surface,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.straighten_rounded,
                    color: AppColors.textPrimary,
                  ),
                ),
                title: Text('unitPreferences'.tr(), style: AppTextStyles.body),
                subtitle: Text(
                  'unitPreferencesSubtitle'.tr(),
                  style: AppTextStyles.caption,
                ),
                trailing: const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textTertiary,
                ),
                onTap: () {},
              ),
              const Divider(color: AppColors.divider),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: const BoxDecoration(
                    color: AppColors.surface,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.dark_mode_rounded,
                    color: AppColors.textPrimary,
                  ),
                ),
                title: Text('darkTheme'.tr(), style: AppTextStyles.body),
                subtitle: Text(
                  'darkThemeSubtitle'.tr(),
                  style: AppTextStyles.caption,
                ),
                trailing: Switch.adaptive(
                  value: _darkThemeEnabled,
                  onChanged: (v) => setState(() => _darkThemeEnabled = v),
                  activeThumbColor: AppColors.textPrimary,
                  activeTrackColor: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
