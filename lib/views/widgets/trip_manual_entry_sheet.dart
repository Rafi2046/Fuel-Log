import 'package:drift/drift.dart' as drift;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/database/app_database.dart';
import '../../viewmodels/trip_log_viewmodel.dart';
import '../../viewmodels/vehicle_viewmodel.dart';
import 'app_primary_button.dart';

/// Optional GPS / live-trip values to pre-fill the manual entry form.
class TripManualEntryPrefill {
  const TripManualEntryPrefill({
    this.initialDistanceKm,
    this.initialDurationSec,
    this.initialOrigin,
    this.initialDestination,
    this.startedAt,
    this.endedAt,
    this.source = 'gps',
  });

  final double? initialDistanceKm;
  final int? initialDurationSec;
  final String? initialOrigin;
  final String? initialDestination;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final String source;
}

/// Full manual trip form — all reference fields, still borderless (no boxed inputs).
Future<void> showTripManualEntrySheet(
  BuildContext context, {
  TripManualEntryPrefill? prefill,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.cardElevated,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppSpacing.radiusXl),
      ),
    ),
    builder: (context) => TripManualEntrySheet(prefill: prefill),
  );
}

class TripManualEntrySheet extends ConsumerStatefulWidget {
  const TripManualEntrySheet({super.key, this.prefill});

  final TripManualEntryPrefill? prefill;

  @override
  ConsumerState<TripManualEntrySheet> createState() =>
      _TripManualEntrySheetState();
}

class _TripManualEntrySheetState extends ConsumerState<TripManualEntrySheet> {
  final _formKey = GlobalKey<FormState>();

  final _titleCtrl = TextEditingController();
  final _originCtrl = TextEditingController();
  final _destinationCtrl = TextEditingController();
  final _startOdoCtrl = TextEditingController();
  final _endOdoCtrl = TextEditingController();
  final _distanceCtrl = TextEditingController();
  final _costPerKmCtrl = TextEditingController();
  final _tripCostCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  DateTime _startDate = DateTime.now();
  TimeOfDay _startTime = TimeOfDay.now();
  DateTime _endDate = DateTime.now();
  TimeOfDay _endTime = TimeOfDay.now();
  String _privacy = 'private';

  static final _dateFmt = DateFormat('dd MMM yyyy');

  @override
  void initState() {
    super.initState();
    _applyPrefill(widget.prefill);
    _startOdoCtrl.addListener(_syncDistanceFromOdo);
    _endOdoCtrl.addListener(_syncDistanceFromOdo);
  }

  void _applyPrefill(TripManualEntryPrefill? prefill) {
    if (prefill == null) return;

    if (prefill.initialOrigin != null && prefill.initialOrigin!.isNotEmpty) {
      _originCtrl.text = prefill.initialOrigin!;
    }
    if (prefill.initialDestination != null &&
        prefill.initialDestination!.isNotEmpty) {
      _destinationCtrl.text = prefill.initialDestination!;
    }

    if (prefill.initialDistanceKm != null) {
      final km = prefill.initialDistanceKm!;
      _distanceCtrl.text = km.truncateToDouble() == km
          ? km.toStringAsFixed(0)
          : km.toStringAsFixed(1);
    }

    final endedAt = prefill.endedAt ?? DateTime.now();
    DateTime startedAt = prefill.startedAt ??
        (prefill.initialDurationSec != null
            ? endedAt.subtract(Duration(seconds: prefill.initialDurationSec!))
            : endedAt);

    _startDate = DateTime(startedAt.year, startedAt.month, startedAt.day);
    _startTime = TimeOfDay.fromDateTime(startedAt);
    _endDate = DateTime(endedAt.year, endedAt.month, endedAt.day);
    _endTime = TimeOfDay.fromDateTime(endedAt);
  }

