import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../models/reminder_model.dart';
import '../../../viewmodels/reminder_viewmodel.dart';
import '../../../viewmodels/vehicle_viewmodel.dart';
import 'widgets/add_reminder_sheet.dart';
import 'widgets/reminder_card.dart';
import 'widgets/reminder_health_overview.dart';

/// Main Vehicle Maintenance & Service Reminders Hub
class RemindersScreen extends ConsumerWidget {
  const RemindersScreen({super.key});

  void _showMarkDoneDialog(
    BuildContext context,
    WidgetRef ref,
    ServiceReminder reminder,
    double currentOdo,
  ) {
    final costController = TextEditingController();
    final notesController = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF181824),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: AppColors.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Mark as Completed',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reset cycle for "${reminder.title}" at current odometer: ${currentOdo.toStringAsFixed(0)} km.',
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: costController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                prefixText: '৳ ',
                labelText: 'Service Cost (Optional)',
                labelStyle: const TextStyle(color: AppColors.textTertiary),
                filled: true,
                fillColor: const Color(0xFF222230),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFF333345)),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              final cost = double.tryParse(costController.text.trim());
              ref.read(remindersProvider.notifier).markAsDone(
                    reminder.id,
                    cost: cost,
                    notes: notesController.text.trim().isEmpty
                        ? null
                        : notesController.text.trim(),
                  );
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: const Color(0xFF1E1E2C),
                  content: Text(
                    '✅ ${reminder.title} marked as completed & cycle reset!',
                    style: const TextStyle(color: Colors.white),
                  ),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Confirm Reset', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(remindersProvider);
    final vehicle = ref.watch(activeVehicleProvider).valueOrNull;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D12),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D12),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          color: AppColors.textPrimary,
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Maintenance & Services',
              style: GoogleFonts.inter(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            if (vehicle != null)
              Text(
                vehicle.name,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, color: AppColors.primary, size: 24),
            tooltip: 'Add Reminder',
            onPressed: () {
              if (vehicle == null) return;
              AddReminderSheet.show(
                context,
                vehicleId: vehicle.id,
                currentOdometer: state.currentOdometer,
                onSave: (newReminder) {
                  ref.read(remindersProvider.notifier).addReminder(newReminder);
                },
              );
            },
          ),
        ],
      ),
      body: state.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : RefreshIndicator(
              color: AppColors.primary,
              backgroundColor: AppColors.cardElevated,
              onRefresh: () => ref.read(remindersProvider.notifier).loadReminders(),
              child: ListView(
                padding: const EdgeInsets.only(bottom: 40),
                children: [
                  // 1. Vehicle Maintenance Health Overview
                  ReminderHealthOverview(
                    state: state,
                    vehicleName: vehicle?.name ?? 'My Vehicle',
                  ),

                  const SizedBox(height: 12),

                  // 2. Section Header
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.screenPadding,
                      vertical: 6,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'ACTIVE REMINDERS',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                            color: AppColors.textTertiary,
                          ),
                        ),
                        Text(
                          '${state.activeReminders.length} items',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 3. Reminders List
                  if (state.activeReminders.isEmpty)
                    Container(
                      margin: const EdgeInsets.all(AppSpacing.screenPadding),
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(0xFF16161D),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF262632)),
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.notifications_active_outlined,
                              color: AppColors.primary,
                              size: 32,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'No Reminders Yet',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Add maintenance reminders to track oil life and receive alerts when servicing is due.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12.5,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 18),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            alignment: WrapAlignment.center,
                            children: [
                              ActionChip(
                                avatar: const Icon(Icons.oil_barrel_rounded, size: 16, color: AppColors.primary),
                                label: const Text('Add Engine Oil'),
                                backgroundColor: const Color(0xFF22222E),
                                side: const BorderSide(color: Color(0xFF333345)),
                                labelStyle: const TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600),
                                onPressed: () {
                                  if (vehicle == null) return;
                                  AddReminderSheet.show(
                                    context,
                                    vehicleId: vehicle.id,
                                    currentOdometer: state.currentOdometer,
                                    onSave: (newReminder) {
                                      ref.read(remindersProvider.notifier).addReminder(newReminder);
                                    },
                                  );
                                },
                              ),
                              ActionChip(
                                avatar: const Icon(Icons.build_rounded, size: 16, color: AppColors.primary),
                                label: const Text('Add Servicing'),
                                backgroundColor: const Color(0xFF22222E),
                                side: const BorderSide(color: Color(0xFF333345)),
                                labelStyle: const TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600),
                                onPressed: () {
                                  if (vehicle == null) return;
                                  AddReminderSheet.show(
                                    context,
                                    vehicleId: vehicle.id,
                                    currentOdometer: state.currentOdometer,
                                    onSave: (newReminder) {
                                      ref.read(remindersProvider.notifier).addReminder(newReminder);
                                    },
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    )
                  else
                    ...state.activeReminders.map((reminder) {
                      return ReminderCard(
                        reminder: reminder,
                        currentOdometer: state.currentOdometer,
                        onMarkDone: () => _showMarkDoneDialog(
                          context,
                          ref,
                          reminder,
                          state.currentOdometer,
                        ),
                        onEdit: () {
                          if (vehicle == null) return;
                          AddReminderSheet.show(
                            context,
                            vehicleId: vehicle.id,
                            currentOdometer: state.currentOdometer,
                            existingReminder: reminder,
                            onSave: (updated) {
                              ref
                                  .read(remindersProvider.notifier)
                                  .updateReminder(updated);
                            },
                          );
                        },
                        onDelete: () {
                          ref
                              .read(remindersProvider.notifier)
                              .deleteReminder(reminder.id);
                        },
                      );
                    }),
                ],
              ),
            ),
    );
  }
}
