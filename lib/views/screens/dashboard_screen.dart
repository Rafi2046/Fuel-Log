import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';
import '../../viewmodels/vehicle_viewmodel.dart';
import '../widgets/app_app_bar.dart';
import '../widgets/trip_manual_entry_sheet.dart';
import 'tabs/dashboard_app_bar.dart';
import 'tabs/dashboard_bottom_bar.dart';
import 'tabs/dashboard_quick_actions_sheet.dart';
import 'tabs/garage_tab.dart';
import 'tabs/home_tab.dart';
import 'tabs/settings_tab.dart';
import 'tabs/stats_tab.dart';
import 'tabs/trip_log_tab.dart';
import 'tabs/vehicle_switcher_sheet.dart';

/// Main shell: IndexedStack tabs + notched FAB bottom bar.
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _currentIndex = 0;
  final GlobalKey<TripLogTabState> _tripTabKey = GlobalKey<TripLogTabState>();

  List<Widget> get _tabs => [
        const HomeTab(),
        TripLogTab(key: _tripTabKey, isActive: _isTripTab),
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

  Future<bool> _onWillPop() async {
    // If not on Home tab, first switch back to Home tab
    if (_currentIndex != 0) {
      setState(() => _currentIndex = 0);
      return false;
    }

    // Show Exit Confirmation Dialog
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: const Color(0xFF161622),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFF262638)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.power_settings_new_rounded,
                  color: AppColors.primary,
                  size: 28,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Exit App?',
                style: GoogleFonts.inter(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Are you sure you want to exit Fuel-Log?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF2E2E3E)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                            fontSize: 13.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(ctx).pop(true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Exit',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    return shouldExit ?? false;
  }

  void _openGarage() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppAppBar(title: 'garageTitle'.tr()),
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

    VehicleSwitcherSheet.show(
      context,
      onManageGarage: _openGarage,
    );
  }

  void _openGasStations() {
    setState(() => _currentIndex = 1);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _tripTabKey.currentState?.openNearbyStations();
    });
  }

  @override
  Widget build(BuildContext context) {
    final activeVehicle = ref.watch(activeVehicleProvider).valueOrNull;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        extendBody: true,
        backgroundColor: AppColors.background,
        appBar: _isTripTab
            ? null
            : buildDashboardAppBar(
                context: context,
                currentIndex: _appBarIndex,
                activeVehicle: activeVehicle,
                onVehicleTap: _openVehicleSwitcher,
                onFuelStationsTap: _openGasStations,
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
                  onExploreStations: _openGasStations,
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
                  color: Colors.white,
                  size: 28,
                ),
              ),
        bottomNavigationBar: DashboardBottomBar(
          currentIndex: _currentIndex,
          onTabTapped: _onTabTapped,
          showFabGap: !_isTripTab,
        ),
      ),
    );
  }
}
