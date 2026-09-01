import 'dart:math' as math;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_text_styles.dart';

/// Compact odometer-style efficiency ring for the Home dashboard.
class EfficiencyGauge extends StatelessWidget {
  const EfficiencyGauge({
    super.key,
    required this.value,
    required this.unit,
    this.size = 168,
  });

  final double value;
  final String unit;
  final double size;

  /// Maps mileage onto a 0–1 arc fill (ICE ~25 km/L scale, EV ~8 km/kWh).
  double get _progress {
    if (value <= 0) return 0;
    final maxScale = unit.contains('kWh') ? 8.0 : 25.0;
    return (value / maxScale).clamp(0.0, 1.0);
  }

  String get _statusKey {
    if (value <= 0) return 'statusNeedMore';
    final isEv = unit.contains('kWh');
    if (isEv) {
      if (value < 3) return 'statusLow';
      if (value < 5) return 'statusFair';
      return 'statusOptimal';
    }
    if (value < 8) return 'statusLow';
    if (value < 12) return 'statusFair';
    return 'statusOptimal';
  }

  Color get _statusColor {
    switch (_statusKey) {
      case 'statusOptimal':
        return AppColors.success;
      case 'statusFair':
        return AppColors.warning;
      case 'statusLow':
        return AppColors.error;
      default:
        return AppColors.textTertiary;
    }
  }

  IconData get _statusIcon {
    switch (_statusKey) {
      case 'statusOptimal':
        return Icons.trending_up_rounded;
      case 'statusFair':
        return Icons.trending_flat_rounded;
      case 'statusLow':
        return Icons.trending_down_rounded;
      default:
        return Icons.info_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasValue = value > 0;

    return SizedBox(
      width: size,
      height: size,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: _progress),
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeOutCubic,
        builder: (context, progress, _) {
          return CustomPaint(
            painter: _GaugePainter(
              progress: progress,
              trackColor: AppColors.primary.withValues(alpha: 0.12),
              progressColor: AppColors.primary,
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'efficiency'.tr().toUpperCase(),
                    style: AppTextStyles.caption.copyWith(
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w600,
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        hasValue ? value.toStringAsFixed(1) : '—',
                        style: AppTextStyles.display.copyWith(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          height: 1,
                        ),
                      ),
                      if (hasValue) ...[
                        const SizedBox(width: 4),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 3),
                          child: Text(
                            unit,
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: _statusColor.withValues(alpha: 0.15),
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusPill),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_statusIcon, size: 12, color: _statusColor),
                        const SizedBox(width: 3),
                        Flexible(
                          child: Text(
                            _statusKey.tr(),
                            style: AppTextStyles.caption.copyWith(
                              color: _statusColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 10,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  _GaugePainter({
    required this.progress,
    required this.trackColor,
    required this.progressColor,
  });

  final double progress;
  final Color trackColor;
  final Color progressColor;

  static const double _startAngle = math.pi * 0.75;
  static const double _sweepAngle = math.pi * 1.5;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final stroke = size.width * 0.065;
    final radius = (size.shortestSide - stroke) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, _startAngle, _sweepAngle, false, trackPaint);

    if (progress <= 0) return;

    final glowPaint = Paint()
      ..color = progressColor.withValues(alpha: 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke + 5
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);

    final progressPaint = Paint()
      ..shader = SweepGradient(
        startAngle: _startAngle,
        endAngle: _startAngle + _sweepAngle,
        colors: [
          progressColor.withValues(alpha: 0.55),
          progressColor,
          AppColors.secondary,
        ],
        stops: const [0.0, 0.55, 1.0],
        transform: const GradientRotation(_startAngle),
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    final sweep = _sweepAngle * progress;
    canvas.drawArc(rect, _startAngle, sweep, false, glowPaint);
    canvas.drawArc(rect, _startAngle, sweep, false, progressPaint);
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.progressColor != progressColor ||
        oldDelegate.trackColor != trackColor;
  }
}
