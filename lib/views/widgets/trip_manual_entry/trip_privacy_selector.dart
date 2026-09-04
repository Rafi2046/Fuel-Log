import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/services/trip_category_prefs.dart';
import 'trip_form_fields.dart';

/// Privacy & purpose dropdown selector with custom category support.
class TripPrivacySelector extends StatelessWidget {
  const TripPrivacySelector({
    super.key,
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

    final selected =
        items.any((item) => item.value == value) ? value : 'private';

    return DropdownButtonFormField<String>(
      key: ValueKey('$selected-${customCategories.length}'),
      initialValue: selected,
      dropdownColor: AppColors.card,
      icon: Icon(
        Icons.keyboard_arrow_down_rounded,
        color: AppColors.textTertiary,
      ),
      decoration: TripFieldDecor.base(
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

/// Dialog allowing user to enter and save a new custom trip category.
class AddCategoryDialog extends StatefulWidget {
  const AddCategoryDialog({super.key});

  @override
  State<AddCategoryDialog> createState() => _AddCategoryDialogState();
}

class _AddCategoryDialogState extends State<AddCategoryDialog> {
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
