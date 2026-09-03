import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../reminders/reminders_screen.dart';
import '../../../../viewmodels/service_log_viewmodel.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../components/forms/custom_date_picker_row.dart';
import '../../../components/forms/custom_sheet_text_field.dart';
import '../../../components/forms/sheet_action_bar.dart';
import 'cost_service_categories.dart';

part 'add_cost_service_sheet_controller.dart';
part 'add_cost_service_sheet_view.dart';

/// Modal bottom sheet for adding non-fuel vehicle costs and maintenance services
class AddCostServiceSheet extends ConsumerStatefulWidget {
  AddCostServiceSheet({
    super.key,
    required this.vehicleId,
    required this.currentOdometer,
  });

  final int vehicleId;
  final double currentOdometer;

  static Future<void> show(
    BuildContext context, {
    required int vehicleId,
    required double currentOdometer,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.appBar,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => AddCostServiceSheet(
        vehicleId: vehicleId,
        currentOdometer: currentOdometer,
      ),
    );
  }

  @override
  ConsumerState<AddCostServiceSheet> createState() =>
      _AddCostServiceSheetState();
}

class _AddCostServiceSheetState extends ConsumerState<AddCostServiceSheet>
    with _AddCostServiceSheetController, _AddCostServiceSheetView {}
