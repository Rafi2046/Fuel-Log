import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/database/app_database.dart';
import '../../viewmodels/fuel_log_viewmodel.dart';
import '../../viewmodels/vehicle_viewmodel.dart';
import '../widgets/app_primary_button.dart';
import '../widgets/app_scaffold.dart';
import 'refueling/refueling_form_fields.dart';

/// Log a fuel fill-up or EV charge against the active vehicle.
class RefuelingFormScreen extends ConsumerStatefulWidget {
  const RefuelingFormScreen({super.key});

  @override
  ConsumerState<RefuelingFormScreen> createState() =>
      _RefuelingFormScreenState();
}

class _RefuelingFormScreenState extends ConsumerState<RefuelingFormScreen> {
  final _odometerController = TextEditingController();
  final _amountController = TextEditingController();
  final _totalCostController = TextEditingController();
  final _noteController = TextEditingController();
  bool _isFullTank = true;

  @override
  void initState() {
    super.initState();
    _amountController.addListener(_refresh);
    _totalCostController.addListener(_refresh);
  }

  @override
  void dispose() {
    _amountController.removeListener(_refresh);
    _totalCostController.removeListener(_refresh);
    _odometerController.dispose();
    _amountController.dispose();
    _totalCostController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _refresh() => setState(() {});

  String? get _pricePerUnit {
    final amount = double.tryParse(_amountController.text.trim());
    final cost = double.tryParse(_totalCostController.text.trim());
    if (amount == null || cost == null || amount <= 0) return null;
    return (cost / amount).toStringAsFixed(2);
  }

  Future<void> _onSave(Vehicle vehicle) async {
    final odometer = double.tryParse(_odometerController.text.trim());
    final amount = double.tryParse(_amountController.text.trim());
    final cost = double.tryParse(_totalCostController.text.trim());
    final note = _noteController.text.trim();
    final isEV = vehicle.isElectric;

    if (odometer == null || odometer < 0) {
      _toast('Enter a valid odometer reading.');
      return;
    }
    if (amount == null || amount <= 0) {
      _toast(isEV ? 'Enter charge amount (kWh).' : 'Enter fuel amount.');
      return;
    }
    if (cost == null || cost < 0) {
      _toast('Enter a valid total cost.');
      return;
    }

    final ok = await ref.read(fuelLogProvider.notifier).addFuelLog(
          vehicleId: vehicle.id,
          date: DateTime.now(),
          odometer: odometer,
          amount: amount,
          cost: cost,
          isFullTank: _isFullTank,
          note: note.isEmpty ? null : note,
        );

    if (!mounted) return;

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Log Saved Successfully'),
          backgroundColor: AppColors.primary,
        ),
      );
      Navigator.of(context).pop();
    } else {
      final err = ref.read(fuelLogProvider);
      _toast('Could not save log${err.hasError ? ' (${err.error})' : ''}');
    }
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final activeAsync = ref.watch(activeVehicleProvider);
    final isSaving = ref.watch(fuelLogProvider).isLoading;

    return AppScaffold(
      title: 'Refueling',
      padding: appScreenPadding,
      body: activeAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (vehicle) {
          if (vehicle == null) {
            return const Center(
              child: Text('No vehicle found. Add a vehicle first.'),
            );
          }
          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: RefuelingFormFields(
                    vehicle: vehicle,
                    odometerController: _odometerController,
                    amountController: _amountController,
                    totalCostController: _totalCostController,
                    noteController: _noteController,
                    isFullTank: _isFullTank,
                    onFullTankChanged: (v) => setState(() => _isFullTank = v),
                    pricePerUnit: _pricePerUnit,
                  ),
                ),
              ),
              AppPrimaryButton(
                label: vehicle.isElectric ? 'Save Charge' : 'Save Refueling',
                icon: Icons.check_circle_rounded,
                isLoading: isSaving,
                onPressed: isSaving ? null : () => _onSave(vehicle),
              ),
            ],
          );
        },
      ),
    );
  }
}
