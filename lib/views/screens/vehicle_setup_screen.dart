import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_motion.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_text_styles.dart';
import '../widgets/app_card.dart';
import '../widgets/app_dropdown_field.dart';
import '../widgets/app_primary_button.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/app_selectable_card.dart';
import '../widgets/app_step_indicator.dart';
import '../widgets/app_text_field.dart';
import 'dashboard_screen.dart';

enum VehicleType { car, bike }

/// 2-Step Wizard for first-run Vehicle Setup (Scaffolding UI).
class VehicleSetupScreen extends StatefulWidget {
  const VehicleSetupScreen({super.key});

  @override
  State<VehicleSetupScreen> createState() => _VehicleSetupScreenState();
}

class _VehicleSetupScreenState extends State<VehicleSetupScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;

  // Step 1 Controllers & State
  VehicleType _selectedType = VehicleType.car;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _modelController = TextEditingController();

  // Step 2 Controllers & State
  final TextEditingController _odometerController = TextEditingController();
  final TextEditingController _tankController = TextEditingController();
  String _selectedFuelType = 'Petrol';

  static const List<String> _fuelTypes = ['Petrol', 'Diesel', 'Octane', 'CNG'];

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _modelController.dispose();
    _odometerController.dispose();
    _tankController.dispose();
    super.dispose();
  }

  void _onNextStep() {
    if (_currentStep == 0) {
      _pageController.animateToPage(
        1,
        duration: AppMotion.normal,
        curve: AppMotion.emphasized,
      );
    }
  }

  void _onPreviousStep() {
    if (_currentStep == 1) {
      _pageController.animateToPage(
        0,
        duration: AppMotion.normal,
        curve: AppMotion.emphasized,
      );
    }
  }

  void _onSaveVehicle() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => const DashboardScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      body: Column(
        children: [
          // Header with Back Button (on Step 2) and Step Indicator
          Padding(
            padding: const EdgeInsets.only(
              left: AppSpacing.screenPadding,
              right: AppSpacing.screenPadding,
              top: AppSpacing.md,
              bottom: AppSpacing.sm,
            ),
            child: Row(
              children: [
                AnimatedOpacity(
                  duration: AppMotion.fast,
                  opacity: _currentStep > 0 ? 1.0 : 0.0,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded),
                    color: AppColors.textPrimary,
                    onPressed: _currentStep > 0 ? _onPreviousStep : null,
                    tooltip: 'Back to Step 1',
                  ),
                ),
                Expanded(
                  child: AppStepIndicator(
                    currentStep: _currentStep + 1,
                    totalSteps: 2,
                    stepTitle: _currentStep == 0
                        ? 'Machine Identity'
                        : 'Technical Specs',
                  ),
                ),
              ],
            ),
          ),

          // 2-Step PageView with physics disabled
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (page) {
                setState(() {
                  _currentStep = page;
                });
              },
              children: [
                // Step 1: Machine Identity
                _Step1MachineIdentity(
                  selectedType: _selectedType,
                  onTypeChanged: (type) => setState(() => _selectedType = type),
                  nameController: _nameController,
                  modelController: _modelController,
                ),

                // Step 2: Specifications
                _Step2Specifications(
                  odometerController: _odometerController,
                  tankController: _tankController,
                  selectedFuelType: _selectedFuelType,
                  fuelTypes: _fuelTypes,
                  onFuelTypeChanged: (type) {
                    if (type != null) {
                      setState(() => _selectedFuelType = type);
                    }
                  },
                ),
              ],
            ),
          ),

          // Sticky Bottom Action Area
          _StickyBottomAction(
            currentStep: _currentStep,
            onPressed: _currentStep == 0 ? _onNextStep : _onSaveVehicle,
          ),
        ],
      ),
    );
  }
}

/// Private modular widget for Step 1: Machine Identity
class _Step1MachineIdentity extends StatelessWidget {
  const _Step1MachineIdentity({
    required this.selectedType,
    required this.onTypeChanged,
    required this.nameController,
    required this.modelController,
  });

