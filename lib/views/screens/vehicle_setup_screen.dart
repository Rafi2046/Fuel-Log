import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_motion.dart';
import '../../core/constants/app_spacing.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/app_step_indicator.dart';
import 'dashboard_screen.dart';
import 'setup_widgets/setup_bottom_action.dart';
import 'setup_widgets/vehicle_identity_step.dart';
import 'setup_widgets/vehicle_specs_step.dart';

/// 2-step first-run vehicle setup wizard (UI shell).
class VehicleSetupScreen extends StatefulWidget {
  const VehicleSetupScreen({super.key});

  @override
  State<VehicleSetupScreen> createState() => _VehicleSetupScreenState();
}

class _VehicleSetupScreenState extends State<VehicleSetupScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;

  VehicleType _selectedType = VehicleType.car;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _modelController = TextEditingController();
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

  void _goNext() {
    _pageController.animateToPage(
      1,
      duration: AppMotion.normal,
      curve: AppMotion.emphasized,
    );
  }

  void _goBack() {
    _pageController.animateToPage(
      0,
      duration: AppMotion.normal,
      curve: AppMotion.emphasized,
    );
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
                  opacity: _currentStep > 0 ? 1 : 0,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded),
                    color: AppColors.textPrimary,
                    onPressed: _currentStep > 0 ? _goBack : null,
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
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (page) => setState(() => _currentStep = page),
              children: [
                VehicleIdentityStep(
                  selectedType: _selectedType,
                  onTypeChanged: (type) =>
                      setState(() => _selectedType = type),
                  nameController: _nameController,
                  modelController: _modelController,
                ),
                VehicleSpecsStep(
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
          SetupBottomAction(
            currentStep: _currentStep,
            onPressed: _currentStep == 0 ? _goNext : _onSaveVehicle,
          ),
        ],
      ),
    );
  }
}
