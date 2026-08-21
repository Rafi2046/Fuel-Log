import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_motion.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_text_styles.dart';

import 'refueling_form_screen.dart';
import 'tabs/dashboard_view.dart';
import 'tabs/garage_view.dart';
import 'tabs/logs_view.dart';
import 'tabs/settings_view.dart';

/// Main Dashboard screen holding BottomAppBar with central notched FAB and tab switching.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;
  final String _selectedVehicle = 'Toyota Axio 🚘';

  final List<Widget> _views = const [
    DashboardView(),
    LogsView(),
    GarageView(),
    SettingsView(),
  ];

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  PreferredSizeWidget _buildAppBar() {
    switch (_currentIndex) {
      case 0:
        return AppBar(
          centerTitle: false,
          elevation: 0,
          backgroundColor: AppColors.background,
          title: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: AppColors.cardElevated,
              borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _selectedVehicle,
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
              ],
            ),
          ),
        );
      case 1:
        return AppBar(
          title: const Text('Logs'),
          actions: [
            IconButton(
              icon: const Icon(Icons.filter_list_rounded),
              color: AppColors.primary,
              tooltip: 'Filter Logs',
              onPressed: () {},
            ),
          ],
        );
      case 2:
        return AppBar(
          title: const Text('My Garage'),
        );
      case 3:
        return AppBar(
          title: const Text('Settings'),
        );
      default:
        return AppBar();
    }
  }

  void _showAddFuelBottomSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.card,
      elevation: 8,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusLg),
        ),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top drag handle pill
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusPill),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Quick Actions',
                  style: AppTextStyles.title.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // Action 1: Refueling
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.local_gas_station_rounded,
                      color: AppColors.primary,
                    ),
                  ),
                  title: Text('Refueling', style: AppTextStyles.body),
                  subtitle: Text(
                    'Log fuel purchase and odometer',
                    style: AppTextStyles.caption,
                  ),
                  trailing: const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textTertiary,
                  ),
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const RefuelingFormScreen(),
                      ),
                    );
                  },
                ),
                const Divider(color: AppColors.divider),

                // Action 2: Add Cost
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.attach_money_rounded,
                      color: AppColors.secondary,
                    ),
                  ),
                  title: Text('Add Cost', style: AppTextStyles.body),
                  subtitle: Text(
                    'Track maintenance, parking, service fees',
                    style: AppTextStyles.caption,
                  ),
                  trailing: const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textTertiary,
                  ),
                  onTap: () {
                    Navigator.of(context).pop();
                  },
                ),
                const Divider(color: AppColors.divider),

                // Action 3: Add Reminder
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.notifications_rounded,
                      color: AppColors.warning,
                    ),
                  ),
                  title: Text('Add Reminder', style: AppTextStyles.body),
                  subtitle: Text(
                    'Set oil change or insurance alert',
                    style: AppTextStyles.caption,
                  ),
                  trailing: const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textTertiary,
                  ),
                  onTap: () {
                    Navigator.of(context).pop();
                  },
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: IndexedStack(
        index: _currentIndex,
        children: _views,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddFuelBottomSheet,
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
        notchMargin: 8.0,
        elevation: 10,
        padding: EdgeInsets.zero,
        child: SizedBox(
          height: 64,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Left Tab Items (Home, Logs)
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _NavBarItem(
                      icon: Icons.home_rounded,
                      label: 'Home',
                      isSelected: _currentIndex == 0,
                      onTap: () => _onTabTapped(0),
                    ),
                    _NavBarItem(
                      icon: Icons.receipt_long_rounded,
                      label: 'Logs',
                      isSelected: _currentIndex == 1,
                      onTap: () => _onTabTapped(1),
                    ),
                  ],
                ),
              ),

              // Spacer gap for the central notched FAB
              const SizedBox(width: 48),

              // Right Tab Items (Garage, Settings)
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _NavBarItem(
                      icon: Icons.directions_car_rounded,
                      label: 'Garage',
                      isSelected: _currentIndex == 2,
                      onTap: () => _onTabTapped(2),
                    ),
                    _NavBarItem(
                      icon: Icons.settings_rounded,
                      label: 'Settings',
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

/// Helper navigation bar item widget with smooth animations
class _NavBarItem extends StatelessWidget {
  const _NavBarItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? AppColors.primary : AppColors.textTertiary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs,
          vertical: AppSpacing.xs,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: AppMotion.fast,
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(height: 2),
            AnimatedDefaultTextStyle(
              duration: AppMotion.fast,
              style: AppTextStyles.caption.copyWith(
                color: color,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}
