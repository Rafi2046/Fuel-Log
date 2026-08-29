import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../widgets/app_primary_button.dart';
import '../../refueling_form_screen.dart';

String _metricTr(String key, {Map<String, String>? replace}) {
  var text = key.tr();
  if (replace != null) {
    for (final entry in replace.entries) {
      text = text.replaceAll('{${entry.key}}', entry.value);
    }
  }
  return text;
}

class MetricExplorerEmptyState extends StatelessWidget {
  const MetricExplorerEmptyState({
    super.key,
    required this.fuelLogCount,
    required this.serviceLogCount,
    required this.categoryIndex,
  });

  final int fuelLogCount;
  final int serviceLogCount;
  final int categoryIndex;

  bool get _needsTwoFuelLogs => categoryIndex != 1;

  @override
  Widget build(BuildContext context) {
    final totalLogs = fuelLogCount + serviceLogCount;
    final logsLabel = _metricTr(
      'metricEmptyLogsInPeriod',
      replace: {'count': '$totalLogs'},
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.04),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                child: const Icon(
                  Icons.insights_outlined,
                  color: AppColors.textSecondary,
                  size: 26,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'metricNoTrendYet'.tr(),
                style: AppTextStyles.title.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'chartNeedMoreLogs'.tr(),
                  textAlign: TextAlign.center,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.35,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 72,
                width: double.infinity,
                child: CustomPaint(
                  painter: MetricEmptySparklinePainter(
                    lineColor: AppColors.primary.withValues(alpha: 0.55),
                    fillColor: AppColors.primary.withValues(alpha: 0.14),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_needsTwoFuelLogs)
          _MetricUnlockSteps(fuelLogCount: fuelLogCount)
        else
          _MetricEmptyInfoLine(text: 'metricEmptyTipCosts'.tr()),
        const SizedBox(height: 10),
        Text(
          logsLabel,
          textAlign: TextAlign.center,
          style: AppTextStyles.caption.copyWith(
            color: AppColors.textTertiary,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 12),
        AppPrimaryButton(
          label: 'actionRefueling'.tr(),
          icon: Icons.local_gas_station_rounded,
          compact: true,
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const RefuelingFormScreen(),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _MetricUnlockSteps extends StatelessWidget {
  const _MetricUnlockSteps({required this.fuelLogCount});

  final int fuelLogCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StepTile(
            label: 'metricEmptyStep1'.tr(),
            done: fuelLogCount >= 1,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Container(
            width: 20,
            height: 1,
            color: Colors.white.withValues(alpha: 0.1),
          ),
        ),
        Expanded(
          child: _StepTile(
            label: 'metricEmptyStep2'.tr(),
            done: fuelLogCount >= 2,
          ),
        ),
      ],
    );
  }
}

class _StepTile extends StatelessWidget {
  const _StepTile({required this.label, required this.done});

  final String label;
  final bool done;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: done
            ? AppColors.primary.withValues(alpha: 0.1)
            : Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: done
              ? AppColors.primary.withValues(alpha: 0.28)
              : Colors.white.withValues(alpha: 0.07),
        ),
      ),
      child: Row(
        children: [
          Icon(
            done ? Icons.check_circle_rounded : Icons.circle_outlined,
            size: 16,
            color: done ? AppColors.primary : AppColors.textTertiary,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: done ? AppColors.textPrimary : AppColors.textSecondary,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricEmptyInfoLine extends StatelessWidget {
  const _MetricEmptyInfoLine({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: AppTextStyles.caption.copyWith(
          color: AppColors.textSecondary,
          fontSize: 11,
          height: 1.35,
        ),
      ),
    );
  }
}

class MetricEmptySparklinePainter extends CustomPainter {
  MetricEmptySparklinePainter({
    required this.lineColor,
    required this.fillColor,
  });

  final Color lineColor;
  final Color fillColor;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    final points = <Offset>[
      Offset(0, size.height * 0.72),
      Offset(size.width * 0.14, size.height * 0.58),
      Offset(size.width * 0.28, size.height * 0.64),
      Offset(size.width * 0.42, size.height * 0.38),
      Offset(size.width * 0.56, size.height * 0.5),
      Offset(size.width * 0.7, size.height * 0.24),
      Offset(size.width * 0.84, size.height * 0.32),
      Offset(size.width, size.height * 0.18),
    ];

    path.moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      final p0 = points[i - 1];
      final p1 = points[i];
      final mid = Offset((p0.dx + p1.dx) / 2, (p0.dy + p1.dy) / 2);
      path.quadraticBezierTo(p0.dx, p0.dy, mid.dx, mid.dy);
    }
    path.lineTo(points.last.dx, points.last.dy);
    canvas.drawPath(path, paint);

    final fill = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            fillColor,
            fillColor.withValues(alpha: 0.0),
          ],
        ).createShader(Offset.zero & size),
    );
  }

  @override
  bool shouldRepaint(covariant MetricEmptySparklinePainter oldDelegate) =>
      oldDelegate.lineColor != lineColor || oldDelegate.fillColor != fillColor;
}
