import 'package:drift/drift.dart' as drift;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/utils/notification_service.dart';
import '../../../../viewmodels/fuel_log_viewmodel.dart';
import '../../../../viewmodels/vehicle_viewmodel.dart';
import '../../../components/forms/sheet_action_bar.dart';
import 'reminder_form_presets.dart';

part 'add_reminder_sheet_controller.dart';
part 'add_reminder_sheet_view.dart';

/// Modal sheet for creating or editing vehicle maintenance reminders.
class AddReminderSheet extends ConsumerStatefulWidget {
  const AddReminderSheet({
    super.key,
    this.vehicleId,
    this.currentOdometer,
    this.existingReminder,
    this.onSave,
  });

  final int? vehicleId;
  final double? currentOdometer;
  final Reminder? existingReminder;
  final VoidCallback? onSave;

  static Future<void> show(
    BuildContext context, {
    int? vehicleId,
    double? currentOdometer,
    Reminder? existingReminder,
    VoidCallback? onSave,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddReminderSheet(
        vehicleId: vehicleId,
        currentOdometer: currentOdometer,
        existingReminder: existingReminder,
        onSave: onSave,
      ),
    );
  }

  @override
  ConsumerState<AddReminderSheet> createState() => _AddReminderSheetState();
}

class _AddReminderSheetState extends ConsumerState<AddReminderSheet>
    with _AddReminderSheetController, _AddReminderSheetView {}
