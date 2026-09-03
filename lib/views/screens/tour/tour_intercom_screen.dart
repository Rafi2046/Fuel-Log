import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../viewmodels/intercom_viewmodel.dart';
import '../../widgets/app_scaffold.dart';
import 'widgets/intercom_header_section.dart';
import 'widgets/intercom_rider_role_selector.dart';
import 'widgets/intercom_role_status_card.dart';
import 'widgets/intercom_smart_toggles.dart';
import 'widgets/tactical_ptt_button.dart';
import 'widgets/tour_join_code_sheet.dart';

/// Active intercom screen for live motorcycle tour communication.
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

class _TourIntercomScreenState extends ConsumerState<TourIntercomScreen>
    with WidgetsBindingObserver {
  IntercomViewModel get _notifier => ref.read(intercomProvider.notifier);
  bool _isUserLeaving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
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

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _notifier.onAppLifecycleChanged(state);
  }

  void _handleLeave() {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          side: BorderSide(color: AppColors.border),
        ),
        title: Text(
          'Leave tour?',
          style: AppTextStyles.title.copyWith(fontSize: 16),
        ),
        content: Text(
          'You will be disconnected from the live voice intercom.',
          style: AppTextStyles.caption.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Cancel',
              style: AppTextStyles.label.copyWith(color: AppColors.textTertiary),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              _isUserLeaving = true;
              Navigator.of(ctx).pop();
              _notifier.leaveIntercom();
              if (mounted && ModalRoute.of(context)?.isCurrent == true) {
                Navigator.of(context).pop();
              }
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

  String _footerTip(IntercomState state) {
    if (state.isPillionMode) {
      return 'Pillion tip: plug in earphones, lock your phone, and use the notification '
          'or headset button to talk.';
    }
    if (state.isDriverMode) {
      return 'Driver tip: hold PTT or a volume button to talk. Intercom stays active on the lock screen.';
    }
    return 'Tip: press and hold a volume button for push-to-talk with gloves on.';
  }

  @override
  Widget build(BuildContext context) {
    final intercomState = ref.watch(intercomProvider);
    final intercomNotifier = ref.read(intercomProvider.notifier);

    ref.listen<IntercomState>(intercomProvider, (previous, next) {
      if (_isUserLeaving) return;
      if (previous?.isConnected == true &&
          !next.isConnected &&
          next.mode == IntercomMode.idle &&
          mounted &&
          ModalRoute.of(context)?.isCurrent == true) {
        Navigator.of(context).maybePop();
        return;
      }

      if (previous != null && previous.isConnected && next.isConnected && mounted) {
        final prevCount = previous.members.where((m) => !m.isCurrentUser).length;
        final nextCount = next.members.where((m) => !m.isCurrentUser).length;
        if (nextCount > prevCount) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle_rounded, color: AppColors.success, size: 18),
                  SizedBox(width: 8),
                  Text('Rider connected to tour'),
                ],
              ),
              backgroundColor: AppColors.cardElevated,
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else if (nextCount < prevCount) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 18),
                  SizedBox(width: 8),
                  Text('Rider out of range / disconnected'),
                ],
              ),
              backgroundColor: AppColors.cardElevated,
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    });

    return AppScaffold(
      title: 'Tour intercom',
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        AppSpacing.appBarBodyGap,
        AppSpacing.screenPadding,
        0,
      ),
      body: ListView(
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.only(bottom: AppSpacing.xl),
        children: [
          IntercomHeaderSection(
            state: intercomState,
            onInvite: _handleInvite,
            onMuteToggle: intercomNotifier.toggleMute,
            onLeave: _handleLeave,
          ),
          if (intercomState.errorMessage != null) ...[
            const SizedBox(height: AppSpacing.sm),
            _ErrorBanner(
              message: intercomState.errorMessage!,
              onRetry: () => intercomNotifier.createTour(
                tourName: widget.tourName ?? intercomState.tourName,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          IntercomRoleStatusCard(state: intercomState),
          const SizedBox(height: AppSpacing.md),
          IntercomRiderRoleSelector(
            compact: true,
            selectedRole: intercomState.riderRole,
            onRoleChanged: intercomNotifier.setRiderRole,
          ),
          const SizedBox(height: AppSpacing.md),
          TacticalPttButton(
            isTransmitting: intercomState.isTransmitting,
            isOpenMic: intercomState.isOpenMic,
            isMuted: intercomState.isMuted,
            onTransmittingChanged: intercomNotifier.setTransmitting,
            onToggleMute: intercomNotifier.toggleMute,
            onToggleOpenMic: intercomNotifier.toggleOpenMicMode,
          ),
          const SizedBox(height: AppSpacing.lg),
          IntercomSmartToggles(
            windNoiseEnabled: intercomState.isWindNoiseCancellationEnabled,
            helmetAudioEnabled: intercomState.isHelmetAudioRouteEnabled,
            loudspeakerEnabled: intercomState.isLoudspeakerEnabled,
            riderRole: intercomState.riderRole,
            meshBridgeEnabled: intercomState.isMeshBridgeEnabled,
            fecRecoveryEnabled: intercomState.isFecRecoveryEnabled,
            onWindNoiseChanged: intercomNotifier.toggleWindNoiseCancellation,
            onHelmetAudioChanged: intercomNotifier.toggleHelmetAudioRoute,
            onLoudspeakerChanged: intercomNotifier.toggleLoudspeaker,
            onMeshBridgeChanged: intercomNotifier.toggleMeshBridge,
            onFecRecoveryChanged: intercomNotifier.toggleFecRecovery,
          ),
          SizedBox(height: AppSpacing.lg),
          Text(
            _footerTip(intercomState),
            textAlign: TextAlign.center,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textTertiary,
              height: 1.4,
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
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, size: 16, color: AppColors.error),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.caption.copyWith(
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
