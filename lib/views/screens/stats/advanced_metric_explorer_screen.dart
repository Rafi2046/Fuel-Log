import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/database/app_database.dart';
import '../../../core/utils/analytics_period.dart';
import '../../../core/utils/app_formatters.dart';
import '../../../viewmodels/fuel_log_viewmodel.dart';
import '../../../viewmodels/service_log_viewmodel.dart';
import '../../../viewmodels/vehicle_viewmodel.dart';
import '../refueling_form_screen.dart';
import '../reports/reports_screen.dart';
import '../../widgets/advanced_efficiency_chart.dart';
import '../../widgets/cost_per_km_chart.dart';
import '../../widgets/fill_up_cost_chart.dart';
import '../../widgets/fuel_price_chart.dart';
import '../../widgets/monthly_cost_breakdown.dart';
import '../../widgets/monthly_distance_chart.dart';
import '../../widgets/odometer_growth_chart.dart';

/// Deep analytics — airy premium layout (filters + chart, no cramped chrome).
class AdvancedMetricExplorerScreen extends ConsumerStatefulWidget {
  const AdvancedMetricExplorerScreen({super.key});

  static Future<void> open(BuildContext context) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const AdvancedMetricExplorerScreen(),
      ),
    );
  }

  @override
  ConsumerState<AdvancedMetricExplorerScreen> createState() =>
      _AdvancedMetricExplorerScreenState();
}

