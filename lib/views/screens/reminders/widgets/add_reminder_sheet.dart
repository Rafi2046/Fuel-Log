import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../models/reminder_model.dart';

/// Modal sheet for creating or editing vehicle maintenance reminders with presets
class AddReminderSheet extends StatefulWidget {
  const AddReminderSheet({
    super.key,
    required this.vehicleId,
    required this.currentOdometer,
    this.existingReminder,
    required this.onSave,
  });

  final int vehicleId;
  final double currentOdometer;
  final ServiceReminder? existingReminder;
  final ValueChanged<ServiceReminder> onSave;

  static Future<void> show(
    BuildContext context, {
    required int vehicleId,
    required double currentOdometer,
    ServiceReminder? existingReminder,
    required ValueChanged<ServiceReminder> onSave,
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
  State<AddReminderSheet> createState() => _AddReminderSheetState();
}

class _AddReminderSheetState extends State<AddReminderSheet> {
  late TextEditingController _titleController;
  late TextEditingController _kmController;
  late TextEditingController _daysController;
  late TextEditingController _notesController;
  late ServiceType _selectedType;

  final List<Map<String, dynamic>> _presets = [
    {
      'name': '🏍️ Bike Engine Oil',
      'type': ServiceType.engineOil,
      'km': '2000',
      'days': '60',
      'notes': 'Semi-Synthetic 10W-40',
    },
    {
      'name': '🚗 Car Engine Oil',
      'type': ServiceType.engineOil,
      'km': '5000',
      'days': '180',
      'notes': 'Synthetic 5W-30 + OEM Filter',
    },
    {
      'name': '🛠️ General Servicing',
      'type': ServiceType.generalService,
      'km': '4000',
      'days': '120',
      'notes': 'Chain lube, tuning & checks',
    },
    {
      'name': '🛑 Brake Pads & Fluid',
      'type': ServiceType.brakeFluid,
      'km': '10000',
      'days': '365',
      'notes': 'DOT 4 Brake Fluid',
    },
    {
      'name': '💨 Air Filter',
      'type': ServiceType.airFilter,
      'km': '6000',
      'days': '180',
      'notes': 'Clean or replace filter',
    },
    {
      'name': '📄 Tax Token',
      'type': ServiceType.taxToken,
      'km': '',
      'days': '365',
      'notes': 'BRTA Renewal',
    },
  ];

  @override
  void initState() {
    super.initState();
    final r = widget.existingReminder;
    _titleController = TextEditingController(text: r?.title ?? 'Engine Oil Change');
    _kmController = TextEditingController(
      text: r?.intervalKm != null ? r!.intervalKm!.toStringAsFixed(0) : '2000',
    );
    _daysController = TextEditingController(
      text: r?.intervalDays != null ? r!.intervalDays.toString() : '60',
    );
    _notesController = TextEditingController(text: r?.notes ?? '');
    _selectedType = r?.serviceType ?? ServiceType.engineOil;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _kmController.dispose();
    _daysController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _applyPreset(Map<String, dynamic> preset) {
    setState(() {
      _titleController.text = preset['name'].toString().replaceFirst(RegExp(r'^[^\s]+\s'), '');
      _selectedType = preset['type'] as ServiceType;
      _kmController.text = preset['km'] as String;
      _daysController.text = preset['days'] as String;
      _notesController.text = preset['notes'] as String;
    });
  }

  void _submit() {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    final km = double.tryParse(_kmController.text.trim());
    final days = int.tryParse(_daysController.text.trim());
    final now = DateTime.now();

    final reminder = ServiceReminder(
      id: widget.existingReminder?.id ??
          '${widget.vehicleId}_${now.millisecondsSinceEpoch}',
      vehicleId: widget.vehicleId,
      title: title,
      serviceType: _selectedType,
      lastServiceOdo: widget.existingReminder?.lastServiceOdo ?? widget.currentOdometer,
      lastServiceDate: widget.existingReminder?.lastServiceDate ?? now,
      intervalKm: km,
      intervalDays: days,
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      isRecurring: true,
      isCompleted: false,
    );

    widget.onSave(reminder);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + bottomInset),
      decoration: const BoxDecoration(
        color: Color(0xFF14141C),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle Bar
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFF333342),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Header
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.notification_add_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  widget.existingReminder != null ? 'Edit Reminder' : 'Add Maintenance Reminder',
                  style: GoogleFonts.inter(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // 1-Tap Quick Presets
            const Text(
              'Quick Presets',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textTertiary,
              ),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _presets.map((p) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: InkWell(
                      onTap: () => _applyPreset(p),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E2A),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFF2E2E3E)),
                        ),
                        child: Text(
                          p['name'] as String,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 16),

            // Reminder Title
            const Text(
              'Reminder Title',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _titleController,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFF1E1E2A),
                hintText: 'e.g. Engine Oil Change',
                hintStyle: const TextStyle(color: AppColors.textTertiary, fontSize: 13),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF2E2E3E)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF2E2E3E)),
                ),
              ),
            ),

            const SizedBox(height: 14),

            // Dual Interval Pickers (KM & Days)
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Repeat Every (KM)',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _kmController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                        decoration: InputDecoration(
                          suffixText: 'km',
                          filled: true,
                          fillColor: const Color(0xFF1E1E2A),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFF2E2E3E)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFF2E2E3E)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Or Every (Days)',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _daysController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                        decoration: InputDecoration(
                          suffixText: 'days',
                          filled: true,
                          fillColor: const Color(0xFF1E1E2A),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFF2E2E3E)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFF2E2E3E)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Notes / Specs
            const Text(
              'Oil Grade / Notes (Optional)',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _notesController,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFF1E1E2A),
                hintText: 'e.g. Motul 7100 10W-40 Full Synthetic',
                hintStyle: const TextStyle(color: AppColors.textTertiary, fontSize: 13),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF2E2E3E)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF2E2E3E)),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Action Buttons
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
                      child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600)),
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
    );
  }
}
