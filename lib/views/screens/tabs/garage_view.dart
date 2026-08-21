import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_outline_button.dart';
import '../vehicle_setup_screen.dart';

/// Garage Tab View listing vehicles with an Add Vehicle button.
class GarageView extends StatelessWidget {
  const GarageView({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      children: [
        // Primary Active Vehicle Card: Toyota Axio
        _VehicleCard(
          name: 'Toyota Axio',
          model: 'Sedan • 2021',
          odometer: '45,210 km',
          icon: Icons.directions_car_filled_rounded,
          isDefault: true,
        ),
        const SizedBox(height: AppSpacing.md),

        // Secondary Vehicle Card: Honda Civic
        _VehicleCard(
          name: 'Honda Civic',
          model: 'Sedan • 2023',
          odometer: '28,400 km',
          icon: Icons.directions_car_outlined,
          isDefault: false,
        ),
        const SizedBox(height: AppSpacing.md),

        // Bike Vehicle Card: Yamaha R15
        _VehicleCard(
          name: 'Yamaha R15',
          model: 'Motorcycle • 2022',
          odometer: '12,100 km',
          icon: Icons.two_wheeler_rounded,
          isDefault: false,
        ),
        const SizedBox(height: AppSpacing.xl),

        // Bottom Prominent Outlined Button: "+ Add New Vehicle"
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

class _VehicleCard extends StatelessWidget {
  const _VehicleCard({
    required this.name,
    required this.model,
    required this.odometer,
    required this.icon,
    required this.isDefault,
  });

  final String name;
  final String model;
  final String odometer;
  final IconData icon;
  final bool isDefault;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      showBorder: isDefault,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: isDefault
                  ? AppColors.primary.withValues(alpha: 0.15)
                  : AppColors.surface,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: isDefault ? AppColors.primary : AppColors.textSecondary,
              size: 28,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      name,
                      style: AppTextStyles.title.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (isDefault) ...[
                      const SizedBox(width: AppSpacing.sm),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusSm),
                        ),
                        child: Text(
                          'DEFAULT',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textPrimary,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text('$model • $odometer', style: AppTextStyles.caption),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.textTertiary,
          ),
        ],
      ),
    );
  }
}
