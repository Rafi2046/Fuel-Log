part of 'add_reminder_sheet.dart';

mixin _AddReminderSheetController on ConsumerState<AddReminderSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _targetOdoController;
  DateTime? _selectedTargetDate;
  String? _selectedTitle;
  String? _selectedOilType;


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
    if (kReminderTitlePresets.contains(initialTitle)) {
      _selectedTitle = initialTitle;
    } else {
      _selectedTitle = 'Custom Title...';
    }
    _targetOdoController = TextEditingController(
      text: r?.targetOdometer != null ? r!.targetOdometer!.toStringAsFixed(0) : '',
    );
    _selectedTargetDate = r?.targetDate;
    _selectedOilType = r?.oilType;

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

    final option = kReminderOilTypes.firstWhere(
      (e) => e['label'] == label || e['name'] == label,
      orElse: () => kReminderOilTypes.first,
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
      lastDate: now.add(Duration(days: 365 * 5)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
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

    double? intervalKm;
    if (_isEngineOil && _selectedOilType != null) {
      final match = kReminderOilTypes
          .where((e) => e['name'] == _selectedOilType || e['label'] == _selectedOilType)
          .firstOrNull;
      if (match != null) {
        intervalKm = match['km'] as double?;
      }
    }

    final db = ref.read(databaseProvider);
    final existing = widget.existingReminder;
    late final int reminderId;

    if (existing != null) {
      await db.updateReminder(
        Reminder(
          id: existing.id,
          vehicleId: vId,
          title: finalTitle,
          targetDate: _selectedTargetDate,
          targetOdometer: targetOdometer,
          isCompleted: existing.isCompleted,
          oilType: _selectedOilType,
          intervalKm: intervalKm,
        ),
      );
      reminderId = existing.id;

      await NotificationService().cancelNotification(reminderId);
    } else {
      reminderId = await db.insertReminder(
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
          oilType: _selectedOilType != null
              ? drift.Value(_selectedOilType)
              : const drift.Value.absent(),
          intervalKm: intervalKm != null
              ? drift.Value(intervalKm)
              : const drift.Value.absent(),
        ),
      );
    }

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
          backgroundColor: AppColors.control,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

}
