import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../viewmodels/fuel_log_viewmodel.dart';
import '../../../viewmodels/reminder_viewmodel.dart';
import '../../../viewmodels/service_log_viewmodel.dart';
import '../../../viewmodels/vehicle_viewmodel.dart';
import '../services/widgets/add_cost_service_sheet.dart';
import '../../widgets/app_app_bar.dart';
import 'widgets/add_reminder_sheet.dart';
import 'widgets/reminders_active_tab.dart';
import 'widgets/reminders_history_tab.dart';

/// Main Vehicle Maintenance & Service Reminders Hub
class RemindersScreen extends ConsumerStatefulWidget {
  const RemindersScreen({super.key, this.initialTabIndex = 0});

  final int initialTabIndex;

  @override
  ConsumerState<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends ConsumerState<RemindersScreen> {
  late int _selectedTabIndex;

  @override
  void initState() {
    super.initState();
    _selectedTabIndex = widget.initialTabIndex;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(remindersProvider);
    final vehicle = ref.watch(activeVehicleProvider).valueOrNull;
    final serviceLogsAsync = ref.watch(serviceLogsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppAppBar(
        leading: const AppBackButton(),
        titleWidget: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Maintenance & Services',
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
                      decoration: BoxDecoration(
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
        actions: [
          IconButton(
            icon: const Icon(
              Icons.add_rounded,
              color: AppColors.primary,
              size: 24,
            ),
            tooltip: _selectedTabIndex == 0 ? 'Add Reminder' : 'Add Expense',
            onPressed: () {
              if (vehicle == null) return;
              if (_selectedTabIndex == 0) {
                AddReminderSheet.show(
                  context,
                  vehicleId: vehicle.id,
                  currentOdometer: state.currentOdometer,
                  onSave: () {
                    ref.read(remindersProvider.notifier).loadReminders();
                  },
                );
              } else {
                final logs = ref.read(vehicleLogsProvider).valueOrNull ?? [];
                final currentOdo =
                    logs.isNotEmpty ? logs.first.odometer : vehicle.startOdo;
                AddCostServiceSheet.show(
                  context,
                  vehicleId: vehicle.id,
                  currentOdometer: currentOdo,
                );
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Segmented Tab Toggle Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenPadding,
              AppSpacing.appBarBodyGap,
              AppSpacing.screenPadding,
              8,
            ),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _selectedTabIndex = 0),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      decoration: BoxDecoration(
                        color: _selectedTabIndex == 0
                            ? AppColors.primary.withValues(alpha: 0.18)
                            : AppColors.appBar,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _selectedTabIndex == 0
                              ? AppColors.primary
                              : AppColors.hairline,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          'Active Reminders',
                          style: TextStyle(
                            color: _selectedTabIndex == 0
                                ? AppColors.primary
                                : AppColors.textSecondary,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _selectedTabIndex = 1),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      decoration: BoxDecoration(
                        color: _selectedTabIndex == 1
                            ? const Color(0xFF2ECC71).withValues(alpha: 0.18)
                            : AppColors.appBar,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _selectedTabIndex == 1
                              ? const Color(0xFF2ECC71)
                              : AppColors.hairline,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          'Cost & Service History',
                          style: TextStyle(
                            color: _selectedTabIndex == 1
                                ? const Color(0xFF2ECC71)
                                : AppColors.textSecondary,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: _selectedTabIndex == 0
                ? RemindersActiveTab(
                    state: state,
                    vehicle: vehicle,
                  )
                : RemindersHistoryTab(
                    logsAsync: serviceLogsAsync,
                  ),
          ),
        ],
      ),
    );
  }
}
