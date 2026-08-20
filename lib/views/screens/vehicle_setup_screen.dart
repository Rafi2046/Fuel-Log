import 'package:flutter/material.dart';

import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_text_styles.dart';
import '../widgets/app_primary_button.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/fade_slide_in.dart';
import '../widgets/outline_headline.dart';
import 'vehicle_setup/vehicle_setup_form.dart';
import 'vehicle_setup/vehicle_setup_form_data.dart';

/// First-run vehicle setup — UI shell with local form state.
class VehicleSetupScreen extends StatefulWidget {
  const VehicleSetupScreen({super.key});

  @override
  State<VehicleSetupScreen> createState() => _VehicleSetupScreenState();
}

class _VehicleSetupScreenState extends State<VehicleSetupScreen> {
  final _data = VehicleSetupFormData();
  final _nameController = TextEditingController();
  final _modelController = TextEditingController();
  final _odometerController = TextEditingController();
  final _tankController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _modelController.dispose();
    _odometerController.dispose();
    _tankController.dispose();
    super.dispose();
  }

  void _onContinue() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Vehicle setup UI ready — ViewModel next')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      padding: appScreenPadding,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppSpacing.md),
                  const FadeSlideIn(
                    child: OutlineHeadline(
                      accent: 'Add ',
                      outline: 'Vehicle',
                      fontSize: 36,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  FadeSlideIn(
                    delay: staggerDelay(1),
                    child: Text(
                      'Set identity, odometer, and tank capacity.',
                      style: AppTextStyles.bodySecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  FadeSlideIn(
                    delay: staggerDelay(2),
                    child: VehicleSetupForm(
                      data: _data,
                      nameController: _nameController,
                      modelController: _modelController,
                      odometerController: _odometerController,
                      tankController: _tankController,
                      onTypeChanged: (type) =>
                          setState(() => _data.type = type),
                      onDefaultChanged: (value) =>
                          setState(() => _data.isDefault = value),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],
              ),
            ),
          ),
          FadeSlideIn(
            delay: staggerDelay(3),
            child: AppPrimaryButton(
              label: 'Continue',
              icon: Icons.arrow_forward_rounded,
              onPressed: _onContinue,
            ),
          ),
        ],
      ),
    );
  }
}
