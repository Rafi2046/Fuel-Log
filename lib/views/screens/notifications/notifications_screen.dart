import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/database/app_database.dart';
import '../../../models/reminder_model.dart';
import '../../../models/weather_models.dart';
import '../../../viewmodels/fuel_log_viewmodel.dart';
import '../../../viewmodels/reminder_viewmodel.dart';
import '../../../viewmodels/vehicle_viewmodel.dart';
import '../../../viewmodels/weather_viewmodel.dart';
import '../../widgets/app_app_bar.dart';
import '../../widgets/app_card.dart';
import '../refueling_form_screen.dart';
import '../services/services_screen.dart';

enum NotificationCategory { all, maintenance, weather, tips }

enum NotificationSeverity { urgent, warning, info, success }

class AppNotificationItem {
  const AppNotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.category,
    required this.severity,
    required this.icon,
    required this.timeAgo,
    this.actionLabel,
    this.onTap,
  });

  final String id;
  final String title;
  final String message;
  final NotificationCategory category;
  final NotificationSeverity severity;
  final IconData icon;
  final String timeAgo;
  final String? actionLabel;
  final VoidCallback? onTap;
}

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  static Future<void> open(BuildContext context) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const NotificationsScreen(),
      ),
    );
  }

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  NotificationCategory _selectedCategory = NotificationCategory.all;
  final Set<String> _dismissedIds = {};

  Color _severityColor(NotificationSeverity severity) {
    switch (severity) {
      case NotificationSeverity.urgent:
        return AppColors.error;
      case NotificationSeverity.warning:
        return const Color(0xFFFBBF24); // Amber
      case NotificationSeverity.info:
        return const Color(0xFF60A5FA); // Blue
      case NotificationSeverity.success:
        return AppColors.success;
    }
  }

  String _categoryBadgeText(NotificationCategory category) {
    switch (category) {
      case NotificationCategory.maintenance:
        return 'MAINTENANCE';
      case NotificationCategory.weather:
        return 'WEATHER ADVISORY';
      case NotificationCategory.tips:
        return 'SMART TIP';
      case NotificationCategory.all:
        return 'NOTIFICATION';
    }
  }

  List<AppNotificationItem> _buildNotifications({
    required Vehicle? vehicle,
    required List<ServiceReminder> overdueReminders,
    required List<ServiceReminder> dueSoonReminders,
    required DriveAdvice? weatherAdvice,
    required double currentOdometer,
    required bool hasFuelLogs,
  }) {
    final list = <AppNotificationItem>[];

    // 1. Overdue Service Alerts
    for (final r in overdueReminders) {
      final id = 'overdue_${r.id}';
      if (_dismissedIds.contains(id)) continue;
      list.add(
        AppNotificationItem(
          id: id,
          title: '${r.title} is Overdue!',
          message:
              'Scheduled maintenance limit exceeded (${r.statusMessage(currentOdometer)}). Service your vehicle now to prevent wear.',
          category: NotificationCategory.maintenance,
          severity: NotificationSeverity.urgent,
          icon: LucideIcons.triangleAlert,
          timeAgo: 'Action Required',
          actionLabel: 'View in Services',
          onTap: () => ServicesScreen.open(context),
        ),
      );
    }

    // 2. Due Soon Service Alerts
    for (final r in dueSoonReminders) {
      final id = 'due_soon_${r.id}';
      if (_dismissedIds.contains(id)) continue;
      list.add(
        AppNotificationItem(
          id: id,
          title: 'Upcoming Service: ${r.title}',
          message:
              'Maintenance due soon (${r.statusMessage(currentOdometer)}). Prepare for scheduled inspection.',
          category: NotificationCategory.maintenance,
          severity: NotificationSeverity.warning,
          icon: LucideIcons.bellRing,
          timeAgo: 'Due Soon',
          actionLabel: 'View in Services',
          onTap: () => ServicesScreen.open(context),
        ),
      );
    }

    // 3. Weather Safety Alert (if rainy or hazardous driving)
    if (weatherAdvice != null) {
      final isCautionOrAvoid = weatherAdvice.level == DriveAdviceLevel.caution ||
          weatherAdvice.level == DriveAdviceLevel.avoid;

      final weatherId = 'weather_daily_alert';
      if (!_dismissedIds.contains(weatherId)) {
        list.add(
          AppNotificationItem(
            id: weatherId,
            title: weatherAdvice.titleKey.tr(),
            message:
                '${weatherAdvice.bodyKey.tr()} • Temperature ${weatherAdvice.snapshot.temperatureC.round()}°C',
            category: NotificationCategory.weather,
            severity: isCautionOrAvoid
                ? (weatherAdvice.level == DriveAdviceLevel.avoid
                    ? NotificationSeverity.urgent
                    : NotificationSeverity.warning)
                : NotificationSeverity.info,
            icon: weatherAdvice.lucideIcon,
            timeAgo: 'Today',
          ),
        );
      }
    }

    // 4. Vehicle Optimal Health Notification (if no overdue or due-soon)
    if (vehicle != null && overdueReminders.isEmpty && dueSoonReminders.isEmpty) {
      final id = 'vehicle_optimal_${vehicle.id}';
      if (!_dismissedIds.contains(id)) {
        list.add(
          AppNotificationItem(
            id: id,
            title: 'Vehicle Status: All Systems Optimal',
            message:
                'All service schedules and maintenance checks for ${vehicle.name} are currently in good health.',
            category: NotificationCategory.maintenance,
            severity: NotificationSeverity.success,
            icon: LucideIcons.shieldCheck,
            timeAgo: 'Active',
            actionLabel: 'Open Services Hub',
            onTap: () => ServicesScreen.open(context),
          ),
        );
      }
    }

    // 5. Fuel / Efficiency Tracking Tip
    final fuelTipId = 'fuel_economy_tip';
    if (!_dismissedIds.contains(fuelTipId)) {
      list.add(
        AppNotificationItem(
          id: fuelTipId,
          title: 'Fuel Economy & Mileage Logging',
          message:
              'Record your exact odometer and fuel volume at each fill-up to monitor fuel consumption and detect leaks early.',
          category: NotificationCategory.tips,
          severity: NotificationSeverity.info,
          icon: LucideIcons.fuel,
          timeAgo: 'Smart Tip',
          actionLabel: 'Log Fueling',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const RefuelingFormScreen(),
              ),
            );
          },
        ),
      );
    }

    return list;
  }

  @override
  Widget build(BuildContext context) {
    final vehicle = ref.watch(activeVehicleProvider).valueOrNull;
    final remindersState = ref.watch(remindersProvider);
    final weatherAdvice = ref.watch(weatherAdviceProvider).valueOrNull;
    final logsAsync = ref.watch(vehicleLogsProvider);
    final fuelLogs = logsAsync.valueOrNull ?? [];

    final activeReminders = remindersState.activeReminders;
    final overdueReminders = activeReminders
        .where((r) =>
            r.status(remindersState.currentOdometer) == ReminderStatus.overdue)
        .toList();
    final dueSoonReminders = activeReminders
        .where((r) =>
            r.status(remindersState.currentOdometer) == ReminderStatus.dueSoon)
        .toList();

    final allNotifications = _buildNotifications(
      vehicle: vehicle,
      overdueReminders: overdueReminders,
      dueSoonReminders: dueSoonReminders,
      weatherAdvice: weatherAdvice,
      currentOdometer: remindersState.currentOdometer,
      hasFuelLogs: fuelLogs.isNotEmpty,
    );

    final filtered = allNotifications.where((n) {
      if (_selectedCategory == NotificationCategory.all) return true;
      return n.category == _selectedCategory;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppAppBar(
        leading: const AppBackButton(),
        title: 'notificationsTitle'.tr(),
        actions: [
          if (allNotifications.isNotEmpty)
            TextButton(
              onPressed: () {
                setState(() {
                  _dismissedIds.addAll(allNotifications.map((n) => n.id));
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('notificationsMarkRead'.tr()),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: Text(
                'notificationsClearAll'.tr(),
                style: GoogleFonts.inter(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Category Filter Tabs
          _buildFilterTabs(allNotifications),

          // Notifications Feed or Empty State
          Expanded(
            child: filtered.isEmpty
                ? _buildEmptyState()
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.screenPadding,
                      AppSpacing.sm,
                      AppSpacing.screenPadding,
                      AppSpacing.xl,
                    ),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, index) {
                      final item = filtered[index];
                      return _buildNotificationCard(item);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs(List<AppNotificationItem> all) {
    final maintenanceCount = all
        .where((n) => n.category == NotificationCategory.maintenance)
        .length;
    final weatherCount =
        all.where((n) => n.category == NotificationCategory.weather).length;
    final tipsCount =
        all.where((n) => n.category == NotificationCategory.tips).length;

    final tabs = [
      (NotificationCategory.all, 'notificationsAll'.tr(), all.length),
      (
        NotificationCategory.maintenance,
        'notificationsMaintenance'.tr(),
        maintenanceCount
      ),
      (NotificationCategory.weather, 'notificationsWeather'.tr(), weatherCount),
      (NotificationCategory.tips, 'notificationsTips'.tr(), tipsCount),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPadding,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: tabs.map((tab) {
          final isSelected = _selectedCategory == tab.$1;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text('${tab.$2} (${tab.$3})'),
              selected: isSelected,
              onSelected: (_) => setState(() => _selectedCategory = tab.$1),
              selectedColor: AppColors.primary.withValues(alpha: 0.16),
              backgroundColor: const Color(0xFF1E1E2C),
              side: BorderSide(
                color: isSelected
                    ? AppColors.primary
                    : const Color(0xFF2A2A3E),
                width: 1,
              ),
              labelStyle: GoogleFonts.inter(
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildNotificationCard(AppNotificationItem item) {
    final sevColor = _severityColor(item.severity);

    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top metadata row
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: sevColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: sevColor.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(item.icon, size: 12, color: sevColor),
                    const SizedBox(width: 4),
                    Text(
                      _categoryBadgeText(item.category),
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: sevColor,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                item.timeAgo,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textTertiary,
                ),
              ),
              const SizedBox(width: 6),
              InkWell(
                onTap: () {
                  setState(() => _dismissedIds.add(item.id));
                },
                borderRadius: BorderRadius.circular(12),
                child: const Padding(
                  padding: EdgeInsets.all(2),
                  child: Icon(
                    Icons.close_rounded,
                    size: 16,
                    color: AppColors.textTertiary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Title & Body
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: sevColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: sevColor.withValues(alpha: 0.2)),
                ),
                child: Icon(item.icon, size: 18, color: sevColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.message,
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w400,
                        color: AppColors.textSecondary,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Action Button (if any)
          if (item.actionLabel != null && item.onTap != null) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: InkWell(
                onTap: item.onTap,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        item.actionLabel!,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 11,
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E2C),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF2A2A3E)),
              ),
              child: const Icon(
                LucideIcons.bellOff,
                size: 28,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'notificationsEmptyTitle'.tr(),
              style: AppTextStyles.title.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'notificationsEmptySubtitle'.tr(),
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySecondary.copyWith(
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