class _AdvancedMetricExplorerScreenState
    extends ConsumerState<AdvancedMetricExplorerScreen> {
  PeriodFilter _selectedPeriod = PeriodFilter.last6Months;
  DateTimeRange? _customDateRange;
  int _categoryIndex = 0;
  int _subMetricIndex = 0;

  static const _surface = Color(0xFF16161E);
  static const _border = Color(0xFF2A2A36);

  String _periodShort(PeriodFilter period) {
    switch (period) {
      case PeriodFilter.allTime:
        return 'All';
      case PeriodFilter.thisYear:
        return 'Year';
      case PeriodFilter.last6Months:
        return '6M';
      case PeriodFilter.last12Months:
        return '12M';
      case PeriodFilter.custom:
        return 'Custom';
    }
  }

  Future<void> _pickCustomDateRange() async {
    final now = DateTime.now();
    final rangeFill = AppColors.primary.withValues(alpha: 0.22);
    final pickerTheme = Theme.of(context).copyWith(
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: ColorScheme.dark(
        primary: AppColors.primary,
        onPrimary: AppColors.textPrimary,
        primaryContainer: rangeFill,
        onPrimaryContainer: AppColors.textPrimary,
        secondary: AppColors.primary,
        onSecondary: AppColors.textPrimary,
        secondaryContainer: rangeFill,
        onSecondaryContainer: AppColors.textPrimary,
        tertiary: AppColors.secondary,
        tertiaryContainer: AppColors.primary.withValues(alpha: 0.16),
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
        surfaceContainerHighest: AppColors.card,
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: AppColors.background,
        headerBackgroundColor: AppColors.background,
        headerForegroundColor: AppColors.textPrimary,
        rangeSelectionBackgroundColor: rangeFill,
        rangeSelectionOverlayColor: WidgetStateProperty.all(
          AppColors.primary.withValues(alpha: 0.12),
        ),
        dayForegroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.textPrimary;
          }
          if (states.contains(WidgetState.disabled)) {
            return AppColors.textTertiary;
          }
          return AppColors.textPrimary;
        }),
        dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary;
          }
          return null;
        }),
        todayForegroundColor: WidgetStateProperty.all(AppColors.primary),
        todayBorder: BorderSide(
          color: AppColors.primary.withValues(alpha: 0.7),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppColors.primary),
      ),
    );

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: now,
      initialDateRange: _customDateRange ??
          DateTimeRange(
            start: now.subtract(const Duration(days: 30)),
            end: now,
          ),
      builder: (context, child) => Theme(data: pickerTheme, child: child!),
    );

    if (!mounted || picked == null) return;
    setState(() {
      _customDateRange = picked;
      _selectedPeriod = PeriodFilter.custom;
    });
  }

  @override
  Widget build(BuildContext context) {
    final logsAsync = ref.watch(vehicleLogsProvider);
    final serviceLogsAsync = ref.watch(serviceLogsProvider);
    final vehicleAsync = ref.watch(activeVehicleProvider);
    final isEV = vehicleAsync.valueOrNull?.isElectric ?? false;
    final mileageUnit = isEV ? 'km/kWh' : 'km/L';

    final allFuelLogs = logsAsync.valueOrNull ?? [];
    final allServiceLogs = serviceLogsAsync.valueOrNull ?? [];

    final filteredFuelLogs = AnalyticsPeriod.filterItems<FuelLog>(
      items: allFuelLogs,
      getDate: (log) => log.date,
      filter: _selectedPeriod,
      customRange: _customDateRange,
    );

    final filteredServiceLogs = AnalyticsPeriod.filterItems<ServiceLog>(
      items: allServiceLogs,
      getDate: (log) => log.date,
      filter: _selectedPeriod,
      customRange: _customDateRange,
    );

    final totalSpend = filteredFuelLogs.fold(0.0, (s, i) => s + i.cost) +
        filteredServiceLogs.fold(0.0, (s, i) => s + i.cost);

    double totalDistanceKm = 0;
    if (filteredFuelLogs.length >= 2) {
      final sorted = List<FuelLog>.from(filteredFuelLogs)
        ..sort((a, b) => a.date.compareTo(b.date));
      totalDistanceKm = sorted.last.odometer - sorted.first.odometer;
    }

    final avgCostPerKm =
        totalDistanceKm > 0 ? totalSpend / totalDistanceKm : 0.0;

    final hasChartData = _hasChartData(
      filteredFuelLogs,
      filteredServiceLogs,
    );

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
        error: (e, _) => Center(
          child: Text('errorPrefix'.tr(namedArgs: {'error': '$e'})),
        ),
        data: (_) => ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            // Period as one menu — not another tab row
            Align(
              alignment: Alignment.centerRight,
              child: _PeriodMenu(
                label: _periodShort(_selectedPeriod),
                onSelect: (period) {
                  if (period == PeriodFilter.custom) {
                    _pickCustomDateRange();
                  } else {
                    setState(() => _selectedPeriod = period);
                  }
                },
              ),
            ),

            const SizedBox(height: 16),

            // KPI — all three visible
            SizedBox(
              height: 112,
              child: Row(
                children: [
                  Expanded(
                    child: _KpiCard(
                      title: 'Cost / km',
                      value: avgCostPerKm > 0
                          ? '৳${avgCostPerKm.toStringAsFixed(2)}'
                          : '—',
                      hint: avgCostPerKm > 0 ? 'per km' : 'Need logs',
                      icon: Icons.speed_rounded,
                      accent: const Color(0xFF38BDF8),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _KpiCard(
                      title: 'Spend',
                      value: AppCurrency.format(totalSpend),
                      hint: _periodShort(_selectedPeriod),
                      icon: Icons.payments_outlined,
                      accent: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _KpiCard(
                      title: 'Distance',
                      value: totalDistanceKm > 0
                          ? '${totalDistanceKm.toStringAsFixed(0)} km'
                          : '—',
                      hint: 'this period',
                      icon: Icons.route_rounded,
                      accent: const Color(0xFFA855F7),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Single category segmented control
            _CategorySegment(
              index: _categoryIndex,
              onChanged: (i) => setState(() {
                _categoryIndex = i;
                _subMetricIndex = 0;
              }),
            ),

            const SizedBox(height: 16),

            // Chart + metric switch inside one surface
            Container(
              width: double.infinity,
              constraints: hasChartData
                  ? const BoxConstraints(minHeight: 280)
                  : null,
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
              decoration: BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                border: Border.all(color: _border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildSubMetricRow(mileageUnit),
                  const SizedBox(height: 8),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 280),
                    child: hasChartData
                        ? _buildActiveChart(
                            filteredFuelLogs,
                            filteredServiceLogs,
                            mileageUnit,
                            isEV,
                          )
                        : const _ExplorerEmptyState(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _hasChartData(List<FuelLog> fuelLogs, List<ServiceLog> serviceLogs) {
    if (_categoryIndex == 1) {
      return fuelLogs.isNotEmpty || serviceLogs.isNotEmpty;
    }
    // Efficiency / distance trends need at least two fuel points
    return fuelLogs.length >= 2;
  }

  Widget _buildSubMetricRow(String mileageUnit) {
    final List<String> options;
    if (_categoryIndex == 0) {
      options = ['Consumption', 'Price', 'Fill-ups'];
    } else if (_categoryIndex == 1) {
      options = ['Monthly spend', 'Cost / km'];
    } else {
      options = ['Monthly km', 'Odometer'];
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < options.length; i++) ...[
            if (i > 0) const SizedBox(width: 4),
            _ChartMetricTab(
              label: options[i],
              selected: _subMetricIndex == i,
              onTap: () => setState(() => _subMetricIndex = i),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActiveChart(
    List<FuelLog> fuelLogs,
    List<ServiceLog> serviceLogs,
    String mileageUnit,
    bool isEV,
  ) {
    final key = ValueKey('chart_${_categoryIndex}_$_subMetricIndex');

    if (_categoryIndex == 0) {
      if (_subMetricIndex == 0) {
        return AdvancedEfficiencyChart(
          key: key,
          logs: fuelLogs,
          unit: mileageUnit,
        );
      } else if (_subMetricIndex == 1) {
        return FuelPriceChart(
          key: key,
          logs: fuelLogs,
          priceUnit: isEV ? '৳/kWh' : '৳/L',
        );
      }
      return FillUpCostChart(key: key, logs: fuelLogs, chartHeight: 240);
    }

    if (_categoryIndex == 1) {
      if (_subMetricIndex == 0) {
        return MonthlyCostBreakdown(
          key: key,
          fuelLogs: fuelLogs,
          serviceLogs: serviceLogs,
        );
      }
      return CostPerKmChart(
        key: key,
        fuelLogs: fuelLogs,
        serviceLogs: serviceLogs,
        chartHeight: 240,
      );
    }

    if (_subMetricIndex == 0) {
      return MonthlyDistanceChart(key: key, logs: fuelLogs);
    }
    return OdometerGrowthChart(key: key, logs: fuelLogs, chartHeight: 240);
  }
}

class _ExplorerEmptyState extends StatelessWidget {
  const _ExplorerEmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.28),
              ),
            ),
            child: const Icon(
              Icons.show_chart_rounded,
              color: AppColors.primary,
              size: 26,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'No trend yet',
            style: AppTextStyles.title.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'chartNeedMoreLogs'.tr(),
            textAlign: TextAlign.center,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 16),
          // Soft sparkline silhouette — fills space without looking empty
          SizedBox(
            height: 56,
            width: double.infinity,
            child: CustomPaint(
              painter: _EmptySparklinePainter(
                color: AppColors.primary.withValues(alpha: 0.35),
              ),
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const RefuelingFormScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.local_gas_station_rounded, size: 18),
              label: Text('actionRefueling'.tr()),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptySparklinePainter extends CustomPainter {
  _EmptySparklinePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    final points = <Offset>[
      Offset(0, size.height * 0.7),
      Offset(size.width * 0.18, size.height * 0.55),
      Offset(size.width * 0.34, size.height * 0.62),
      Offset(size.width * 0.5, size.height * 0.35),
      Offset(size.width * 0.66, size.height * 0.48),
      Offset(size.width * 0.82, size.height * 0.22),
      Offset(size.width, size.height * 0.3),
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
            color.withValues(alpha: 0.18),
            color.withValues(alpha: 0.0),
          ],
        ).createShader(Offset.zero & size),
    );
  }

  @override
  bool shouldRepaint(covariant _EmptySparklinePainter oldDelegate) =>
      oldDelegate.color != color;
}

class _PeriodMenu extends StatelessWidget {
  const _PeriodMenu({
    required this.label,
    required this.onSelect,
  });

  final String label;
  final ValueChanged<PeriodFilter> onSelect;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppSpacing.radiusMd);
    return PopupMenuButton<PeriodFilter>(
      onSelected: onSelect,
      color: const Color(0xFF1A1A24),
      shape: RoundedRectangleBorder(borderRadius: radius),
      itemBuilder: (context) => PeriodFilter.values
          .map(
            (period) => PopupMenuItem(
              value: period,
              child: Text(
                switch (period) {
                  PeriodFilter.allTime => 'All time',
                  PeriodFilter.thisYear => 'This year',
                  PeriodFilter.last6Months => 'Last 6 months',
                  PeriodFilter.last12Months => 'Last 12 months',
                  PeriodFilter.custom => 'Custom range',
                },
                style: AppTextStyles.body.copyWith(fontSize: 14),
              ),
            ),
          )
          .toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A24),
          borderRadius: radius,
          border: Border.all(color: const Color(0xFF2A2A36)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.calendar_today_outlined,
                size: 14, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppTextStyles.label.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.keyboard_arrow_down_rounded,
                size: 18, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

class _CategorySegment extends StatelessWidget {
  const _CategorySegment({
    required this.index,
    required this.onChanged,
  });

  final int index;
  final ValueChanged<int> onChanged;

  static const _items = [
    (Icons.local_gas_station_rounded, 'Fuel'),
    (Icons.account_balance_wallet_outlined, 'Costs'),
    (Icons.route_rounded, 'Distance'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A24),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: const Color(0xFF2A2A36)),
      ),
      child: Row(
        children: [
          for (var i = 0; i < _items.length; i++)
            Expanded(
              child: _SegmentCell(
                icon: _items[i].$1,
                label: _items[i].$2,
                selected: index == i,
                onTap: () => onChanged(i),
              ),
            ),
        ],
      ),
    );
  }
}

class _SegmentCell extends StatelessWidget {
  const _SegmentCell({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppSpacing.radiusSm);
    return Material(
      color: selected
          ? AppColors.primary.withValues(alpha: 0.18)
          : Colors.transparent,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 15,
                color: selected ? AppColors.primary : AppColors.textTertiary,
              ),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  label,
                  style: AppTextStyles.label.copyWith(
                    color:
                        selected ? AppColors.primary : AppColors.textSecondary,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChartMetricTab extends StatelessWidget {
  const _ChartMetricTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          label,
          style: AppTextStyles.label.copyWith(
            color: selected ? AppColors.primary : AppColors.textTertiary,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.title,
    required this.value,
    required this.hint,
    required this.icon,
    required this.accent,
  });

  final String title;
  final String value;
  final String hint;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
      decoration: BoxDecoration(
        color: const Color(0xFF16161E),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(color: const Color(0xFF2A2A36)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Icon(icon, size: 14, color: accent),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textTertiary,
              fontWeight: FontWeight.w500,
              fontSize: 11,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const Spacer(),
          Text(
            value,
            style: AppTextStyles.title.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              height: 1.15,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            hint,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textTertiary,
              fontSize: 10,
              height: 1.1,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
