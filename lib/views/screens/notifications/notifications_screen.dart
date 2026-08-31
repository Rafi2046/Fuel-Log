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

  Color _severityAccent(NotificationSeverity severity) {
    switch (severity) {
      case NotificationSeverity.urgent:
        return const Color(0xFFEF4444);
      case NotificationSeverity.warning:
        return const Color(0xFFF59E0B);
      case NotificationSeverity.info:
        return AppColors.primary;
      case NotificationSeverity.success:
        return const Color(0xFF10B981);
    }
  }

  String _categoryLabel(NotificationCategory category) {
    switch (category) {
      case NotificationCategory.maintenance:
        return 'Maintenance';
      case NotificationCategory.weather:
        return 'Weather Advisory';
      case NotificationCategory.tips:
        return 'Efficiency Tip';
      case NotificationCategory.all:
        return 'Notification';
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
          title: '${r.title} is Overdue',
          message:
              '${r.statusMessage(currentOdometer)}. Schedule service to prevent vehicle wear.',
          category: NotificationCategory.maintenance,
          severity: NotificationSeverity.urgent,
          icon: LucideIcons.triangleAlert,
          timeAgo: 'Action Required',
          actionLabel: 'Open Services Hub',
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
          title: 'Upcoming: ${r.title}',
          message:
              '${r.statusMessage(currentOdometer)}. Inspection due shortly.',
          category: NotificationCategory.maintenance,
          severity: NotificationSeverity.warning,
          icon: LucideIcons.bellRing,
          timeAgo: 'Due Soon',
          actionLabel: 'Open Services Hub',
          onTap: () => ServicesScreen.open(context),
        ),
      );
    }

    // 3. Weather Safety Alert
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
                '${weatherAdvice.bodyKey.tr()} • ${weatherAdvice.snapshot.temperatureC.round()}°C',
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

    // 4. Vehicle Optimal Health Notification
    if (vehicle != null && overdueReminders.isEmpty && dueSoonReminders.isEmpty) {
      final id = 'vehicle_optimal_${vehicle.id}';
      if (!_dismissedIds.contains(id)) {
        list.add(
          AppNotificationItem(
            id: id,
            title: 'Vehicle Systems Optimal',
            message:
                'All maintenance schedules for ${vehicle.name} are currently in good health.',
            category: NotificationCategory.maintenance,
            severity: NotificationSeverity.success,
            icon: LucideIcons.shieldCheck,
            timeAgo: 'Active',
            actionLabel: 'View Services',
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
              'Record odometer and fuel volume at each fill-up to monitor consumption and detect issues.',
          category: NotificationCategory.tips,
          severity: NotificationSeverity.info,
          icon: LucideIcons.fuel,
          timeAgo: 'Tip',
          actionLabel: 'Log Refuel',
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
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: TextButton(
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
            ),
        ],
      ),
      body: Column(
        children: [
          // Sleek Segmented TabBar with 10px rounded corners
          _buildSegmentedFilterBar(allNotifications),

          const SizedBox(height: AppSpacing.xs),

          // Notifications Feed or Empty State
          Expanded(
            child: filtered.isEmpty
                ? _buildEmptyState()
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.screenPadding,
                      AppSpacing.xs,
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

  /// Refined segmented category bar with subtle 10px borders and no bubbly checkmarks
  Widget _buildSegmentedFilterBar(List<AppNotificationItem> all) {
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

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        AppSpacing.sm,
        AppSpacing.screenPadding,
        AppSpacing.xs,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: tabs.map((tab) {
            final isSelected = _selectedCategory == tab.$1;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: InkWell(
                onTap: () => setState(() => _selectedCategory = tab.$1),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF1E1E2C)
                        : const Color(0xFF14141E),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF3E3E56)
                          : const Color(0xFF222232),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        tab.$2,
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected
                              ? AppColors.textPrimary
                              : AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF2A2A3E)
                              : const Color(0xFF1A1A26),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${tab.$3}',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isSelected
                                ? AppColors.textPrimary
                                : AppColors.textTertiary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  /// Minimalist luxury notification card with quiet elegance and high readability
  Widget _buildNotificationCard(AppNotificationItem item) {
    final isUrgent = item.severity == NotificationSeverity.urgent;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF161622),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isUrgent
                  ? const Color(0xFFEF4444).withValues(alpha: 0.35)
                  : const Color(0xFF262638),
              width: 1,
            ),
          ),
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Unified tactile dark icon container
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E2C),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFF2A2A3E),
                    width: 1,
                  ),
                ),
                child: Icon(
                  item.icon,
                  size: 17,
                  color: isUrgent ? const Color(0xFFEF4444) : AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 12),

              // Main notification content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header metadata: category tag • time • dismiss
                    Row(
                      children: [
                        Text(
                          _categoryLabel(item.category),
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isUrgent
                                ? const Color(0xFFEF4444)
                                : AppColors.textTertiary,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          width: 3,
                          height: 3,
                          decoration: const BoxDecoration(
                            color: AppColors.textTertiary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          item.timeAgo,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textTertiary,
                          ),
                        ),
                        const Spacer(),
                        InkWell(
                          onTap: () =>
                              setState(() => _dismissedIds.add(item.id)),
                          borderRadius: BorderRadius.circular(10),
                          child: const Padding(
                            padding: EdgeInsets.all(2),
                            child: Icon(
                              Icons.close_rounded,
                              size: 15,
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),

                    // Title
                    Text(
                      item.title,
                      style: GoogleFonts.inter(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 3),

                    // Body
                    Text(
                      item.message,
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w400,
                        color: AppColors.textSecondary,
                        height: 1.35,
                      ),
                    ),

                    // Inline quiet action link if available
                    if (item.actionLabel != null) ...[
                      const SizedBox(height: 8),
                      Row(
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
                          const SizedBox(width: 3),
                          const Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 10,
                            color: AppColors.primary,
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
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
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E2C),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF2A2A3E)),
              ),
              child: const Icon(
                LucideIcons.bellOff,
                size: 24,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'notificationsEmptyTitle'.tr(),
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'notificationsEmptySubtitle'.tr(),
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 12.5,
                color: AppColors.textTertiary,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
