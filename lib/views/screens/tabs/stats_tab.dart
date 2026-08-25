import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/database/app_database.dart';
import '../../../core/utils/analytics_period.dart';
import '../../../core/utils/app_formatters.dart';
import '../../../viewmodels/fuel_log_viewmodel.dart';
import '../../../viewmodels/service_log_viewmodel.dart';
import '../../../viewmodels/vehicle_viewmodel.dart';
import '../reports/reports_screen.dart';
import '../../widgets/advanced_efficiency_chart.dart';
import '../../widgets/analytics_carousel.dart';
import '../../widgets/cost_per_km_chart.dart';
import '../../widgets/fill_up_cost_chart.dart';
import '../../widgets/fuel_price_chart.dart';
import '../../widgets/monthly_cost_breakdown.dart';
import '../../widgets/monthly_distance_chart.dart';
import '../../widgets/odometer_growth_chart.dart';

/// Comprehensive Analytics & Insights Hub (Combines Carousel & Detailed Metric Explorer)
class StatsTab extends ConsumerStatefulWidget {
  const StatsTab({super.key});

  @override
  ConsumerState<StatsTab> createState() => _StatsTabState();
}

class _StatsTabState extends ConsumerState<StatsTab> {
  PeriodFilter _selectedPeriod = PeriodFilter.allTime;
  DateTimeRange? _customDateRange;

  // Primary Category Index: 0: Fuel & Efficiency, 1: Costs & Spend, 2: Distance & Mileage
  int _categoryIndex = 0;

  // Sub-metric Index
  int _subMetricIndex = 0;

