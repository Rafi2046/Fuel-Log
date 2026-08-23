import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import 'tabs/dashboard_app_bar.dart';
import 'tabs/dashboard_nav_item.dart';
import 'tabs/dashboard_quick_actions_sheet.dart';
import 'tabs/garage_tab.dart';
import 'tabs/home_tab.dart';
import 'tabs/logs_tab.dart';
import 'tabs/settings_tab.dart';
import 'tabs/stats_tab.dart';

/// Main shell: IndexedStack tabs + notched FAB bottom bar.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;
  final String _selectedVehicle = 'Toyota Axio 🚘';

  /// Home · Logs · Stats · Settings — Garage opens from the vehicle chip.
  static const List<Widget> _tabs = [
    HomeTab(),
    LogsTab(),
    StatsTab(),
    SettingsTab(),
  ];

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: buildDashboardAppBar(
        context: context,
        currentIndex: _currentIndex,
        selectedVehicle: _selectedVehicle,
        onVehicleTap: _openGarage,
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _tabs,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        onPressed: () => showDashboardQuickActionsSheet(context),
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
        shape: const CircularNotchedRectangle(),
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
                      icon: Icons.receipt_long_rounded,
                      label: 'navLogs'.tr(),
                      isSelected: _currentIndex == 1,
                      onTap: () => _onTabTapped(1),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 48),
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
