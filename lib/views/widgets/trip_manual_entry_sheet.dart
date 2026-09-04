import 'package:drift/drift.dart' as drift;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

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
import 'trip_location_picker_page.dart';
import 'trip_manual_entry/trip_entry_form_sections.dart';
import 'trip_manual_entry/trip_manual_entry_prefill.dart';
import 'trip_manual_entry/trip_manual_entry_sheet_layout.dart';
import 'trip_manual_entry/trip_privacy_selector.dart';

export 'trip_manual_entry/trip_manual_entry_prefill.dart';

/// Full manual trip form — all reference fields, borderless style.
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
      builder: (ctx) => const AddCategoryDialog(),
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
      _distanceCtrl.text =
          km < 10 ? km.toStringAsFixed(2) : km.toStringAsFixed(1);
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
    _costPerKmCtrl.text =
        avg < 10 ? avg.toStringAsFixed(1) : avg.toStringAsFixed(0);
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
          : const drift.Value.absent(),
    );

    setState(() => _isSaving = true);

    try {
      final messenger = ScaffoldMessenger.of(context);
      final nav = Navigator.of(context);
      await ref.read(tripLogProvider.notifier).addTrip(companion);
      if (!mounted) return;
      nav.pop();
      messenger.showSnackBar(
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
    return TripManualEntrySheetLayout(
      formKey: _formKey,
      onClose: () => Navigator.of(context).pop(),
      onSave: _onSave,
      isSaving: _isSaving,
      children: [
        TripGeneralInfoSection(
          titleCtrl: _titleCtrl,
          privacy: _privacy,
          customCategories: _customCategories,
          onPrivacyChanged: (v) => setState(() => _privacy = v),
          onAddCustomCategory: _addCustomCategory,
        ),
        const SizedBox(height: AppSpacing.sm),
        TripRouteSection(
          originCtrl: _originCtrl,
          destinationCtrl: _destinationCtrl,
          startOdoCtrl: _startOdoCtrl,
          endOdoCtrl: _endOdoCtrl,
          startDate: _startDate,
          startTime: _startTime,
          endDate: _endDate,
          endTime: _endTime,
          dateFmt: _dateFmt,
          onPickOriginMap: () => _pickMapLocation(isStart: true),
          onPickDestMap: () => _pickMapLocation(isStart: false),
          onPickStartDate: () => _pickDate(isStart: true),
          onPickStartTime: () => _pickTime(isStart: true),
          onPickEndDate: () => _pickDate(isStart: false),
          onPickEndTime: () => _pickTime(isStart: false),
        ),
        const SizedBox(height: AppSpacing.sm),
        TripFinancialsSection(
          costPerKmCtrl: _costPerKmCtrl,
          tripCostCtrl: _tripCostCtrl,
          distanceCtrl: _distanceCtrl,
          noteCtrl: _noteCtrl,
        ),
      ],
    );
  }
}
