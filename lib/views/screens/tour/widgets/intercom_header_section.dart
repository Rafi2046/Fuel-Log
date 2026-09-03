import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../viewmodels/intercom_viewmodel.dart';
import '../../../widgets/clean_glass_panel.dart';

/// Session summary: tour info, riders, and connection status.
class IntercomHeaderSection extends StatelessWidget {
  const IntercomHeaderSection({
    super.key,
    required this.state,
    this.onInvite,
    this.onMuteToggle,
    this.onLeave,
  });

  final IntercomState state;
  final VoidCallback? onInvite;
  final VoidCallback? onMuteToggle;
  final VoidCallback? onLeave;

  static const _avatarColors = [
    Color(0xFFFF7A50),
    Color(0xFF3B82F6),
    Color(0xFF10B981),
    Color(0xFF8B5CF6),
    Color(0xFFEC4899),
  ];

  String get _displayTourTitle {
    final raw = state.tourName.trim();
    final code = state.channelCode.trim().toUpperCase();
    if (raw.isEmpty ||
        raw.toUpperCase() == 'TOUR' ||
        raw.toUpperCase() == 'TOUR $code' ||
        raw.toUpperCase() == code) {
      return 'Live Intercom';
    }
    return raw;
  }

  @override
  Widget build(BuildContext context) {
    final status = _SessionStatus.fromState(state);
    final isAlone = state.onlineCount <= 1;
    final remoteCount = state.members.where((m) => !m.isCurrentUser).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (onInvite != null || onMuteToggle != null || onLeave != null) ...[
          _SessionActionBar(
            state: state,
            onInvite: onInvite,
            onMuteToggle: onMuteToggle,
            onLeave: onLeave,
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        CleanGlassPanel(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      _displayTourTitle,
                      style: AppTextStyles.title.copyWith(fontSize: 17),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _LiveBadge(
                    count: state.onlineCount,
                    isAlone: isAlone,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Tour code',
                style: AppTextStyles.caption.copyWith(fontSize: 11),
              ),
              SizedBox(height: 2),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _formatCode(state.channelCode),
                      style: GoogleFonts.firaCode(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                        letterSpacing: 2.5,
                      ),
                    ),
                  ),
                  if (onInvite != null)
                    InkWell(
                      onTap: onInvite,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.35),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.qr_code_rounded,
                              size: 13,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Show QR',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(height: AppSpacing.md),
              Divider(color: AppColors.divider, height: 1),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isAlone
                              ? 'Waiting for members'
                              : '$remoteCount member${remoteCount == 1 ? '' : 's'} joined',
                          style: AppTextStyles.label.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          isAlone
                              ? (state.isHost
                                  ? 'Share your tour code to invite'
                                  : 'Searching for tour host nearby')
                              : '${state.onlineCount} active on this channel',
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ),
                  ),
                  if (isAlone)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    ),
                ],
              ),
              if (isAlone && onInvite != null) ...[
                const SizedBox(height: AppSpacing.sm),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: onInvite,
                    icon: const Icon(Icons.qr_code_scanner_rounded, size: 16),
                    label: const Text('Show Tour QR & Invite Code'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: BorderSide(
                        color: AppColors.primary.withValues(alpha: 0.4),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      ),
                    ),
                  ),
                ),
              ],
              if (state.members.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: Column(
                    key: ValueKey(state.members.length),
                    children: [
                      for (var i = 0; i < state.members.length; i++) ...[
                        _RiderListTile(
                          member: state.members[i],
                          color: _avatarColors[i % _avatarColors.length],
                        ),
                        if (i < state.members.length - 1)
                          const SizedBox(height: AppSpacing.xs),
                      ],
                    ],
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: status.backgroundColor,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  border: Border.all(color: status.borderColor),
                ),
                child: Row(
                  children: [
                    Icon(status.icon, size: 15, color: status.iconColor),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        status.label,
                        style: AppTextStyles.caption.copyWith(
                          fontWeight: FontWeight.w600,
                          color: status.textColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static String _formatCode(String code) =>
      code.replaceAll(' ', '').split('').join(' ');
}

class _RiderListTile extends StatelessWidget {
  const _RiderListTile({
    required this.member,
    required this.color,
  });

  final IntercomMember member;
  final Color color;

  String get _displayName =>
      member.isCurrentUser ? 'You' : member.name;

  String get _initials {
    if (member.isCurrentUser) return 'Y';
    final value = member.initials.trim();
    if (value.length <= 2) return value.toUpperCase();
    return value.substring(0, 2).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.cardElevated,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(
          color: member.isCurrentUser
              ? AppColors.primary.withValues(alpha: 0.22)
              : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.16),
            ),
            child: Text(
              _initials,
              style: AppTextStyles.caption.copyWith(
                fontWeight: FontWeight.w700,
                color: member.isCurrentUser
                    ? AppColors.primary
                    : AppColors.textPrimary,
              ),
            ),
          ),
          SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              _displayName,
              style: AppTextStyles.label.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                fontSize: 13,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (member.isOnline)
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.success,
                border: Border.all(color: AppColors.cardElevated, width: 1),
              ),
            ),
        ],
      ),
    );
  }
}

