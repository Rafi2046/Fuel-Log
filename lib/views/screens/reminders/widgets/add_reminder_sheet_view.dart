part of 'add_reminder_sheet.dart';

mixin _AddReminderSheetView on ConsumerState<AddReminderSheet> {
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
                  children: kReminderTitlePresets.map((preset) {
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
                      ? kReminderOilTypes.firstWhere(
                          (e) => e['name'] == _selectedOilType,
                          orElse: () => kReminderOilTypes.first,
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
                  items: kReminderOilTypes.map((opt) {
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
              SheetActionBar(
                primaryLabel: 'Save Reminder',
                onPrimary: _submit,
                primaryColor: AppColors.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
