import 'dart:ui';

import 'package:drift/drift.dart' as drift;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/database/app_database.dart';
import '../../core/services/navigation_routing_service.dart';
import '../../core/services/reverse_geocoding_service.dart';
import '../../core/services/trip_category_prefs.dart';
import '../../core/utils/trip_stats_helper.dart';
import '../../viewmodels/fuel_log_viewmodel.dart';
import '../../viewmodels/trip_log_viewmodel.dart';
import '../../viewmodels/vehicle_viewmodel.dart';
import 'app_primary_button.dart';
import 'clean_glass_panel.dart';
import 'trip_location_picker_page.dart';

/// Optional GPS / live-trip values to pre-fill the manual entry form.
class TripManualEntryPrefill {
  const TripManualEntryPrefill({
    this.initialDistanceKm,
    this.initialDurationSec,
    this.initialOrigin,
    this.initialDestination,
    this.startPoint,
    this.endPoint,
    this.startedAt,
    this.endedAt,
    this.source = 'gps',
    this.routeJson,
  });

  final double? initialDistanceKm;
  final int? initialDurationSec;
  final String? initialOrigin;
  final String? initialDestination;
  final LatLng? startPoint;
  final LatLng? endPoint;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final String source;
  final String? routeJson;
}

/// Full manual trip form — all reference fields, still borderless (no boxed inputs).
Future<void> showTripManualEntrySheet(
  BuildContext context, {
  TripManualEntryPrefill? prefill,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.55),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(28),
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
  List<String> _customCategories = const [];
  LatLng? _originPoint;
  LatLng? _destPoint;
  bool _isSaving = false;

  static final _dateFmt = DateFormat('dd MMM yyyy');

  @override
  void initState() {
    super.initState();
    _applyPrefill(widget.prefill);
    _prefillCostFromFuelHistory();
    _startOdoCtrl.addListener(_syncDistanceFromOdo);
    _endOdoCtrl.addListener(_syncDistanceFromOdo);
    _costPerKmCtrl.addListener(_syncTripCostFromRate);
    _distanceCtrl.addListener(_syncTripCostFromRate);
    _loadCustomCategories();
  }

  Future<void> _loadCustomCategories() async {
    final custom = await TripCategoryPrefs.loadCustom();
    if (!mounted) return;
    setState(() => _customCategories = custom);
  }

  Future<void> _addCustomCategory() async {
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => const _AddCategoryDialog(),
    );
    if (name == null || name.isEmpty || !mounted) {
      if (mounted) setState(() {});
      return;
    }

    final custom = await TripCategoryPrefs.addCustom(name);
    if (!mounted) return;
    setState(() {
      _customCategories = custom;
      _privacy = name.trim();
    });
  }

  void _applyPrefill(TripManualEntryPrefill? prefill) {
    if (prefill == null) return;

    _originPoint = prefill.startPoint;
    _destPoint = prefill.endPoint;

    if (prefill.initialOrigin != null && prefill.initialOrigin!.isNotEmpty) {
      _originCtrl.text = prefill.initialOrigin!;
    } else if (prefill.startPoint != null) {
      ReverseGeocodingService.resolveLabel(prefill.startPoint!).then((label) {
        if (mounted &&
            label != null &&
            label.isNotEmpty &&
            _originCtrl.text.isEmpty) {
          setState(() {
            _originCtrl.text = label;
          });
        }
      });
    }

    if (prefill.initialDestination != null &&
        prefill.initialDestination!.isNotEmpty) {
      _destinationCtrl.text = prefill.initialDestination!;
    } else if (prefill.endPoint != null) {
      ReverseGeocodingService.resolveLabel(prefill.endPoint!).then((label) {
        if (mounted &&
            label != null &&
            label.isNotEmpty &&
            _destinationCtrl.text.isEmpty) {
          setState(() {
            _destinationCtrl.text = label;
          });
        }
      });
    }

    if (prefill.initialDistanceKm != null) {
      final km = prefill.initialDistanceKm!;
      _distanceCtrl.text = km < 10
          ? km.toStringAsFixed(2)
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

  void _prefillCostFromFuelHistory() {
    if (_costPerKmCtrl.text.trim().isNotEmpty) return;
    final logs = ref.read(vehicleLogsProvider).valueOrNull ?? const [];
    final avg = TripStatsHelper.averageCostPerKm(logs);
    if (avg <= 0) return;
    _costPerKmCtrl.text = avg < 10
        ? avg.toStringAsFixed(1)
        : avg.toStringAsFixed(0);
    _syncTripCostFromRate();
  }

  @override
  void dispose() {
    _startOdoCtrl.removeListener(_syncDistanceFromOdo);
    _endOdoCtrl.removeListener(_syncDistanceFromOdo);
    _costPerKmCtrl.removeListener(_syncTripCostFromRate);
    _distanceCtrl.removeListener(_syncTripCostFromRate);
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

  void _syncTripCostFromRate() {
    final rate = double.tryParse(_costPerKmCtrl.text.trim());
    final km = double.tryParse(_distanceCtrl.text.trim());
    if (rate == null || km == null || rate <= 0 || km <= 0) return;
    final total = rate * km;
    final text = total == total.roundToDouble()
        ? total.toStringAsFixed(0)
        : total.toStringAsFixed(1);
    if (_tripCostCtrl.text == text) return;
    _tripCostCtrl.text = text;
  }

  Future<void> _pickMapLocation({required bool isStart}) async {
    final picked = await showTripLocationPicker(
      context,
      title: isStart ? 'startPoint'.tr() : 'endPoint'.tr(),
      initial: isStart ? _originPoint : _destPoint,
    );
    if (picked == null || !mounted) return;
    setState(() {
      if (isStart) {
        _originPoint = picked.point;
        _originCtrl.text = picked.label;
      } else {
        _destPoint = picked.point;
        _destinationCtrl.text = picked.label;
      }
    });
    await _recalcDistanceFromMap();
  }

  Future<void> _recalcDistanceFromMap() async {
    if (_originPoint == null || _destPoint == null) return;
    final route = await NavigationRoutingService.instance.getDrivingRoute(
      start: _originPoint!,
      destination: _destPoint!,
    );
    final km = route.distanceMeters / 1000.0;
    if (!mounted || km <= 0) return;
    final text = km == km.roundToDouble()
        ? km.toStringAsFixed(0)
        : km.toStringAsFixed(1);
    _distanceCtrl.text = text;
    _syncTripCostFromRate();
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
    if (_isSaving) return;
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
      routeJson: widget.prefill?.routeJson != null
          ? drift.Value(widget.prefill!.routeJson)
          : drift.Value.absent(),
    );

    setState(() => _isSaving = true);

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
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.92;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
          child: Container(
            height: maxHeight,
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(28)),
              border: Border.all(
                color: AppColors.border,
              ),
            ),
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
                              width: 36,
                              height: 4,
                              decoration: BoxDecoration(
                                color: AppColors.borderStrong,
                                borderRadius: BorderRadius.circular(
                                  AppSpacing.radiusPill,
                                ),
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
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                              _GlassIconButton(
                                icon: Icons.close_rounded,
                                onPressed: () => Navigator.of(context).pop(),
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
                          AppSpacing.md,
                          AppSpacing.screenPadding,
                          AppSpacing.sm,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _GlassSection(
                              child: Column(
                                children: [
                                  _UnderlineField(
                                    controller: _titleCtrl,
                                    label: 'tripTitleField'.tr(),
                                    hint: 'tripTitleHint'.tr(),
                                    icon: Icons.work_outline_rounded,
                                    textInputAction: TextInputAction.next,
                                  ),
                                  const SizedBox(height: AppSpacing.xs),
                                  _PrivacySelector(
                                    value: _privacy,
                                    customCategories: _customCategories,
                                    onChanged: (v) =>
                                        setState(() => _privacy = v),
                                    onAddCustom: _addCustomCategory,
                                    showBorder: false,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            _GlassSection(
                              label: 'startPoint'.tr(),
                              child: Column(
                                children: [
                                  _LocationField(
                                    controller: _originCtrl,
                                    label: 'tripOrigin'.tr(),
                                    hint: 'tripOriginHint'.tr(),
                                    icon: Icons.location_on_outlined,
                                    onPickMap: () =>
                                        _pickMapLocation(isStart: true),
                                    validator: (v) =>
                                        (v == null || v.trim().isEmpty)
                                            ? 'fieldRequired'.tr()
                                            : null,
                                  ),
                                  const SizedBox(height: AppSpacing.xs),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _TapField(
                                          icon: Icons.calendar_today_outlined,
                                          label: 'date'.tr(),
                                          value: _dateFmt.format(_startDate),
                                          onTap: () =>
                                              _pickDate(isStart: true),
                                        ),
                                      ),
                                      const SizedBox(width: AppSpacing.sm),
                                      Expanded(
                                        child: _TapField(
                                          icon: Icons.schedule_rounded,
                                          label: 'time'.tr(),
                                          value: _startTime.format(context),
                                          onTap: () =>
                                              _pickTime(isStart: true),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: AppSpacing.xs),
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
                                    showBorder: false,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            _GlassSection(
                              label: 'endPoint'.tr(),
                              child: Column(
                                children: [
                                  _LocationField(
                                    controller: _destinationCtrl,
                                    label: 'tripDestination'.tr(),
                                    hint: 'tripDestinationHint'.tr(),
                                    icon: Icons.flag_outlined,
                                    onPickMap: () =>
                                        _pickMapLocation(isStart: false),
                                    validator: (v) =>
                                        (v == null || v.trim().isEmpty)
                                            ? 'fieldRequired'.tr()
                                            : null,
                                  ),
                                  const SizedBox(height: AppSpacing.xs),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _TapField(
                                          icon: Icons.calendar_today_outlined,
                                          label: 'date'.tr(),
                                          value: _dateFmt.format(_endDate),
                                          onTap: () =>
                                              _pickDate(isStart: false),
                                        ),
                                      ),
                                      const SizedBox(width: AppSpacing.sm),
                                      Expanded(
                                        child: _TapField(
                                          icon: Icons.schedule_rounded,
                                          label: 'time'.tr(),
                                          value: _endTime.format(context),
                                          onTap: () =>
                                              _pickTime(isStart: false),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: AppSpacing.xs),
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
                                    showBorder: false,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            _GlassSection(
                              label: 'optional'.tr(),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _UnderlineField(
                                          controller: _costPerKmCtrl,
                                          label: 'costPerKm'.tr(),
                                          hint: 'costPerKmHint'.tr(),
                                          prefixText: '৳ ',
                                          keyboardType: const TextInputType
                                              .numberWithOptions(
                                            decimal: true,
                                          ),
                                          textInputAction:
                                              TextInputAction.next,
                                        ),
                                      ),
                                      const SizedBox(width: AppSpacing.sm),
                                      Expanded(
                                        child: _UnderlineField(
                                          controller: _tripCostCtrl,
                                          label: 'tripCost'.tr(),
                                          hint: 'tripCostHint'.tr(),
                                          prefixText: '৳ ',
                                          keyboardType: const TextInputType
                                              .numberWithOptions(
                                            decimal: true,
                                          ),
                                          textInputAction:
                                              TextInputAction.next,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: AppSpacing.xs),
                                  _UnderlineField(
                                    controller: _distanceCtrl,
                                    label: 'totalDistance'.tr(),
                                    hint: '0.0',
                                    icon: Icons.straighten_rounded,
                                    suffix: 'km'.tr(),
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                    textInputAction: TextInputAction.next,
                                  ),
                                  const SizedBox(height: AppSpacing.xs),
                                  _UnderlineField(
                                    controller: _noteCtrl,
                                    label: 'note'.tr(),
                                    hint: 'tripNoteHint'.tr(),
                                    icon: Icons.notes_rounded,
                                    maxLines: 2,
                                    textInputAction: TextInputAction.done,
                                    showBorder: false,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    _TripSaveFooter(
                      isSaving: _isSaving,
                      onSave: _onSave,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassSection extends StatelessWidget {
  const _GlassSection({
    required this.child,
    this.label,
  });

  final Widget child;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return CleanGlassPanel(
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      padding: EdgeInsets.fromLTRB(12, 8, 12, 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (label != null) ...[
            Text(
              label!,
              style: AppTextStyles.label.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
                fontSize: 11,
                letterSpacing: 0.3,
              ),
            ),
            SizedBox(height: AppSpacing.xs),
          ],
          child,
        ],
      ),
    );
  }
}

class _TripFieldDecor {
  _TripFieldDecor._();

  static const prefixConstraints = BoxConstraints(minWidth: 34, minHeight: 28);
  static const contentPadding = EdgeInsets.symmetric(vertical: 4);
  static const multiLinePadding = EdgeInsets.only(top: 8, bottom: 4);
  static final _iconColor = AppColors.textTertiary;
  static final _labelColor = AppColors.textTertiary;
  static final _focusedLabelColor = AppColors.textSecondary;

  static InputDecoration base({
    String? labelText,
    String? hintText,
    IconData? prefixIcon,
    String? prefixText,
    String? suffixText,
    int maxLines = 1,
    bool showBorder = true,
  }) {
    final borderSide = showBorder
        ? BorderSide(color: AppColors.border)
        : BorderSide.none;
    final focusedBorder = showBorder
        ? UnderlineInputBorder(
            borderSide: BorderSide(
              color: AppColors.primary.withValues(alpha: 0.65),
              width: 1.2,
            ),
          )
        : InputBorder.none;

    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      prefixIcon: prefixIcon == null
          ? null
          : Icon(prefixIcon, color: _iconColor, size: 18),
      prefixIconConstraints: prefixConstraints,
      prefixText: prefixText,
      prefixStyle: AppTextStyles.body.copyWith(
        color: AppColors.primary,
        fontWeight: FontWeight.w700,
        fontSize: 16,
      ),
      suffixText: suffixText,
      suffixStyle: AppTextStyles.caption.copyWith(
        color: AppColors.textTertiary,
        fontSize: 11,
      ),
      isDense: true,
      filled: false,
      alignLabelWithHint: maxLines > 1,
      contentPadding: maxLines > 1 ? multiLinePadding : contentPadding,
      border: UnderlineInputBorder(borderSide: borderSide),
      enabledBorder: UnderlineInputBorder(borderSide: borderSide),
      focusedBorder: focusedBorder,
      errorBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: AppColors.error),
      ),
      focusedErrorBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: AppColors.error, width: 1.4),
      ),
      labelStyle: AppTextStyles.caption.copyWith(
        fontSize: 11,
        color: _labelColor,
      ),
      floatingLabelStyle: AppTextStyles.caption.copyWith(
        color: _focusedLabelColor,
        fontSize: 11,
      ),
      hintStyle: AppTextStyles.bodySecondary.copyWith(
        color: AppColors.textTertiary,
        fontSize: 13,
      ),
    );
  }
}

class _GlassIconButton extends StatelessWidget {
  const _GlassIconButton({
    required this.icon,
    required this.onPressed,
  });

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.inputFill,
      shape: CircleBorder(),
      child: InkWell(
        onTap: onPressed,
        customBorder: CircleBorder(),
        child: Padding(
          padding: EdgeInsets.all(8),
          child: Icon(icon, size: 20, color: AppColors.textSecondary),
        ),
      ),
    );
  }
}

class _TripSaveFooter extends StatelessWidget {
  const _TripSaveFooter({
    required this.isSaving,
    required this.onSave,
  });

  final bool isSaving;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: AppColors.border),
        ),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.card.withValues(alpha: 0.2),
            AppColors.card,
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenPadding,
          AppSpacing.sm,
          AppSpacing.screenPadding,
          AppSpacing.md,
        ),
        child: AppPrimaryButton(
          label: 'saveTrip'.tr(),
          icon: Icons.check_rounded,
          isLoading: isSaving,
          compact: true,
          onPressed: isSaving ? null : onSave,
        ),
      ),
    );
  }
}

class _PrivacySelector extends StatelessWidget {
  const _PrivacySelector({
    required this.value,
    required this.customCategories,
    required this.onChanged,
    required this.onAddCustom,
    this.showBorder = true,
  });

  final String value;
  final List<String> customCategories;
  final ValueChanged<String> onChanged;
  final VoidCallback onAddCustom;
  final bool showBorder;

  @override
  Widget build(BuildContext context) {
    final items = <DropdownMenuItem<String>>[
      DropdownMenuItem(value: 'private', child: Text('privacyPrivate'.tr())),
      DropdownMenuItem(value: 'work', child: Text('privacyWork'.tr())),
      DropdownMenuItem(value: 'other', child: Text('privacyOther'.tr())),
      for (final name in customCategories)
        DropdownMenuItem(value: name, child: Text(name)),
      DropdownMenuItem(
        value: TripCategoryPrefs.addCustomValue,
        child: Text(
          'addCustomCategory'.tr(),
          style: AppTextStyles.body.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    ];

    final selected = items.any((item) => item.value == value)
        ? value
        : 'private';

    return DropdownButtonFormField<String>(
      key: ValueKey('$selected-${customCategories.length}'),
      initialValue: selected,
      dropdownColor: AppColors.card,
      icon: Icon(
        Icons.keyboard_arrow_down_rounded,
        color: AppColors.textTertiary,
      ),
      decoration: _TripFieldDecor.base(
        labelText: 'tripPrivacy'.tr(),
        prefixIcon: Icons.label_outline_rounded,
        showBorder: showBorder,
      ),
      style: AppTextStyles.body.copyWith(
        fontWeight: FontWeight.w500,
        fontSize: 14,
      ),
      items: items,
      onChanged: (v) {
        if (v == null) return;
        if (v == TripCategoryPrefs.addCustomValue) {
          onAddCustom();
          return;
        }
        onChanged(v);
      },
    );
  }
}

class _AddCategoryDialog extends StatefulWidget {
  const _AddCategoryDialog();

  @override
  State<_AddCategoryDialog> createState() => _AddCategoryDialogState();
}

class _AddCategoryDialogState extends State<_AddCategoryDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _controller.text.trim();
    if (name.isEmpty) return;
    Navigator.of(context).pop(name);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.appBar,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: AppColors.hairline),
      ),
      title: Text(
        'addCustomCategory'.tr(),
        style: AppTextStyles.title.copyWith(fontSize: 17),
      ),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _submit(),
        style: AppTextStyles.body,
        cursorColor: AppColors.primary,
        decoration: InputDecoration(
          hintText: 'customCategoryHint'.tr(),
          hintStyle: AppTextStyles.bodySecondary.copyWith(
            color: AppColors.textTertiary,
            fontSize: 13,
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'cancel'.tr(),
            style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
          ),
        ),
        TextButton(
          onPressed: _submit,
          child: Text(
            'save'.tr(),
            style: AppTextStyles.body.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
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
        decoration: _TripFieldDecor.base(
          labelText: label,
          prefixIcon: icon,
        ),
        child: Text(
          value,
          style: AppTextStyles.body.copyWith(
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

class _LocationField extends StatelessWidget {
  const _LocationField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    required this.onPickMap,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final VoidCallback onPickMap;
  final FormFieldValidator<String>? validator;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: _UnderlineField(
            controller: controller,
            label: label,
            hint: hint,
            icon: icon,
            textInputAction: TextInputAction.next,
            validator: validator,
          ),
        ),
        const SizedBox(width: 10),
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Tooltip(
            message: 'pickOnMap'.tr(),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onPickMap,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                child: Ink(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.28),
                    ),
                  ),
                  child: Icon(
                    LucideIcons.mapPinned,
                    size: 17,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _UnderlineField extends StatelessWidget {
  const _UnderlineField({
    required this.controller,
    required this.label,
    required this.hint,
    this.icon,
    this.prefixText,
    this.suffix,
    this.keyboardType,
    this.inputFormatters,
    this.textInputAction,
    this.validator,
    this.maxLines = 1,
    this.showBorder = true,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData? icon;
  final String? prefixText;
  final String? suffix;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final TextInputAction? textInputAction;
  final FormFieldValidator<String>? validator;
  final int maxLines;
  final bool showBorder;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      textInputAction: textInputAction,
      validator: validator,
      maxLines: maxLines,
      style: AppTextStyles.body.copyWith(
        fontWeight: FontWeight.w500,
        fontSize: 14,
      ),
      cursorColor: AppColors.primary,
      decoration: _TripFieldDecor.base(
        labelText: label,
        hintText: hint,
        prefixIcon: icon,
        prefixText: prefixText,
        suffixText: suffix,
        maxLines: maxLines,
        showBorder: showBorder,
      ),
    );
  }
}
