import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/database/app_database.dart';
import '../../../core/utils/analytics_period.dart';
import '../../../core/utils/app_formatters.dart';
import '../../../viewmodels/fuel_log_viewmodel.dart';
import '../../../viewmodels/service_log_viewmodel.dart';
import '../../../viewmodels/vehicle_viewmodel.dart';
import '../reports/reports_screen.dart';
import 'widgets/metric_chart_pane.dart';
import 'widgets/metric_date_range_picker.dart';
import 'widgets/metric_filter_chips.dart';
import 'widgets/metric_kpi_row.dart';

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
  int _subMetricIndex = 0;

  String _short(PeriodFilter p) => switch (p) {
        PeriodFilter.allTime => 'All',
        PeriodFilter.thisYear => 'Year',
        PeriodFilter.last6Months => '6M',
        PeriodFilter.last12Months => '12M',
        PeriodFilter.custom => 'Custom',
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
      appBar: AppBar(
        title: Text('metricExplorerTitle'.tr()),
        actions: [
          IconButton(
            tooltip: 'report'.tr(),
            onPressed: () => ReportsScreen.open(context),
            icon: const Icon(Icons.description_outlined),
            color: AppColors.primary,
          ),
        ],
      ),
      body: logsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (e, _) =>
            Center(child: Text('errorPrefix'.tr(namedArgs: {'error': '$e'}))),
        data: (_) => ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: MetricPeriodMenu(
                label: _short(_period),
                onSelect: _selectPeriod,
              ),
            ),
            const SizedBox(height: 16),
            MetricKpiRow(
              costPerKm: distanceKm > 0 ? spend / distanceKm : 0,
              spendLabel: AppCurrency.format(spend),
              distanceKm: distanceKm,
              periodHint: _short(_period),
            ),
            const SizedBox(height: 24),
            MetricFilterChips(
              index: _categoryIndex,
              onChanged: (i) => setState(() {
                _categoryIndex = i;
                _subMetricIndex = 0;
              }),
            ),
            const SizedBox(height: 16),
            MetricChartPane(
              categoryIndex: _categoryIndex,
              subMetricIndex: _subMetricIndex,
              onSubMetricChanged: (i) => setState(() => _subMetricIndex = i),
              fuelLogs: fuelLogs,
              serviceLogs: serviceLogs,
              mileageUnit: isEV ? 'km/kWh' : 'km/L',
              isEV: isEV,
            ),
          ],
        ),
      ),
    );
  }
}
