import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_motion.dart';
import '../../../../core/constants/app_spacing.dart';

/// Massive tactical Push-to-Talk (PTT) centerpiece button with deep neon coral glow.
class TacticalPttButton extends StatefulWidget {
  const TacticalPttButton({
    super.key,
    required this.isTransmitting,
    required this.onTransmittingChanged,
    this.isMuted = false,
  });

  final bool isTransmitting;
  final ValueChanged<bool> onTransmittingChanged;
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

  void _startTransmitting() {
    if (widget.isMuted) return;
    widget.onTransmittingChanged(true);
  }

  void _stopTransmitting() {
    widget.onTransmittingChanged(false);
  }

  @override
  Widget build(BuildContext context) {
    const buttonSize = 220.0;
    final isTransmitting = widget.isTransmitting;
    final isMuted = widget.isMuted;

    return Center(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _startTransmitting(),
        onTapUp: (_) => _stopTransmitting(),
        onTapCancel: _stopTransmitting,
        onPanDown: (_) => _startTransmitting(),
        onPanEnd: (_) => _stopTransmitting(),
        onPanCancel: _stopTransmitting,
        onLongPressStart: (_) => _startTransmitting(),
        onLongPressEnd: (_) => _stopTransmitting(),
        onLongPressCancel: _stopTransmitting,
        child: AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            final pulseVal = _pulseAnimation.value;

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
                    width: isTransmitting
                        ? buttonSize + 44 + (pulseVal * 12)
                        : buttonSize + 20,
                    height: isTransmitting
                        ? buttonSize + 44 + (pulseVal * 12)
                        : buttonSize + 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: isTransmitting
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
                    width: isTransmitting ? buttonSize + 24 : buttonSize + 16,
                    height: isTransmitting ? buttonSize + 24 : buttonSize + 16,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isTransmitting
                            ? AppColors.primary.withValues(alpha: 0.6)
                            : AppColors.primary.withValues(alpha: 0.15),
                        width: isTransmitting ? 1.8 : 1.0,
                      ),
                    ),
                  ),

                  // Main Button Core with Transform Scale
                  AnimatedScale(
                    scale: isTransmitting ? 0.94 : 1.0,
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
                        gradient: isTransmitting
                            ? RadialGradient(
                                colors: [
                                  AppColors.primary.withValues(alpha: 0.28),
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
                          color: isTransmitting
                              ? AppColors.primary
                              : (isMuted
                                  ? AppColors.error.withValues(alpha: 0.4)
                                  : AppColors.primaryMuted),
                          width: isTransmitting ? 2.5 : 1.5,
                        ),
                        boxShadow: [
                          if (isTransmitting) ...[
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
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.08),
                              blurRadius: 16,
                              spreadRadius: 1,
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
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isTransmitting
                                  ? AppColors.primary.withValues(alpha: 0.22)
                                  : (isMuted
                                      ? AppColors.error.withValues(alpha: 0.12)
                                      : AppColors.cardElevated),
                              border: Border.all(
                                color: isTransmitting
                                    ? AppColors.primary
                                    : (isMuted
                                        ? AppColors.error
                                        : Colors.white.withValues(alpha: 0.06)),
                                width: isTransmitting ? 1.5 : 1.0,
                              ),
                            ),
                            child: Icon(
                              isMuted
                                  ? Icons.mic_off_rounded
                                  : (isTransmitting
                                      ? Icons.record_voice_over_rounded
                                      : Icons.mic_rounded),
                              size: 40,
                              color: isMuted
                                  ? AppColors.error
                                  : (isTransmitting
                                      ? AppColors.primary
                                      : AppColors.textPrimary),
                            ),
                          ),

                          const SizedBox(height: 14),

                          // Audio Frequency / Wave Bars (when transmitting) or idle status
                          if (isTransmitting)
                            _LiveWaveformBars(pulseValue: pulseVal)
                          else
                            const SizedBox(height: 8),

                          const SizedBox(height: 10),

                          // State Text
                          AnimatedDefaultTextStyle(
                            duration: AppMotion.fast,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: isTransmitting ? 13 : 11,
                              fontWeight: isTransmitting
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                              letterSpacing: isTransmitting ? 1.6 : 1.2,
                              color: isMuted
                                  ? AppColors.error
                                  : (isTransmitting
                                      ? AppColors.textPrimary
                                      : AppColors.textSecondary),
                              shadows: isTransmitting
                                  ? [
                                      Shadow(
                                        color: AppColors.primary
                                            .withValues(alpha: 0.8),
                                        blurRadius: 12,
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Text(
                              isMuted
                                  ? 'MIC IS MUTED'
                                  : (isTransmitting
                                      ? '● TRANSMITTING...'
                                      : 'TAP & HOLD TO SPEAK'),
                              textAlign: TextAlign.center,
                            ),
                          ),

                          if (!isTransmitting && !isMuted) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Release to listen',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w400,
                                color: AppColors.textTertiary,
                              ),
                            ),
                          ],
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
