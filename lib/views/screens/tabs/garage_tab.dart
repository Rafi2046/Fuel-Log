import 'package:flutter/material.dart';

import '../../../core/constants/app_spacing.dart';
import '../../widgets/app_outline_button.dart';
import '../vehicle_setup_screen.dart';
import 'garage_vehicle_card.dart';

/// Garage tab listing vehicles with an Add Vehicle button.
class GarageTab extends StatelessWidget {
  const GarageTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      children: [
        const GarageVehicleCard(
          name: 'Toyota Axio',
          model: 'Sedan • 2021',
          odometer: '45,210 km',
          icon: Icons.directions_car_filled_rounded,
          isDefault: true,
        ),
        const SizedBox(height: AppSpacing.md),
        const GarageVehicleCard(
          name: 'Honda Civic',
          model: 'Sedan • 2023',
          odometer: '28,400 km',
          icon: Icons.directions_car_outlined,
          isDefault: false,
        ),
        const SizedBox(height: AppSpacing.md),
        const GarageVehicleCard(
          name: 'Yamaha R15',
          model: 'Sport Bike • 2022',
          odometer: '12,850 km',
          icon: Icons.two_wheeler_rounded,
          isDefault: false,
        ),
        const SizedBox(height: AppSpacing.xl),
        AppOutlineButton(
          label: '+ Add New Vehicle',
          icon: Icons.add_rounded,
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const VehicleSetupScreen(),
              ),
            );
          },
        ),
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }
}
