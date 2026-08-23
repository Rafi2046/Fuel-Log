import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_text_styles.dart';
import '../../viewmodels/vehicle_viewmodel.dart';
import 'tabs/dashboard_app_bar.dart';
import 'tabs/dashboard_nav_item.dart';
import 'tabs/dashboard_quick_actions_sheet.dart';
import 'tabs/garage_tab.dart';
import 'tabs/home_tab.dart';
import 'tabs/settings_tab.dart';
import 'tabs/stats_tab.dart';
import 'tabs/trip_log_tab.dart';
import '../widgets/trip_manual_entry_sheet.dart';

/// Main shell: IndexedStack tabs + notched FAB bottom bar.
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _currentIndex = 0;

  List<Widget> get _tabs => [
        const HomeTab(),
        TripLogTab(isActive: _isTripTab),
        const StatsTab(),
        const SettingsTab(),
      ];

  bool get _isTripTab => _currentIndex == 1;

  /// App bar index map: Trip has no bar; Stats/Settings keep their titles.
  int get _appBarIndex {
    switch (_currentIndex) {
      case 0:
        return 0;
      case 2:
        return 2;
      case 3:
        return 3;
      default:
        return 0;
    }
  }

  void _onTabTapped(int index) => setState(() => _currentIndex = index);

  void _openGarage() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(title: Text('garageTitle'.tr())),
          body: const GarageTab(),
        ),
      ),
    );
  }

  void _openVehicleSwitcher() {
    final vehicles = ref.read(vehiclesProvider).valueOrNull ?? [];
    if (vehicles.length <= 1) {
      _openGarage();
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.cardElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusXl),
        ),
      ),
      builder: (context) {
        final currentActive = ref.read(activeVehicleProvider).valueOrNull;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenPadding,
              vertical: AppSpacing.md,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Switch Vehicle',
                  style: AppTextStyles.title.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                ...vehicles.map((v) {
                  final isSelected = v.id == currentActive?.id;
                  final type = v.type.toLowerCase();
                  final isBike = type == 'bike' ||
                      type.contains('bike') ||
                      type.contains('motorcycle') ||
                      type.contains('scooter');
                  final icon = isBike
                      ? Icons.two_wheeler_rounded
                      : Icons.directions_car_filled_rounded;

                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.surface,
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusMd),
                      ),
                      child: Icon(
                        icon,
                        color: isSelected
                            ? Colors.white
                            : AppColors.textSecondary,
                        size: 22,
                      ),
                    ),
                    title: Text(
                      v.name,
                      style: AppTextStyles.body.copyWith(
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textPrimary,
                      ),
                    ),
                    subtitle: v.model != null && v.model!.isNotEmpty
                        ? Text(
                            '${v.model} • ${v.fuelType}',
                            style: AppTextStyles.caption,
                          )
                        : Text(v.fuelType, style: AppTextStyles.caption),
                    trailing: isSelected
                        ? const Icon(
                            Icons.check_circle_rounded,
                            color: AppColors.primary,
                          )
                        : null,
                    onTap: () {
                      ref.read(selectedVehicleIdProvider.notifier).state =
                          v.id;
                      Navigator.of(context).pop();
                    },
                  );
                }),
                const Divider(color: AppColors.divider, height: 24),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                    child: const Icon(
                      Icons.garage_rounded,
                      color: AppColors.primary,
                      size: 22,
                    ),
                  ),
                  title: Text(
                    'Manage Garage',
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: AppColors.textTertiary,
                  ),
                  onTap: () {
                    Navigator.of(context).pop();
                    _openGarage();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeVehicle = ref.watch(activeVehicleProvider).valueOrNull;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _isTripTab
          ? null
          : buildDashboardAppBar(
              context: context,
              currentIndex: _appBarIndex,
              activeVehicle: activeVehicle,
              onVehicleTap: _openVehicleSwitcher,
              onGarageTap: _openGarage,
            ),
      body: IndexedStack(
        index: _currentIndex,
        children: _tabs,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: _isTripTab
          ? null
          : FloatingActionButton(
              onPressed: () => showDashboardQuickActionsSheet(
                context,
                onRecordTrip: () {
                  setState(() => _currentIndex = 1);
                  // Open manual entry after switching to Trip.
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!mounted) return;
                    showTripManualEntrySheet(context);
                  });
                },
              ),
              backgroundColor: AppColors.primary,
              elevation: 6,
              shape: const CircleBorder(),
              child: const Icon(
                Icons.local_gas_station_rounded,
                color: AppColors.textPrimary,
                size: 28,
              ),
            ),
      bottomNavigationBar: BottomAppBar(
        color: AppColors.surface,
        shape: _isTripTab ? null : const CircularNotchedRectangle(),
        notchMargin: 8,
        elevation: 10,
        padding: EdgeInsets.zero,
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    DashboardNavItem(
                      icon: Icons.home_rounded,
                      label: 'navHome'.tr(),
                      isSelected: _currentIndex == 0,
                      onTap: () => _onTabTapped(0),
                    ),
                    DashboardNavItem(
                      icon: Icons.route_rounded,
                      label: 'navTrip'.tr(),
                      isSelected: _currentIndex == 1,
                      onTap: () => _onTabTapped(1),
                    ),
                  ],
                ),
              ),
              if (!_isTripTab) const SizedBox(width: 48),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    DashboardNavItem(
                      icon: Icons.bar_chart_rounded,
                      label: 'navStats'.tr(),
                      isSelected: _currentIndex == 2,
                      onTap: () => _onTabTapped(2),
                    ),
                    DashboardNavItem(
                      icon: Icons.settings_rounded,
                      label: 'navSettings'.tr(),
                      isSelected: _currentIndex == 3,
                      onTap: () => _onTabTapped(3),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
