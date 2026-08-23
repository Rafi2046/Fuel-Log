import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/database/app_database.dart';
import '../screens/chart_fullscreen_page.dart';
import 'advanced_efficiency_chart.dart';
import 'expense_ratio_chart.dart';

/// Swipeable analytics with pill indicators + fullscreen expand.
class AnalyticsCarousel extends StatefulWidget {
  const AnalyticsCarousel({
    super.key,
    required this.logs,
    required this.mileageUnit,
    this.chartHeight = 220,
  });

  final List<FuelLog> logs;
  final String mileageUnit;
  final double chartHeight;

  @override
  State<AnalyticsCarousel> createState() => _AnalyticsCarouselState();
}

class _AnalyticsCarouselState extends State<AnalyticsCarousel> {
  final _controller = PageController();
  int _page = 0;

  String get _title =>
      _page == 0 ? 'consumption'.tr() : 'expenseRatio'.tr();

  Widget _chartFor(int index) {
    if (index == 0) {
      return AdvancedEfficiencyChart(
        logs: widget.logs,
        unit: widget.mileageUnit,
      );
    }
    return ExpenseRatioChart(logs: widget.logs);
  }

  Future<void> _openFullscreen() {
    return ChartFullscreenPage.open(
      context,
      title: _title,
      child: _chartFor(_page),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              _title,
              style: AppTextStyles.label.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            IconButton(
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              tooltip: 'expandChart'.tr(),
              onPressed: _openFullscreen,
              icon: const Icon(
                Icons.open_in_full_rounded,
                size: 18,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Container(
          height: widget.chartHeight,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.cardElevated,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(color: AppColors.border),
          ),
          child: PageView(
            controller: _controller,
            onPageChanged: (i) => setState(() => _page = i),
            children: [
              _chartFor(0),
              _chartFor(1),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(2, (i) {
            final active = i == _page;
            return GestureDetector(
              onTap: () => _controller.animateToPage(
                i,
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOut,
              ),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: active ? 18 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: active ? AppColors.primary : AppColors.textTertiary,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}