class _SessionActionBar extends StatelessWidget {
  const _SessionActionBar({
    required this.state,
    this.onInvite,
    this.onMuteToggle,
    this.onLeave,
  });

  final IntercomState state;
  final VoidCallback? onInvite;
  final VoidCallback? onMuteToggle;
  final VoidCallback? onLeave;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (onInvite != null) ...[
          Expanded(
            child: _ActionButton(
              icon: Icons.qr_code_rounded,
              label: 'QR / Invite',
              onPressed: onInvite!,
            ),
          ),
          SizedBox(width: AppSpacing.sm),
        ],
        if (onMuteToggle != null) ...[
          Expanded(
            child: _ActionButton(
              icon: state.isMuted
                  ? Icons.mic_off_rounded
                  : Icons.mic_none_rounded,
              label: state.isMuted ? 'Unmute' : 'Mute',
              onPressed: onMuteToggle!,
              foregroundColor:
                  state.isMuted ? AppColors.error : AppColors.textPrimary,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
        if (onLeave != null)
          Expanded(
            child: _ActionButton(
              icon: Icons.call_end_rounded,
              label: 'Leave',
              onPressed: onLeave!,
              foregroundColor: AppColors.error,
            ),
          ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.foregroundColor,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    final fg = foregroundColor ?? AppColors.textPrimary;
    return SizedBox(
      height: AppSpacing.buttonHeightCompact,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: fg,
          side: BorderSide(color: AppColors.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        ),
        icon: Icon(icon, size: 16),
        label: Text(
          label,
          style: AppTextStyles.label.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: fg,
          ),
        ),
      ),
    );
  }
}

class _SessionStatus {
  const _SessionStatus({
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.textColor,
    required this.backgroundColor,
    required this.borderColor,
  });

  final String label;
  final IconData icon;
  final Color iconColor;
  final Color textColor;
  final Color backgroundColor;
  final Color borderColor;

  factory _SessionStatus.fromState(IntercomState state) {
    final isAlone = state.onlineCount <= 1;

    if (state.isConnected) {
      if (state.isTransmitting) {
        return _SessionStatus(
          label: isAlone
              ? 'Transmitting — waiting for riders to hear you'
              : 'Broadcasting to ${state.onlineCount} riders',
          icon: Icons.podcasts_rounded,
          iconColor: AppColors.primary,
          textColor: AppColors.textPrimary,
          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
          borderColor: AppColors.primary.withValues(alpha: 0.22),
        );
      }
      if (isAlone) {
        return _SessionStatus(
          label: state.isHost
              ? 'Waiting for riders to join…'
              : 'Looking for tour host…',
          icon: Icons.radar_rounded,
          iconColor: AppColors.primary,
          textColor: AppColors.textSecondary,
          backgroundColor: AppColors.primary.withValues(alpha: 0.08),
          borderColor: AppColors.primary.withValues(alpha: 0.2),
        );
      }
      return _SessionStatus(
        label: 'Voice channel active',
        icon: Icons.check_circle_outline_rounded,
        iconColor: AppColors.success,
        textColor: AppColors.textSecondary,
        backgroundColor: AppColors.success.withValues(alpha: 0.08),
        borderColor: AppColors.success.withValues(alpha: 0.2),
      );
    }
    if (state.isConnecting) {
      return _SessionStatus(
        label: 'Connecting to nearby riders…',
        icon: Icons.sync_rounded,
        iconColor: AppColors.warning,
        textColor: AppColors.textSecondary,
        backgroundColor: AppColors.warning.withValues(alpha: 0.08),
        borderColor: AppColors.warning.withValues(alpha: 0.2),
      );
    }
    return _SessionStatus(
      label: 'Waiting for riders to join',
      icon: Icons.radio_button_checked_rounded,
      iconColor: AppColors.textTertiary,
      textColor: AppColors.textTertiary,
      backgroundColor: AppColors.cardElevated,
      borderColor: AppColors.border,
    );
  }
}

class _LiveBadge extends StatelessWidget {
  const _LiveBadge({required this.count, required this.isAlone});

  final int count;
  final bool isAlone;

  @override
  Widget build(BuildContext context) {
    final color = isAlone ? AppColors.primary : AppColors.success;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(
          color: color.withValues(alpha: 0.28),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            isAlone ? 'Hosting' : 'Live · $count',
            style: AppTextStyles.caption.copyWith(
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
