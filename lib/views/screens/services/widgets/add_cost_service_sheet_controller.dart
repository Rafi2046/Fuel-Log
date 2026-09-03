part of 'add_cost_service_sheet.dart';

mixin _AddCostServiceSheetController on ConsumerState<AddCostServiceSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _costController;
  late TextEditingController _titleController;
  late TextEditingController _odoController;
  late TextEditingController _notesController;
  DateTime _selectedDate = DateTime.now();

  String _selectedCategory = 'Maintenance';
  String? _selectedPresetTitle;

  bool get _isCustomTitle => _selectedPresetTitle == 'Custom Title...';

  List<String> get _currentPresets {
    final cat = kCostServiceCategories.firstWhere(
      (c) => c['id'] == _selectedCategory,
      orElse: () => kCostServiceCategories.first,
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
      lastDate: now.add(Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: AppColors.surface,
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
        backgroundColor: AppColors.control,
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

}
