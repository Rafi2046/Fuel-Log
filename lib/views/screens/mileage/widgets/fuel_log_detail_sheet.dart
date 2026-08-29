import 'package:drift/drift.dart' show Value;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/utils/app_formatters.dart';
import '../../../../models/mileage_entry_model.dart';
import '../../../../viewmodels/fuel_log_viewmodel.dart';
import '../../../../viewmodels/mileage_log_viewmodel.dart';
import '../../../widgets/app_primary_button.dart';
import '../../../widgets/app_text_field.dart';
import '../../../widgets/clean_glass_panel.dart';

/// Bottom sheet showing full refueling log details with optional station edit.
class FuelLogDetailSheet extends ConsumerStatefulWidget {
  const FuelLogDetailSheet({
    super.key,
    required this.log,
    required this.unit,
    required this.isEV,
    this.entry,
  });

  final FuelLog log;
  final String unit;
  final bool isEV;
  final MileageEntryModel? entry;

  static Future<void> show(
    BuildContext context, {
    required FuelLog log,
    required String unit,
    required bool isEV,
    MileageEntryModel? entry,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FuelLogDetailSheet(
        log: log,
        unit: unit,
        isEV: isEV,
        entry: entry,
      ),
    );
  }

  @override
  ConsumerState<FuelLogDetailSheet> createState() => _FuelLogDetailSheetState();
}

class _FuelLogDetailSheetState extends ConsumerState<FuelLogDetailSheet> {
  late final TextEditingController _stationController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _stationController = TextEditingController(text: widget.log.stationName ?? '');
  }

  @override
  void dispose() {
    _stationController.dispose();
    super.dispose();
  }

  Future<void> _saveStation() async {
    final station = _stationController.text.trim();
    setState(() => _isSaving = true);
    final ok = await ref.read(fuelLogProvider.notifier).updateFuelLog(
          widget.log.copyWith(
            stationName: Value(station.isEmpty ? null : station),
          ),
        );
    if (!mounted) return;
    setState(() => _isSaving = false);
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('fuelLogStationSaved'.tr())),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final log = widget.log;
    final entry = widget.entry;
    final pricePerUnit = log.amount > 0 ? log.cost / log.amount : 0.0;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: CleanGlassPanel(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.md,
          AppSpacing.md,
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                      ),
                      child: Icon(
                        widget.isEV
                            ? Icons.battery_charging_full_rounded
                            : Icons.local_gas_station_rounded,
                        color: AppColors.primary,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'fuelLogDetailsTitle'.tr(),
                        style: AppTextStyles.title.copyWith(fontSize: 16),
                      ),
                    ),
                    Text(
                      AppCurrency.format(log.cost),
                      style: AppTextStyles.title.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                _DetailRow(
                  label: 'date'.tr(),
                  value: AppDateFormats.formatLogDate(log.date),
                ),
                _DetailRow(
                  label: widget.isEV ? 'refuelChipEv'.tr() : 'refuelGasFuel'.tr(),
                  value: '${log.amount.toStringAsFixed(1)} ${widget.unit}',
                ),
                if (pricePerUnit > 0)
                  _DetailRow(
                    label: 'fuelLogPricePerUnit'.tr(),
                    value: '${AppCurrency.format(pricePerUnit)}/${widget.unit}',
                  ),
                _DetailRow(
                  label: 'refuelTotalOdometer'.tr(),
                  value: '${log.odometer.toStringAsFixed(0)} km',
                ),
                if (entry?.distanceDriven != null)
                  _DetailRow(
                    label: 'fuelLogDistanceSinceLast'.tr(),
                    value: '+${entry!.distanceDriven!.toStringAsFixed(0)} km',
                  ),
                if (entry != null)
                  _DetailRow(
                    label: 'fuelLogEfficiency'.tr(),
                    value: entry.formatEfficiency(
                      ref.watch(selectedEfficiencyUnitProvider),
                    ),
                  ),
                _DetailRow(
                  label: widget.isEV ? 'fullCharge'.tr() : 'fullTank'.tr(),
                  value: log.isFullTank ? 'fullTank'.tr() : 'Partial',
                ),
                if (log.note != null && log.note!.isNotEmpty)
                  _DetailRow(label: 'note'.tr(), value: log.note!),
                const SizedBox(height: AppSpacing.sm),
                AppTextField(
                  label: 'fuelLogStation'.tr(),
                  hint: 'fuelLogStationHint'.tr(),
                  controller: _stationController,
                  prefixIcon: Icons.storefront_outlined,
                  dense: true,
                  textInputAction: TextInputAction.done,
                ),
                const SizedBox(height: AppSpacing.sm),
                AppPrimaryButton(
                  label: 'refuelSaveRefueling'.tr(),
                  onPressed: _isSaving ? null : _saveStation,
                  isLoading: _isSaving,
                  compact: true,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textTertiary,
                fontSize: 11,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.body.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
