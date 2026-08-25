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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Reset Maintenance Cycle',
                style: GoogleFonts.inter(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Reset cycle for "${reminder.title}" at current odometer: ${currentOdo.toStringAsFixed(0)} km.',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: costController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  prefixText: '৳ ',
                  prefixStyle: const TextStyle(
                      color: AppColors.primary, fontWeight: FontWeight.bold),
                  labelText: 'Service Cost (Optional)',
                  labelStyle:
                      const TextStyle(color: AppColors.textTertiary, fontSize: 13),
                  filled: true,
                  fillColor: const Color(0xFF1E1E2A),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF2E2E3E)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF2E2E3E)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: AppColors.primary, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(ctx).pop(),
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
                                '✅ ${reminder.title} reset successfully!',
                                style: const TextStyle(color: Colors.white),
                              ),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Confirm',
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
                onSave: () {
                  ref.read(remindersProvider.notifier).loadReminders();
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
                padding: const EdgeInsets.only(top: 8, bottom: 40),
                children: [
                  // 1. Section Header
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
                                    onSave: () {
                                      ref.read(remindersProvider.notifier).loadReminders();
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
                                    onSave: () {
                                      ref.read(remindersProvider.notifier).loadReminders();
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
                            onSave: () {
                              ref
                                  .read(remindersProvider.notifier)
                                  .loadReminders();
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
