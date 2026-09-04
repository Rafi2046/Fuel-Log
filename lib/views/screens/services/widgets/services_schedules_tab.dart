import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../viewmodels/reminder_viewmodel.dart';
import '../../../../viewmodels/vehicle_viewmodel.dart';
import '../../../widgets/app_primary_button.dart';
import '../../../widgets/app_shimmer.dart';
import '../../reminders/widgets/add_reminder_sheet.dart';
import '../../reminders/widgets/reminder_card.dart';
import 'complete_service_dialog.dart';

/// Schedules tab in ServicesScreen.
class ServicesSchedulesTab extends ConsumerWidget {
  const ServicesSchedulesTab({
    super.key,
    required this.state,
    required this.onAddReminder,
  });

  final RemindersState state;
  final VoidCallback onAddReminder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (state.isLoading && state.reminders.isEmpty) {
      return const ServicesSkeleton();
    }

    final activeList = state.activeReminders;

    if (activeList.isEmpty) {
      return AppRefreshIndicator(
        onRefresh: () async {
          await ref.read(remindersProvider.notifier).loadReminders();
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: MediaQuery.sizeOf(context).height * 0.2,
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.wash,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Icon(
                        Icons.alarm_on_rounded,
                        size: 32,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No Maintenance Schedules Set',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Set service reminders for engine oil, filters, brake pads, and tire rotation.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    AppPrimaryButton(
                      label: 'servicesAddReminder'.tr(),
                      icon: Icons.add_rounded,
                      compact: true,
                      onPressed: onAddReminder,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return AppRefreshIndicator(
      onRefresh: () async {
        await ref.read(remindersProvider.notifier).loadReminders();
      },
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(0, 8, 0, 80),
        itemCount: activeList.length,
        itemBuilder: (ctx, idx) {
          final reminder = activeList[idx];
          return ReminderCard(
            reminder: reminder,
            currentOdometer: state.currentOdometer,
            onMarkDone: () => CompleteServiceDialog.show(context, reminder),
            onEdit: () async {
              final vehicle = ref.read(activeVehicleProvider).valueOrNull;
              if (vehicle == null) return;
              final numId = int.tryParse(reminder.id);
              if (numId == null) return;
              final db = ref.read(databaseProvider);
              final driftReminder = await db.getReminderById(numId);
              if (driftReminder == null || !context.mounted) return;
              AddReminderSheet.show(
                context,
                vehicleId: vehicle.id,
                currentOdometer: state.currentOdometer,
                existingReminder: driftReminder,
                onSave: () =>
                    ref.read(remindersProvider.notifier).loadReminders(),
              );
            },
            onDelete: () =>
                ref.read(remindersProvider.notifier).deleteReminder(reminder.id),
          );
        },
      ),
    );
  }
}
