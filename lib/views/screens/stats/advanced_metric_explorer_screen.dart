import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/database/app_database.dart';
import '../../../core/utils/analytics_period.dart';
import '../../../core/utils/app_formatters.dart';
import '../../../viewmodels/fuel_log_viewmodel.dart';
import '../../../viewmodels/service_log_viewmodel.dart';
import '../../../viewmodels/vehicle_viewmodel.dart';
import '../../widgets/app_app_bar.dart';
import '../reports/reports_screen.dart';
import 'widgets/metric_overview_card.dart';
import 'widgets/metric_chart_pane.dart';
import 'widgets/metric_date_range_picker.dart';
import 'widgets/metric_filter_chips.dart';

/// Deep analytics — airy premium layout (filters + chart).
class AdvancedMetricExplorerScreen extends ConsumerStatefulWidget {
  const AdvancedMetricExplorerScreen({super.key});

  static Future<void> open(BuildContext context) {
    return Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AdvancedMetricExplorerScreen()),
    );
  }

  @override
  ConsumerState<AdvancedMetricExplorerScreen> createState() =>
      _AdvancedMetricExplorerScreenState();
}

class _AdvancedMetricExplorerScreenState
    extends ConsumerState<AdvancedMetricExplorerScreen> {
  PeriodFilter _period = PeriodFilter.last6Months;
  DateTimeRange? _customRange;
  int _categoryIndex = 0;
  final _subMetricIndices = [0, 0, 0];

  void _setCategory(int index) {
    if (index == _categoryIndex) return;
    setState(() => _categoryIndex = index);
  }

  void _onMetricPageChanged(int category, int sub) {
    if (_categoryIndex == category && _subMetricIndices[category] == sub) {
      return;
    }
    setState(() {
      _categoryIndex = category;
      _subMetricIndices[category] = sub;
    });
  }

  void _swipeToNextCategory() {
    if (_categoryIndex >= 2) return;
    _setCategory(_categoryIndex + 1);
  }

  void _swipeToPreviousCategory() {
    if (_categoryIndex <= 0) return;
    _setCategory(_categoryIndex - 1);
  }

  void _handleCategoryBarSwipe(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    if (velocity.abs() < 280) return;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (velocity < 0) {
        _swipeToNextCategory();
      } else {
        _swipeToPreviousCategory();
      }
    });
  }

  String _short(PeriodFilter p) => switch (p) {
        PeriodFilter.allTime => 'metricPeriodAll'.tr(),
        PeriodFilter.thisYear => 'metricPeriodYear'.tr(),
        PeriodFilter.last6Months => 'metricPeriod6M'.tr(),
        PeriodFilter.last12Months => 'metricPeriod12M'.tr(),
        PeriodFilter.custom => 'metricPeriodCustom'.tr(),
      };

  Future<void> _selectPeriod(PeriodFilter period) async {
    if (period != PeriodFilter.custom) {
      setState(() => _period = period);
      return;
    }
    final picked =
        await showMetricDateRangePicker(context, initialRange: _customRange);
    if (!mounted || picked == null) return;
    setState(() {
      _customRange = picked;
      _period = PeriodFilter.custom;
    });
  }

  @override
  Widget build(BuildContext context) {
    final logsAsync = ref.watch(vehicleLogsProvider);
    final isEV =
        ref.watch(activeVehicleProvider).valueOrNull?.isElectric ?? false;
    final fuelLogs = AnalyticsPeriod.filterItems<FuelLog>(
      items: logsAsync.valueOrNull ?? const [],
      getDate: (l) => l.date,
      filter: _period,
      customRange: _customRange,
    );
    final serviceLogs = AnalyticsPeriod.filterItems<ServiceLog>(
      items: ref.watch(serviceLogsProvider).valueOrNull ?? const [],
      getDate: (l) => l.date,
      filter: _period,
      customRange: _customRange,
    );
    final spend = fuelLogs.fold(0.0, (s, i) => s + i.cost) +
        serviceLogs.fold(0.0, (s, i) => s + i.cost);
    double distanceKm = 0;
    if (fuelLogs.length >= 2) {
      final sorted = [...fuelLogs]..sort((a, b) => a.date.compareTo(b.date));
      distanceKm = sorted.last.odometer - sorted.first.odometer;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppAppBar(
        leading: const AppBackButton(),
        title: 'metricExplorerTitle'.tr(),
        actions: [
          IconButton(
            tooltip: 'report'.tr(),
            onPressed: () => ReportsScreen.open(context),
            icon: const Icon(Icons.description_outlined),
            color: AppColors.textSecondary,
          ),
        ],
      ),
      body: logsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (e, _) =>
            Center(child: Text('errorPrefix'.tr(namedArgs: {'error': '$e'}))),
        data: (_) => SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenPadding,
              AppSpacing.appBarBodyGap,
              AppSpacing.screenPadding,
              AppSpacing.md,
            ),
            child: Column(
              children: [
                MetricOverviewCard(
                  periodLabel: _short(_period),
                  onPeriodSelect: _selectPeriod,
                  costPerKm: distanceKm > 0 ? spend / distanceKm : 0,
                  spendLabel: AppCurrency.format(spend),
                  distanceKm: distanceKm,
                  periodHint: _short(_period),
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onHorizontalDragEnd: _handleCategoryBarSwipe,
                  child: MetricFilterChips(
                    index: _categoryIndex,
                    onChanged: _setCategory,
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: MetricChartPane(
                    categoryIndex: _categoryIndex,
                    subMetricIndex: _subMetricIndices[_categoryIndex],
                    onPageChanged: _onMetricPageChanged,
                    fuelLogs: fuelLogs,
                    serviceLogs: serviceLogs,
                    mileageUnit: isEV ? 'km/kWh' : 'km/L',
                    isEV: isEV,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