  final VehicleType selectedType;
  final ValueChanged<VehicleType> onTypeChanged;
  final TextEditingController nameController;
  final TextEditingController modelController;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPadding,
        vertical: AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Title & Subtitle
          Text(
            'Add Vehicle',
            style: AppTextStyles.display.copyWith(
              fontSize: 30,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            "Set your vehicle's basic identity.",
            style: AppTextStyles.bodySecondary,
          ),
          const SizedBox(height: AppSpacing.xl),

          // Machine Type Selector Cards (Car vs Bike)
          Text('Select Machine Type', style: AppTextStyles.label),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: AppSelectableCard(
                  title: 'Car',
                  icon: Icons.directions_car_rounded,
                  isSelected: selectedType == VehicleType.car,
                  onTap: () => onTypeChanged(VehicleType.car),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: AppSelectableCard(
                  title: 'Bike',
                  icon: Icons.two_wheeler_rounded,
                  isSelected: selectedType == VehicleType.bike,
                  onTap: () => onTypeChanged(VehicleType.bike),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),

          // Vehicle Identity Text Fields inside elevated dark Card container
          AppCard(
            child: Column(
              children: [
                AppTextField(
                  label: 'Vehicle Name',
                  hint: 'e.g., Family SUV',
                  controller: nameController,
                  prefixIcon: Icons.directions_car_outlined,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  label: 'Model',
                  hint: 'e.g., Toyota Axio',
                  controller: modelController,
                  prefixIcon: Icons.badge_outlined,
                  textInputAction: TextInputAction.done,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}

/// Private modular widget for Step 2: Specifications
class _Step2Specifications extends StatelessWidget {
  const _Step2Specifications({
    required this.odometerController,
    required this.tankController,
    required this.selectedFuelType,
    required this.fuelTypes,
    required this.onFuelTypeChanged,
  });

  final TextEditingController odometerController;
  final TextEditingController tankController;
  final String selectedFuelType;
  final List<String> fuelTypes;
  final ValueChanged<String?> onFuelTypeChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPadding,
        vertical: AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Title & Subtitle
          Text(
            'Technical Specs',
            style: AppTextStyles.display.copyWith(
              fontSize: 30,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Odometer and fuel details.',
            style: AppTextStyles.bodySecondary,
          ),
          const SizedBox(height: AppSpacing.xl),

          // Specifications Form Card
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Start Odometer
                AppTextField(
                  label: 'Start Odometer',
                  hint: '0',
                  controller: odometerController,
                  keyboardType: TextInputType.number,
                  prefixIcon: Icons.speed_rounded,
                  suffixText: 'km',
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: AppSpacing.md),

                // Fuel Type Dropdown Selector
                AppDropdownField<String>(
                  label: 'Fuel Type',
                  value: selectedFuelType,
                  prefixIcon: Icons.local_gas_station_rounded,
                  items: fuelTypes
                      .map(
                        (type) => DropdownMenuItem<String>(
                          value: type,
                          child: Text(type),
                        ),
                      )
                      .toList(),
                  onChanged: onFuelTypeChanged,
                ),
                const SizedBox(height: AppSpacing.md),

                // Tank Capacity
                AppTextField(
                  label: 'Tank Capacity',
                  hint: '40',
                  controller: tankController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  prefixIcon: Icons.opacity_rounded,
                  suffixText: 'Liters',
                  textInputAction: TextInputAction.done,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}

/// Sticky Bottom Container with Wide CTA Action Button
class _StickyBottomAction extends StatelessWidget {
  const _StickyBottomAction({
    required this.currentStep,
    required this.onPressed,
  });

  final int currentStep;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(
          top: BorderSide(color: AppColors.divider, width: 1.0),
        ),
      ),
      child: SafeArea(
        top: false,
        child: AppPrimaryButton(
          label: currentStep == 0 ? 'Continue' : 'Save Vehicle',
          icon: currentStep == 0
              ? Icons.arrow_forward_rounded
              : Icons.check_circle_rounded,
          onPressed: onPressed,
        ),
      ),
    );
  }
}
