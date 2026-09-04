import 'dart:io';
import 'package:drift/drift.dart' as drift;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/constants/document_categories.dart';
import '../../../../core/database/app_database.dart';
import '../../../../viewmodels/document_vault_viewmodel.dart';
import '../../../components/forms/custom_sheet_text_field.dart';
import '../../../components/forms/sheet_action_bar.dart';

/// Modal bottom sheet for adding or editing a vehicle document / license.
class AddEditDocumentSheet extends ConsumerStatefulWidget {
  const AddEditDocumentSheet({
    super.key,
    required this.vehicleId,
    this.existingDoc,
  });

  final int vehicleId;
  final VehicleDocument? existingDoc;

  static Future<bool?> show(
    BuildContext context, {
    required int vehicleId,
    VehicleDocument? existingDoc,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.appBar,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => AddEditDocumentSheet(
        vehicleId: vehicleId,
        existingDoc: existingDoc,
      ),
    );
  }

  @override
  ConsumerState<AddEditDocumentSheet> createState() =>
      _AddEditDocumentSheetState();
}

class _AddEditDocumentSheetState extends ConsumerState<AddEditDocumentSheet> {
  final _formKey = GlobalKey<FormState>();
  late DocumentCategory _selectedCategory;
  late TextEditingController _titleController;
  late TextEditingController _numberController;
  late TextEditingController _authorityController;
  late TextEditingController _costController;
  late TextEditingController _noteController;

  DateTime? _issueDate;
  DateTime? _expiryDate;
  bool _noExpiry = false;

  String? _frontImagePath;
  String? _backImagePath;

  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final doc = widget.existingDoc;
    _selectedCategory = doc != null
        ? DocumentCategoryX.fromCode(doc.category)
        : DocumentCategory.taxToken;

    _titleController = TextEditingController(
        text: doc?.title ?? _selectedCategory.localizedName);
    _numberController =
        TextEditingController(text: doc?.documentNumber ?? '');
    _authorityController =
        TextEditingController(text: doc?.issuingAuthority ?? '');
    _costController = TextEditingController(
        text: doc?.cost != null ? doc!.cost!.toStringAsFixed(0) : '');
    _noteController = TextEditingController(text: doc?.note ?? '');

    _issueDate = doc?.issueDate;
    _expiryDate = doc?.expiryDate;
    _noExpiry = doc != null && doc.expiryDate == null;

    _frontImagePath = doc?.frontImagePath;
    _backImagePath = doc?.backImagePath;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _numberController.dispose();
    _authorityController.dispose();
    _costController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _onCategoryChanged(DocumentCategory category) {
    setState(() {
      _selectedCategory = category;
      if (_titleController.text.isEmpty ||
          DocumentCategory.values
              .any((c) => c.localizedName == _titleController.text)) {
        _titleController.text = category.localizedName;
      }
      if (category == DocumentCategory.nid ||
          category == DocumentCategory.invoice) {
        _noExpiry = true;
        _expiryDate = null;
      }
    });
  }

