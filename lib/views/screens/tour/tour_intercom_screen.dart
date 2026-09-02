import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../viewmodels/intercom_viewmodel.dart';
import '../../widgets/app_scaffold.dart';
import 'widgets/intercom_header_section.dart';
import 'widgets/intercom_rider_tips.dart';
import 'widgets/intercom_smart_toggles.dart';
import 'widgets/tactical_ptt_button.dart';
import 'widgets/tour_join_code_sheet.dart';

/// Active tactical Intercom screen for live motorcycle tour communication.
class TourIntercomScreen extends ConsumerStatefulWidget {
  const TourIntercomScreen({
    super.key,
    this.tourName,
    this.preGeneratedCode,
  });

  final String? tourName;
  final String? preGeneratedCode;

  @override
  ConsumerState<TourIntercomScreen> createState() => _TourIntercomScreenState();
}

class _TourIntercomScreenState extends ConsumerState<TourIntercomScreen> {
  IntercomViewModel get _notifier => ref.read(intercomProvider.notifier);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final state = ref.read(intercomProvider);
      if (!state.isConnected && !state.isConnecting) {
        if (state.mode == IntercomMode.hosting || state.isHost) {
          _notifier.createTour(
            tourName: widget.tourName ?? state.tourName,
            preGeneratedCode: widget.preGeneratedCode ?? state.joinCode,
          );
        }
      }
    });
  }

  void _handleLeave() {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        title: Text(
          'Leave Tour Channel?',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        content: Text(
          'You will be disconnected from the live mesh voice intercom.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Cancel',
              style: GoogleFonts.plusJakartaSans(color: AppColors.textTertiary),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              Navigator.of(ctx).pop();
              _notifier.leaveIntercom();
              Navigator.of(context).pop();
            },
            child: const Text('Leave'),
          ),
        ],
      ),
    );
  }

  void _handleInvite() {
    HapticFeedback.selectionClick();
    final state = ref.read(intercomProvider);
    final code = state.joinCode ?? state.channelCode;
    TourJoinCodeSheet.show(context, joinCode: code, tourName: state.tourName);
  }

  @override
  Widget build(BuildContext context) {
    final intercomState = ref.watch(intercomProvider);
    final intercomNotifier = ref.read(intercomProvider.notifier);

    return AppScaffold(
      title: 'TOUR INTERCOM',
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPadding,
        vertical: 10,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Header Section: Tour Name, Active Mesh Badge & Overlapping Avatar Stack
            IntercomHeaderSection(
              state: intercomState,
              onMuteToggle: intercomNotifier.toggleMute,
              onLeave: _handleLeave,
              onInvite: _handleInvite,
            ),

            const SizedBox(height: 16),

            // 2. Active Transmission / Connection Status Banner
            _TransmissionBanner(state: intercomState),

            if (intercomState.errorMessage != null) ...[
              const SizedBox(height: 12),
              _ErrorBanner(
                message: intercomState.errorMessage!,
                onRetry: () => intercomNotifier.createTour(
                  tourName: widget.tourName ?? intercomState.tourName,
                ),
              ),
            ],

            const SizedBox(height: 16),

            // 3. The Voice Centerpiece (Hands-Free Call / PTT Button)
            TacticalPttButton(
              isTransmitting: intercomState.isTransmitting,
              isOpenMic: intercomState.isOpenMic,
              isMuted: intercomState.isMuted,
              onTransmittingChanged: intercomNotifier.setTransmitting,
              onToggleMute: intercomNotifier.toggleMute,
              onToggleOpenMic: intercomNotifier.toggleOpenMicMode,
            ),

            const SizedBox(height: 24),

            // 4. Smart Toggles (Glassmorphism Cards)
            IntercomSmartToggles(
              windNoiseEnabled:
                  intercomState.isWindNoiseCancellationEnabled,
              helmetAudioEnabled:
                  intercomState.isHelmetAudioRouteEnabled,
              meshBridgeEnabled: intercomState.isMeshBridgeEnabled,
              onWindNoiseChanged:
                  intercomNotifier.toggleWindNoiseCancellation,
              onHelmetAudioChanged:
                  intercomNotifier.toggleHelmetAudioRoute,
              onMeshBridgeChanged: intercomNotifier.toggleMeshBridge,
            ),

            const SizedBox(height: 16),

            // 5. Rider Tips & Zero Data Mesh Bridge Info
            const IntercomRiderTips(),

            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }
}

/// Dynamic live transmission status banner.
class _TransmissionBanner extends StatelessWidget {
  const _TransmissionBanner({required this.state});

  final IntercomState state;

  @override
  Widget build(BuildContext context) {
    final isTransmitting = state.isTransmitting;
    final isConnecting = state.isConnecting;
    final isConnected = state.isConnected;

    String statusText;
    IconData icon;
    Color iconColor;

    if (isConnected) {
      if (isTransmitting) {
        statusText = 'BROADCASTING TO ${state.onlineCount} RIDERS • LIVE AUDIO';
        icon = Icons.podcasts_rounded;
        iconColor = AppColors.primary;
      } else {
        statusText = 'OFFLINE P2P VOICE ACTIVE • ${state.channelCode.toUpperCase()}';
        icon = Icons.check_circle_outline_rounded;
        iconColor = AppColors.success;
      }
    } else if (isConnecting) {
      statusText = 'CONNECTING TO OFFLINE P2P MESH...';
      icon = Icons.sync_rounded;
      iconColor = AppColors.warning;
    } else {
      statusText = 'STANDBY • TAP & HOLD PTT TO TRANSMIT';
      icon = Icons.radio_button_checked_rounded;
      iconColor = AppColors.textSecondary;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isTransmitting
            ? AppColors.primary.withValues(alpha: 0.18)
            : AppColors.card,
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
        border: Border.all(
          color: isTransmitting
              ? AppColors.primary.withValues(alpha: 0.5)
              : Colors.white.withValues(alpha: 0.06),
          width: 1.2,
        ),
        boxShadow: isTransmitting
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.25),
                  blurRadius: 14,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 14,
            color: iconColor,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              statusText,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
                color: isTransmitting ? AppColors.textPrimary : AppColors.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, size: 16, color: AppColors.error),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.error,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 16, color: AppColors.error),
            onPressed: onRetry,
            tooltip: 'Retry',
          ),
        ],
      ),
    );
  }
}
