import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../widgets/app_card.dart';

/// Settings Tab View listing export, import, unit preferences, and dark mode.
class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  bool _darkThemeEnabled = true;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      children: [
        // Data Section Header
        Text('DATA & STORAGE', style: AppTextStyles.label),
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
                title: Text('Export Data (CSV)', style: AppTextStyles.body),
                subtitle: Text(
                  'Backup fuel logs to CSV file',
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
                title: Text('Import Data', style: AppTextStyles.body),
                subtitle: Text(
                  'Restore records from CSV backup',
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

        // Preferences Section Header
        Text('PREFERENCES', style: AppTextStyles.label),
        const SizedBox(height: AppSpacing.sm),
        AppCard(
          child: Column(
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.straighten_rounded,
                    color: AppColors.textPrimary,
                  ),
                ),
                title: Text(
                  'Unit Preferences (km/L)',
                  style: AppTextStyles.body,
                ),
                subtitle: Text(
                  'Kilometers (km), Liters (L)',
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
                    color: AppColors.surface,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.dark_mode_rounded,
                    color: AppColors.textPrimary,
                  ),
                ),
                title: Text('Dark Theme Toggle', style: AppTextStyles.body),
                subtitle: Text(
                  'Pure Dark Mode Enabled',
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