  Future<void> _pickCustomDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: now,
      initialDateRange: _customDateRange ??
          DateTimeRange(
            start: now.subtract(const Duration(days: 30)),
            end: now,
          ),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            scaffoldBackgroundColor: const Color(0xFF12121A),
            colorScheme: ColorScheme.dark(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              secondary: AppColors.primary,
              onSecondary: Colors.white,
              secondaryContainer: AppColors.primary.withValues(alpha: 0.25),
              onSecondaryContainer: Colors.white,
              surface: const Color(0xFF1E1E2C),
              onSurface: AppColors.textPrimary,
            ),
            datePickerTheme: DatePickerThemeData(
              backgroundColor: const Color(0xFF12121A),
              headerBackgroundColor: const Color(0xFF1A1A26),
              headerForegroundColor: AppColors.textPrimary,
              rangePickerBackgroundColor: const Color(0xFF12121A),
              rangePickerHeaderBackgroundColor: const Color(0xFF1A1A26),
              rangePickerHeaderForegroundColor: AppColors.textPrimary,
              rangeSelectionBackgroundColor:
                  AppColors.primary.withValues(alpha: 0.25),
              rangeSelectionOverlayColor: WidgetStateProperty.all(
                  AppColors.primary.withValues(alpha: 0.3)),
              dayForegroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return Colors.white;
                }
                return AppColors.textPrimary;
              }),
              dayStyle: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _customDateRange = picked;
        _selectedPeriod = PeriodFilter.custom;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final logsAsync = ref.watch(vehicleLogsProvider);
    final serviceLogsAsync = ref.watch(serviceLogsProvider);
    final vehicleAsync = ref.watch(activeVehicleProvider);
    final vehicle = vehicleAsync.valueOrNull;
    final isEV = vehicle?.isElectric ?? false;
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

    // Calculate KPI Metrics
    final totalFuelSpend =
        filteredFuelLogs.fold(0.0, (sum, item) => sum + item.cost);
    final totalServiceSpend =
        filteredServiceLogs.fold(0.0, (sum, item) => sum + item.cost);
    final totalSpend = totalFuelSpend + totalServiceSpend;

    double totalDistanceKm = 0.0;
    if (filteredFuelLogs.length >= 2) {
      final sorted = List<FuelLog>.from(filteredFuelLogs)
        ..sort((a, b) => a.date.compareTo(b.date));
      totalDistanceKm = sorted.last.odometer - sorted.first.odometer;
    }

    final avgCostPerKm =
        totalDistanceKm > 0 ? (totalSpend / totalDistanceKm) : 0.0;

    return logsAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
      error: (e, _) => Center(
        child: Text('Error: $e',
            style: const TextStyle(color: AppColors.textSecondary)),
      ),
      data: (logs) => ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenPadding,
          AppSpacing.sm,
          AppSpacing.screenPadding,
          AppSpacing.xl,
        ),
        children: [
          // 1. ORIGINAL SWIPEABLE ANALYTICS CAROUSEL (with Expand Fullscreen & Expense Ratio Donut Chart)
          AnalyticsCarousel(
            logs: logs,
            mileageUnit: mileageUnit,
            isElectric: isEV,
          ),

          const SizedBox(height: AppSpacing.lg),

          // SECTION HEADER FOR ADVANCED METRICS
          Row(
            children: [
              const Icon(Icons.analytics_rounded,
                  size: 20, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Advanced Metric Explorer',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              InkWell(
                onTap: () => ReportsScreen.open(context),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.3)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.description_rounded,
                          size: 14, color: AppColors.primary),
                      SizedBox(width: 4),
                      Text(
                        'Report',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.sm),

          // 2. TIME PERIOD SELECTOR CHIPS
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: PeriodFilter.values.map((period) {
                final isSelected = _selectedPeriod == period;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(period.label),
                    selected: isSelected,
                    onSelected: (val) {
                      if (!val) return;
                      if (period == PeriodFilter.custom) {
                        _pickCustomDateRange();
                      } else {
                        setState(() {
                          _selectedPeriod = period;
                        });
                      }
                    },
                    selectedColor: AppColors.primary.withValues(alpha: 0.2),
                    backgroundColor: const Color(0xFF1E1E2A),
                    side: BorderSide(
                      color: isSelected
                          ? AppColors.primary
                          : const Color(0xFF2E2E3E),
                    ),
                    labelStyle: TextStyle(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textPrimary,
                      fontSize: 12,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                    showCheckmark: false,
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 14),

          // 3. KPI SUMMARY METRIC CARDS
          Row(
            children: [
              Expanded(
                child: _KpiCard(
                  title: 'Cost / km',
                  value: avgCostPerKm > 0
                      ? '৳${avgCostPerKm.toStringAsFixed(2)}/km'
                      : 'N/A',
                  icon: Icons.speed_rounded,
                  color: const Color(0xFF38BDF8),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _KpiCard(
                  title: 'Period Spend',
                  value: AppCurrency.format(totalSpend),
                  icon: Icons.account_balance_wallet_rounded,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _KpiCard(
                  title: 'Distance',
                  value: '${totalDistanceKm.toStringAsFixed(0)} km',
                  icon: Icons.route_rounded,
                  color: const Color(0xFFA855F7),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // 4. CATEGORY SELECTOR SEGMENTED CONTROL
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFF161622),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF262638)),
            ),
            child: Row(
              children: [
                _CategoryTab(
                  label: 'Fuel & Mileage',
                  icon: Icons.local_gas_station_rounded,
                  isSelected: _categoryIndex == 0,
                  onTap: () => setState(() {
                    _categoryIndex = 0;
                    _subMetricIndex = 0;
                  }),
                ),
                _CategoryTab(
                  label: 'Costs & Spend',
                  icon: Icons.account_balance_wallet_rounded,
                  isSelected: _categoryIndex == 1,
                  onTap: () => setState(() {
                    _categoryIndex = 1;
                    _subMetricIndex = 0;
                  }),
                ),
                _CategoryTab(
                  label: 'Distance',
                  icon: Icons.route_rounded,
                  isSelected: _categoryIndex == 2,
                  onTap: () => setState(() {
                    _categoryIndex = 2;
                    _subMetricIndex = 0;
                  }),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // 5. SUB-METRIC SELECTION CHIPS
          _buildSubMetricChips(mileageUnit),

          const SizedBox(height: 14),

          // 6. ACTIVE DETAILED METRIC CHART
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _buildActiveChart(
              filteredFuelLogs,
              filteredServiceLogs,
              mileageUnit,
              isEV,
            ),
          ),

          const SizedBox(height: 20),

          // 7. MONTHLY SPENDING BREAKDOWN
          Text(
            'Monthly Spending Breakdown',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          MonthlyCostBreakdown(
            fuelLogs: filteredFuelLogs,
            serviceLogs: filteredServiceLogs,
          ),
        ],
      ),
    );
  }

  Widget _buildSubMetricChips(String mileageUnit) {
    List<String> options = [];
    if (_categoryIndex == 0) {
      options = [
        'Consumption ($mileageUnit)',
        'Gas Price (৳/L)',
        'Fill-up Costs (৳)'
      ];
    } else if (_categoryIndex == 1) {
      options = ['Monthly Total Spend', 'Cost per KM (৳/km)'];
    } else {
      options = ['Monthly Distance (km)', 'Odometer Growth (km)'];
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: options.asMap().entries.map((entry) {
          final idx = entry.key;
          final label = entry.value;
          final isSelected = _subMetricIndex == idx;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(label),
              selected: isSelected,
              onSelected: (val) {
                if (val) setState(() => _subMetricIndex = idx);
              },
              selectedColor: AppColors.primary.withValues(alpha: 0.2),
              backgroundColor: const Color(0xFF1E1E2A),
              side: BorderSide(
                color: isSelected ? AppColors.primary : const Color(0xFF2E2E3E),
              ),
              labelStyle: TextStyle(
                color: isSelected ? AppColors.primary : AppColors.textPrimary,
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              showCheckmark: false,
            ),
          );
        }).toList(),
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
      } else {
        return FillUpCostChart(
          key: key,
          logs: fuelLogs,
          chartHeight: 240,
        );
      }
    } else if (_categoryIndex == 1) {
      if (_subMetricIndex == 0) {
        return MonthlyCostBreakdown(
          key: key,
          fuelLogs: fuelLogs,
          serviceLogs: serviceLogs,
        );
      } else {
        return CostPerKmChart(
          key: key,
          fuelLogs: fuelLogs,
          serviceLogs: serviceLogs,
          chartHeight: 240,
        );
      }
    } else {
      if (_subMetricIndex == 0) {
        return MonthlyDistanceChart(
          key: key,
          logs: fuelLogs,
        );
      } else {
        return OdometerGrowthChart(
          key: key,
          logs: fuelLogs,
          chartHeight: 240,
        );
      }
    }
  }
}

class _CategoryTab extends StatelessWidget {
  const _CategoryTab({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.18)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? AppColors.primary : Colors.transparent,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? AppColors.primary : AppColors.textTertiary,
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color:
                      isSelected ? AppColors.primary : AppColors.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
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
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF161622),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF242436)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 13, color: color),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: AppColors.textTertiary,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
