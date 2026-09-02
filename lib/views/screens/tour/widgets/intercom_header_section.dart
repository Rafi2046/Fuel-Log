import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../viewmodels/intercom_viewmodel.dart';
import '../../../widgets/clean_glass_panel.dart';

/// Top section with Tour Title, active channel badge, and overlapping avatar stack.
class IntercomHeaderSection extends StatelessWidget {
  const IntercomHeaderSection({
    super.key,
    required this.state,
    required this.onMuteToggle,
    this.onLeave,
    this.onInvite,
  });

  final IntercomState state;
  final VoidCallback onMuteToggle;
  final VoidCallback? onLeave;
  final VoidCallback? onInvite;

  static const _avatarColors = [
    Color(0xFFFF7A50),
    Color(0xFF3B82F6),
    Color(0xFF10B981),
    Color(0xFF8B5CF6),
    Color(0xFFEC4899),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top Bar: Tour Name + Live Status Pill + Actions
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          state.tourName,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Glowing Live Status Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.15),
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusPill),
                          border: Border.all(
                            color: AppColors.success.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.success,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.success,
                                    blurRadius: 6,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              'LIVE (${state.onlineCount})',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppColors.success,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    state.channelCode,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textTertiary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),

            // Quick Mute / Leave Call Actions
            if (state.isHost && onInvite != null)
              IconButton(
                onPressed: onInvite,
                tooltip: 'Invite Riders',
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.primary.withValues(alpha: 0.18),
                  foregroundColor: AppColors.primary,
                  padding: const EdgeInsets.all(8),
                ),
                icon: const Icon(Icons.person_add_rounded, size: 20),
              ),
            if (state.isHost && onInvite != null) const SizedBox(width: 6),
            IconButton(
              onPressed: onMuteToggle,
              tooltip: state.isMuted ? 'Unmute' : 'Mute',
              style: IconButton.styleFrom(
                backgroundColor: state.isMuted
                    ? AppColors.error.withValues(alpha: 0.2)
                    : AppColors.cardElevated,
                foregroundColor: state.isMuted
                    ? AppColors.error
                    : AppColors.textSecondary,
                padding: const EdgeInsets.all(8),
              ),
              icon: Icon(
                state.isMuted
                    ? Icons.mic_off_rounded
                    : Icons.mic_none_rounded,
                size: 20,
              ),
            ),
            const SizedBox(width: 6),
            if (onLeave != null)
              IconButton(
                onPressed: onLeave,
                tooltip: 'Leave Intercom',
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.error.withValues(alpha: 0.15),
                  foregroundColor: AppColors.error,
                  padding: const EdgeInsets.all(8),
                ),
                icon: const Icon(Icons.call_end_rounded, size: 20),
              ),
          ],
        ),

        const SizedBox(height: 14),

        // Overlapping Avatar Stack of Connected Members Card
        CleanGlassPanel(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              // Overlapping Avatar Stack
              SizedBox(
                height: 40,
                width: 32.0 + ((state.members.length - 1) * 26.0),
                child: Stack(
                  children: List.generate(state.members.length, (index) {
                    final member = state.members[index];
                    final color = _avatarColors[index % _avatarColors.length];

                    return Positioned(
                      left: index * 26.0,
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: color.withValues(alpha: 0.22),
                          border: Border.all(
                            color: member.isCurrentUser
                                ? AppColors.primary
                                : AppColors.background,
                            width: 2.2,
                          ),
                          boxShadow: member.isCurrentUser
                              ? [
                                  BoxShadow(
                                    color: AppColors.primary.withValues(
                                      alpha: 0.4,
                                    ),
                                    blurRadius: 6,
                                  ),
                                ]
                              : null,
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Text(
                              member.initials,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: member.isCurrentUser
                                    ? AppColors.primary
                                    : Colors.white,
                              ),
                            ),
                            // Glowing Online Dot
                            if (member.isOnline)
                              Positioned(
                                right: 1,
                                bottom: 1,
                                child: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.success,
                                    border: Border.all(
                                      color: AppColors.background,
                                      width: 1.5,
                                    ),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: AppColors.success,
                                        blurRadius: 4,
                                        spreadRadius: 0.5,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              ),

              const SizedBox(width: 12),

              // Connected info text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${state.onlineCount} Riders Connected',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      'Resilient P2P Mesh • High Fidelity',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w400,
                        color: AppColors.textTertiary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Audio Wave Indicator icon
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withValues(alpha: 0.12),
                ),
                child: const Icon(
                  Icons.graphic_eq_rounded,
                  size: 16,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
