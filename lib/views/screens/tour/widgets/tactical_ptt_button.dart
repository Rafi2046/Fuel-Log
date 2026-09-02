import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_motion.dart';
import '../../../../core/constants/app_spacing.dart';

/// Tactical Voice Intercom Centerpiece supporting:
/// 1. Hands-Free Open Call Mode (biker doesn't need to touch screen while riding)
/// 2. Push-to-Talk (PTT) Walkie-Talkie Mode
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

  @override
  Widget build(BuildContext context) {
    const buttonSize = 210.0;
    final isTransmitting = widget.isTransmitting;
    final isMuted = widget.isMuted;
    final isOpenMic = widget.isOpenMic;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Center(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (_) => _onPttTapDown(),
            onTapUp: (_) => _onPttTapUp(),
            onTapCancel: _onPttTapUp,
            onPanDown: (_) {
              if (!isOpenMic) widget.onTransmittingChanged(true);
            },
            onPanEnd: (_) {
              if (!isOpenMic) widget.onTransmittingChanged(false);
            },
            onPanCancel: _onPttTapUp,
            child: AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                final pulseVal = _pulseAnimation.value;
                final isLive = isTransmitting && !isMuted;

                return SizedBox(
                  width: buttonSize + 50,
                  height: buttonSize + 50,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Outer Ambient Glow Aura
                      AnimatedContainer(
                        duration: AppMotion.fast,
                        curve: AppMotion.emphasized,
                        width: isLive
                            ? buttonSize + 44 + (pulseVal * 12)
                            : buttonSize + 20,
                        height: isLive
                            ? buttonSize + 44 + (pulseVal * 12)
                            : buttonSize + 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: isLive
                                ? [
                                    AppColors.primary.withValues(
                                      alpha: 0.35 + (pulseVal * 0.15),
                                    ),
                                    AppColors.primary.withValues(alpha: 0.08),
                                    Colors.transparent,
                                  ]
                                : [
                                    AppColors.primary.withValues(
                                      alpha: 0.06 + (pulseVal * 0.04),
                                    ),
                                    Colors.transparent,
                                  ],
                          ),
                        ),
                      ),

                      // Concentric Tactical Radar Ring
                      AnimatedContainer(
                        duration: AppMotion.fast,
                        curve: AppMotion.emphasized,
                        width: isLive ? buttonSize + 24 : buttonSize + 16,
                        height: isLive ? buttonSize + 24 : buttonSize + 16,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isLive
                                ? AppColors.primary.withValues(alpha: 0.6)
                                : AppColors.primary.withValues(alpha: 0.15),
                            width: isLive ? 1.8 : 1.0,
                          ),
                        ),
                      ),

                      // Main Button Core
                      AnimatedScale(
                        scale: isLive ? 0.96 : 1.0,
                        duration: AppMotion.fast,
                        curve: AppMotion.emphasized,
                        child: AnimatedContainer(
                          duration: AppMotion.fast,
                          curve: AppMotion.emphasized,
                          width: buttonSize,
                          height: buttonSize,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.card,
                            gradient: isLive
                                ? RadialGradient(
                                    colors: [
                                      AppColors.primary.withValues(alpha: 0.3),
                                      const Color(0xFF261814),
                                      AppColors.card,
                                    ],
                                    radius: 0.85,
                                  )
                                : const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Color(0xFF242424),
                                      Color(0xFF1A1A1A),
                                      Color(0xFF141414),
                                    ],
                                  ),
                            border: Border.all(
                              color: isLive
                                  ? AppColors.primary
                                  : (isMuted
                                      ? AppColors.error.withValues(alpha: 0.6)
                                      : AppColors.primaryMuted),
                              width: isLive ? 2.5 : 1.5,
                            ),
                            boxShadow: [
                              if (isLive) ...[
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.6),
                                  blurRadius: 36,
                                  spreadRadius: 4,
                                ),
                                BoxShadow(
                                  color: AppColors.secondary.withValues(alpha: 0.3),
                                  blurRadius: 60,
                                  spreadRadius: 8,
                                ),
                              ] else ...[
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.6),
                                  blurRadius: 18,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Center Tactical Icon
                              AnimatedContainer(
                                duration: AppMotion.fast,
                                padding: const EdgeInsets.all(15),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isLive
                                      ? AppColors.primary.withValues(alpha: 0.22)
                                      : (isMuted
                                          ? AppColors.error.withValues(alpha: 0.15)
                                          : AppColors.cardElevated),
                                  border: Border.all(
                                    color: isLive
                                        ? AppColors.primary
                                        : (isMuted
                                            ? AppColors.error
                                            : Colors.white.withValues(alpha: 0.08)),
                                    width: isLive ? 1.5 : 1.0,
                                  ),
                                ),
                                child: Icon(
                                  isMuted
                                      ? Icons.mic_off_rounded
                                      : (isLive
                                          ? Icons.record_voice_over_rounded
                                          : Icons.mic_rounded),
                                  size: 38,
                                  color: isMuted
                                      ? AppColors.error
                                      : (isLive
                                          ? AppColors.primary
                                          : AppColors.textPrimary),
                                ),
                              ),

                              const SizedBox(height: 12),

                              // Audio Frequency Wave Bars or Status
                              if (isLive)
                                _LiveWaveformBars(pulseValue: pulseVal)
                              else
                                const SizedBox(height: 8),

                              const SizedBox(height: 8),

                              // State Text
                              AnimatedDefaultTextStyle(
                                duration: AppMotion.fast,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: isLive ? 13 : 11,
                                  fontWeight: isLive ? FontWeight.w800 : FontWeight.w600,
                                  letterSpacing: isLive ? 1.4 : 1.0,
                                  color: isMuted
                                      ? AppColors.error
                                      : (isLive
                                          ? AppColors.textPrimary
                                          : AppColors.textSecondary),
                                  shadows: isLive
                                      ? [
                                          Shadow(
                                            color: AppColors.primary.withValues(alpha: 0.8),
                                            blurRadius: 12,
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Text(
                                  isMuted
                                      ? 'MIC MUTED'
                                      : (isOpenMic
                                          ? '🎙️ LIVE CALL ACTIVE'
                                          : (isTransmitting
                                              ? '● TRANSMITTING...'
                                              : 'TAP & HOLD TO SPEAK')),
                                  textAlign: TextAlign.center,
                                ),
                              ),

                              const SizedBox(height: 4),
                              Text(
                                isMuted
                                    ? 'Tap to Unmute'
                                    : (isOpenMic
                                        ? 'Hands-Free • Speak anytime'
                                        : 'Release to listen'),
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w400,
                                  color: AppColors.textTertiary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),

        const SizedBox(height: 14),

        // Mode Switcher Pill (Hands-Free Call vs PTT)
        Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          padding: const EdgeInsets.all(3),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ModeChip(
                label: '🎙️ Hands-Free Call',
                isSelected: isOpenMic,
                onTap: () => widget.onToggleOpenMic(true),
              ),
              const SizedBox(width: 4),
              _ModeChip(
                label: '🔘 Push-to-Talk',
                isSelected: !isOpenMic,
                onTap: () => widget.onToggleOpenMic(false),
              ),
            ],
          ),
        ),
      ],
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
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.35),
                    blurRadius: 8,
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

/// Simulated live audio spectrum equalizer bars.
class _LiveWaveformBars extends StatelessWidget {
  const _LiveWaveformBars({required this.pulseValue});

  final double pulseValue;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(7, (index) {
        final factor = math.sin((pulseValue * math.pi * 2) + (index * 0.8)).abs();
        final height = 6.0 + (factor * 16.0);

        return Container(
          width: 3.5,
          height: height,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: index == 3 ? AppColors.primary : AppColors.secondary,
            borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.6),
                blurRadius: 4,
              ),
            ],
          ),
        );
      }),
    );
  }
}
