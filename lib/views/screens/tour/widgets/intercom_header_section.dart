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

  @override
  Widget build(BuildContext context) {
    final status = _SessionStatus.fromState(state);
    final isAlone = state.onlineCount <= 1;
    final avatarStackWidth = _avatarStackWidth(state.members.length);

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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          state.tourName,
                          style: AppTextStyles.title.copyWith(fontSize: 17),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Tour code',
                          style: AppTextStyles.caption.copyWith(fontSize: 11),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _formatCode(state.channelCode),
                          style: GoogleFonts.firaCode(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                            letterSpacing: 3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _LiveBadge(
                    count: state.onlineCount,
                    isAlone: isAlone,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              const Divider(color: AppColors.divider, height: 1),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  SizedBox(
                    height: 40,
                    width: avatarStackWidth,
                    child: ClipRect(
                      clipBehavior: Clip.none,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: List.generate(state.members.length, (index) {
                          final member = state.members[index];
                          final color =
                              _avatarColors[index % _avatarColors.length];

                          return Positioned(
                            left: index * 24.0,
                            child: _MemberAvatar(
                              member: member,
                              color: color,
                            ),
                          );
                        }),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isAlone
                              ? 'Just you for now'
                              : '${state.onlineCount} riders connected',
                          style: AppTextStyles.label.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          isAlone
                              ? 'Invite riders with your tour code'
                              : 'Offline mesh • no mobile data',
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
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

  static double _avatarStackWidth(int memberCount) {
    if (memberCount <= 0) return 40;
    const avatarSize = 40.0;
    const overlap = 24.0;
    return avatarSize + ((memberCount - 1) * overlap);
  }

  static String _formatCode(String code) =>
      code.replaceAll(' ', '').split('').join(' ');
}

class _MemberAvatar extends StatelessWidget {
  const _MemberAvatar({required this.member, required this.color});

  final IntercomMember member;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.18),
        border: Border.all(
          color: member.isCurrentUser
              ? AppColors.primary.withValues(alpha: 0.5)
              : AppColors.border,
        ),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Text(
            member.initials,
            style: AppTextStyles.caption.copyWith(
              fontWeight: FontWeight.w700,
              color: member.isCurrentUser
                  ? AppColors.primary
                  : AppColors.textPrimary,
            ),
          ),
          if (member.isOnline)
            Positioned(
              right: 1,
              bottom: 1,
              child: Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.success,
                  border: Border.all(
                    color: AppColors.card,
                    width: 1.5,
                  ),
                ),
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
        if (state.isHost && onInvite != null) ...[
          Expanded(
            child: _ActionButton(
              icon: Icons.person_add_outlined,
              label: 'Invite',
              onPressed: onInvite!,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
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
    this.foregroundColor = AppColors.textPrimary,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppSpacing.buttonHeightCompact,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: foregroundColor,
          side: const BorderSide(color: AppColors.border),
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
            color: foregroundColor,
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
          label: 'Channel ready — share code to invite riders',
          icon: Icons.group_add_outlined,
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
