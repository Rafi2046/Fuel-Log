part of 'add_cost_service_sheet.dart';

mixin _AddCostServiceSheetView on ConsumerState<AddCostServiceSheet>, _AddCostServiceSheetController {
  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
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
                    color: AppColors.borderStrong,
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
                    child: Icon(
                      Icons.build_circle_rounded,
                      color: Color(0xFF2ECC71),
                      size: 22,
                    ),
                  ),
                  SizedBox(width: 12),
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

              SizedBox(height: 20),

              // 3. Category Selector Chips
              Text(
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
                  children: kCostServiceCategories.map((cat) {
                    final catId = cat['id'] as String;
                    final isSelected = _selectedCategory == catId;
                    return Padding(
                      padding: EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        avatar: Icon(
                          cat['icon'] as IconData,
                          size: 15,
                          color: isSelected
                              ? Color(0xFF2ECC71)
                              : AppColors.textTertiary,
                        ),
                        label: Text(cat['label'] as String),
                        selected: isSelected,
                        onSelected: (val) {
                          if (val) _onCategoryChanged(catId);
                        },
                        selectedColor:
                            const Color(0xFF2ECC71).withValues(alpha: 0.18),
                        backgroundColor: AppColors.inputFill,
                        side: BorderSide(
                          color: isSelected
                              ? Color(0xFF2ECC71)
                              : AppColors.border,
                        ),
                        labelStyle: TextStyle(
                          color: isSelected
                              ? Color(0xFF2ECC71)
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

              SizedBox(height: 16),

              // 4. Title Presets
              Text(
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
                        backgroundColor: AppColors.inputFill,
                        side: BorderSide(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.border,
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
                SizedBox(height: 10),
                TextFormField(
                  controller: _titleController,
                  style: TextStyle(
                      color: AppColors.textPrimary, fontSize: 14),
                  validator: (val) => val == null || val.trim().isEmpty
                      ? 'Please enter custom title'
                      : null,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColors.inputFill,
                    hintText: 'e.g. Engine Flush, Wiper Blade Replacement...',
                    hintStyle: TextStyle(
                        color: AppColors.textTertiary, fontSize: 13),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                          color: AppColors.primary, width: 1.5),
                    ),
                  ),
                ),
              ],

              SizedBox(height: 16),

              // 5. Cost Input Field
              Text(
                'Total Cost (৳) *',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 6),
              TextFormField(
                controller: _costController,
                keyboardType: TextInputType.number,
                style: TextStyle(
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
                  prefixStyle: TextStyle(
                      color: AppColors.primary, fontWeight: FontWeight.bold),
                  filled: true,
                  fillColor: AppColors.inputFill,
                  hintText: 'e.g. 2500',
                  hintStyle: TextStyle(
                      color: AppColors.textTertiary, fontSize: 13),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.border),
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
                        Text(
                          'Odometer (km)',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 6),
                        TextFormField(
                          controller: _odoController,
                          keyboardType: TextInputType.number,
                          style: TextStyle(
                              color: AppColors.textPrimary, fontSize: 14),
                          decoration: InputDecoration(
                            suffixText: 'km',
                            suffixStyle: TextStyle(
                                color: AppColors.textTertiary, fontSize: 12),
                            filled: true,
                            fillColor: AppColors.inputFill,
                            hintText: 'e.g. 5000',
                            hintStyle: TextStyle(
                                color: AppColors.textTertiary, fontSize: 13),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  BorderSide(color: AppColors.border),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  BorderSide(color: AppColors.border),
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
                    child: CustomDatePickerRow(
                      label: 'Date',
                      date: _selectedDate,
                      onTap: _pickDate,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // 7. Notes / Workshop Input
              CustomSheetTextField(
                label: 'Notes / Workshop Name (Optional)',
                controller: _notesController,
                hintText: 'e.g. Navana Toyota Workshop, Gulshan',
                maxLines: 2,
              ),

              const SizedBox(height: 24),

              // 8. Buttons Row
              SheetActionBar(
                primaryLabel: 'Save Cost',
                onPrimary: _submit,
                primaryColor: const Color(0xFF2ECC71),
              ),
            ],
          ),
        ),
      ),
          ),
        ],
      ),
    );
  }
}
