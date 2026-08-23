import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_motion.dart';
import '../../core/utils/fuel_options.dart';
import '../../viewmodels/vehicle_viewmodel.dart';
import '../widgets/app_scaffold.dart';
import 'dashboard_screen.dart';
import 'setup_widgets/setup_bottom_action.dart';
import 'setup_widgets/setup_wizard_header.dart';
import 'setup_widgets/vehicle_identity_step.dart';
import 'setup_widgets/vehicle_specs_step.dart';

/// 2-step first-run vehicle setup — saves via Drift + Riverpod.
class VehicleSetupScreen extends ConsumerStatefulWidget {
  const VehicleSetupScreen({super.key});

  @override
  ConsumerState<VehicleSetupScreen> createState() =>
      _VehicleSetupScreenState();
}

class _VehicleSetupScreenState extends ConsumerState<VehicleSetupScreen> {
  final _pageController = PageController();
  int _currentStep = 0;

  VehicleType _selectedType = VehicleType.car;
  final _nameController = TextEditingController();
  final _modelController = TextEditingController();
  final _odometerController = TextEditingController();
  final _capacityController = TextEditingController();
  String _selectedFuelType = 'Petrol';

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _modelController.dispose();
    _odometerController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  void _onTypeChanged(VehicleType type) {
    setState(() {
      _selectedType = type;
      final options = FuelOptions.forVehicleType(type);
      if (!options.contains(_selectedFuelType)) {
        _selectedFuelType = options.first;
      }
    });
  }

  void _onFuelTypeChanged(String? type) {
    if (type == null) return;
    setState(() => _selectedFuelType = type);
  }

  void _goTo(int page) {
    _pageController.animateToPage(
      page,
      duration: AppMotion.normal,
      curve: AppMotion.emphasized,
    );
  }

  void _goNext() {
    if (_nameController.text.trim().isEmpty) {
      _showMessage('Please enter a vehicle name.');
      return;
    }
    _goTo(1);
  }

  Future<void> _onSaveVehicle() async {
    final name = _nameController.text.trim();
    final model = _modelController.text.trim();
    final startOdo = double.tryParse(_odometerController.text.trim());
    final capacity = double.tryParse(_capacityController.text.trim());
    final isElectric = FuelOptions.isElectric(_selectedFuelType);

    if (name.isEmpty) {
      _showMessage('Please enter a vehicle name.');
      return;
    }
    if (startOdo == null || startOdo < 0) {
      _showMessage('Enter a valid starting odometer.');
      return;
    }
    if (capacity == null || capacity <= 0) {
      _showMessage(
        isElectric
            ? 'Enter a valid battery capacity.'
            : 'Enter a valid tank capacity.',
      );
      return;
    }

    final success = await ref.read(vehicleProvider.notifier).addVehicle(
          type: _selectedType == VehicleType.car ? 'Car' : 'Bike',
          name: name,
          model: model.isEmpty ? null : model,
          startOdo: startOdo,
          capacity: capacity,
          fuelType: _selectedFuelType,
          isElectric: isElectric,
        );

    if (!mounted) return;

    if (success) {
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const DashboardScreen()),
      );
    } else {
      final err = ref.read(vehicleProvider);
      final detail = err.hasError ? ' (${err.error})' : '';
      _showMessage('Could not save vehicle$detail');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      body: Column(
        children: [
          SetupWizardHeader(
            currentStep: _currentStep,
            onBack: () => _goTo(0),
          ),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (page) => setState(() => _currentStep = page),
              children: [
                VehicleIdentityStep(
                  selectedType: _selectedType,
                  onTypeChanged: _onTypeChanged,
                  nameController: _nameController,
                  modelController: _modelController,
                ),
                VehicleSpecsStep(
                  vehicleType: _selectedType,
                  odometerController: _odometerController,
                  capacityController: _capacityController,
                  selectedFuelType: _selectedFuelType,
                  onFuelTypeChanged: _onFuelTypeChanged,
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
