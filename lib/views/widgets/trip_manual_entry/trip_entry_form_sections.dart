import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/app_spacing.dart';
import 'trip_form_fields.dart';
import 'trip_privacy_selector.dart';

/// General Information Section (Trip title & privacy purpose category).
class TripGeneralInfoSection extends StatelessWidget {
  const TripGeneralInfoSection({
    super.key,
    required this.titleCtrl,
    required this.privacy,
    required this.customCategories,
    required this.onPrivacyChanged,
    required this.onAddCustomCategory,
  });

  final TextEditingController titleCtrl;
  final String privacy;
  final List<String> customCategories;
  final ValueChanged<String> onPrivacyChanged;
  final VoidCallback onAddCustomCategory;

  @override
  Widget build(BuildContext context) {
    return GlassSection(
      child: Column(
        children: [
          UnderlineField(
            controller: titleCtrl,
            label: 'tripTitleField'.tr(),
            hint: 'tripTitleHint'.tr(),
            icon: Icons.work_outline_rounded,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: AppSpacing.xs),
          TripPrivacySelector(
            value: privacy,
            customCategories: customCategories,
            onChanged: onPrivacyChanged,
            onAddCustom: onAddCustomCategory,
            showBorder: false,
          ),
        ],
      ),
    );
  }
}

/// Route & Schedule Section (Origin/Destination, Pickers, Odometers).
class TripRouteSection extends StatelessWidget {
  const TripRouteSection({
    super.key,
    required this.originCtrl,
    required this.destinationCtrl,
    required this.startOdoCtrl,
    required this.endOdoCtrl,
    required this.startDate,
    required this.startTime,
    required this.endDate,
    required this.endTime,
    required this.dateFmt,
    required this.onPickOriginMap,
    required this.onPickDestMap,
    required this.onPickStartDate,
    required this.onPickStartTime,
    required this.onPickEndDate,
    required this.onPickEndTime,
  });

  final TextEditingController originCtrl;
  final TextEditingController destinationCtrl;
  final TextEditingController startOdoCtrl;
  final TextEditingController endOdoCtrl;
  final DateTime startDate;
  final TimeOfDay startTime;
  final DateTime endDate;
  final TimeOfDay endTime;
  final DateFormat dateFmt;
  final VoidCallback onPickOriginMap;
  final VoidCallback onPickDestMap;
  final VoidCallback onPickStartDate;
  final VoidCallback onPickStartTime;
  final VoidCallback onPickEndDate;
  final VoidCallback onPickEndTime;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Start Point Card
        GlassSection(
          label: 'startPoint'.tr(),
          child: Column(
            children: [
              LocationField(
                controller: originCtrl,
                label: 'tripOrigin'.tr(),
                hint: 'tripOriginHint'.tr(),
                icon: Icons.location_on_outlined,
                onPickMap: onPickOriginMap,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'fieldRequired'.tr() : null,
              ),
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  Expanded(
                    child: TapField(
                      icon: Icons.calendar_today_outlined,
                      label: 'date'.tr(),
                      value: dateFmt.format(startDate),
                      onTap: onPickStartDate,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: TapField(
                      icon: Icons.schedule_rounded,
                      label: 'time'.tr(),
                      value: startTime.format(context),
                      onTap: onPickStartTime,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              UnderlineField(
                controller: startOdoCtrl,
                label: 'startOdometer'.tr(),
                hint: '0',
                icon: Icons.speed_rounded,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                textInputAction: TextInputAction.next,
                showBorder: false,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),

        // End Point Card
        GlassSection(
          label: 'endPoint'.tr(),
          child: Column(
            children: [
              LocationField(
                controller: destinationCtrl,
                label: 'tripDestination'.tr(),
                hint: 'tripDestinationHint'.tr(),
                icon: Icons.flag_outlined,
                onPickMap: onPickDestMap,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'fieldRequired'.tr() : null,
              ),
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  Expanded(
                    child: TapField(
                      icon: Icons.calendar_today_outlined,
                      label: 'date'.tr(),
                      value: dateFmt.format(endDate),
                      onTap: onPickEndDate,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: TapField(
                      icon: Icons.schedule_rounded,
                      label: 'time'.tr(),
                      value: endTime.format(context),
                      onTap: onPickEndTime,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              UnderlineField(
                controller: endOdoCtrl,
                label: 'endOdometer'.tr(),
                hint: '0',
                icon: Icons.speed_rounded,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                textInputAction: TextInputAction.next,
                showBorder: false,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Optional Financials & Notes Section (Cost per km, total cost, distance, notes).
class TripFinancialsSection extends StatelessWidget {
  const TripFinancialsSection({
    super.key,
    required this.costPerKmCtrl,
    required this.tripCostCtrl,
    required this.distanceCtrl,
    required this.noteCtrl,
  });

  final TextEditingController costPerKmCtrl;
  final TextEditingController tripCostCtrl;
  final TextEditingController distanceCtrl;
  final TextEditingController noteCtrl;

  @override
  Widget build(BuildContext context) {
    return GlassSection(
      label: 'optional'.tr(),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: UnderlineField(
                  controller: costPerKmCtrl,
                  label: 'costPerKm'.tr(),
                  hint: 'costPerKmHint'.tr(),
                  prefixText: '৳ ',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  textInputAction: TextInputAction.next,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: UnderlineField(
                  controller: tripCostCtrl,
                  label: 'tripCost'.tr(),
                  hint: 'tripCostHint'.tr(),
                  prefixText: '৳ ',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  textInputAction: TextInputAction.next,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          UnderlineField(
            controller: distanceCtrl,
            label: 'totalDistance'.tr(),
            hint: '0.0',
            icon: Icons.straighten_rounded,
            suffix: 'km'.tr(),
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
            ),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: AppSpacing.xs),
          UnderlineField(
            controller: noteCtrl,
            label: 'note'.tr(),
            hint: 'tripNoteHint'.tr(),
            icon: Icons.notes_rounded,
            maxLines: 2,
            textInputAction: TextInputAction.done,
            showBorder: false,
          ),
        ],
      ),
    );
  }
}
