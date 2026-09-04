import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/models/intercom_rider_role.dart';
import '../../../widgets/clean_glass_panel.dart';

/// Audio enhancement settings in a single premium list card.
class IntercomSmartToggles extends StatelessWidget {
  const IntercomSmartToggles({
    super.key,
    required this.windNoiseEnabled,
    required this.helmetAudioEnabled,
    required this.meshBridgeEnabled,
    required this.fecRecoveryEnabled,
    required this.loudspeakerEnabled,
    required this.riderRole,
    required this.onWindNoiseChanged,
    required this.onHelmetAudioChanged,
    required this.onLoudspeakerChanged,
    required this.onMeshBridgeChanged,
    required this.onFecRecoveryChanged,
  });

  final bool windNoiseEnabled;
  final bool helmetAudioEnabled;
  final bool meshBridgeEnabled;
  final bool fecRecoveryEnabled;
  final bool loudspeakerEnabled;
  final IntercomRiderRole riderRole;
  final ValueChanged<bool> onWindNoiseChanged;
  final ValueChanged<bool> onHelmetAudioChanged;
  final ValueChanged<bool> onLoudspeakerChanged;
  final ValueChanged<bool> onMeshBridgeChanged;
  final ValueChanged<bool> onFecRecoveryChanged;

  static const _dividerIndent = 46.0;


  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 4, bottom: AppSpacing.sm),
          child: Text(
            'Audio',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textTertiary,
              fontWeight: FontWeight.w600,
              fontSize: 11,
              letterSpacing: 0.4,
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
                subtitle: 'Reduces wind at highway speeds',
                value: windNoiseEnabled,
                onChanged: onWindNoiseChanged,
              ),
              _InsetDivider(indent: _dividerIndent),
              _SettingRow(
                icon: Icons.headset_mic_rounded,
                title: 'Helmet / earphone audio',
                subtitle: 'Route through Bluetooth / wired earbuds or helmet',
                value: helmetAudioEnabled,
                onChanged: onHelmetAudioChanged,
              ),
              _InsetDivider(indent: _dividerIndent),
              _SettingRow(
                icon: Icons.volume_up_rounded,
                title: 'Loudspeaker',
                subtitle: 'Play through phone speaker (for bike mount)',
                value: loudspeakerEnabled,
                onChanged: onLoudspeakerChanged,
              ),
              _InsetDivider(indent: _dividerIndent),
              _SettingRow(
                icon: Icons.wifi_tethering_rounded,
                title: 'Mesh bridge',
                subtitle: 'Extend range without mobile data',
                value: meshBridgeEnabled,
                onChanged: onMeshBridgeChanged,
              ),
              _InsetDivider(indent: _dividerIndent),
              _SettingRow(
                icon: Icons.auto_graph_rounded,
                title: 'Auto FEC recovery',
                subtitle: 'Keeps audio stable on packet loss',
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

class _InsetDivider extends StatelessWidget {
  const _InsetDivider({required this.indent});

  final double indent;

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      indent: indent,
      color: AppColors.border.withValues(alpha: 0.55),
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

  void _handleTap() {
    HapticFeedback.selectionClick();
    onChanged(!value);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _handleTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: Padding(
          padding: EdgeInsets.fromLTRB(14, 11, 12, 11),
          child: Row(
            children: [
              Icon(
                icon,
                size: 18,
                color: value ? AppColors.primary : AppColors.textTertiary,
              ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTextStyles.body.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 1),
                      Text(
                        subtitle,
                        style: AppTextStyles.caption.copyWith(
                          fontSize: 11,
                          color: AppColors.textTertiary,
                          height: 1.25,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _CompactSwitch(
                  value: value,
                  onChanged: onChanged,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompactSwitch extends StatelessWidget {
  const _CompactSwitch({
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scale: 0.78,
      child: CupertinoSwitch(
        value: value,
        activeTrackColor: AppColors.primary,
        onChanged: onChanged == null
            ? null
            : (next) {
                HapticFeedback.selectionClick();
                onChanged!(next);
              },
      ),
    );
  }
}
