import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../viewmodels/service_log_viewmodel.dart';
import '../../reminders/reminders_screen.dart';

/// Modal bottom sheet for adding non-fuel vehicle costs and maintenance services
class AddCostServiceSheet extends ConsumerStatefulWidget {
  const AddCostServiceSheet({
    super.key,
    required this.vehicleId,
    required this.currentOdometer,
  });

  final int vehicleId;
  final double currentOdometer;

  static Future<void> show(
    BuildContext context, {
    required int vehicleId,
    required double currentOdometer,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF161622),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => AddCostServiceSheet(
        vehicleId: vehicleId,
        currentOdometer: currentOdometer,
      ),
    );
  }

  @override
  ConsumerState<AddCostServiceSheet> createState() =>
      _AddCostServiceSheetState();
}

class _AddCostServiceSheetState extends ConsumerState<AddCostServiceSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _costController;
  late TextEditingController _titleController;
  late TextEditingController _odoController;
  late TextEditingController _notesController;
  DateTime _selectedDate = DateTime.now();

  String _selectedCategory = 'Maintenance';
  String? _selectedPresetTitle;

  static const List<Map<String, dynamic>> _categories = [
    {
      'id': 'Maintenance',
      'label': 'Maintenance',
      'icon': Icons.build_rounded,
      'presets': [
        'Engine Oil Change',
        'Brake Pad Replacement',
        'Tire Alignment',
        'Air Filter',
        'General Servicing',
        'Battery Change',
        'Custom Title...',
      ],
    },
    {
      'id': 'Parking & Toll',
      'label': 'Parking & Toll',
      'icon': Icons.local_parking_rounded,
      'presets': [
        'Parking Fee',
        'Highway Toll',
        'Bridge Toll',
        'Custom Title...',
      ],
    },
    {
      'id': 'Tax & Legal',
      'label': 'Tax & Legal',
      'icon': Icons.description_rounded,
      'presets': [
        'Tax Token Renewal',
        'Fitness Certificate',
        'Insurance Premium',
        'Traffic Fine',
        'Custom Title...',
      ],
    },
    {
      'id': 'Wash & Detailing',
      'label': 'Wash & Detailing',
      'icon': Icons.clean_hands_rounded,
      'presets': [
        'Express Wash',
        'Full Detailing',
        'Polish & Wax',
        'Custom Title...',
      ],
    },
    {
      'id': 'Parts & Accessories',
      'label': 'Parts & Accessories',
      'icon': Icons.shopping_bag_rounded,
      'presets': [
        'Spare Parts',
        'Helmet',
        'Dashcam',
        'Seat Covers',
        'New Tires',
        'Custom Title...',
      ],
    },
    {
      'id': 'Other',
      'label': 'Other',
      'icon': Icons.more_horiz_rounded,
      'presets': [
        'Miscellaneous Expense',
        'Custom Title...',
      ],
    },
  ];

  bool get _isCustomTitle => _selectedPresetTitle == 'Custom Title...';

  List<String> get _currentPresets {
    final cat = _categories.firstWhere(
      (c) => c['id'] == _selectedCategory,
      orElse: () => _categories.first,
    );
    return List<String>.from(cat['presets'] as List);
  }

  @override
  void initState() {
    super.initState();
    _costController = TextEditingController();
    _odoController = TextEditingController(
      text: widget.currentOdometer > 0
          ? widget.currentOdometer.toStringAsFixed(0)
          : '',
    );
    _notesController = TextEditingController();

    final presets = _currentPresets;
    _selectedPresetTitle = presets.first;
    _titleController = TextEditingController(text: presets.first);
  }

  @override
  void dispose() {
    _costController.dispose();
    _titleController.dispose();
    _odoController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _onCategoryChanged(String newCat) {
    setState(() {
      _selectedCategory = newCat;
      final presets = _currentPresets;
      _selectedPresetTitle = presets.first;
      if (presets.first != 'Custom Title...') {
        _titleController.text = presets.first;
      } else {
        _titleController.clear();
      }
    });
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: now.add(const Duration(days: 365)),
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
        _selectedDate = picked;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final rawTitle =
        (_isCustomTitle ? _titleController.text : (_selectedPresetTitle ?? ''))
            .trim();
    if (rawTitle.isEmpty) return;

    final cost = double.tryParse(_costController.text.trim()) ?? 0.0;
    if (cost <= 0) return;

    final odo = double.tryParse(_odoController.text.trim());
    final note = _notesController.text.trim().isEmpty
        ? null
        : _notesController.text.trim();

    final serviceLogService = ref.read(serviceLogServiceProvider);
    await serviceLogService.addServiceLog(
      vehicleId: widget.vehicleId,
      date: _selectedDate,
      category: _selectedCategory,
      title: rawTitle,
      cost: cost,
      odometer: odo,
      note: note,
    );

    if (!mounted) return;
    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF1E1E2C),
        content: Text(
          '✅ Added "$rawTitle" (৳${cost.toStringAsFixed(0)})',
          style: const TextStyle(color: Colors.white),
        ),
        action: SnackBarAction(
          label: 'View History',
          textColor: const Color(0xFF2ECC71),
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const RemindersScreen(initialTabIndex: 1),
              ),
            );
          },
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Drag Handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFF333348),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 2. Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2ECC71).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.build_circle_rounded,
                      color: Color(0xFF2ECC71),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Add Cost / Service',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // 3. Category Selector Chips
              const Text(
                'Expense Category',
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
                  children: _categories.map((cat) {
                    final catId = cat['id'] as String;
                    final isSelected = _selectedCategory == catId;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        avatar: Icon(
                          cat['icon'] as IconData,
                          size: 15,
                          color: isSelected
                              ? const Color(0xFF2ECC71)
                              : AppColors.textTertiary,
                        ),
                        label: Text(cat['label'] as String),
                        selected: isSelected,
                        onSelected: (val) {
                          if (val) _onCategoryChanged(catId);
                        },
                        selectedColor:
                            const Color(0xFF2ECC71).withValues(alpha: 0.18),
                        backgroundColor: const Color(0xFF1E1E2A),
                        side: BorderSide(
                          color: isSelected
                              ? const Color(0xFF2ECC71)
                              : const Color(0xFF2E2E3E),
                        ),
                        labelStyle: TextStyle(
                          color: isSelected
                              ? const Color(0xFF2ECC71)
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

              const SizedBox(height: 16),

              // 4. Title Presets
              const Text(
                'Service / Item Title',
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
                  children: _currentPresets.map((preset) {
                    final isSelected = _selectedPresetTitle == preset;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(preset),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _selectedPresetTitle = preset;
                              if (preset != 'Custom Title...') {
                                _titleController.text = preset;
                              } else {
                                _titleController.clear();
                              }
                            });
                          }
                        },
                        selectedColor:
                            AppColors.primary.withValues(alpha: 0.2),
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

              // Custom Title TextField
              if (_isCustomTitle) ...[
                const SizedBox(height: 10),
                TextFormField(
                  controller: _titleController,
                  style: const TextStyle(
                      color: AppColors.textPrimary, fontSize: 14),
                  validator: (val) => val == null || val.trim().isEmpty
                      ? 'Please enter custom title'
                      : null,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFF1E1E2A),
                    hintText: 'e.g. Engine Flush, Wiper Blade Replacement...',
                    hintStyle: const TextStyle(
                        color: AppColors.textTertiary, fontSize: 13),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
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
                          color: AppColors.primary, width: 1.5),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // 5. Cost Input Field
              const Text(
                'Total Cost (৳) *',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _costController,
                keyboardType: TextInputType.number,
                style: const TextStyle(
                    color: AppColors.textPrimary, fontSize: 14),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter cost amount';
                  }
                  final parsed = double.tryParse(val.trim());
                  if (parsed == null || parsed <= 0) {
                    return 'Enter a valid cost amount';
                  }
                  return null;
                },
                decoration: InputDecoration(
                  prefixText: '৳ ',
                  prefixStyle: const TextStyle(
                      color: AppColors.primary, fontWeight: FontWeight.bold),
                  filled: true,
                  fillColor: const Color(0xFF1E1E2A),
                  hintText: 'e.g. 2500',
                  hintStyle: const TextStyle(
                      color: AppColors.textTertiary, fontSize: 13),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
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
                        color: AppColors.primary, width: 1.5),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // 6. Odometer & Date Row
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Odometer (km)',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _odoController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(
                              color: AppColors.textPrimary, fontSize: 14),
                          decoration: InputDecoration(
                            suffixText: 'km',
                            suffixStyle: const TextStyle(
                                color: AppColors.textTertiary, fontSize: 12),
                            filled: true,
                            fillColor: const Color(0xFF1E1E2A),
                            hintText: 'e.g. 5000',
                            hintStyle: const TextStyle(
                                color: AppColors.textTertiary, fontSize: 13),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  const BorderSide(color: Color(0xFF2E2E3E)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  const BorderSide(color: Color(0xFF2E2E3E)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                  color: AppColors.primary, width: 1.5),
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
                          'Date',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        InkWell(
                          onTap: _pickDate,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 13),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E1E2A),
                              borderRadius: BorderRadius.circular(12),
                              border:
                                  Border.all(color: const Color(0xFF2E2E3E)),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.calendar_today_rounded,
                                  color: AppColors.primary,
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    dateFormat.format(_selectedDate),
                                    style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 13,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // 7. Notes / Workshop Input
              const Text(
                'Notes / Workshop Name (Optional)',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _notesController,
                style: const TextStyle(
                    color: AppColors.textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFF1E1E2A),
                  hintText: 'e.g. Navana Toyota Workshop, Gulshan',
                  hintStyle: const TextStyle(
                      color: AppColors.textTertiary, fontSize: 13),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
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
                        color: AppColors.primary, width: 1.5),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // 8. Buttons Row
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF2E2E3E)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
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
                          backgroundColor: const Color(0xFF2ECC71),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Save Cost',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
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
