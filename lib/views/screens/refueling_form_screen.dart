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
  final _tripOdometerController = TextEditingController();
  final _amountController = TextEditingController();
  final _pricePerUnitController = TextEditingController();
  final _totalCostController = TextEditingController();
  final _noteController = TextEditingController();

  bool _isFullTank = true;
  bool _isSetupTankLevel = false;
  double _beforeLevelPercent = 20.0;
  double _afterLevelPercent = 100.0;
  bool _isUpdating = false;

  @override
  void dispose() {
    _odometerController.dispose();
    _tripOdometerController.dispose();
    _amountController.dispose();
    _pricePerUnitController.dispose();
    _totalCostController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _onOdometerChanged(double? lastOdo) {
    if (_isUpdating) return;
    _isUpdating = true;
    final total = double.tryParse(_odometerController.text.trim());
    if (total != null && lastOdo != null && lastOdo > 0) {
      final trip = total - lastOdo;
      if (trip >= 0) {
        _tripOdometerController.text =
            trip.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '');
      }
    }
    _isUpdating = false;
  }

  void _onTripOdometerChanged(double? lastOdo) {
    if (_isUpdating) return;
    _isUpdating = true;
    final trip = double.tryParse(_tripOdometerController.text.trim());
    final baseOdo = lastOdo ?? 0.0;
    if (trip != null && trip >= 0) {
      final total = baseOdo + trip;
      _odometerController.text =
          total.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '');
    }
    _isUpdating = false;
  }

  void _onAmountChanged() {
    if (_isUpdating) return;
    _isUpdating = true;
    final amount = double.tryParse(_amountController.text.trim());
    final price = double.tryParse(_pricePerUnitController.text.trim());
    if (amount != null && price != null && amount > 0) {
      final cost = amount * price;
      _totalCostController.text = cost.toStringAsFixed(2);
    }
    _isUpdating = false;
  }

  void _onPriceChanged() {
    if (_isUpdating) return;
    _isUpdating = true;
    final amount = double.tryParse(_amountController.text.trim());
    final price = double.tryParse(_pricePerUnitController.text.trim());
    if (amount != null && price != null && amount > 0) {
      final cost = amount * price;
      _totalCostController.text = cost.toStringAsFixed(2);
    }
    _isUpdating = false;
  }

  void _onTotalCostChanged() {
    if (_isUpdating) return;
    _isUpdating = true;
    final cost = double.tryParse(_totalCostController.text.trim());
    final amount = double.tryParse(_amountController.text.trim());
    if (cost != null && amount != null && amount > 0) {
      final price = cost / amount;
      _pricePerUnitController.text = price.toStringAsFixed(2);
    }
    _isUpdating = false;
  }

  void _recalculateFromSliders(double capacity) {
    final cap = capacity > 0 ? capacity : 50.0;
    final addedPercent = (_afterLevelPercent - _beforeLevelPercent).clamp(0.0, 100.0);
    final calculatedLiters = (addedPercent / 100.0) * cap;

    _isUpdating = true;
    _amountController.text = calculatedLiters.toStringAsFixed(1);
    _isUpdating = false;
    _onAmountChanged();
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
    final logsAsync = ref.watch(vehicleLogsProvider);
    final isSaving = ref.watch(fuelLogProvider).isLoading;

    final logs = logsAsync.valueOrNull ?? [];
    final lastOdometer = logs.isNotEmpty ? logs.first.odometer : null;

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
                  physics: const BouncingScrollPhysics(),
                  child: RefuelingFormFields(
                    vehicle: vehicle,
                    odometerController: _odometerController,
                    tripOdometerController: _tripOdometerController,
                    amountController: _amountController,
                    pricePerUnitController: _pricePerUnitController,
                    totalCostController: _totalCostController,
                    noteController: _noteController,
                    lastOdometer: lastOdometer,
                    isFullTank: _isFullTank,
                    isSetupTankLevel: _isSetupTankLevel,
                    beforeLevelPercent: _beforeLevelPercent,
                    afterLevelPercent: _afterLevelPercent,
                    onOdometerChanged: () => _onOdometerChanged(lastOdometer),
                    onTripOdometerChanged: () => _onTripOdometerChanged(lastOdometer),
                    onAmountChanged: _onAmountChanged,
                    onPriceChanged: _onPriceChanged,
                    onTotalCostChanged: _onTotalCostChanged,
                    onFullTankChanged: (val) {
                      setState(() {
                        _isFullTank = val;
                        if (val) {
                          _isSetupTankLevel = false;
                          _afterLevelPercent = 100.0;
                        }
                      });
                    },
                    onSetupTankLevelChanged: (val) {
                      setState(() {
                        _isSetupTankLevel = val;
                        if (val) {
                          _recalculateFromSliders(vehicle.capacity);
                        }
                      });
                    },
                    onBeforeLevelChanged: (val) {
                      setState(() => _beforeLevelPercent = val);
                      _recalculateFromSliders(vehicle.capacity);
                    },
                    onAfterLevelChanged: (val) {
                      setState(() => _afterLevelPercent = val);
                      _recalculateFromSliders(vehicle.capacity);
                    },
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
