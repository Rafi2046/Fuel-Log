import 'package:flutter/material.dart';
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

/// Premium tactical "Push-to-Talk" (PTT) Bike Tour Intercom Screen.
/// Backed by low-latency Offline P2P UDP Voice Mesh.
class TourIntercomScreen extends ConsumerStatefulWidget {
  const TourIntercomScreen({
    super.key,
    this.tourName,
    this.channelName,
  });

  final String? tourName;
  final String? channelName;

  @override
  ConsumerState<TourIntercomScreen> createState() => _TourIntercomScreenState();
}

class _TourIntercomScreenState extends ConsumerState<TourIntercomScreen> {
  // Pre-captured notifier reference — safe to call in dispose() without ref.
  late final IntercomViewModel _notifier;

  @override
  void initState() {
    super.initState();
    // ref.read() is valid synchronously in initState for ConsumerStatefulWidget.
    // Capture it now so build() and dispose() can use _notifier safely.
    _notifier = ref.read(intercomProvider.notifier);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (widget.tourName != null) {
        _notifier.setTourName(widget.tourName!);
      }
      // If we aren't connected yet (opened directly without lobby), start hosting
      if (!ref.read(intercomProvider).isConnected) {
        _notifier.createTour(tourName: widget.tourName ?? 'My Bike Tour');
      }
    });
  }

  @override
  void dispose() {
    // Safe: uses pre-captured reference — does NOT call ref after unmount.
    _notifier.leaveIntercom();
    super.dispose();
  }

  Future<void> _handleLeave() async {
    await _notifier.leaveIntercom();
    if (mounted) {
      Navigator.of(context).maybePop();
    }
  }

  void _handleInvite() {
    final state = ref.read(intercomProvider);
    if (state.joinCode != null) {
      TourJoinCodeSheet.show(
        context,
        joinCode: state.joinCode!,
        tourName: state.tourName,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final intercomState = ref.watch(intercomProvider);
    final intercomNotifier = _notifier;

    return AppScaffold(
      leading: AppBackButton(
        onPressed: _handleLeave,
      ),
      titleWidget: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withValues(alpha: 0.16),
            ),
            child: const Icon(
              Icons.sensors_rounded,
              size: 16,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'TOUR INTERCOM',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
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

    if (isTransmitting) {
      statusText = 'BROADCASTING TO ${state.onlineCount} RIDERS • LIVE AUDIO';
      icon = Icons.podcasts_rounded;
      iconColor = AppColors.primary;
    } else if (isConnecting) {
      statusText = 'CONNECTING TO OFFLINE P2P MESH...';
      icon = Icons.sync_rounded;
      iconColor = AppColors.warning;
    } else if (isConnected) {
      statusText = 'OFFLINE P2P VOICE ACTIVE • ${state.channelCode.toUpperCase()}';
      icon = Icons.check_circle_outline_rounded;
      iconColor = AppColors.success;
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
                color: isTransmitting
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
                letterSpacing: 0.9,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// Banner showing error or permission required message.
class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: AppColors.error.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: AppColors.error,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              foregroundColor: AppColors.primary,
            ),
            child: const Text('Retry', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