  @override
  void dispose() {
    _startOdoCtrl.removeListener(_syncDistanceFromOdo);
    _endOdoCtrl.removeListener(_syncDistanceFromOdo);
    _titleCtrl.dispose();
    _originCtrl.dispose();
    _destinationCtrl.dispose();
    _startOdoCtrl.dispose();
    _endOdoCtrl.dispose();
    _distanceCtrl.dispose();
    _costPerKmCtrl.dispose();
    _tripCostCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  void _syncDistanceFromOdo() {
    final start = double.tryParse(_startOdoCtrl.text);
    final end = double.tryParse(_endOdoCtrl.text);
    if (start == null || end == null || end < start) return;
    final km = end - start;
    final text = km == km.roundToDouble()
        ? km.toStringAsFixed(0)
        : km.toStringAsFixed(1);
    if (_distanceCtrl.text == text) return;
    _distanceCtrl.text = text;
  }

  Future<void> _pickDate({required bool isStart}) async {
    final initial = isStart ? _startDate : _endDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _startDate = picked;
      } else {
        _endDate = picked;
      }
    });
  }

  Future<void> _pickTime({required bool isStart}) async {
    final initial = isStart ? _startTime : _endTime;
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _startTime = picked;
      } else {
        _endTime = picked;
      }
    });
  }

  Future<void> _onSave() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final activeVehicle = ref.read(activeVehicleProvider).valueOrNull;
    if (activeVehicle == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No active vehicle selected.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final startOdo = double.tryParse(_startOdoCtrl.text.trim());
    final endOdo = double.tryParse(_endOdoCtrl.text.trim());

    double? distance = double.tryParse(_distanceCtrl.text.trim());
    if (distance == null &&
        startOdo != null &&
        endOdo != null &&
        endOdo >= startOdo) {
      distance = endOdo - startOdo;
    }
    final distanceKm = distance ?? 0.0;

    final costPerKm = double.tryParse(_costPerKmCtrl.text.trim());
    final tripCost = double.tryParse(_tripCostCtrl.text.trim());

    final startedAt = DateTime(
      _startDate.year,
      _startDate.month,
      _startDate.day,
      _startTime.hour,
      _startTime.minute,
    );
    DateTime endedAt = DateTime(
      _endDate.year,
      _endDate.month,
      _endDate.day,
      _endTime.hour,
      _endTime.minute,
    );
    if (endedAt.isBefore(startedAt)) {
      endedAt = startedAt;
    }
    final durationSec = endedAt.difference(startedAt).inSeconds;

    final title = _titleCtrl.text.trim();
    final origin = _originCtrl.text.trim();
    final destination = _destinationCtrl.text.trim();
    final note = _noteCtrl.text.trim();

    final companion = TripLogsCompanion.insert(
      vehicleId: activeVehicle.id,
      title: title.isNotEmpty ? drift.Value(title) : const drift.Value.absent(),
      origin:
          origin.isNotEmpty ? drift.Value(origin) : const drift.Value.absent(),
      destination: destination.isNotEmpty
          ? drift.Value(destination)
          : const drift.Value.absent(),
      startedAt: startedAt,
      endedAt: endedAt,
      startOdo: startOdo != null
          ? drift.Value(startOdo)
          : const drift.Value.absent(),
      endOdo:
          endOdo != null ? drift.Value(endOdo) : const drift.Value.absent(),
      distanceKm: distanceKm,
      durationSec: durationSec,
      costPerKm: costPerKm != null
          ? drift.Value(costPerKm)
          : const drift.Value.absent(),
      totalCost: tripCost != null
          ? drift.Value(tripCost)
          : const drift.Value.absent(),
      source: widget.prefill?.source ?? 'manual',
      privacy: _privacy,
      note: note.isNotEmpty ? drift.Value(note) : const drift.Value.absent(),
    );

    try {
      await ref.read(tripLogProvider.notifier).addTrip(companion);
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'tripSaved'.tr(),
            style: AppTextStyles.body.copyWith(color: AppColors.textPrimary),
          ),
          backgroundColor: AppColors.cardElevated,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save trip: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.92;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SizedBox(
        height: maxHeight,
        child: SafeArea(
          top: false,
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screenPadding,
                    AppSpacing.md,
                    AppSpacing.screenPadding,
                    0,
                  ),
                  child: Column(
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppColors.border,
                            borderRadius:
                                BorderRadius.circular(AppSpacing.radiusPill),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'addTrip'.tr(),
                              style: AppTextStyles.title.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.close_rounded),
                            color: AppColors.textSecondary,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.screenPadding,
                      AppSpacing.sm,
                      AppSpacing.screenPadding,
                      AppSpacing.md,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _UnderlineField(
                          controller: _titleCtrl,
                          label: 'tripTitleField'.tr(),
                          hint: 'tripTitleHint'.tr(),
                          icon: Icons.work_outline_rounded,
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _PrivacySelector(
                          value: _privacy,
                          onChanged: (v) => setState(() => _privacy = v),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        _SectionLabel('startPoint'.tr()),
                        const SizedBox(height: AppSpacing.sm),
                        _UnderlineField(
                          controller: _originCtrl,
                          label: 'tripOrigin'.tr(),
                          hint: 'tripOriginHint'.tr(),
                          icon: Icons.location_on_outlined,
                          textInputAction: TextInputAction.next,
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'fieldRequired'.tr()
                              : null,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Row(
                          children: [
                            Expanded(
                              child: _TapField(
                                icon: Icons.calendar_today_outlined,
                                label: 'date'.tr(),
                                value: _dateFmt.format(_startDate),
                                onTap: () => _pickDate(isStart: true),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: _TapField(
                                icon: Icons.schedule_rounded,
                                label: 'time'.tr(),
                                value: _startTime.format(context),
                                onTap: () => _pickTime(isStart: true),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _UnderlineField(
                          controller: _startOdoCtrl,
                          label: 'startOdometer'.tr(),
                          hint: '0',
                          icon: Icons.speed_rounded,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        _SectionLabel('endPoint'.tr()),
                        const SizedBox(height: AppSpacing.sm),
                        _UnderlineField(
                          controller: _destinationCtrl,
                          label: 'tripDestination'.tr(),
                          hint: 'tripDestinationHint'.tr(),
                          icon: Icons.flag_outlined,
                          textInputAction: TextInputAction.next,
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'fieldRequired'.tr()
                              : null,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Row(
                          children: [
                            Expanded(
                              child: _TapField(
                                icon: Icons.calendar_today_outlined,
                                label: 'date'.tr(),
                                value: _dateFmt.format(_endDate),
                                onTap: () => _pickDate(isStart: false),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: _TapField(
                                icon: Icons.schedule_rounded,
                                label: 'time'.tr(),
                                value: _endTime.format(context),
                                onTap: () => _pickTime(isStart: false),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _UnderlineField(
                          controller: _endOdoCtrl,
                          label: 'endOdometer'.tr(),
                          hint: '0',
                          icon: Icons.speed_rounded,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        _SectionLabel('optional'.tr()),
                        const SizedBox(height: AppSpacing.sm),
                        Row(
                          children: [
                            Expanded(
                              child: _UnderlineField(
                                controller: _costPerKmCtrl,
                                label: 'costPerKm'.tr(),
                                hint: '0',
                                icon: Icons.payments_outlined,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                textInputAction: TextInputAction.next,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: _UnderlineField(
                                controller: _tripCostCtrl,
                                label: 'tripCost'.tr(),
                                hint: '0',
                                icon: Icons.attach_money_rounded,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                textInputAction: TextInputAction.next,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _UnderlineField(
                          controller: _distanceCtrl,
                          label: 'totalDistance'.tr(),
                          hint: '0.0',
                          icon: Icons.straighten_rounded,
                          suffix: 'km'.tr(),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _UnderlineField(
                          controller: _noteCtrl,
                          label: 'note'.tr(),
                          hint: 'tripNoteHint'.tr(),
                          icon: Icons.notes_rounded,
                          maxLines: 3,
                          textInputAction: TextInputAction.done,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screenPadding,
                    0,
                    AppSpacing.screenPadding,
                    AppSpacing.md,
                  ),
                  child: AppPrimaryButton(
                    label: 'saveTrip'.tr(),
                    icon: Icons.check_rounded,
                    onPressed: _onSave,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTextStyles.label.copyWith(
        color: AppColors.primary,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _PrivacySelector extends StatelessWidget {
  const _PrivacySelector({
    required this.value,
    required this.onChanged,
  });

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      key: ValueKey(value),
      initialValue: value,
      dropdownColor: AppColors.card,
      icon: const Icon(Icons.keyboard_arrow_down_rounded,
          color: AppColors.primary),
      decoration: InputDecoration(
        labelText: 'tripPrivacy'.tr(),
        prefixIcon: const Icon(Icons.label_outline_rounded,
            color: AppColors.primary, size: 20),
        filled: false,
        contentPadding: const EdgeInsets.only(top: 12, bottom: 10),
        border: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.border),
        ),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.border),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.primary, width: 1.6),
        ),
        labelStyle: AppTextStyles.caption,
        floatingLabelStyle:
            AppTextStyles.caption.copyWith(color: AppColors.primary),
      ),
      style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w500),
      items: [
        DropdownMenuItem(value: 'private', child: Text('privacyPrivate'.tr())),
        DropdownMenuItem(value: 'work', child: Text('privacyWork'.tr())),
        DropdownMenuItem(value: 'other', child: Text('privacyOther'.tr())),
      ],
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }
}

class _TapField extends StatelessWidget {
  const _TapField({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: AppColors.primary, size: 18),
          filled: false,
          contentPadding: const EdgeInsets.only(top: 12, bottom: 10),
          border: const UnderlineInputBorder(
            borderSide: BorderSide(color: AppColors.border),
          ),
          enabledBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: AppColors.border),
          ),
          labelStyle: AppTextStyles.caption,
        ),
        child: Text(
          value,
          style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}

class _UnderlineField extends StatelessWidget {
  const _UnderlineField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.suffix,
    this.keyboardType,
    this.inputFormatters,
    this.textInputAction,
    this.validator,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final String? suffix;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final TextInputAction? textInputAction;
  final FormFieldValidator<String>? validator;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      textInputAction: textInputAction,
      validator: validator,
      maxLines: maxLines,
      style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w500),
      cursorColor: AppColors.primary,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
        suffixText: suffix,
        suffixStyle: AppTextStyles.caption.copyWith(
          color: AppColors.textSecondary,
        ),
        filled: false,
        alignLabelWithHint: maxLines > 1,
        contentPadding: EdgeInsets.only(
          top: maxLines > 1 ? 16 : 12,
          bottom: 10,
        ),
        border: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.border),
        ),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.border),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.primary, width: 1.6),
        ),
        errorBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.error, width: 1.6),
        ),
        labelStyle: AppTextStyles.caption,
        floatingLabelStyle: AppTextStyles.caption.copyWith(
          color: AppColors.primary,
        ),
        hintStyle: AppTextStyles.bodySecondary.copyWith(
          color: AppColors.textTertiary,
        ),
      ),
    );
  }
}
