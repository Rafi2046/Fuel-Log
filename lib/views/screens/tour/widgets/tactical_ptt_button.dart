import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_motion.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../widgets/clean_glass_panel.dart';

/// Voice intercom centerpiece supporting hands-free and push-to-talk modes.
class TacticalPttButton extends StatefulWidget {
  const TacticalPttButton({
    super.key,
    required this.isTransmitting,
    required this.isOpenMic,
    required this.onTransmittingChanged,
    required this.onToggleMute,
    required this.onToggleOpenMic,
    this.isMuted = false,
  });

  final bool isTransmitting;
  final bool isOpenMic;
  final ValueChanged<bool> onTransmittingChanged;
  final VoidCallback onToggleMute;
  final ValueChanged<bool> onToggleOpenMic;
  final bool isMuted;

  @override
  State<TacticalPttButton> createState() => _TacticalPttButtonState();
}

class _TacticalPttButtonState extends State<TacticalPttButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _pulseAnimation = CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOutSine,
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _onPttTapDown() {
    if (widget.isOpenMic) {
      widget.onToggleMute();
    } else {
      if (widget.isMuted) return;
      widget.onTransmittingChanged(true);
    }
  }

  void _onPttTapUp() {
    if (!widget.isOpenMic) {
      widget.onTransmittingChanged(false);
    }
  }

  String get _title {
    if (widget.isMuted) return 'Mic muted';
    if (widget.isOpenMic) return 'Live call active';
    if (widget.isTransmitting) return 'Transmitting…';
    return 'Tap & hold to speak';
  }

  String get _subtitle {
    if (widget.isMuted) return 'Tap the mic to unmute';
    if (widget.isOpenMic) return 'Hands-free mode is on';
    if (widget.isTransmitting) return 'Release to listen';
    return 'Push-to-talk mode';
  }

  @override
  Widget build(BuildContext context) {
    const buttonSize = 148.0;
    final isLive = widget.isTransmitting && !widget.isMuted;

    return CleanGlassPanel(
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.md,
      ),
      child: Column(
        children: [
          Text(
            'Voice control',
            style: AppTextStyles.label.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (_) => _onPttTapDown(),
            onTapUp: (_) => _onPttTapUp(),
            onTapCancel: _onPttTapUp,
            onPanDown: (_) {
              if (!widget.isOpenMic) widget.onTransmittingChanged(true);
            },
            onPanEnd: (_) {
              if (!widget.isOpenMic) widget.onTransmittingChanged(false);
            },
            onPanCancel: _onPttTapUp,
            child: AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                final pulseVal = _pulseAnimation.value;

                return Column(
                  children: [
                    SizedBox(
                      width: buttonSize + 24,
                      height: buttonSize + 24,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          if (isLive)
                            Container(
                              width: buttonSize + 18 + (pulseVal * 8),
                              height: buttonSize + 18 + (pulseVal * 8),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.primary
                                      .withValues(alpha: 0.18 + pulseVal * 0.1),
                                ),
                              ),
                            ),
                          AnimatedContainer(
                            duration: AppMotion.fast,
                            curve: AppMotion.emphasized,
                            width: buttonSize,
                            height: buttonSize,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isLive
                                  ? AppColors.primary.withValues(alpha: 0.12)
                                  : AppColors.cardElevated,
                              border: Border.all(
                                color: widget.isMuted
                                    ? AppColors.error.withValues(alpha: 0.4)
                                    : (isLive
                                        ? AppColors.primary
                                            .withValues(alpha: 0.45)
                                        : AppColors.border),
                                width: isLive ? 1.5 : 1,
                              ),
                            ),
                            child: Icon(
                              widget.isMuted
                                  ? Icons.mic_off_rounded
                                  : Icons.mic_rounded,
                              size: 44,
                              color: widget.isMuted
                                  ? AppColors.error
                                  : (isLive
                                      ? AppColors.primary
                                      : AppColors.textPrimary),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isLive) ...[
                      const SizedBox(height: AppSpacing.md),
                      _LiveWaveformBars(pulseValue: pulseVal),
                    ],
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            _title,
            style: AppTextStyles.title.copyWith(fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            _subtitle,
            style: AppTextStyles.caption,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(color: AppColors.border),
            ),
            padding: const EdgeInsets.all(3),
            child: Row(
              children: [
                Expanded(
                  child: _ModeChip(
                    label: 'Hands-free',
                    isSelected: widget.isOpenMic,
                    onTap: () => widget.onToggleOpenMic(true),
                  ),
                ),
                Expanded(
                  child: _ModeChip(
                    label: 'Push-to-talk',
                    isSelected: !widget.isOpenMic,
                    onTap: () => widget.onToggleOpenMic(false),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeChip extends StatelessWidget {
  const _ModeChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.cardElevated : Colors.transparent,
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          border: isSelected
              ? Border.all(color: AppColors.border)
              : Border.all(color: Colors.transparent),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: AppTextStyles.label.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color:
                isSelected ? AppColors.textPrimary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _LiveWaveformBars extends StatelessWidget {
  const _LiveWaveformBars({required this.pulseValue});

  final double pulseValue;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final factor =
            math.sin((pulseValue * math.pi * 2) + (index * 0.8)).abs();
        final height = 4.0 + (factor * 10.0);

        return Container(
          width: 3,
          height: height,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(2),
          ),
        );
      }),
    );
  }
}