  Future<void> _pickImage(
      {required bool isFront, required ImageSource source}) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 1800,
        maxHeight: 1800,
        imageQuality: 85,
      );
      if (picked == null) return;

      final appDir = await getApplicationDocumentsDirectory();
      final vaultDir = Directory('${appDir.path}/vault_documents');
      if (!vaultDir.existsSync()) {
        vaultDir.createSync(recursive: true);
      }

      final fileName =
          'doc_${DateTime.now().millisecondsSinceEpoch}_${picked.name}';
      final saved = await File(picked.path).copy('${vaultDir.path}/$fileName');

      setState(() {
        if (isFront) {
          _frontImagePath = saved.path;
        } else {
          _backImagePath = saved.path;
        }
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  void _showImageSourceDialog(bool isFront) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF1B1B27),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading:
                      const Icon(LucideIcons.camera, color: Color(0xFF38BDF8)),
                  title: Text(
                    'refuelOcrCamera'.tr(),
                    style: AppTextStyles.body,
                  ),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _pickImage(isFront: isFront, source: ImageSource.camera);
                  },
                ),
                ListTile(
                  leading:
                      const Icon(LucideIcons.image, color: Color(0xFF10B981)),
                  title: Text(
                    'refuelOcrGallery'.tr(),
                    style: AppTextStyles.body,
                  ),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _pickImage(isFront: isFront, source: ImageSource.gallery);
                  },
                ),
                if ((isFront && _frontImagePath != null) ||
                    (!isFront && _backImagePath != null))
                  ListTile(
                    leading: const Icon(LucideIcons.trash2,
                        color: Color(0xFFEF4444)),
                    title: Text(
                      'deleteDocument'.tr(),
                      style: AppTextStyles.body
                          .copyWith(color: const Color(0xFFEF4444)),
                    ),
                    onTap: () {
                      Navigator.of(ctx).pop();
                      setState(() {
                        if (isFront) {
                          _frontImagePath = null;
                        } else {
                          _backImagePath = null;
                        }
                      });
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickDate({required bool isIssue}) async {
    final initialDate = isIssue
        ? (_issueDate ?? DateTime.now())
        : (_expiryDate ?? DateTime.now().add(Duration(days: 365)));

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2050),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppColors.primary,
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
        if (isIssue) {
          _issueDate = picked;
        } else {
          _expiryDate = picked;
          _noExpiry = false;
        }
      });
    }
  }

  Future<void> _saveDocument() async {
    if (!_formKey.currentState!.validate()) return;

    final controller = ref.read(documentVaultControllerProvider);
    final cost = double.tryParse(_costController.text.trim());

    if (widget.existingDoc == null) {
      // Insert new
      final companion = VehicleDocumentsCompanion(
        vehicleId: drift.Value(widget.vehicleId),
        category: drift.Value(_selectedCategory.code),
        title: drift.Value(_titleController.text.trim()),
        documentNumber: drift.Value(_numberController.text.trim().isNotEmpty
            ? _numberController.text.trim()
            : null),
        issueDate: drift.Value(_issueDate),
        expiryDate: drift.Value(_noExpiry ? null : _expiryDate),
        frontImagePath: drift.Value(_frontImagePath),
        backImagePath: drift.Value(_backImagePath),
        cost: drift.Value(cost),
        issuingAuthority: drift.Value(_authorityController.text.trim().isNotEmpty
            ? _authorityController.text.trim()
            : null),
        note: drift.Value(_noteController.text.trim().isNotEmpty
            ? _noteController.text.trim()
            : null),
      );

      await controller.addDocument(companion);
    } else {
      // Update existing
      final updated = widget.existingDoc!.copyWith(
        category: _selectedCategory.code,
        title: _titleController.text.trim(),
        documentNumber: drift.Value(_numberController.text.trim().isNotEmpty
            ? _numberController.text.trim()
            : null),
        issueDate: drift.Value(_issueDate),
        expiryDate: drift.Value(_noExpiry ? null : _expiryDate),
        frontImagePath: drift.Value(_frontImagePath),
        backImagePath: drift.Value(_backImagePath),
        cost: drift.Value(cost),
        issuingAuthority: drift.Value(_authorityController.text.trim().isNotEmpty
            ? _authorityController.text.trim()
            : null),
        note: drift.Value(_noteController.text.trim().isNotEmpty
            ? _noteController.text.trim()
            : null),
      );

      await controller.updateDocument(updated);
    }

    if (!mounted) return;
    Navigator.of(context).pop(true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('docSavedSuccess'.tr()),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isEditing = widget.existingDoc != null;

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
              // Drag Handle
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

              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      LucideIcons.fileLock2,
                      color: Color(0xFF10B981),
                      size: 22,
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    isEditing ? 'editDocument'.tr() : 'addDocument'.tr(),
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 1. Document Category Chips
              Text(
                'docCategoryField'.tr(),
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF94A3B8),
                ),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: DocumentCategory.values.map((cat) {
                    final isSelected = cat == _selectedCategory;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              cat.icon,
                              size: 14,
                              color: isSelected
                                  ? Colors.white
                                  : const Color(0xFF94A3B8),
                            ),
                            const SizedBox(width: 5),
                            Text(cat.localizedName),
                          ],
                        ),
                        selected: isSelected,
                        onSelected: (_) => _onCategoryChanged(cat),
                        selectedColor: AppColors.primary,
                        backgroundColor: const Color(0xFF1B1B27),
                        labelStyle: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w500,
                          color: isSelected
                              ? Colors.white
                              : Color(0xFF94A3B8),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.hairline,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),

              // 2. Title & Number
              CustomSheetTextField(
                controller: _titleController,
                label: 'docTitleField'.tr(),
                hintText: 'e.g. Tax Token 2024-2025',
                prefixIcon: const Icon(LucideIcons.heading,
                    size: 16, color: Color(0xFF71717A)),
                validator: (val) => val == null || val.trim().isEmpty
                    ? 'Required'
                    : null,
              ),
              const SizedBox(height: 14),

              CustomSheetTextField(
                controller: _numberController,
                label: 'docNumberField'.tr(),
                hintText: 'e.g. DHAKA-METRO-LA-1234',
                prefixIcon: const Icon(LucideIcons.hash,
                    size: 16, color: Color(0xFF71717A)),
              ),
              const SizedBox(height: 16),

              // 3. Issue & Expiry Dates
              Row(
                children: [
                  Expanded(
                    child: _buildDateTile(
                      label: 'docIssueDateField'.tr(),
                      date: _issueDate,
                      onTap: () => _pickDate(isIssue: true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildDateTile(
                      label: 'docExpiryDateField'.tr(),
                      date: _expiryDate,
                      disabled: _noExpiry,
                      onTap: () => _pickDate(isIssue: false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // No Expiry Checkbox
              Row(
                children: [
                  Checkbox(
                    value: _noExpiry,
                    activeColor: AppColors.primary,
                    onChanged: (val) {
                      setState(() {
                        _noExpiry = val ?? false;
                        if (_noExpiry) _expiryDate = null;
                      });
                    },
                  ),
                  Text(
                    'docNoExpiryToggle'.tr(),
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 4. Photo Attachments (Front & Back)
              Text(
                'Attachments (Photos)',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF94A3B8),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildPhotoBox(
                      label: 'docFrontPhoto'.tr(),
                      imagePath: _frontImagePath,
                      onTap: () => _showImageSourceDialog(true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildPhotoBox(
                      label: 'docBackPhoto'.tr(),
                      imagePath: _backImagePath,
                      onTap: () => _showImageSourceDialog(false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 5. Authority & Cost
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: CustomSheetTextField(
                      controller: _authorityController,
                      label: 'docAuthorityField'.tr(),
                      hintText: 'e.g. BRTA',
                      prefixIcon: const Icon(LucideIcons.building,
                          size: 16, color: Color(0xFF71717A)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 1,
                    child: CustomSheetTextField(
                      controller: _costController,
                      label: 'docCostField'.tr(),
                      hintText: '৳ 0',
                      keyboardType: TextInputType.number,
                      prefixIcon: const Icon(LucideIcons.banknote,
                          size: 16, color: Color(0xFF71717A)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // 6. Notes
              CustomSheetTextField(
                controller: _noteController,
                label: 'docNoteField'.tr(),
                hintText: 'Additional details or reminders...',
                maxLines: 2,
                prefixIcon: const Icon(LucideIcons.fileEdit,
                    size: 16, color: Color(0xFF71717A)),
              ),
              const SizedBox(height: 24),

              // Submit Action
              SheetActionBar(
                primaryLabel:
                    isEditing ? 'editDocument'.tr() : 'addDocument'.tr(),
                onPrimary: _saveDocument,
                onCancel: () => Navigator.of(context).pop(),
                primaryColor: AppColors.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateTile({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
    bool disabled = false,
  }) {
    return InkWell(
      onTap: disabled ? null : onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: disabled ? Color(0xFF12121A) : Color(0xFF1B1B27),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: AppColors.hairline,
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 10.5,
                color: const Color(0xFF71717A),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  LucideIcons.calendar,
                  size: 14,
                  color: disabled
                      ? const Color(0xFF52525B)
                      : const Color(0xFF38BDF8),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    disabled
                        ? 'Lifetime'
                        : (date != null
                            ? DateFormat('dd MMM yyyy').format(date)
                            : 'Select date'),
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: disabled
                          ? Color(0xFF71717A)
                          : (date != null
                              ? AppColors.textPrimary
                              : const Color(0xFF71717A)),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoBox({
    required String label,
    required String? imagePath,
    required VoidCallback onTap,
  }) {
    final hasImage = imagePath != null && File(imagePath).existsSync();

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: Color(0xFF1B1B27),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: hasImage ? Color(0xFF10B981) : AppColors.hairline,
            width: 1,
          ),
        ),
        child: hasImage
            ? ClipRRect(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd - 1),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.file(
                      File(imagePath),
                      fit: BoxFit.cover,
                    ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        color: Colors.black.withValues(alpha: 0.65),
                        child: Text(
                          label,
                          style: GoogleFonts.inter(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    LucideIcons.camera,
                    size: 22,
                    color: Color(0xFF71717A),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '+ Upload',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF38BDF8),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
