import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/database/app_database.dart';
import '../../../models/reminder_model.dart';
import '../../../viewmodels/fuel_log_viewmodel.dart';
import '../../../viewmodels/reminder_viewmodel.dart';
import '../../../viewmodels/service_log_viewmodel.dart';
import '../../../viewmodels/vehicle_viewmodel.dart';
import '../services/widgets/add_cost_service_sheet.dart';
import 'widgets/add_reminder_sheet.dart';
import 'widgets/reminder_card.dart';

/// Main Vehicle Maintenance & Service Reminders Hub
class RemindersScreen extends ConsumerStatefulWidget {
  const RemindersScreen({super.key, this.initialTabIndex = 0});

  final int initialTabIndex;

  @override
  ConsumerState<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends ConsumerState<RemindersScreen> {
  late int _selectedTabIndex;

  @override
  void initState() {
    super.initState();
    _selectedTabIndex = widget.initialTabIndex;
  }

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
                style:
                    const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  prefixText: '৳ ',
                  prefixStyle: const TextStyle(
                      color: AppColors.primary, fontWeight: FontWeight.bold),
                  labelText: 'Service Cost (Optional)',
                  labelStyle: const TextStyle(
                      color: AppColors.textTertiary, fontSize: 13),
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
                        onPressed: () async {
                          final cost = double.tryParse(costController.text.trim());
                          await ref.read(remindersProvider.notifier).markAsDone(
                                reminder.id,
                                cost: cost,
                                notes: notesController.text.trim().isEmpty
                                    ? null
                                    : notesController.text.trim(),
                              );
                          if (!ctx.mounted) return;
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

  IconData _getCategoryIcon(String category) {
    final lower = category.toLowerCase();
    if (lower.contains('maintenance')) return Icons.build_rounded;
    if (lower.contains('parking') || lower.contains('toll')) {
      return Icons.local_parking_rounded;
    }
    if (lower.contains('tax') ||
        lower.contains('legal') ||
        lower.contains('document')) {
      return Icons.description_rounded;
    }
    if (lower.contains('wash') || lower.contains('detailing')) {
      return Icons.clean_hands_rounded;
    }
    if (lower.contains('parts') || lower.contains('accessories')) {
      return Icons.shopping_bag_rounded;
    }
    return Icons.receipt_long_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(remindersProvider);
    final vehicle = ref.watch(activeVehicleProvider).valueOrNull;
    final serviceLogsAsync = ref.watch(serviceLogsProvider);

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
            icon: const Icon(Icons.add_rounded,
                color: AppColors.primary, size: 24),
            tooltip: _selectedTabIndex == 0 ? 'Add Reminder' : 'Add Expense',
            onPressed: () {
              if (vehicle == null) return;
              if (_selectedTabIndex == 0) {
                AddReminderSheet.show(
                  context,
                  vehicleId: vehicle.id,
                  currentOdometer: state.currentOdometer,
                  onSave: () {
                    ref.read(remindersProvider.notifier).loadReminders();
                  },
                );
              } else {
                final logs = ref.read(vehicleLogsProvider).valueOrNull ?? [];
                final currentOdo =
                    logs.isNotEmpty ? logs.first.odometer : vehicle.startOdo;
                AddCostServiceSheet.show(
                  context,
                  vehicleId: vehicle.id,
                  currentOdometer: currentOdo,
                );
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Segmented Tab Toggle Bar
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenPadding,
              vertical: 8,
            ),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _selectedTabIndex = 0),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      decoration: BoxDecoration(
                        color: _selectedTabIndex == 0
                            ? AppColors.primary.withValues(alpha: 0.18)
                            : const Color(0xFF161622),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _selectedTabIndex == 0
                              ? AppColors.primary
                              : const Color(0xFF262638),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          'Active Reminders',
                          style: TextStyle(
                            color: _selectedTabIndex == 0
                                ? AppColors.primary
                                : AppColors.textSecondary,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _selectedTabIndex = 1),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      decoration: BoxDecoration(
                        color: _selectedTabIndex == 1
                            ? const Color(0xFF2ECC71).withValues(alpha: 0.18)
                            : const Color(0xFF161622),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _selectedTabIndex == 1
                              ? const Color(0xFF2ECC71)
                              : const Color(0xFF262638),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          'Cost & Service History',
                          style: TextStyle(
                            color: _selectedTabIndex == 1
                                ? const Color(0xFF2ECC71)
                                : AppColors.textSecondary,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: _selectedTabIndex == 0
                ? _buildRemindersList(state, vehicle)
                : _buildServiceHistoryList(serviceLogsAsync),
          ),
        ],
      ),
    );
  }

  Widget _buildRemindersList(RemindersState state, Vehicle? vehicle) {
    if (state.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      backgroundColor: AppColors.cardElevated,
      onRefresh: () => ref.read(remindersProvider.notifier).loadReminders(),
      child: ListView(
        padding: const EdgeInsets.only(top: 4, bottom: 40),
        children: [
          // Section Header
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

          if (state.activeReminders.isEmpty)
            Container(
              margin: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenPadding,
                vertical: 20,
              ),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF161622),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF262638)),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.notifications_none_rounded,
                      color: AppColors.primary,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No Active Reminders',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Add maintenance reminders to track oil life and receive alerts.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: AppColors.textSecondary,
                    ),
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
                  final numId = int.tryParse(reminder.id);
                  AddReminderSheet.show(
                    context,
                    vehicleId: vehicle.id,
                    currentOdometer: state.currentOdometer,
                    existingReminder: numId != null
                        ? Reminder(
                            id: numId,
                            vehicleId: reminder.vehicleId,
                            title: reminder.title,
                            targetDate: reminder.targetDate,
                            targetOdometer: reminder.targetOdo,
                            isCompleted: reminder.isCompleted,
                          )
                        : null,
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
              );
            }),
        ],
      ),
    );
  }

  Widget _buildServiceHistoryList(AsyncValue<List<ServiceLog>> logsAsync) {
    final dateFormat = DateFormat('MMM dd, yyyy');

    return logsAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: Color(0xFF2ECC71)),
      ),
      error: (e, _) => Center(
        child: Text('Error: $e',
            style: const TextStyle(color: AppColors.textSecondary)),
      ),
      data: (logs) {
        if (logs.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2ECC71).withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.receipt_long_rounded,
                      color: Color(0xFF2ECC71),
                      size: 36,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'No Cost & Service Records Yet',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Tap + at the top or quick actions to record parking fees, tolls, car wash, or service bills.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenPadding,
            vertical: 8,
          ),
          itemCount: logs.length,
          itemBuilder: (context, index) {
            final item = logs[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF161620),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF242434)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFF202030),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _getCategoryIcon(item.category),
                      color: const Color(0xFF2ECC71),
                      size: 19,
                    ),
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
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${dateFormat.format(item.date)} ${item.odometer != null ? '• ${item.odometer!.toStringAsFixed(0)} km' : ''}',
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: AppColors.textTertiary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (item.note != null && item.note!.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            item.note!,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                              fontStyle: FontStyle.italic,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '৳${item.cost.toStringAsFixed(0)}',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF2ECC71),
                        ),
                      ),
                      PopupMenuButton<String>(
                        icon: const Icon(
                          Icons.more_vert_rounded,
                          color: AppColors.textTertiary,
                          size: 16,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        color: AppColors.cardElevated,
                        elevation: 8,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: const BorderSide(color: AppColors.border),
                        ),
                        onSelected: (val) {
                          if (val == 'delete') {
                            ref
                                .read(serviceLogServiceProvider)
                                .deleteServiceLog(item.id);
                          }
                        },
                        itemBuilder: (_) => [
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete_outline_rounded,
                                    size: 15, color: Color(0xFFEF4444)),
                                SizedBox(width: 8),
                                Text('Delete',
                                    style: TextStyle(color: Color(0xFFEF4444))),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
