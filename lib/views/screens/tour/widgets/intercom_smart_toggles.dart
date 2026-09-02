import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';

/// 2-column grid of tactical glassmorphism cards for intercom smart toggles.
class IntercomSmartToggles extends StatelessWidget {
  const IntercomSmartToggles({
    super.key,
    required this.windNoiseEnabled,
    required this.helmetAudioEnabled,
    required this.meshBridgeEnabled,
    required this.onWindNoiseChanged,
    required this.onHelmetAudioChanged,
    required this.onMeshBridgeChanged,
  });

  final bool windNoiseEnabled;
  final bool helmetAudioEnabled;
  final bool meshBridgeEnabled;
  final ValueChanged<bool> onWindNoiseChanged;
  final ValueChanged<bool> onHelmetAudioChanged;
  final ValueChanged<bool> onMeshBridgeChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.tune_rounded,
              size: 15,
              color: AppColors.textTertiary,
            ),
            const SizedBox(width: 6),
            Text(
              'SMART INTERCOM AUDIO ENHANCEMENTS',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.textTertiary,
                letterSpacing: 1.1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            // Toggle 1: Wind Noise Cancellation
            Expanded(
              child: _TacticalToggleCard(
                icon: Icons.air_rounded,
                title: 'Wind Noise Filter',
                subtitle: 'Cut 80km/h+ turbulence',
                value: windNoiseEnabled,
                onChanged: onWindNoiseChanged,
              ),
            ),
            const SizedBox(width: 10),
            // Toggle 2: Helmet Audio Route
            Expanded(
              child: _TacticalToggleCard(
                icon: Icons.headset_mic_rounded,
                title: 'Helmet Audio',
                subtitle: 'Bluetooth / Sena direct',
                value: helmetAudioEnabled,
                onChanged: onHelmetAudioChanged,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            // Toggle 3: Offline Mesh Bridge
            Expanded(
              child: _TacticalToggleCard(
                icon: Icons.wifi_tethering_rounded,
                title: 'Mesh Bridge',
                subtitle: 'Zero cellular data mode',
                value: meshBridgeEnabled,
                onChanged: onMeshBridgeChanged,
              ),
            ),
            const SizedBox(width: 10),
            // Static/Active info: Auto FEC Recovery
            Expanded(
              child: _TacticalInfoCard(
                icon: Icons.auto_graph_rounded,
                title: 'Auto FEC Recovery',
                subtitle: 'Packet-loss correction on',
                badgeText: 'ACTIVE',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _TacticalToggleCard extends StatelessWidget {
  const _TacticalToggleCard({
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
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: value
              ? AppColors.primary.withValues(alpha: 0.35)
              : Colors.white.withValues(alpha: 0.07),
          width: 1.2,
        ),
        boxShadow: [
          if (value)
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: value
                      ? AppColors.primary.withValues(alpha: 0.16)
                      : AppColors.cardElevated,
                  border: Border.all(
                    color: value
                        ? AppColors.primary.withValues(alpha: 0.4)
                        : Colors.white.withValues(alpha: 0.06),
                  ),
                ),
                child: Icon(
                  icon,
                  size: 16,
                  color: value ? AppColors.primary : AppColors.textTertiary,
                ),
              ),
              Transform.scale(
                scale: 0.75,
                child: Switch(
                  value: value,
                  onChanged: onChanged,
                  activeThumbColor: AppColors.primary,
                  activeTrackColor: AppColors.primary.withValues(alpha: 0.35),
                  inactiveThumbColor: AppColors.textTertiary,
                  inactiveTrackColor: AppColors.cardElevated,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: FontWeight.w400,
              color: AppColors.textTertiary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _TacticalInfoCard extends StatelessWidget {
  const _TacticalInfoCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.badgeText,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String badgeText;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.07),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.cardElevated,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.06),
                  ),
                ),
                child: Icon(
                  icon,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  border: Border.all(
                    color: AppColors.success.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  badgeText,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.success,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: FontWeight.w400,
              color: AppColors.textTertiary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
