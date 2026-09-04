import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/utils/vehicle_display.dart';
import '../../../../viewmodels/vehicle_viewmodel.dart';

/// Modal bottom sheet to edit vehicle details (name, model, registration number, tank capacity).
class EditVehicleSheet extends ConsumerStatefulWidget {
  const EditVehicleSheet({
    super.key,
    required this.vehicle,
  });

  final Vehicle vehicle;

  static Future<bool?> show(
    BuildContext context,
    Vehicle vehicle,
  ) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: false,
      backgroundColor: Colors.transparent,
      builder: (_) => EditVehicleSheet(vehicle: vehicle),
    );
  }

  @override
  ConsumerState<EditVehicleSheet> createState() => _EditVehicleSheetState();
}

class _EditVehicleSheetState extends ConsumerState<EditVehicleSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _modelController;
  late final TextEditingController _regController;
  late final TextEditingController _capacityController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.vehicle.name);
    _modelController = TextEditingController(text: widget.vehicle.model ?? '');
    _regController = TextEditingController(text: widget.vehicle.brand ?? '');
    _capacityController = TextEditingController(
      text: widget.vehicle.capacity.toStringAsFixed(
        widget.vehicle.capacity.truncateToDouble() == widget.vehicle.capacity ? 0 : 1,
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _modelController.dispose();
    _regController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vehicle name cannot be empty'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final model = _modelController.text.trim();
    final regNo = _regController.text.trim();
    final capacity = double.tryParse(_capacityController.text.trim());

    setState(() => _isSaving = true);

    final success = await ref.read(vehicleProvider.notifier).updateVehicle(
          id: widget.vehicle.id,
          name: name,
          model: model.isEmpty ? null : model,
          brand: regNo.isEmpty ? null : regNo,
          capacity: capacity,
        );

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      ref.invalidate(vehiclesProvider);
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle_rounded, color: AppColors.success, size: 18),
              SizedBox(width: 8),
              Text('Vehicle details updated successfully'),
            ],
          ),
          backgroundColor: AppColors.cardElevated,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update vehicle'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isBike = VehicleDisplay.isBike(widget.vehicle);
    final isEV = widget.vehicle.isElectric;
    final capacityUnit = isEV ? 'kWh' : 'L';
    final capacityLabel = isEV ? 'Battery Capacity' : 'Tank Capacity';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusXl),
        ),
        border: Border.all(color: AppColors.border),
      ),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        AppSpacing.md,
        AppSpacing.screenPadding,
        MediaQuery.of(context).viewInsets.bottom +
            MediaQuery.paddingOf(context).bottom +
            AppSpacing.md,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag Handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: EdgeInsets.only(bottom: AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.textTertiary.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Title Row
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: Icon(
                    VehicleDisplay.iconFor(widget.vehicle),
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Edit Vehicle',
                        style: AppTextStyles.headline.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '${widget.vehicle.type} • ${widget.vehicle.fuelType}',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textTertiary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(Icons.close_rounded),
                  color: AppColors.textTertiary,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            SizedBox(height: AppSpacing.lg),

            // Grouped Form Card
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  _EditFormField(
                    label: 'Vehicle Name',
                    hint: 'e.g., Daily Ride',
                    controller: _nameController,
                    icon: isBike
                        ? Icons.two_wheeler_outlined
                        : Icons.directions_car_outlined,
                    textInputAction: TextInputAction.next,
                  ),
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: AppColors.border.withValues(alpha: 0.6),
                    indent: 56,
                  ),
                  _EditFormField(
                    label: 'Model',
                    hint: isBike ? 'e.g., Yamaha R15' : 'e.g., Toyota Axio',
                    controller: _modelController,
                    icon: Icons.commute_rounded,
                    textInputAction: TextInputAction.next,
                    textCapitalization: TextCapitalization.words,
                  ),
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: AppColors.border.withValues(alpha: 0.6),
                    indent: 56,
                  ),
                  _EditFormField(
                    label: 'Registration Number',
                    hint: 'e.g., Dhaka Metro-HA 12-3456',
                    controller: _regController,
                    icon: Icons.badge_outlined,
                    textInputAction: TextInputAction.next,
                    textCapitalization: TextCapitalization.characters,
                  ),
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: AppColors.border.withValues(alpha: 0.6),
                    indent: 56,
                  ),
                  _EditFormField(
                    label: capacityLabel,
                    hint: 'e.g., 14',
                    controller: _capacityController,
                    icon: isEV
                        ? Icons.battery_charging_full_rounded
                        : Icons.opacity_rounded,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    textInputAction: TextInputAction.done,
                    suffixText: capacityUnit,
                  ),
                ],
              ),
            ),
            SizedBox(height: AppSpacing.xl),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textPrimary,
                      side: BorderSide(color: AppColors.borderStrong),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      ),
                    ),
                    child: Text('Cancel'),
                  ),
                ),
                SizedBox(width: AppSpacing.md),
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    onPressed: _isSaving ? null : _save,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      ),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.check_rounded, size: 18),
                              SizedBox(width: 6),
                              Text(
                                'Save Changes',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EditFormField extends StatelessWidget {
  const _EditFormField({
    required this.label,
    required this.hint,
    required this.controller,
    required this.icon,
    this.textInputAction = TextInputAction.next,
    this.textCapitalization = TextCapitalization.none,
    this.keyboardType,
    this.suffixText,
  });

  final String label;
  final String hint;
  final TextEditingController controller;
  final IconData icon;
  final TextInputAction textInputAction;
  final TextCapitalization textCapitalization;
  final TextInputType? keyboardType;
  final String? suffixText;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(color: AppColors.border),
            ),
            child: Icon(
              icon,
              size: 17,
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textTertiary,
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 2),
                TextField(
                  controller: controller,
                  textInputAction: textInputAction,
                  textCapitalization: textCapitalization,
                  keyboardType: keyboardType,
                  style: AppTextStyles.body.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                  cursorColor: AppColors.primary,
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    hintText: hint,
                    hintStyle: AppTextStyles.bodySecondary.copyWith(
                      color: AppColors.textTertiary.withValues(alpha: 0.6),
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (suffixText != null)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(
                suffixText!,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
