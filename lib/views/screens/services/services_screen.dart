import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../viewmodels/fuel_log_viewmodel.dart';
import '../../../viewmodels/reminder_viewmodel.dart';
import '../../../viewmodels/service_log_viewmodel.dart';
import '../../../viewmodels/vehicle_viewmodel.dart';
import '../../widgets/app_app_bar.dart';
import '../reminders/widgets/add_reminder_sheet.dart';
import 'widgets/add_cost_service_sheet.dart';
import 'widgets/services_analytics_tab.dart';
import 'widgets/services_history_tab.dart';
import 'widgets/services_schedules_tab.dart';
import 'widgets/services_top_summary_banner.dart';

/// Full-featured Services & Maintenance Hub Screen
class ServicesScreen extends ConsumerStatefulWidget {
  const ServicesScreen({super.key, this.initialTabIndex = 0});

  final int initialTabIndex;

  static Future<void> open(BuildContext context, {int initialTabIndex = 0}) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ServicesScreen(initialTabIndex: initialTabIndex),
      ),
    );
  }

  @override
  ConsumerState<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends ConsumerState<ServicesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _openAddCostSheet() {
    final vehicle = ref.read(activeVehicleProvider).valueOrNull;
    if (vehicle == null) return;
    final logs = ref.read(vehicleLogsProvider).valueOrNull ?? [];
    final currentOdo = logs.isNotEmpty ? logs.first.odometer : vehicle.startOdo;

    AddCostServiceSheet.show(
      context,
      vehicleId: vehicle.id,
      currentOdometer: currentOdo,
    );
  }

  void _openAddReminderSheet() {
    final vehicle = ref.read(activeVehicleProvider).valueOrNull;
    if (vehicle == null) return;
    final remindersState = ref.read(remindersProvider);

    AddReminderSheet.show(
      context,
      vehicleId: vehicle.id,
      currentOdometer: remindersState.currentOdometer,
      onSave: () {
        ref.read(remindersProvider.notifier).loadReminders();
      },
    );
  }

  Widget? _buildFloatingActionButton(RemindersState state) {
    if (_tabController.index == 0) {
      if (state.activeReminders.isEmpty) return null;
      return FloatingActionButton.extended(
        onPressed: _openAddReminderSheet,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.alarm_add_rounded, size: 18),
        label: Text(
          'servicesAddReminder'.tr(),
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        ),
      );
    } else if (_tabController.index == 1) {
      return FloatingActionButton.extended(
        onPressed: _openAddCostSheet,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 2,
        icon: const Icon(Icons.add_rounded, size: 18),
        label: Text(
          'servicesLogNew'.tr(),
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        ),
      );
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final remindersState = ref.watch(remindersProvider);
    final serviceLogsAsync = ref.watch(serviceLogsProvider);
    final vehicle = ref.watch(activeVehicleProvider).valueOrNull;
    final serviceLogs = serviceLogsAsync.valueOrNull ?? [];

    final totalServiceSpend =
        serviceLogs.fold<double>(0.0, (sum, item) => sum + item.cost);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppAppBar(
        leading: const AppBackButton(),
        titleWidget: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'servicesHubTitle'.tr(),
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            if (vehicle != null)
              Padding(
                padding: const EdgeInsets.only(top: 1),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 5,
                      height: 5,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      vehicle.name,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: AppSpacing.appBarBodyGap),
          ServicesTopSummaryBanner(
            state: remindersState,
            totalSpend: totalServiceSpend,
            logCount: serviceLogs.length,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenPadding,
              vertical: 8,
            ),
            child: Container(
              height: 40,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: AppColors.wash,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.hairline),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: AppColors.isDark ? 0.25 : 0.04,
                      ),
                      blurRadius: 6,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                labelColor: AppColors.textPrimary,
                unselectedLabelColor: AppColors.textTertiary,
                labelStyle: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
                unselectedLabelStyle: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.alarm_rounded, size: 14),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            'servicesSchedulesTab'.tr(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.receipt_long_rounded, size: 14),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            'servicesHistoryTab'.tr(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.pie_chart_outline_rounded, size: 14),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            'servicesAnalyticsTab'.tr(),
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
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                ServicesSchedulesTab(
                  state: remindersState,
                  onAddReminder: _openAddReminderSheet,
                ),
                ServicesHistoryTab(
                  logs: serviceLogs,
                  vehicleName: vehicle?.name,
                ),
                ServicesAnalyticsTab(
                  logs: serviceLogs,
                  totalSpend: totalServiceSpend,
                  vehicle: vehicle,
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(remindersState),
    );
  }
}
