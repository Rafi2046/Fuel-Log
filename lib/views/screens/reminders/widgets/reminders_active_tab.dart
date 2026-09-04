import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/database/app_database.dart';
import '../../../../models/reminder_model.dart';
import '../../../../viewmodels/reminder_viewmodel.dart';
import '../../../../viewmodels/vehicle_viewmodel.dart';
import '../../../widgets/app_shimmer.dart';
import 'add_reminder_sheet.dart';
import 'reminder_card.dart';

/// Active maintenance reminders list tab in RemindersScreen.
class RemindersActiveTab extends ConsumerStatefulWidget {
  const RemindersActiveTab({
    super.key,
    required this.state,
    required this.vehicle,
  });

  final RemindersState state;
  final Vehicle? vehicle;

  @override
  ConsumerState<RemindersActiveTab> createState() => _RemindersActiveTabState();
}

class _RemindersActiveTabState extends ConsumerState<RemindersActiveTab> {
  void _showMarkDoneDialog(
    BuildContext context,
    ServiceReminder reminder,
    double currentOdo,
  ) {
    final costController = TextEditingController();
    final notesController = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.appBar,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: AppColors.hairline),
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
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: costController,
                keyboardType: TextInputType.number,
                style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  prefixText: '৳ ',
                  prefixStyle: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                  labelText: 'Service Cost (Optional)',
                  labelStyle: TextStyle(
                    color: AppColors.textTertiary,
                    fontSize: 13,
                  ),
                  filled: true,
                  fillColor: const Color(0xFF1E1E2A),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
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
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 1.5,
                    ),
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
                        child: Text(
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
                        onPressed: () async {
                          final cost =
                              double.tryParse(costController.text.trim());
                          await ref.read(remindersProvider.notifier).markAsDone(
                                reminder.id,
                                cost: cost,
                                notes: notesController.text.trim().isEmpty
                                    ? null
                                    : notesController.text.trim(),
                              );
                          if (!ctx.mounted) return;
                          Navigator.of(ctx).pop();
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: AppColors.control,
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
  Widget build(BuildContext context) {
    final state = widget.state;
    final vehicle = widget.vehicle;

    if (state.isLoading && state.reminders.isEmpty) {
      return const RemindersSkeleton();
    }

    return AppRefreshIndicator(
      onRefresh: () async {
        await ref.read(remindersProvider.notifier).loadReminders();
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(top: 4, bottom: 40),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenPadding,
              vertical: 6,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'UPCOMING MAINTENANCE',
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  '${state.reminders.length} Active',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (state.reminders.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenPadding,
                vertical: 24,
              ),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.appBar,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.hairline),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_circle_outline_rounded,
                        color: AppColors.primary,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'All Scheduled Maintenance Up-to-Date',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Tap the + icon at top right to add a custom maintenance interval for engine oil, coolant, battery, etc.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...state.reminders.map((reminder) {
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenPadding,
                  vertical: 6,
                ),
                child: ReminderCard(
                  reminder: reminder,
                  currentOdometer: state.currentOdometer,
                  onEdit: () async {
                    if (vehicle == null) return;
                    final numId = int.tryParse(reminder.id);
                    if (numId == null) return;
                    final db = ref.read(databaseProvider);
                    final driftReminder = await db.getReminderById(numId);
                    if (!mounted || !context.mounted) return;
                    if (driftReminder == null) return;
                    AddReminderSheet.show(
                      context,
                      vehicleId: vehicle.id,
                      currentOdometer: state.currentOdometer,
                      existingReminder: driftReminder,
                      onSave: () {
                        ref.read(remindersProvider.notifier).loadReminders();
                      },
                    );
                  },
                  onDelete: () {
                    ref
                        .read(remindersProvider.notifier)
                        .deleteReminder(reminder.id);
                  },
                  onMarkDone: () {
                    _showMarkDoneDialog(
                      context,
                      reminder,
                      state.currentOdometer,
                    );
                  },
                ),
              );
            }),
        ],
      ),
    );
  }
}
