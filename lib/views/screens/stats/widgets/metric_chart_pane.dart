import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/database/app_database.dart';
import '../../../widgets/advanced_efficiency_chart.dart';
import '../../../widgets/app_primary_button.dart';
import '../../../widgets/cost_per_km_chart.dart';
import '../../../widgets/fill_up_cost_chart.dart';
import '../../../widgets/fuel_price_chart.dart';
import '../../../widgets/odometer_growth_chart.dart';
import 'metric_chart_empty.dart';
import 'metric_monthly_distance_panel.dart';
import 'metric_monthly_spend_panel.dart';

/// Flat page order for horizontal swipe across all metric tabs.
abstract final class MetricExplorerPages {
  static const slots = <({int category, int sub})>[
    (category: 0, sub: 0),
    (category: 0, sub: 1),
    (category: 0, sub: 2),
    (category: 1, sub: 0),
    (category: 1, sub: 1),
    (category: 2, sub: 0),
    (category: 2, sub: 1),
  ];

  static int flatIndex(int category, int sub) {
    return slots.indexWhere(
      (slot) => slot.category == category && slot.sub == sub,
    );
  }
}

class MetricChartPane extends StatefulWidget {
  const MetricChartPane({
    super.key,
    required this.categoryIndex,
    required this.subMetricIndex,
    required this.onPageChanged,
    required this.fuelLogs,
    required this.serviceLogs,
    required this.mileageUnit,
    required this.isEV,
  });

  final int categoryIndex;
  final int subMetricIndex;
  final void Function(int category, int sub) onPageChanged;
  final List<FuelLog> fuelLogs;
  final List<ServiceLog> serviceLogs;
  final String mileageUnit;
  final bool isEV;

  @override
  State<MetricChartPane> createState() => _MetricChartPaneState();
}

class _MetricChartPaneState extends State<MetricChartPane> {
  late PageController _pageController;
  int? _suppressSyncForIndex;

  bool _hasDataFor(int category) {
    if (category == 1) {
      return widget.fuelLogs.isNotEmpty || widget.serviceLogs.isNotEmpty;
    }
    return widget.fuelLogs.length >= 2;
  }

  List<String> _subMetricLabels(int category) {
    if (category == 0) {
      return [
        'metricSubConsumption'.tr(),
        'metricSubPrice'.tr(),
        'metricSubFillUps'.tr(),
      ];
    }
    if (category == 1) {
      return [
        'metricSubMonthlySpend'.tr(),
        'metricKpiCostPerKm'.tr(),
      ];
    }
    return [
      'metricSubMonthlyKm'.tr(),
      'metricSubOdometer'.tr(),
    ];
  }

  @override
  void initState() {
    super.initState();
    final initial = MetricExplorerPages.flatIndex(
      widget.categoryIndex,
      widget.subMetricIndex,
    );
    _pageController = PageController(
      initialPage: initial < 0 ? 0 : initial,
    );
  }

  @override
  void didUpdateWidget(MetricChartPane oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.categoryIndex == widget.categoryIndex &&
        oldWidget.subMetricIndex == widget.subMetricIndex) {
      return;
    }
    final target = MetricExplorerPages.flatIndex(
      widget.categoryIndex,
      widget.subMetricIndex,
    );
    if (target < 0) return;
    if (_suppressSyncForIndex == target) {
      _suppressSyncForIndex = null;
      return;
    }
    _schedulePageJump(target);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _schedulePageJump(int target) {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_pageController.hasClients) return;
      final current = _pageController.page?.round();
      if (current == target) return;
      _pageController.animateToPage(
        target,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    });
  }

  void _handlePageChanged(int index) {
    _suppressSyncForIndex = index;
    final slot = MetricExplorerPages.slots[index];
    widget.onPageChanged(slot.category, slot.sub);
  }

  void _goToPage(int category, int sub) {
    final target = MetricExplorerPages.flatIndex(category, sub);
    if (target < 0) return;
    _suppressSyncForIndex = target;
    widget.onPageChanged(category, sub);
    _schedulePageJump(target);
  }

  @override
  Widget build(BuildContext context) {
    final labels = _subMetricLabels(widget.categoryIndex);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.card,
            AppColors.card.withValues(alpha: 0.92),
          ],
        ),
        border: Border.all(color: AppColors.washBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 16, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _subMetricRow(labels),
              const SizedBox(height: 8),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  clipBehavior: Clip.hardEdge,
                  onPageChanged: _handlePageChanged,
                  children: [
                    for (final slot in MetricExplorerPages.slots)
                      KeyedSubtree(
                        key: ValueKey(
                          'chart_${slot.category}_${slot.sub}',
                        ),
                        child: _hasDataFor(slot.category)
                            ? _chartFor(slot.category, slot.sub)
                            : MetricExplorerEmptyState(
                                fuelLogCount: widget.fuelLogs.length,
                                serviceLogCount: widget.serviceLogs.length,
                                categoryIndex: slot.category,
                              ),
                      ),
                  ],
                ),
              ),
              if (!_hasDataFor(widget.categoryIndex)) ...[
                const SizedBox(height: 10),
                AppPrimaryButton(
                  label: 'actionRefueling'.tr(),
                  icon: Icons.local_gas_station_rounded,
                  compact: true,
                  onPressed: () => openMetricRefueling(context),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _subMetricRow(List<String> options) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.wash,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (var i = 0; i < options.length; i++) ...[
              if (i > 0) const SizedBox(width: 4),
              MetricChartTab(
                label: options[i],
                selected: widget.subMetricIndex == i,
                onTap: () => _goToPage(widget.categoryIndex, i),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _chartFor(int category, int subMetricIndex) {
    if (category == 0) {
      if (subMetricIndex == 0) {
        return AdvancedEfficiencyChart(
          logs: widget.fuelLogs,
          unit: widget.mileageUnit,
        );
      } else if (subMetricIndex == 1) {
        return FuelPriceChart(
          logs: widget.fuelLogs,
          priceUnit: widget.isEV ? '৳/kWh' : '৳/L',
        );
      }
      return FillUpCostChart(logs: widget.fuelLogs);
    }
    if (category == 1) {
      if (subMetricIndex == 0) {
        return MetricMonthlySpendPanel(
          fuelLogs: widget.fuelLogs,
          serviceLogs: widget.serviceLogs,
        );
      }
      return CostPerKmChart(
        fuelLogs: widget.fuelLogs,
        serviceLogs: widget.serviceLogs,
      );
    }
    if (subMetricIndex == 0) {
      return MetricMonthlyDistancePanel(logs: widget.fuelLogs);
    }
    return OdometerGrowthChart(logs: widget.fuelLogs);
  }
}

class MetricChartTab extends StatelessWidget {
  const MetricChartTab({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppSpacing.radiusSm);
    return Material(
      color: selected
          ? AppColors.primary.withValues(alpha: 0.14)
          : Colors.transparent,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(
              color: selected
                  ? AppColors.primary.withValues(alpha: 0.3)
                  : Colors.transparent,
            ),
          ),
          child: Text(
            label,
            style: AppTextStyles.label.copyWith(
              color: selected ? AppColors.textPrimary : AppColors.textSecondary,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}
