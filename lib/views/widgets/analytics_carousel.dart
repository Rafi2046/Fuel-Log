import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/database/app_database.dart';
import '../screens/chart_fullscreen_page.dart';
import 'advanced_efficiency_chart.dart';
import 'expense_ratio_chart.dart';

/// Swipeable analytics — expand control lives inside the chart card.
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

  Widget _chartFor(int index, {required bool fullscreen}) {
    if (index == 0) {
      return AdvancedEfficiencyChart(
        logs: widget.logs,
        unit: widget.mileageUnit,
        scrollable: fullscreen,
      );
    }
    return ExpenseRatioChart(logs: widget.logs);
  }

  Future<void> _openFullscreen() {
    return ChartFullscreenPage.open(
      context,
      title: _title,
      child: _chartFor(_page, fullscreen: true),
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
        Text(
          _title,
          style: AppTextStyles.label.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w600,
          ),
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
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              Positioned.fill(
                child: PageView(
                  controller: _controller,
                  onPageChanged: (i) => setState(() => _page = i),
                  children: [
                    _chartFor(0, fullscreen: false),
                    _chartFor(1, fullscreen: false),
                  ],
                ),
              ),
              Positioned(
                top: 6,
                right: 6,
                child: Material(
                  color: AppColors.background.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  child: InkWell(
                    onTap: _openFullscreen,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    child: Tooltip(
                      message: 'expandChart'.tr(),
                      child: const Padding(
                        padding: EdgeInsets.all(8),
                        child: Icon(
                          Icons.open_in_full_rounded,
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
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
