import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_text_styles.dart';
import '../widgets/app_card.dart';
import '../widgets/app_dropdown_field.dart';
import '../widgets/app_primary_button.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/app_text_field.dart';
import '../widgets/app_toggle_row.dart';

/// Screen UI for logging a new refueling entry.
class RefuelingFormScreen extends StatefulWidget {
  const RefuelingFormScreen({super.key});

  @override
  State<RefuelingFormScreen> createState() => _RefuelingFormScreenState();
}

class _RefuelingFormScreenState extends State<RefuelingFormScreen> {
  final TextEditingController _odometerController = TextEditingController();
  final TextEditingController _fuelAmountController = TextEditingController();
  final TextEditingController _totalCostController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  String _selectedFuelType = 'Petrol';
  bool _isFullTank = true;

  static const List<String> _fuelTypes = ['Petrol', 'Diesel', 'Octane', 'CNG'];

  @override
  void dispose() {
    _odometerController.dispose();
    _fuelAmountController.dispose();
    _totalCostController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _onSave() {
    // Scaffold UI save callback - pop back to previous screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Refueling record created (UI scaffolding ready)'),
        backgroundColor: AppColors.primary,
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Refueling',
      actions: [
        IconButton(
          icon: const Icon(Icons.check_rounded),
          color: AppColors.primary,
          iconSize: 26,
          tooltip: 'Save Refueling',
          onPressed: _onSave,
        ),
      ],
      padding: appScreenPadding,
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Log Refueling',
                    style: AppTextStyles.display.copyWith(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Record your fuel volume, cost, and odometer reading.',
                    style: AppTextStyles.bodySecondary,
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Main Input Fields Card
                  AppCard(
                    child: Column(
                      children: [
                        // Odometer Field
                        AppTextField(
                          label: 'Odometer (km)',
                          hint: 'e.g., 45000',
                          controller: _odometerController,
                          keyboardType: TextInputType.number,
                          prefixIcon: Icons.speed_rounded,
                          suffixText: 'km',
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: AppSpacing.md),

                        // Fuel Amount Field
                        AppTextField(
                          label: 'Fuel Amount (L)',
                          hint: 'e.g., 35.5',
                          controller: _fuelAmountController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          prefixIcon: Icons.local_gas_station_rounded,
                          suffixText: 'Liters',
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: AppSpacing.md),

                        // Total Cost Field
                        AppTextField(
                          label: 'Total Cost',
                          hint: 'e.g., 4500',
                          controller: _totalCostController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          prefixIcon: Icons.attach_money_rounded,
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: AppSpacing.md),

                        // Fuel Type Dropdown Field
                        AppDropdownField<String>(
                          label: 'Fuel Type',
                          value: _selectedFuelType,
                          prefixIcon: Icons.opacity_rounded,
                          items: _fuelTypes
                              .map(
                                (type) => DropdownMenuItem<String>(
                                  value: type,
                                  child: Text(type),
                                ),
                              )
                              .toList(),
                          onChanged: (type) {
                            if (type != null) {
                              setState(() => _selectedFuelType = type);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Full Tank Toggle Row
                  AppToggleRow(
                    title: 'Full Tank?',
                    subtitle: 'Was the fuel tank filled completely?',
                    value: _isFullTank,
                    onChanged: (val) => setState(() => _isFullTank = val),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Optional Note Field Card
                  AppCard(
                    child: AppTextField(
                      label: 'Note (Optional)',
                      hint: 'e.g., Station location or payment method',
                      controller: _noteController,
                      prefixIcon: Icons.notes_rounded,
                      maxLines: 3,
                      textInputAction: TextInputAction.done,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
          ),

          // Bottom Action Button
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: AppPrimaryButton(
              label: 'Save Refueling',
              icon: Icons.check_circle_rounded,
              onPressed: _onSave,
            ),
          ),
        ],
      ),
    );
  }
}
