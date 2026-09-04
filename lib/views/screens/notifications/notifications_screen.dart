import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/database/app_database.dart';
import '../../../models/reminder_model.dart';
import '../../../models/weather_models.dart';
import '../../../viewmodels/fuel_log_viewmodel.dart';
import '../../../viewmodels/notification_inbox_viewmodel.dart';
import '../../../viewmodels/reminder_viewmodel.dart';
import '../../../viewmodels/vehicle_viewmodel.dart';
import '../../../viewmodels/weather_viewmodel.dart';
import '../../widgets/app_app_bar.dart';
import '../../widgets/app_shimmer.dart';
import '../refueling_form_screen.dart';
import '../services/services_screen.dart';
import 'models/app_notification_item.dart';
import 'widgets/notification_category_filter_bar.dart';
import 'widgets/notification_empty_state.dart';
import 'widgets/notification_item_card.dart';

export 'models/app_notification_item.dart';

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

  List<AppNotificationItem> _buildNotifications({
    required Vehicle? vehicle,
    required List<ServiceReminder> overdueReminders,
    required List<ServiceReminder> dueSoonReminders,
    required DriveAdvice? weatherAdvice,
    required double currentOdometer,
    required Set<String> dismissedIds,
  }) {
    final list = <AppNotificationItem>[];

    for (final r in overdueReminders) {
      final id = 'overdue_${r.id}';
      if (dismissedIds.contains(id)) continue;
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
          onTap: () async {
            await ref.read(notificationInboxProvider.notifier).dismiss(id);
            if (!mounted) return;
            await ServicesScreen.open(context);
          },
        ),
      );
    }

    for (final r in dueSoonReminders) {
      final id = 'due_soon_${r.id}';
      if (dismissedIds.contains(id)) continue;
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
          onTap: () async {
            await ref.read(notificationInboxProvider.notifier).dismiss(id);
            if (!mounted) return;
            await ServicesScreen.open(context);
          },
        ),
      );
    }

    if (weatherAdvice != null) {
      final isCautionOrAvoid = weatherAdvice.level == DriveAdviceLevel.caution ||
          weatherAdvice.level == DriveAdviceLevel.avoid;

      const weatherId = 'weather_daily_alert';
      if (!dismissedIds.contains(weatherId)) {
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
            onTap: () => ref
                .read(notificationInboxProvider.notifier)
                .dismiss(weatherId),
          ),
        );
      }
    }

    if (vehicle != null &&
        overdueReminders.isEmpty &&
        dueSoonReminders.isEmpty) {
      final id = 'vehicle_optimal_${vehicle.id}';
      if (!dismissedIds.contains(id)) {
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
            onTap: () async {
              await ref.read(notificationInboxProvider.notifier).dismiss(id);
              if (!mounted) return;
              await ServicesScreen.open(context);
            },
          ),
        );
      }
    }

    const fuelTipId = 'fuel_economy_tip';
    if (!dismissedIds.contains(fuelTipId)) {
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
          onTap: () async {
            await ref
                .read(notificationInboxProvider.notifier)
                .dismiss(fuelTipId);
            if (!mounted) return;
            await Navigator.of(context).push(
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
    final dismissedIds = ref.watch(notificationInboxProvider);

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
      dismissedIds: dismissedIds,
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
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  final ids = allNotifications.map((n) => n.id).toList();
                  await ref
                      .read(notificationInboxProvider.notifier)
                      .dismissAll(ids);
                  messenger.showSnackBar(
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
          NotificationCategoryFilterBar(
            selectedCategory: _selectedCategory,
            onSelectCategory: (cat) => setState(() => _selectedCategory = cat),
            allNotifications: allNotifications,
          ),
          const SizedBox(height: AppSpacing.xs),
          Expanded(
            child: AppRefreshIndicator(
              onRefresh: () async {
                ref.invalidate(vehicleLogsProvider);
                ref.invalidate(remindersProvider);
                ref.invalidate(weatherAdviceProvider);
              },
              child: filtered.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(
                          height: MediaQuery.sizeOf(context).height * 0.25,
                        ),
                        const NotificationEmptyState(),
                      ],
                    )
                  : ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.screenPadding,
                        AppSpacing.xs,
                        AppSpacing.screenPadding,
                        AppSpacing.xl,
                      ),
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (context, index) {
                        final item = filtered[index];
                        return NotificationItemCard(
                          item: item,
                          onDismiss: () => ref
                              .read(notificationInboxProvider.notifier)
                              .dismiss(item.id),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
