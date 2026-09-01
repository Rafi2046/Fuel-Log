import 'package:easy_localization/easy_localization.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../viewmodels/e_document_viewmodel.dart';
import '../../../../viewmodels/vehicle_viewmodel.dart';
import '../../../components/forms/sheet_action_bar.dart';

/// Modal bottom sheet to upload and record a new E-Document.
class AddEDocumentSheet extends ConsumerStatefulWidget {
  const AddEDocumentSheet({super.key, this.initialVehicleId});

  final int? initialVehicleId;

  static Future<bool?> show(
    BuildContext context, {
    int? initialVehicleId,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF121218),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => AddEDocumentSheet(
        initialVehicleId: initialVehicleId,
      ),
    );
  }

  @override
  ConsumerState<AddEDocumentSheet> createState() => _AddEDocumentSheetState();
}

class _AddEDocumentSheetState extends ConsumerState<AddEDocumentSheet> {
  final _formKey = GlobalKey<FormState>();

  EDocumentType _selectedType = EDocumentType.taxToken;
  int? _selectedVehicleId;
  DateTime? _expiryDate;
  bool _noExpiry = false;

  String? _pickedFilePath;
  bool _isSaving = false;

  final _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _selectedVehicleId = widget.initialVehicleId;
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      if (picked != null) {
        setState(() => _pickedFilePath = picked.path);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error selecting image: $e')),
      );
    }
  }

  Future<void> _pickPdf() async {
    try {
      final result = await FilePickerPlatform.instance.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg'],
      );
      if (result.isNotEmpty && result.first.path != null) {
        setState(() => _pickedFilePath = result.first.path);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error selecting file: $e')),
      );
    }
  }

  void _showPickerOptions() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF1B1B24),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(LucideIcons.camera, color: Color(0xFFFF7A50)),
                title: const Text('Take Photo with Camera',
                    style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(LucideIcons.image, color: Color(0xFF38BDF8)),
                title: const Text('Choose Image from Gallery',
                    style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading:
                    const Icon(LucideIcons.fileText, color: Color(0xFF10B981)),
                title: const Text('Upload PDF / Document File',
                    style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _pickPdf();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiryDate ?? DateTime.now().add(const Duration(days: 365)),
      firstDate: DateTime(2000),
      lastDate: DateTime(2050),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFFFF7A50),
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
        _expiryDate = picked;
        _noExpiry = false;
      });
    }
  }

  Future<void> _saveDocument() async {
    if (!_formKey.currentState!.validate()) return;
    if (_pickedFilePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please attach a photo or PDF of the document'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final controller = ref.read(eDocumentControllerProvider);
      await controller.addDocumentFromPath(
        vehicleId: _selectedVehicleId,
        docType: _selectedType.code,
        sourcePath: _pickedFilePath!,
        expiryDate: _noExpiry ? null : _expiryDate,
      );

      if (!mounted) return;
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_selectedType.displayName} saved to vault!'),
          backgroundColor: const Color(0xFFFF7A50),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save document: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final vehiclesAsync = ref.watch(vehiclesProvider);
    final vehicles = vehiclesAsync.valueOrNull ?? [];

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
              // Drag handle
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
                      color: const Color(0xFFFF7A50).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      LucideIcons.filePlus,
                      color: Color(0xFFFF7A50),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Add E-Document',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 1. Document Type Dropdown
              Text(
                'Document Type',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF94A3B8),
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFF1B1B24),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  border: Border.all(color: const Color(0xFF262638), width: 1),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<EDocumentType>(
                    value: _selectedType,
                    dropdownColor: const Color(0xFF1B1B24),
                    isExpanded: true,
                    icon: const Icon(LucideIcons.chevronDown,
                        size: 16, color: Color(0xFFA1A1AA)),
                    items: EDocumentType.values.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text(
                          type.displayName,
                          style: GoogleFonts.inter(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedType = val;
                          if (val == EDocumentType.drivingLicense) {
                            _selectedVehicleId = null; // Personal by default
                          }
                        });
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 2. Vehicle Association Dropdown
              Text(
                'Associated Vehicle',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF94A3B8),
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFF1B1B24),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  border: Border.all(color: const Color(0xFF262638), width: 1),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int?>(
                    value: _selectedVehicleId,
                    dropdownColor: const Color(0xFF1B1B24),
                    isExpanded: true,
                    icon: const Icon(LucideIcons.chevronDown,
                        size: 16, color: Color(0xFFA1A1AA)),
                    items: [
                      DropdownMenuItem<int?>(
                        value: null,
                        child: Text(
                          'Personal / User (Not Vehicle Specific)',
                          style: GoogleFonts.inter(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF94A3B8),
                          ),
                        ),
                      ),
                      ...vehicles.map((v) {
                        return DropdownMenuItem<int?>(
                          value: v.id,
                          child: Text(
                            '${v.name} (${v.type})',
                            style: GoogleFonts.inter(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        );
                      }),
                    ],
                    onChanged: (val) =>
                        setState(() => _selectedVehicleId = val),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 3. File / Camera / Gallery Attachment
              Text(
                'Document File (Image or PDF)',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF94A3B8),
                ),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: _showPickerOptions,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                child: Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B1B24),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    border: Border.all(
                      color: _pickedFilePath != null
                          ? const Color(0xFFFF7A50)
                          : const Color(0xFF262638),
                      width: 1.2,
                    ),
                  ),
                  child: _pickedFilePath != null
                      ? Row(
                          children: [
                            Icon(
                              _pickedFilePath!.endsWith('.pdf')
                                  ? LucideIcons.fileText
                                  : LucideIcons.image,
                              color: const Color(0xFFFF7A50),
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _pickedFilePath!.split('/').last,
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Tap to change file',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      color: const Color(0xFFFF7A50),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              LucideIcons.checkCircle2,
                              color: Color(0xFF10B981),
                              size: 20,
                            ),
                          ],
                        )
                      : Column(
                          children: [
                            const Icon(
                              LucideIcons.uploadCloud,
                              color: Color(0xFFFF7A50),
                              size: 28,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Attach Camera Photo, Gallery, or PDF',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'JPG, PNG, PDF up to 15MB',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: const Color(0xFF71717A),
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 16),

              // 4. Expiry Date Picker
              Text(
                'Expiry Date',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF94A3B8),
                ),
              ),
              const SizedBox(height: 6),
              InkWell(
                onTap: _noExpiry ? null : _pickDate,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: _noExpiry
                        ? const Color(0xFF121218)
                        : const Color(0xFF1B1B24),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    border:
                        Border.all(color: const Color(0xFF262638), width: 1),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        LucideIcons.calendar,
                        size: 16,
                        color: _noExpiry
                            ? const Color(0xFF52525B)
                            : const Color(0xFFFF7A50),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _noExpiry
                              ? 'Lifetime / No Expiry'
                              : (_expiryDate != null
                                  ? DateFormat('dd MMMM yyyy')
                                      .format(_expiryDate!)
                                  : 'Select Expiry Date'),
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: _noExpiry || _expiryDate == null
                                ? const Color(0xFF94A3B8)
                                : AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 4),

              Row(
                children: [
                  Checkbox(
                    value: _noExpiry,
                    activeColor: const Color(0xFFFF7A50),
                    onChanged: (val) {
                      setState(() {
                        _noExpiry = val ?? false;
                        if (_noExpiry) _expiryDate = null;
                      });
                    },
                  ),
                  Text(
                    'No Expiry Date (Lifetime)',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 5. Actions
              SheetActionBar(
                primaryLabel: _isSaving ? 'Saving...' : 'Save Document',
                onPrimary: _saveDocument,
                onCancel: () => Navigator.of(context).pop(),
                primaryColor: const Color(0xFFFF7A50),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
