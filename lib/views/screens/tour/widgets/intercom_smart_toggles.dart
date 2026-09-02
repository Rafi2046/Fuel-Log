import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../widgets/clean_glass_panel.dart';

/// Audio enhancement settings in a single premium list card.
class IntercomSmartToggles extends StatelessWidget {
  const IntercomSmartToggles({
    super.key,
    required this.windNoiseEnabled,
    required this.helmetAudioEnabled,
    required this.meshBridgeEnabled,
    required this.fecRecoveryEnabled,
    required this.onWindNoiseChanged,
    required this.onHelmetAudioChanged,
    required this.onMeshBridgeChanged,
    required this.onFecRecoveryChanged,
  });

  final bool windNoiseEnabled;
  final bool helmetAudioEnabled;
  final bool meshBridgeEnabled;
  final bool fecRecoveryEnabled;
  final ValueChanged<bool> onWindNoiseChanged;
  final ValueChanged<bool> onHelmetAudioChanged;
  final ValueChanged<bool> onMeshBridgeChanged;
  final ValueChanged<bool> onFecRecoveryChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: AppSpacing.sm),
          child: Text(
            'Audio',
            style: AppTextStyles.label.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        CleanGlassPanel(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _SettingRow(
                icon: Icons.air_rounded,
                title: 'Wind noise filter',
                subtitle: 'Cuts wind rumble and background hiss',
                value: windNoiseEnabled,
                onChanged: onWindNoiseChanged,
              ),
              const Divider(height: 1, color: AppColors.divider),
              _SettingRow(
                icon: Icons.headset_mic_rounded,
                title: 'Helmet audio',
                subtitle: 'Routes through Bluetooth / Sena intercom',
                value: helmetAudioEnabled,
                onChanged: onHelmetAudioChanged,
              ),
              const Divider(height: 1, color: AppColors.divider),
              _SettingRow(
                icon: Icons.wifi_tethering_rounded,
                title: 'Mesh bridge',
                subtitle: 'Host relays audio between riders',
                value: meshBridgeEnabled,
                onChanged: onMeshBridgeChanged,
              ),
              const Divider(height: 1, color: AppColors.divider),
              _SettingRow(
                icon: Icons.auto_graph_rounded,
                title: 'Auto FEC recovery',
                subtitle: 'Smooths playback when packets drop',
                value: fecRecoveryEnabled,
                onChanged: onFecRecoveryChanged,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          _IconTile(icon: icon, active: value),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.label.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(subtitle, style: AppTextStyles.caption),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.primary,
            activeTrackColor: AppColors.primary.withValues(alpha: 0.35),
            inactiveThumbColor: AppColors.textTertiary,
            inactiveTrackColor: AppColors.cardElevated,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
  }
}

class _IconTile extends StatelessWidget {
  const _IconTile({required this.icon, required this.active});

  final IconData icon;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: active
            ? AppColors.primary.withValues(alpha: 0.1)
            : AppColors.cardElevated,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(
          color: active
              ? AppColors.primary.withValues(alpha: 0.25)
              : AppColors.border,
        ),
      ),
      child: Icon(
        icon,
        size: 17,
        color: active ? AppColors.primary : AppColors.textSecondary,
      ),
    );
  }
}
