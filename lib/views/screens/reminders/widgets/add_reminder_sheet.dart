import 'package:drift/drift.dart' as drift;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/utils/notification_service.dart';
import '../../../../viewmodels/fuel_log_viewmodel.dart';
import '../../../../viewmodels/vehicle_viewmodel.dart';

/// Modal sheet for creating or editing vehicle maintenance reminders in Drift DB.
class AddReminderSheet extends ConsumerStatefulWidget {
  const AddReminderSheet({
    super.key,
    this.vehicleId,
    this.currentOdometer,
    this.existingReminder,
    this.onSave,
  });

  final int? vehicleId;
  final double? currentOdometer;
  final Reminder? existingReminder;
  final VoidCallback? onSave;

  static Future<void> show(
    BuildContext context, {
    int? vehicleId,
    double? currentOdometer,
    Reminder? existingReminder,
    VoidCallback? onSave,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddReminderSheet(
        vehicleId: vehicleId,
        currentOdometer: currentOdometer,
        existingReminder: existingReminder,
        onSave: onSave,
      ),
    );
  }

  @override
  ConsumerState<AddReminderSheet> createState() => _AddReminderSheetState();
}

class _AddReminderSheetState extends ConsumerState<AddReminderSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _targetOdoController;
  DateTime? _selectedTargetDate;
  String? _selectedTitle;
  String? _selectedOilType;

  static const List<String> _titlePresets = [
    'Engine Oil',
    'Tire Rotation',
    'General Service',
    'Air Filter',
    'Brake Pads & Fluid',
    'Spark Plug Check',
    'Battery Check',
    'Tax Token Renewal',
    'Custom Title...',
  ];

  static const List<Map<String, dynamic>> _oilTypes = [
    {
      'label': 'Mineral (~1500 km)',
      'name': 'Mineral',
      'km': 1500.0,
    },
    {
      'label': 'Semi-Synthetic (~2500 km)',
      'name': 'Semi-Synthetic',
      'km': 2500.0,
    },
    {
      'label': 'Fully Synthetic (~4000 km)',
      'name': 'Fully Synthetic',
      'km': 4000.0,
    },
  ];

  bool get _isCustomTitle => _selectedTitle == 'Custom Title...';

  bool get _isEngineOil {
    final title = (_isCustomTitle ? _titleController.text : (_selectedTitle ?? ''))
        .trim()
        .toLowerCase();
    return title == 'engine oil' || title.startsWith('engine oil');
  }

  bool get _isDateOnlyReminder {
    final title = (_isCustomTitle ? _titleController.text : (_selectedTitle ?? ''))
        .trim()
        .toLowerCase();
    return title.contains('tax') ||
        title.contains('token') ||
        title.contains('insurance') ||
        title.contains('license') ||
        title.contains('registration') ||
        title.contains('fitness');
  }

  @override
  void initState() {
    super.initState();
    final r = widget.existingReminder;
    final initialTitle = r?.title ?? 'Engine Oil';
    _titleController = TextEditingController(text: initialTitle);
    if (_titlePresets.contains(initialTitle)) {
      _selectedTitle = initialTitle;
    } else {
      _selectedTitle = 'Custom Title...';
    }
    _targetOdoController = TextEditingController(
      text: r?.targetOdometer != null ? r!.targetOdometer!.toStringAsFixed(0) : '',
    );
    _selectedTargetDate = r?.targetDate;

    _titleController.addListener(_onTitleChanged);
  }

  void _onTitleChanged() {
    setState(() {
      if (!_isEngineOil) {
        _selectedOilType = null;
      }
    });
  }

  @override
  void dispose() {
    _titleController.removeListener(_onTitleChanged);
    _titleController.dispose();
    _targetOdoController.dispose();
    super.dispose();
  }

  void _onOilTypeSelected(String? label, double currentOdo) {
    if (label == null) return;

    final option = _oilTypes.firstWhere(
      (e) => e['label'] == label || e['name'] == label,
      orElse: () => _oilTypes.first,
    );

    final String name = option['name'] as String;
    final double intervalKm = option['km'] as double;
    final double newTargetOdo = currentOdo + intervalKm;

    setState(() {
      _selectedOilType = name;
      _targetOdoController.text = newTargetOdo.toStringAsFixed(0);
    });
  }

  Future<void> _pickTargetDate() async {
    final now = DateTime.now();
    final initialDate = _selectedTargetDate ?? now.add(const Duration(days: 30));
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate.isBefore(now) ? now : initialDate,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365 * 5)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: Color(0xFF1E1E2A),
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedTargetDate = picked;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final rawTitle = (_isCustomTitle
            ? _titleController.text
            : (_selectedTitle ?? ''))
        .trim();
    if (rawTitle.isEmpty) return;

    if (_isDateOnlyReminder && _selectedTargetDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Target Date is required for Tax Token / Date-based reminders.'),
          backgroundColor: Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    String finalTitle = rawTitle;
    if (_isEngineOil && _selectedOilType != null && _selectedOilType!.isNotEmpty) {
      if (!rawTitle.contains(_selectedOilType!)) {
        finalTitle = '$rawTitle ($_selectedOilType)';
      }
    }

    final activeVehicle = ref.read(activeVehicleProvider).valueOrNull;
    final vId = widget.vehicleId ?? activeVehicle?.id;
    if (vId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No active vehicle selected.')),
      );
      return;
    }

    final targetOdoText = _targetOdoController.text.trim();
    final targetOdometer =
        targetOdoText.isNotEmpty ? double.tryParse(targetOdoText) : null;

    final db = ref.read(databaseProvider);
    final reminderId = await db.insertReminder(
      RemindersCompanion.insert(
        vehicleId: vId,
        title: finalTitle,
        targetDate: _selectedTargetDate != null
            ? drift.Value(_selectedTargetDate!)
            : const drift.Value.absent(),
        targetOdometer: targetOdometer != null
            ? drift.Value(targetOdometer)
            : const drift.Value.absent(),
        isCompleted: const drift.Value(false),
      ),
    );

    // If a Date is selected, immediately schedule local notification
    if (_selectedTargetDate != null) {
      await NotificationService().scheduleNotification(
        id: reminderId,
        title: finalTitle,
        scheduledDate: _selectedTargetDate!,
        body: 'Maintenance Due Today: $finalTitle',
      );
    }

    widget.onSave?.call();

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Reminder "$finalTitle" saved successfully!'),
          backgroundColor: const Color(0xFF1E1E2C),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final dateFormat = DateFormat('MMM dd, yyyy');

    final vehicle = ref.watch(activeVehicleProvider).valueOrNull;
    final logs = ref.watch(vehicleLogsProvider).valueOrNull ?? const [];
    final double currentOdo = widget.currentOdometer ??
        (logs.isNotEmpty ? logs.first.odometer : (vehicle?.startOdo ?? 0.0));

    return Container(
      padding: EdgeInsets.fromLTRB(20, 14, 20, 20 + bottomInset),
      decoration: const BoxDecoration(
        color: Color(0xFF14141C),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle Bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFF333342),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Title Header
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.notifications_active_rounded,
                      color: AppColors.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Add Maintenance Reminder',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Horizontal Tab Bar Choice Chips for Reminder Title
              const Text(
                'Reminder Title',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),

              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _titlePresets.map((preset) {
                    final isSelected = _selectedTitle == preset;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(preset),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _selectedTitle = preset;
                              if (preset != 'Custom Title...') {
                                _titleController.text = preset;
                              } else {
                                _titleController.clear();
                              }
                              if (!_isEngineOil) {
                                _selectedOilType = null;
                              }
                            });
                          }
                        },
                        selectedColor: AppColors.primary.withValues(alpha: 0.2),
                        backgroundColor: const Color(0xFF1E1E2A),
                        side: BorderSide(
                          color: isSelected
                              ? AppColors.primary
                              : const Color(0xFF2E2E3E),
                        ),
                        labelStyle: TextStyle(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.textPrimary,
                          fontSize: 12,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                        showCheckmark: false,
                      ),
                    );
                  }).toList(),
                ),
              ),

              // Conditionally show Custom Title TextField ONLY if 'Custom Title...' is selected
              if (_isCustomTitle) ...[
                const SizedBox(height: 10),
                TextFormField(
                  controller: _titleController,
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                  validator: (val) =>
                      val == null || val.trim().isEmpty ? 'Please enter a custom title' : null,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFF1E1E2A),
                    labelText: 'Custom Title Name',
                    labelStyle: const TextStyle(color: AppColors.textTertiary, fontSize: 13),
                    hintText: 'e.g. Transmission Fluid, Coolant Flush...',
                    hintStyle: const TextStyle(color: AppColors.textTertiary, fontSize: 13),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF2E2E3E)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF2E2E3E)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                    ),
                  ),
                ),
              ],

              // Conditional Oil Type Dropdown
              if (_isEngineOil) ...[
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(
                          Icons.oil_barrel_rounded,
                          color: AppColors.primary,
                          size: 16,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Oil Type',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    Flexible(
                      child: Text(
                        'Current Odo: ${currentOdo.toStringAsFixed(0)} km',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textTertiary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: _selectedOilType != null
                      ? _oilTypes.firstWhere(
                          (e) => e['name'] == _selectedOilType,
                          orElse: () => _oilTypes.first,
                        )['label'] as String
                      : null,
                  dropdownColor: const Color(0xFF1E1E2A),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                  ),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFF1E1E2A),
                    hintText: 'Select oil type',
                    hintStyle: const TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: 13,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    prefixIcon: const Icon(
                      Icons.opacity_rounded,
                      color: AppColors.primary,
                      size: 18,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF2E2E3E)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF2E2E3E)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppColors.primary,
                        width: 1.5,
                      ),
                    ),
                  ),
                  items: _oilTypes.map((opt) {
                    return DropdownMenuItem<String>(
                      value: opt['label'] as String,
                      child: Text(
                        opt['label'] as String,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (val) => _onOilTypeSelected(val, currentOdo),
                ),
              ],

              // Target Odometer (km) - Conditionally hidden for Date-Only reminders (Tax Token, Insurance, etc.)
              if (!_isDateOnlyReminder) ...[
                const SizedBox(height: 16),
                const Text(
                  'Target Odometer (km)',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _targetOdoController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                  decoration: InputDecoration(
                    suffixText: 'km',
                    suffixStyle: const TextStyle(color: AppColors.textTertiary),
                    filled: true,
                    fillColor: const Color(0xFF1E1E2A),
                    hintText: 'e.g. 5000 (Optional)',
                    hintStyle: const TextStyle(color: AppColors.textTertiary, fontSize: 13),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF2E2E3E)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF2E2E3E)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // Target Date Picker
              Row(
                children: [
                  const Text(
                    'Target Date',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (_isDateOnlyReminder)
                    const Text(
                      ' * (Required)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFEF4444),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              InkWell(
                onTap: _pickTargetDate,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E2A),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _isDateOnlyReminder && _selectedTargetDate == null
                          ? const Color(0xFFEF4444).withValues(alpha: 0.6)
                          : const Color(0xFF2E2E3E),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_today_rounded,
                            color: AppColors.primary,
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            _selectedTargetDate != null
                                ? dateFormat.format(_selectedTargetDate!)
                                : _isDateOnlyReminder
                                    ? 'Select Target Date *'
                                    : 'Select Target Date (Optional)',
                            style: TextStyle(
                              color: _selectedTargetDate != null
                                  ? AppColors.textPrimary
                                  : _isDateOnlyReminder
                                      ? const Color(0xFFEF4444)
                                      : AppColors.textTertiary,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      if (_selectedTargetDate != null)
                        GestureDetector(
                          onTap: () => setState(() => _selectedTargetDate = null),
                          child: const Icon(
                            Icons.close_rounded,
                            color: AppColors.textTertiary,
                            size: 18,
                          ),
                        )
                      else
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: AppColors.textTertiary,
                          size: 20,
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Submit & Cancel Action Buttons
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textPrimary,
                          side: const BorderSide(color: Color(0xFF2E2E3E)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Cancel',
                            style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Save Reminder',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
